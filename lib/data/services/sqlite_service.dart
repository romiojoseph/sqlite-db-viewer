import 'dart:typed_data';
import 'package:sqlite3/sqlite3.dart';
import '../../core/utils/sql_readonly_guard.dart';
import '../models/column_filter.dart';
import '../models/db_column.dart';
import '../models/db_foreign_key.dart';
import '../models/db_index.dart';
import '../models/db_sequence.dart';
import '../models/db_table.dart';
import '../models/db_trigger.dart';
import '../models/query_result.dart';

class TableDataFetchRequest {
  final String filePath;
  final String tableName;
  final int limit;
  final int offset;
  final String? sortColumn;
  final bool sortAscending;
  final String? whereClause;
  final List<dynamic>? whereArgs;

  const TableDataFetchRequest({
    required this.filePath,
    required this.tableName,
    this.limit = 50,
    this.offset = 0,
    this.sortColumn,
    this.sortAscending = true,
    this.whereClause,
    this.whereArgs,
  });
}

/// Top-level function — safe to call inside [compute] / [Isolate.run].
QueryResult fetchTableDataInIsolate(TableDataFetchRequest req) {
  final db = sqlite3.open(req.filePath, mode: OpenMode.readOnly);
  final stopwatch = Stopwatch()..start();
  try {
    final escapedTable = req.tableName.replaceAll('"', '""');
    var sql = 'SELECT * FROM "$escapedTable"';

    if (req.whereClause != null && req.whereClause!.trim().isNotEmpty) {
      sql += ' WHERE ${req.whereClause}';
    }

    if (req.sortColumn != null && req.sortColumn!.isNotEmpty) {
      final escapedSort = req.sortColumn!.replaceAll('"', '""');
      final direction = req.sortAscending ? 'ASC' : 'DESC';
      sql += ' ORDER BY "$escapedSort" $direction';
    }

    sql += ' LIMIT ${req.limit} OFFSET ${req.offset};';

    final resultSet = db.select(sql, req.whereArgs ?? const []);
    stopwatch.stop();

    final columns = resultSet.columnNames;
    final rows = <List<dynamic>>[];

    for (final row in resultSet) {
      final rowList = <dynamic>[];
      for (var i = 0; i < columns.length; i++) {
        final val = row.values[i];
        if (val is List<int>) {
          rowList.add(Uint8List.fromList(val));
        } else {
          rowList.add(val);
        }
      }
      rows.add(rowList);
    }

    final int totalCount;
    if (req.whereClause != null && req.whereClause!.trim().isNotEmpty) {
      final countResult = db.select(
        'SELECT COUNT(*) AS total_count FROM "$escapedTable" WHERE ${req.whereClause};',
        req.whereArgs ?? const [],
      );
      totalCount =
          (countResult.isNotEmpty
              ? (countResult.first['total_count'] as num?)?.toInt()
              : null) ??
          rows.length;
    } else {
      int? rowCount;
      try {
        final countResult = db.select(
          'SELECT COUNT(*) AS total_count FROM "$escapedTable";',
        );
        if (countResult.isNotEmpty) {
          rowCount = (countResult.first['total_count'] as num?)?.toInt();
        }
      } catch (_) {}
      totalCount = rowCount ?? rows.length;
    }

    return QueryResult(
      columns: columns,
      rows: rows,
      executionDuration: stopwatch.elapsed,
      totalRows: totalCount,
      isSuccess: true,
    );
  } catch (e) {
    stopwatch.stop();
    return QueryResult.failure(e.toString(), duration: stopwatch.elapsed);
  } finally {
    db.close();
  }
}

/// Top-level function — safe to call inside [Isolate.run] because it opens
/// its own DB handle rather than sharing the main-thread handle.
List<DbTable> fetchTablesMetadataInIsolate(String filePath) {
  final db = sqlite3.open(filePath, mode: OpenMode.readOnly);
  try {
    const query = '''
      SELECT name, type, sql
      FROM sqlite_master
      WHERE type IN ('table', 'view') AND name NOT LIKE 'sqlite_%'
      ORDER BY type, name;
    ''';
    final result = db.select(query);
    final tables = <DbTable>[];

    for (final row in result) {
      final name = (row['name'] ?? '').toString();
      final type = (row['type'] ?? 'table').toString();
      final sql = row['sql']?.toString();

      final escaped = name.replaceAll('"', '""');

      // columns
      final colResult = db.select('PRAGMA table_info("$escaped");');
      final columns = colResult.map((r) => DbColumn.fromRow(r)).toList();

      // indexes
      final idxListResult = db.select('PRAGMA index_list("$escaped");');
      final indexes = <DbIndex>[];
      for (final idxRow in idxListResult) {
        final index = DbIndex.fromRow(idxRow);
        final idxEscaped = index.name.replaceAll('"', '""');
        final infoResult = db.select('PRAGMA index_info("$idxEscaped");');
        final columnNames = infoResult
            .map((r) => (r['name'] ?? '').toString())
            .toList();
        indexes.add(index.copyWith(columns: columnNames));
      }

      // foreign keys
      final fkResult = db.select('PRAGMA foreign_key_list("$escaped");');
      final foreignKeys = fkResult.map((r) => DbForeignKey.fromRow(r)).toList();

      // row count
      int? rowCount;
      try {
        final countResult = db.select('SELECT COUNT(*) AS c FROM "$escaped";');
        if (countResult.isNotEmpty) {
          rowCount = (countResult.first['c'] as num?)?.toInt();
        }
      } catch (_) {}

      tables.add(
        DbTable(
          name: name,
          type: type,
          sql: sql,
          rowCount: rowCount,
          columns: columns,
          indexes: indexes,
          foreignKeys: foreignKeys,
        ),
      );
    }
    return tables;
  } finally {
    db.close();
  }
}

class SqliteService {
  Database? _db;
  String? _currentFilePath;

  bool get isOpen => _db != null;
  String? get currentFilePath => _currentFilePath;
  Database? get db => _db;

  void open(String filePath) {
    close();
    _db = sqlite3.open(filePath, mode: OpenMode.readOnly);
    _currentFilePath = filePath;
  }

  void close() {
    _db?.close();
    _db = null;
    _currentFilePath = null;
  }

  List<DbTable> getTables() {
    final db = _db;
    if (db == null) return [];

    const query = '''
      SELECT name, type, sql 
      FROM sqlite_master 
      WHERE type IN ('table', 'view') AND name NOT LIKE 'sqlite_%'
      ORDER BY type, name;
    ''';

    final result = db.select(query);
    final tables = <DbTable>[];

    for (final row in result) {
      final name = (row['name'] ?? '').toString();
      final type = (row['type'] ?? 'table').toString();
      final sql = row['sql']?.toString();

      final columns = _getTableColumns(name);
      final indexes = _getTableIndexes(name);
      final foreignKeys = _getTableForeignKeys(name);
      final rowCount = _getTableRowCount(name);

      tables.add(
        DbTable(
          name: name,
          type: type,
          sql: sql,
          rowCount: rowCount,
          columns: columns,
          indexes: indexes,
          foreignKeys: foreignKeys,
        ),
      );
    }

    return tables;
  }

  List<DbColumn> _getTableColumns(String tableName) {
    final db = _db;
    if (db == null) return [];

    try {
      final escaped = tableName.replaceAll('"', '""');
      final result = db.select('PRAGMA table_info("$escaped");');
      return result.map((row) => DbColumn.fromRow(row)).toList();
    } catch (_) {
      return [];
    }
  }

  List<DbIndex> _getTableIndexes(String tableName) {
    final db = _db;
    if (db == null) return [];

    try {
      final escaped = tableName.replaceAll('"', '""');
      final result = db.select('PRAGMA index_list("$escaped");');
      final indexes = <DbIndex>[];

      for (final row in result) {
        final index = DbIndex.fromRow(row);
        final indexEscaped = index.name.replaceAll('"', '""');

        String? indexSql;
        try {
          final sqlResult = db.select(
            'SELECT sql FROM sqlite_master WHERE type = ? AND name = ?;',
            ['index', index.name],
          );
          if (sqlResult.isNotEmpty) {
            indexSql = sqlResult.first['sql']?.toString();
          }
        } catch (_) {}

        final infoResult = db.select('PRAGMA index_xinfo("$indexEscaped");');
        final columnNames = <String>[];
        for (final infoRow in infoResult) {
          final cid = (infoRow['cid'] as num?)?.toInt() ?? -1;
          if (cid >= 0) {
            final colName = (infoRow['name'] ?? '').toString();
            if (colName.isNotEmpty) {
              columnNames.add(colName);
            }
          } else if (cid == -2) {
            final exprName = (infoRow['name'] ?? '').toString();
            columnNames.add(exprName.isNotEmpty ? exprName : '<expr>');
          }
        }

        indexes.add(index.copyWith(columns: columnNames, sql: indexSql));
      }

      return indexes;
    } catch (_) {
      return [];
    }
  }

  List<DbForeignKey> _getTableForeignKeys(String tableName) {
    final db = _db;
    if (db == null) return [];

    try {
      final escaped = tableName.replaceAll('"', '""');
      final result = db.select('PRAGMA foreign_key_list("$escaped");');
      return result.map((row) => DbForeignKey.fromRow(row)).toList();
    } catch (_) {
      return [];
    }
  }

  int? _getTableRowCount(String tableName) {
    final db = _db;
    if (db == null) return null;

    try {
      final escaped = tableName.replaceAll('"', '""');
      final result = db.select(
        'SELECT COUNT(*) AS total_count FROM "$escaped";',
      );
      if (result.isNotEmpty) {
        return (result.first['total_count'] as num?)?.toInt();
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  List<DbTrigger> getTriggers() {
    final db = _db;
    if (db == null) return [];

    try {
      const query = '''
        SELECT name, tbl_name, sql 
        FROM sqlite_master 
        WHERE type = 'trigger' AND name NOT LIKE 'sqlite_%'
        ORDER BY name;
      ''';
      final result = db.select(query);
      return result
          .map(
            (row) => DbTrigger(
              name: (row['name'] ?? '').toString(),
              tableName: (row['tbl_name'] ?? '').toString(),
              sql: row['sql']?.toString(),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<DbSequence> getSequences() {
    final db = _db;
    if (db == null) return [];

    try {
      final result = db.select(
        'SELECT name, seq FROM sqlite_sequence ORDER BY name;',
      );
      return result
          .map(
            (row) => DbSequence(
              name: (row['name'] ?? '').toString(),
              seq: (row['seq'] as num?)?.toInt() ?? 0,
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  QueryResult getTableData(
    String tableName, {
    int limit = 50,
    int offset = 0,
    String? sortColumn,
    bool sortAscending = true,
    String? whereClause,
    List<dynamic>? whereArgs,
  }) {
    final db = _db;
    if (db == null) {
      return QueryResult.failure('No database is currently open');
    }

    final stopwatch = Stopwatch()..start();
    try {
      final escapedTable = tableName.replaceAll('"', '""');
      var sql = 'SELECT * FROM "$escapedTable"';

      if (whereClause != null && whereClause.trim().isNotEmpty) {
        sql += ' WHERE $whereClause';
      }

      if (sortColumn != null && sortColumn.isNotEmpty) {
        final escapedSort = sortColumn.replaceAll('"', '""');
        final direction = sortAscending ? 'ASC' : 'DESC';
        sql += ' ORDER BY "$escapedSort" $direction';
      }

      sql += ' LIMIT $limit OFFSET $offset;';

      final resultSet = db.select(sql, whereArgs ?? const []);
      stopwatch.stop();

      final columns = resultSet.columnNames;
      final rows = <List<dynamic>>[];

      for (final row in resultSet) {
        final rowList = <dynamic>[];
        for (var i = 0; i < columns.length; i++) {
          final val = row.values[i];
          if (val is List<int>) {
            rowList.add(Uint8List.fromList(val));
          } else {
            rowList.add(val);
          }
        }
        rows.add(rowList);
      }

      final int totalCount;
      if (whereClause != null && whereClause.trim().isNotEmpty) {
        final countResult = db.select(
          'SELECT COUNT(*) AS total_count FROM "$escapedTable" WHERE $whereClause;',
          whereArgs ?? const [],
        );
        totalCount =
            (countResult.isNotEmpty
                ? (countResult.first['total_count'] as num?)?.toInt()
                : null) ??
            rows.length;
      } else {
        totalCount = _getTableRowCount(tableName) ?? rows.length;
      }

      return QueryResult(
        columns: columns,
        rows: rows,
        executionDuration: stopwatch.elapsed,
        totalRows: totalCount,
        isSuccess: true,
      );
    } catch (e) {
      stopwatch.stop();
      return QueryResult.failure(e.toString(), duration: stopwatch.elapsed);
    }
  }

  List<DistinctColumnValue> getDistinctColumnValues(
    String tableName,
    String columnName, {
    int limit = 300,
  }) {
    final db = _db;
    if (db == null) return [];

    try {
      final escapedTable = tableName.replaceAll('"', '""');
      final escapedCol = columnName.replaceAll('"', '""');
      final sql =
          '''
        SELECT "$escapedCol" AS val, COUNT(*) AS count
        FROM "$escapedTable"
        GROUP BY "$escapedCol"
        ORDER BY count DESC, val ASC
        LIMIT $limit;
      ''';
      final result = db.select(sql);
      return result.map((row) {
        final val = row['val'];
        final count = (row['count'] as num?)?.toInt() ?? 0;
        return DistinctColumnValue(value: val, count: count);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  QueryResult executeCustomQuery(String sqlQuery, {int maxRows = 50000}) {
    final db = _db;
    if (db == null) {
      return QueryResult.failure('No database is currently open');
    }

    final validation = SqlReadonlyGuard.validate(sqlQuery);
    if (!validation.isValid) {
      return QueryResult.failure(
        validation.errorMessage ?? 'Query rejected by read-only guard',
      );
    }

    final stopwatch = Stopwatch()..start();
    try {
      final stmt = db.prepare(sqlQuery);
      try {
        final cursor = stmt.selectCursor();
        final columns = cursor.columnNames;
        final rows = <List<dynamic>>[];
        var isCapped = false;
        while (cursor.moveNext()) {
          if (rows.length >= maxRows) {
            isCapped = true;
            break;
          }
          final row = cursor.current;
          final rowList = <dynamic>[];
          for (var i = 0; i < columns.length; i++) {
            final val = row.values[i];
            if (val is List<int>) {
              rowList.add(Uint8List.fromList(val));
            } else {
              rowList.add(val);
            }
          }
          rows.add(rowList);
        }

        stopwatch.stop();

        return QueryResult(
          columns: columns,
          rows: rows,
          executionDuration: stopwatch.elapsed,
          totalRows: rows.length,
          isSuccess: true,
          isCapped: isCapped,
          maxCap: maxRows,
        );
      } finally {
        stmt.close();
      }
    } catch (e) {
      stopwatch.stop();
      return QueryResult.failure(e.toString(), duration: stopwatch.elapsed);
    }
  }
}
