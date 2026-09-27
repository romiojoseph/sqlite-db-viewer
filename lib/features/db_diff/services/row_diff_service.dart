import 'dart:typed_data';
import '../../../core/utils/byte_formatter.dart';
import '../../../data/models/db_table.dart';
import '../../../data/services/sqlite_service.dart';
import '../models/column_diff.dart';
import '../models/row_diff.dart';
import '../models/schema_diff_result.dart';
import '../models/table_diff_result.dart';
import 'row_hash_service.dart';

class RowDiffService {
  final SqliteService serviceA;
  final SqliteService serviceB;

  const RowDiffService({required this.serviceA, required this.serviceB});

  Future<TableDiffResult> diffTable(
    String tableName,
    SchemaDiffResult schemaDiff, {
    DbTable? tableA,
    int maxDetailCap = 500,
    int maxNoPkRowsCap = 50000,
  }) async {
    if (!schemaDiff.existsInA) {
      return TableDiffResult(
        tableName: tableName,
        status: TableDiffStatus.onlyInB,
        schemaDiff: schemaDiff,
        statusMessage: 'Table exists only in Database B',
      );
    }

    if (!schemaDiff.existsInB) {
      return TableDiffResult(
        tableName: tableName,
        status: TableDiffStatus.onlyInA,
        schemaDiff: schemaDiff,
        statusMessage: 'Table exists only in Database A',
      );
    }

    if (!schemaDiff.isIdentical) {
      return TableDiffResult(
        tableName: tableName,
        status: TableDiffStatus.schemaChanged,
        schemaDiff: schemaDiff,
        statusMessage:
            'Schema structure mismatch; row-level comparison skipped',
      );
    }

    final dbA = serviceA.db;
    final dbB = serviceB.db;

    if (dbA == null || dbB == null) {
      return TableDiffResult(
        tableName: tableName,
        status: TableDiffStatus.identical,
        schemaDiff: schemaDiff,
        statusMessage: 'Databases are not open',
      );
    }

    final resolvedTableA =
        tableA ??
        serviceA.getTables().cast<DbTable?>().firstWhere(
          (t) => t?.name == tableName,
          orElse: () => null,
        );

    if (resolvedTableA == null) {
      return TableDiffResult(
        tableName: tableName,
        status: TableDiffStatus.onlyInB,
        schemaDiff: schemaDiff,
        statusMessage: 'Table definition could not be resolved from Database A',
      );
    }

    final pkCols = resolvedTableA.columns
        .where((c) => c.isPrimaryKey)
        .map((c) => c.name)
        .toList();
    final allColumns = resolvedTableA.columns.map((c) => c.name).toList();

    final escapedTable = tableName.replaceAll('"', '""');
    final countA = _getRowCount(dbA, escapedTable);
    final countB = _getRowCount(dbB, escapedTable);

    if (countA == null || countB == null) {
      return TableDiffResult(
        tableName: tableName,
        status: TableDiffStatus.error,
        schemaDiff: schemaDiff,
        statusMessage: 'Failed to query row counts from database',
      );
    }

    if (countA == 0 && countB == 0) {
      return TableDiffResult(
        tableName: tableName,
        status: TableDiffStatus.emptyInBoth,
        schemaDiff: schemaDiff,
        totalRowsA: 0,
        totalRowsB: 0,
        hasPrimaryKey: pkCols.isNotEmpty,
        primaryKeyColumns: pkCols,
        statusMessage: 'Empty table in both databases',
      );
    }

    if (pkCols.isEmpty) {
      if (countA > maxNoPkRowsCap || countB > maxNoPkRowsCap) {
        return TableDiffResult(
          tableName: tableName,
          status: TableDiffStatus.notCompared,
          schemaDiff: schemaDiff,
          totalRowsA: countA,
          totalRowsB: countB,
          hasPrimaryKey: false,
          statusMessage:
              'Table exceeds $maxNoPkRowsCap rows without a primary key; in-memory comparison skipped',
        );
      }
    } else {
      const maxPkRowsCap = 100000;
      if (countA > maxPkRowsCap || countB > maxPkRowsCap) {
        return TableDiffResult(
          tableName: tableName,
          status: TableDiffStatus.notCompared,
          schemaDiff: schemaDiff,
          totalRowsA: countA,
          totalRowsB: countB,
          hasPrimaryKey: true,
          primaryKeyColumns: pkCols,
          statusMessage:
              'Table exceeds $maxPkRowsCap rows; in-memory comparison skipped to prevent memory exhaustion',
        );
      }
    }

    final rowsA = _fetchRows(dbA, escapedTable, pkCols);
    final rowsB = _fetchRows(dbB, escapedTable, pkCols);

    if (rowsA == null || rowsB == null) {
      return TableDiffResult(
        tableName: tableName,
        status: TableDiffStatus.error,
        schemaDiff: schemaDiff,
        totalRowsA: countA,
        totalRowsB: countB,
        hasPrimaryKey: pkCols.isNotEmpty,
        primaryKeyColumns: pkCols,
        statusMessage: 'Failed to read table records during comparison',
      );
    }

    final totalRowsA = rowsA.length;
    final totalRowsB = rowsB.length;

    if (pkCols.isEmpty) {
      final rowCountsA = <String, int>{};
      for (final r in rowsA) {
        final key = RowHashService.canonicalRowString(r, allColumns);
        rowCountsA[key] = (rowCountsA[key] ?? 0) + 1;
      }

      final rowCountsB = <String, int>{};
      for (final r in rowsB) {
        final key = RowHashService.canonicalRowString(r, allColumns);
        rowCountsB[key] = (rowCountsB[key] ?? 0) + 1;
      }

      final isCountMatch = totalRowsA == totalRowsB;
      var isExactMatch = isCountMatch && rowCountsA.length == rowCountsB.length;
      if (isExactMatch) {
        for (final entry in rowCountsA.entries) {
          if (rowCountsB[entry.key] != entry.value) {
            isExactMatch = false;
            break;
          }
        }
      }

      if (isCountMatch && isExactMatch) {
        return TableDiffResult(
          tableName: tableName,
          status: TableDiffStatus.hashOnlyIdentical,
          schemaDiff: schemaDiff,
          totalRowsA: totalRowsA,
          totalRowsB: totalRowsB,
          hasPrimaryKey: false,
          statusMessage:
              'Row count and contents match ($totalRowsA rows; no primary key declared)',
        );
      } else {
        return TableDiffResult(
          tableName: tableName,
          status: TableDiffStatus.hashOnlyChanged,
          schemaDiff: schemaDiff,
          totalRowsA: totalRowsA,
          totalRowsB: totalRowsB,
          hasPrimaryKey: false,
          statusMessage:
              'Row count or content mismatch ($totalRowsA in A vs $totalRowsB in B; no primary key available for row-level matching)',
        );
      }
    }

    final mapA = <String, Map<String, dynamic>>{};
    for (final row in rowsA) {
      final key = RowHashService.buildKeyString(row, pkCols);
      mapA[key] = row;
    }

    final mapB = <String, Map<String, dynamic>>{};
    for (final row in rowsB) {
      final key = RowHashService.buildKeyString(row, pkCols);
      mapB[key] = row;
    }

    final keysA = mapA.keys.toSet();
    final keysB = mapB.keys.toSet();

    final removedKeys = keysA.difference(keysB).toList();
    final addedKeys = keysB.difference(keysA).toList();
    final commonKeys = keysA.intersection(keysB).toList();

    final allDiffs = <RowDiff>[];
    var modifiedCount = 0;

    for (final key in removedKeys) {
      final rowA = mapA[key]!;
      allDiffs.add(
        RowDiff(
          type: RowDiffType.removed,
          primaryKeyLabel: RowHashService.buildKeyDisplay(rowA, pkCols),
          rowDataA: rowA,
        ),
      );
    }

    for (final key in addedKeys) {
      final rowB = mapB[key]!;
      allDiffs.add(
        RowDiff(
          type: RowDiffType.added,
          primaryKeyLabel: RowHashService.buildKeyDisplay(rowB, pkCols),
          rowDataB: rowB,
        ),
      );
    }

    for (final key in commonKeys) {
      final rowA = mapA[key]!;
      final rowB = mapB[key]!;
      final columnDiffs = <ColumnDiff>[];

      for (final col in allColumns) {
        final valA = rowA[col];
        final valB = rowB[col];

        if (!_areValuesEqual(valA, valB)) {
          columnDiffs.add(
            ColumnDiff(
              columnName: col,
              oldValue: valA,
              newValue: valB,
              isBlob: valA is Uint8List || valB is Uint8List,
            ),
          );
        }
      }

      if (columnDiffs.isNotEmpty) {
        modifiedCount++;
        allDiffs.add(
          RowDiff(
            type: RowDiffType.modified,
            primaryKeyLabel: RowHashService.buildKeyDisplay(rowA, pkCols),
            rowDataA: rowA,
            rowDataB: rowB,
            changedColumns: columnDiffs,
          ),
        );
      }
    }

    final isIdentical =
        removedKeys.isEmpty && addedKeys.isEmpty && modifiedCount == 0;
    final isCapped = allDiffs.length > maxDetailCap;
    final displayDiffs = isCapped
        ? allDiffs.sublist(0, maxDetailCap)
        : allDiffs;

    return TableDiffResult(
      tableName: tableName,
      status: isIdentical
          ? TableDiffStatus.identical
          : TableDiffStatus.dataChanged,
      schemaDiff: schemaDiff,
      rowDiffs: displayDiffs,
      addedRowCount: addedKeys.length,
      removedRowCount: removedKeys.length,
      modifiedRowCount: modifiedCount,
      totalRowsA: totalRowsA,
      totalRowsB: totalRowsB,
      isCapped: isCapped,
      maxCap: maxDetailCap,
      hasPrimaryKey: true,
      primaryKeyColumns: pkCols,
    );
  }

  static String generateDiffCsv(TableDiffResult result) {
    final buffer = StringBuffer();
    buffer.writeln('ChangeType,Key,Column,OldValue,NewValue');

    for (final diff in result.rowDiffs) {
      final key = _escapeCsv(_neutralizeFormula(diff.primaryKeyLabel));
      if (diff.isAdded) {
        final formatted = _escapeCsv(_formatRowForCsv(diff.rowDataB));
        buffer.writeln('ADDED,$key,,,$formatted');
      } else if (diff.isRemoved) {
        final formatted = _escapeCsv(_formatRowForCsv(diff.rowDataA));
        buffer.writeln('REMOVED,$key,,,$formatted');
      } else if (diff.isModified) {
        for (final col in diff.changedColumns) {
          final colName = _escapeCsv(_neutralizeFormula(col.columnName));
          final oldVal = _escapeCsv(_formatVal(col.oldValue));
          final newVal = _escapeCsv(_formatVal(col.newValue));
          buffer.writeln('MODIFIED,$key,$colName,$oldVal,$newVal');
        }
      }
    }

    return buffer.toString();
  }

  static String _formatRowForCsv(Map<String, dynamic>? row) {
    if (row == null) return '';
    return row.entries
        .map((e) => '${_neutralizeFormula(e.key)}: ${_formatVal(e.value)}')
        .join('; ');
  }

  static String _formatVal(dynamic val) {
    if (val == null) return 'NULL';
    if (val is Uint8List) {
      return ByteFormatter.toHexSnippet(val);
    }
    return _neutralizeFormula(val.toString());
  }

  static String _neutralizeFormula(String value) {
    if (value.isEmpty) return value;
    if (num.tryParse(value) != null) return value;
    if (value.startsWith('\t') || value.startsWith('\r')) {
      return "'$value";
    }
    final trimmed = value.trimLeft();
    if (trimmed.startsWith('=') ||
        trimmed.startsWith('+') ||
        trimmed.startsWith('-') ||
        trimmed.startsWith('@') ||
        trimmed.startsWith('\t') ||
        trimmed.startsWith('\r')) {
      return "'$value";
    }
    return value;
  }

  static String _escapeCsv(String val) {
    if (val.contains(',') ||
        val.contains('"') ||
        val.contains('\n') ||
        val.contains('\r')) {
      return '"${val.replaceAll('"', '""')}"';
    }
    return val;
  }

  int? _getRowCount(dynamic db, String escapedTable) {
    try {
      final res = db.select('SELECT COUNT(*) AS c FROM "$escapedTable";');
      if (res.isNotEmpty) {
        return (res.first['c'] as num?)?.toInt();
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  List<Map<String, dynamic>>? _fetchRows(
    dynamic db,
    String escapedTable,
    List<String> pkCols,
  ) {
    var sql = 'SELECT * FROM "$escapedTable"';
    if (pkCols.isNotEmpty) {
      final orderCols = pkCols
          .map((c) => '"${c.replaceAll('"', '""')}" ASC')
          .join(', ');
      sql += ' ORDER BY $orderCols';
    }

    try {
      final result = db.select(sql);
      final rows = <Map<String, dynamic>>[];
      for (final row in result) {
        final rowMap = <String, dynamic>{};
        for (final col in result.columnNames) {
          final val = row[col];
          if (val is List<int>) {
            rowMap[col] = Uint8List.fromList(val);
          } else {
            rowMap[col] = val;
          }
        }
        rows.add(rowMap);
      }
      return rows;
    } catch (_) {
      return null;
    }
  }

  bool _areValuesEqual(dynamic a, dynamic b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;
    if (a is Uint8List && b is Uint8List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (a[i] != b[i]) return false;
      }
      return true;
    }
    return a == b;
  }
}
