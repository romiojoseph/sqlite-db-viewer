import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqlite3/sqlite3.dart';

class JsonImportRequest {
  final String dbPath;
  final String jsonFilePath;
  final String? customTableName;

  const JsonImportRequest({
    required this.dbPath,
    required this.jsonFilePath,
    this.customTableName,
  });
}

class JsonImportResult {
  final String tableName;
  final int rowsImported;
  final int columnsCount;
  final bool isNewTable;
  final List<String> columns;

  const JsonImportResult({
    required this.tableName,
    required this.rowsImported,
    required this.columnsCount,
    required this.isNewTable,
    required this.columns,
  });
}

/// Top-level worker function safe for compute / isolate execution
JsonImportResult importJsonWorker(JsonImportRequest request) {
  final file = File(request.jsonFilePath);
  if (!file.existsSync()) {
    throw Exception('JSON file does not exist at "${request.jsonFilePath}".');
  }

  // Read content with BOM stripping
  String rawContent = file.readAsStringSync(encoding: utf8);
  if (rawContent.startsWith('\uFEFF')) {
    rawContent = rawContent.substring(1);
  }

  final dynamic decoded;
  try {
    decoded = jsonDecode(rawContent);
  } catch (e) {
    throw Exception('Invalid JSON format: $e');
  }

  final List<Map<String, dynamic>> records = [];

  if (decoded is List) {
    for (final item in decoded) {
      if (item is Map<String, dynamic>) {
        records.add(item);
      } else if (item is Map) {
        records.add(Map<String, dynamic>.from(item));
      } else {
        // Primitive in list, wrap in value object
        records.add({'value': item});
      }
    }
  } else if (decoded is Map<String, dynamic>) {
    records.add(decoded);
  } else if (decoded is Map) {
    records.add(Map<String, dynamic>.from(decoded));
  } else {
    throw Exception('JSON root must be an array of objects or an object.');
  }

  if (records.isEmpty) {
    throw Exception('JSON file contains no records.');
  }

  // Collect all unique keys across all records
  final keyOrder = <String>[];
  final seenKeys = <String>{};
  for (final rec in records) {
    for (final k in rec.keys) {
      if (seenKeys.add(k)) {
        keyOrder.add(k);
      }
    }
  }

  if (keyOrder.isEmpty) {
    throw Exception('JSON records have no properties.');
  }

  // Sanitize headers
  final headers = <String>[];
  final headerToKeyMap = <String, String>{};
  final seenSanitized = <String, int>{};

  for (var i = 0; i < keyOrder.length; i++) {
    final rawKey = keyOrder[i];
    var h = rawKey.trim();
    if (h.isEmpty) {
      h = 'column_${i + 1}';
    }
    if (seenSanitized.containsKey(h)) {
      final count = seenSanitized[h]! + 1;
      seenSanitized[h] = count;
      h = '${h}_$count';
    } else {
      seenSanitized[h] = 1;
    }
    headers.add(h);
    headerToKeyMap[h] = rawKey;
  }

  // Infer column types
  final columnTypes = <String, String>{};
  for (final h in headers) {
    final rawKey = headerToKeyMap[h]!;
    final values = <dynamic>[];
    for (final rec in records) {
      if (rec.containsKey(rawKey) && rec[rawKey] != null) {
        values.add(rec[rawKey]);
      }
    }
    columnTypes[h] = JsonImportService.inferSqliteType(values);
  }

  // Resolve table name
  String tableName = request.customTableName?.trim() ?? '';
  if (tableName.isEmpty) {
    final base = file.uri.pathSegments.last;
    final dotIdx = base.lastIndexOf('.');
    tableName = dotIdx > 0 ? base.substring(0, dotIdx) : base;
  }
  tableName = tableName.replaceAll(
    RegExp(r'[^a-zA-Z0-9_\u00C0-\u024F\u1E00-\u1EFF]'),
    '_',
  );
  final stripped = tableName.replaceAll('_', '');
  if (stripped.isEmpty) {
    tableName = 'imported_json_table';
  } else if (RegExp(r'^\d').hasMatch(tableName)) {
    tableName = 'tbl_$tableName';
  }

  final db = sqlite3.open(request.dbPath);

  try {
    db.execute('BEGIN TRANSACTION;');
    try {
      final checkStmt = db.prepare(
        "SELECT name FROM sqlite_master WHERE type='table' AND name = ?;",
      );
      final existingTableResult = checkStmt.select([tableName]);
      checkStmt.close();

      final isNewTable = existingTableResult.isEmpty;

      if (isNewTable) {
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
        for (final rec in records) {
          final params = <dynamic>[];
          for (final h in headers) {
            final rawKey = headerToKeyMap[h]!;
            if (rec.containsKey(rawKey)) {
              final val = rec[rawKey];
              if (val == null) {
                params.add(null);
              } else if (val is int || val is double || val is String) {
                params.add(val);
              } else if (val is bool) {
                params.add(val ? 1 : 0);
              } else {
                // Object, list or map -> JSON encode as text
                params.add(jsonEncode(val));
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

      return JsonImportResult(
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

class JsonImportService {
  JsonImportService._();

  /// Infers SQLite storage type ('INTEGER', 'REAL', or 'TEXT') from sample dynamic values.
  static String inferSqliteType(List<dynamic> values) {
    if (values.isEmpty) return 'TEXT';

    var allInts = true;
    var allReals = true;

    for (final val in values) {
      if (val is int) {
        // int is valid for both
      } else if (val is double) {
        allInts = false;
      } else if (val is num) {
        if (val % 1 != 0) allInts = false;
      } else if (val is String) {
        if (int.tryParse(val) == null) allInts = false;
        if (double.tryParse(val) == null) allReals = false;
      } else {
        allInts = false;
        allReals = false;
        break;
      }
      if (!allReals) break;
    }

    if (allInts) return 'INTEGER';
    if (allReals) return 'REAL';
    return 'TEXT';
  }

  /// High level import helper with isolate offloading
  static Future<JsonImportResult> importJson({
    required String dbPath,
    required String jsonFilePath,
    String? customTableName,
  }) async {
    final req = JsonImportRequest(
      dbPath: dbPath,
      jsonFilePath: jsonFilePath,
      customTableName: customTableName,
    );

    return await compute(importJsonWorker, req);
  }
}
