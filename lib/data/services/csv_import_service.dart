import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqlite3/sqlite3.dart';

class CsvImportRequest {
  final String dbPath;
  final String csvFilePath;
  final String? customTableName;

  const CsvImportRequest({
    required this.dbPath,
    required this.csvFilePath,
    this.customTableName,
  });
}

class CsvImportResult {
  final String tableName;
  final int rowsImported;
  final int columnsCount;
  final bool isNewTable;
  final List<String> columns;

  const CsvImportResult({
    required this.tableName,
    required this.rowsImported,
    required this.columnsCount,
    required this.isNewTable,
    required this.columns,
  });
}

/// Top-level worker function safe for compute / isolate execution
CsvImportResult importCsvWorker(CsvImportRequest request) {
  final file = File(request.csvFilePath);
  if (!file.existsSync()) {
    throw Exception('CSV file does not exist at "${request.csvFilePath}".');
  }

  // Read content with BOM stripping
  String rawContent = file.readAsStringSync(encoding: utf8);
  if (rawContent.startsWith('\uFEFF')) {
    rawContent = rawContent.substring(1);
  }

  final parsed = CsvImportService.parseCsv(rawContent);
  if (parsed.isEmpty) {
    throw Exception('CSV file is empty.');
  }

  final rawHeaders = parsed.first;
  final rows = parsed.skip(1).toList();

  if (rawHeaders.isEmpty) {
    throw Exception('CSV header row is empty.');
  }

  // Resolve sanitized unique column names
  final headers = <String>[];
  final seenHeaders = <String, int>{};
  for (var i = 0; i < rawHeaders.length; i++) {
    var h = rawHeaders[i].trim();
    if (h.isEmpty) {
      h = 'column_${i + 1}';
    }
    if (seenHeaders.containsKey(h)) {
      final count = seenHeaders[h]! + 1;
      seenHeaders[h] = count;
      h = '${h}_$count';
    } else {
      seenHeaders[h] = 1;
    }
    headers.add(h);
  }

  // Infer data types per column
  final columnTypes = <String, String>{};
  for (var i = 0; i < headers.length; i++) {
    final colName = headers[i];
    final values = <String>[];
    for (final row in rows) {
      if (i < row.length) {
        final val = row[i].trim();
        if (val.isNotEmpty) {
          values.add(val);
        }
      }
    }
    columnTypes[colName] = CsvImportService.inferSqliteType(values);
  }

  // Resolve table name
  String tableName = request.customTableName?.trim() ?? '';
  if (tableName.isEmpty) {
    final base = file.uri.pathSegments.last;
    final dotIdx = base.lastIndexOf('.');
    tableName = dotIdx > 0 ? base.substring(0, dotIdx) : base;
  }
  // Replace characters not safe for basic SQL identifiers with underscores
  tableName = tableName.replaceAll(
    RegExp(r'[^a-zA-Z0-9_\u00C0-\u024F\u1E00-\u1EFF]'),
    '_',
  );
  // Trim leading/trailing underscores and fallback if empty or starts with digit
  final stripped = tableName.replaceAll('_', '');
  if (stripped.isEmpty) {
    tableName = 'imported_table';
  } else if (RegExp(r'^\d').hasMatch(tableName)) {
    tableName = 'tbl_$tableName';
  }

  final db = sqlite3.open(request.dbPath);

  try {
    db.execute('BEGIN TRANSACTION;');
    try {
      // Check if table exists
      final checkStmt = db.prepare(
        "SELECT name FROM sqlite_master WHERE type='table' AND name = ?;",
      );
      final existingTableResult = checkStmt.select([tableName]);
      checkStmt.close();

      final isNewTable = existingTableResult.isEmpty;

      if (isNewTable) {
        // Create new table
        final colDefs = headers
            .map((h) {
              final type = columnTypes[h] ?? 'TEXT';
              final escaped = h.replaceAll('"', '""');
              return '"$escaped" $type';
            })
            .join(', ');

        final escapedTable = tableName.replaceAll('"', '""');
        db.execute('CREATE TABLE "$escapedTable" ($colDefs);');
      } else {
        // Existing table: inspect existing columns and alter table if new columns exist
        final escapedTable = tableName.replaceAll('"', '""');
        final pragmaInfo = db.select('PRAGMA table_info("$escapedTable");');
        final existingCols = pragmaInfo
            .map((r) => (r['name'] ?? '').toString().toLowerCase())
            .toSet();

        for (final h in headers) {
          if (!existingCols.contains(h.toLowerCase())) {
            final type = columnTypes[h] ?? 'TEXT';
            final escapedCol = h.replaceAll('"', '""');
            db.execute(
              'ALTER TABLE "$escapedTable" ADD COLUMN "$escapedCol" $type;',
            );
          }
        }
      }

      // Insert rows in a single batch transaction
      final escapedTable = tableName.replaceAll('"', '""');
      final colListStr = headers
          .map((h) => '"${h.replaceAll('"', '""')}"')
          .join(', ');
      final placeholders = List.filled(headers.length, '?').join(', ');
      final insertSql =
          'INSERT INTO "$escapedTable" ($colListStr) VALUES ($placeholders);';

      final insertStmt = db.prepare(insertSql);
      var importedCount = 0;

      try {
        for (final row in rows) {
          // Skip completely empty lines
          if (row.isEmpty || (row.length == 1 && row[0].trim().isEmpty)) {
            continue;
          }

          final params = <dynamic>[];
          for (var i = 0; i < headers.length; i++) {
            if (i < row.length) {
              final raw = row[i];
              final type = columnTypes[headers[i]];
              if (raw.isEmpty) {
                params.add(null);
              } else if (type == 'INTEGER') {
                params.add(int.tryParse(raw.trim()) ?? raw);
              } else if (type == 'REAL') {
                params.add(double.tryParse(raw.trim()) ?? raw);
              } else {
                params.add(raw);
              }
            } else {
              params.add(null);
            }
          }

          insertStmt.execute(params);
          importedCount++;
        }
      } finally {
        insertStmt.close();
      }

      db.execute('COMMIT;');

      return CsvImportResult(
        tableName: tableName,
        rowsImported: importedCount,
        columnsCount: headers.length,
        isNewTable: isNewTable,
        columns: headers,
      );
    } catch (e) {
      db.execute('ROLLBACK;');
      rethrow;
    }
  } finally {
    db.close();
  }
}

class CsvImportService {
  CsvImportService._();

  /// Parses raw CSV string handling quoted fields, commas, escaped quotes, and newlines.
  static List<List<String>> parseCsv(String input) {
    final rows = <List<String>>[];
    if (input.isEmpty) return rows;

    final currentRow = <String>[];
    final currentCell = StringBuffer();
    var inQuotes = false;
    var i = 0;

    while (i < input.length) {
      final char = input[i];

      if (inQuotes) {
        if (char == '"') {
          if (i + 1 < input.length && input[i + 1] == '"') {
            currentCell.write('"');
            i += 2;
            continue;
          } else {
            inQuotes = false;
          }
        } else {
          currentCell.write(char);
        }
      } else {
        if (char == '"') {
          inQuotes = true;
        } else if (char == ',') {
          currentRow.add(currentCell.toString());
          currentCell.clear();
        } else if (char == '\r') {
          if (i + 1 < input.length && input[i + 1] == '\n') {
            i++;
          }
          currentRow.add(currentCell.toString());
          currentCell.clear();
          rows.add(List.from(currentRow));
          currentRow.clear();
        } else if (char == '\n') {
          currentRow.add(currentCell.toString());
          currentCell.clear();
          rows.add(List.from(currentRow));
          currentRow.clear();
        } else {
          currentCell.write(char);
        }
      }
      i++;
    }

    if (currentCell.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentCell.toString());
      rows.add(currentRow);
    }

    return rows;
  }

  /// Infers SQLite storage type ('INTEGER', 'REAL', or 'TEXT') from sample non-empty values.
  static String inferSqliteType(List<String> values) {
    if (values.isEmpty) return 'TEXT';

    var allInts = true;
    var allReals = true;

    for (final val in values) {
      if (int.tryParse(val) == null) {
        allInts = false;
      }
      if (double.tryParse(val) == null) {
        allReals = false;
      }
      if (!allReals) break;
    }

    if (allInts) return 'INTEGER';
    if (allReals) return 'REAL';
    return 'TEXT';
  }

  /// High level import helper with isolate offloading
  static Future<CsvImportResult> importCsv({
    required String dbPath,
    required String csvFilePath,
    String? customTableName,
  }) async {
    final req = CsvImportRequest(
      dbPath: dbPath,
      csvFilePath: csvFilePath,
      customTableName: customTableName,
    );

    return await compute(importCsvWorker, req);
  }
}
