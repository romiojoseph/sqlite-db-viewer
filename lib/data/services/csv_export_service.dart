import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:sqlite3/sqlite3.dart';
import '../../core/utils/byte_formatter.dart';
import '../models/db_table.dart';
import '../models/query_result.dart';
import 'sqlite_service.dart';

class _ExportAllRequest {
  final String dbPath;
  final String outPath;
  final List<String> tableNames;
  const _ExportAllRequest(this.dbPath, this.outPath, this.tableNames);
}

class _ExportTableRequest {
  final String dbPath;
  final String outPath;
  final String tableName;
  final String? whereClause;
  final List<dynamic>? whereArgs;
  final String? sortColumn;
  final bool sortAscending;

  const _ExportTableRequest({
    required this.dbPath,
    required this.outPath,
    required this.tableName,
    this.whereClause,
    this.whereArgs,
    this.sortColumn,
    this.sortAscending = true,
  });
}

Future<void> _exportTableWorker(_ExportTableRequest req) async {
  final db = sqlite3.open(req.dbPath, mode: OpenMode.readOnly);
  final file = File(req.outPath);
  final sink = file.openWrite(encoding: utf8);

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

    final stmt = db.prepare(sql);
    try {
      final cursor = stmt.selectCursor(req.whereArgs ?? const []);
      final columns = cursor.columnNames;

      // Write CSV headers with formula neutralization
      sink.writeln(
        columns
            .map(
              (c) => CsvExportService.escapeCsvCell(
                CsvExportService.neutralizeSpreadsheetFormula(c),
              ),
            )
            .join(','),
      );

      while (cursor.moveNext()) {
        final row = cursor.current;
        final rowValues = <dynamic>[];
        for (var i = 0; i < columns.length; i++) {
          final val = row.values[i];
          if (val is List<int>) {
            rowValues.add(Uint8List.fromList(val));
          } else {
            rowValues.add(val);
          }
        }
        sink.writeln(
          rowValues.map(CsvExportService.formatCellForCsv).join(','),
        );
      }
    } finally {
      stmt.close();
    }
    await sink.flush();
  } finally {
    db.close();
    await sink.close();
  }
}

String _sanitizeZipEntryName(String originalName, Set<String> usedNames) {
  var safeName = originalName
      .replaceAll(RegExp(r'[/\\?%*:|"<>]'), '_')
      .replaceAll(RegExp(r'\.\.+'), '_')
      .trim();
  if (safeName.isEmpty) safeName = 'table';

  var candidate = '$safeName.csv';
  var index = 1;
  while (usedNames.contains(candidate.toLowerCase())) {
    index++;
    candidate = '${safeName}_$index.csv';
  }
  usedNames.add(candidate.toLowerCase());
  return candidate;
}

Future<void> _exportAllTablesWorker(_ExportAllRequest req) async {
  final db = sqlite3.open(req.dbPath, mode: OpenMode.readOnly);
  final encoder = ZipFileEncoder();
  encoder.create(req.outPath);
  final usedNames = <String>{};
  final tempDir = Directory.systemTemp.createTempSync('db_zip_export_');

  try {
    for (final tableName in req.tableNames) {
      final escapedTable = tableName.replaceAll('"', '""');
      final stmt = db.prepare('SELECT * FROM "$escapedTable";');
      try {
        final cursor = stmt.selectCursor();
        final columns = cursor.columnNames;
        final entryFileName = _sanitizeZipEntryName(tableName, usedNames);
        final tempCsvFile = File(
          '${tempDir.path}${Platform.pathSeparator}$entryFileName',
        );
        final sink = tempCsvFile.openWrite(encoding: utf8);

        try {
          sink.writeln(
            columns
                .map(
                  (c) => CsvExportService.escapeCsvCell(
                    CsvExportService.neutralizeSpreadsheetFormula(c),
                  ),
                )
                .join(','),
          );

          while (cursor.moveNext()) {
            final row = cursor.current;
            final rowValues = <dynamic>[];
            for (var i = 0; i < columns.length; i++) {
              final val = row.values[i];
              if (val is List<int>) {
                rowValues.add(Uint8List.fromList(val));
              } else {
                rowValues.add(val);
              }
            }
            sink.writeln(
              rowValues.map(CsvExportService.formatCellForCsv).join(','),
            );
          }
        } finally {
          await sink.flush();
          await sink.close();
        }

        encoder.addFile(tempCsvFile, entryFileName);
      } finally {
        stmt.close();
      }
    }
  } finally {
    db.close();
    encoder.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  }
}

class CsvExportService {
  CsvExportService._();

  static String generateCsv(QueryResult result) {
    final buffer = StringBuffer();

    final escapedHeaders = result.columns
        .map((c) => escapeCsvCell(neutralizeSpreadsheetFormula(c)))
        .join(',');
    buffer.writeln(escapedHeaders);

    for (final row in result.rows) {
      final line = row.map(formatCellForCsv).join(',');
      buffer.writeln(line);
    }

    return buffer.toString();
  }

  static String generateTsv(QueryResult result) {
    final buffer = StringBuffer();

    final escapedHeaders = result.columns
        .map((c) => formatCellForTsv(c))
        .join('\t');
    buffer.writeln(escapedHeaders);

    for (final row in result.rows) {
      final line = row.map(formatCellForTsv).join('\t');
      buffer.writeln(line);
    }

    return buffer.toString();
  }

  static String formatSingleRowAsCsv(List<String> columns, List<dynamic> row) {
    return row.map(formatCellForCsv).join(',');
  }

  static String formatSingleRowAsTsv(List<String> columns, List<dynamic> row) {
    return row.map(formatCellForTsv).join('\t');
  }

  static String formatSingleRowAsJson(List<String> columns, List<dynamic> row) {
    final map = <String, dynamic>{};
    for (var i = 0; i < columns.length; i++) {
      final key = columns[i];
      final val = i < row.length ? row[i] : null;
      if (val is Uint8List) {
        map[key] = ByteFormatter.toHexSnippet(val);
      } else {
        map[key] = val;
      }
    }
    return jsonEncode(map);
  }

  static Future<String?> exportToFile(
    QueryResult result, {
    String defaultFileName = 'export.csv',
  }) async {
    final dummyBytes = Uint8List(0);
    final uri = await FilePickerPlatform.instance.saveFile(
      dialogTitle: 'Export to CSV',
      fileName: defaultFileName,
      bytes: dummyBytes,
      mimeType: 'text/csv',
    );

    if (uri == null) return null;

    final path = uri.toFilePath();

    // Offload CSV generation and file writing to background
    await compute((args) {
      final res = args[0] as QueryResult;
      final outPath = args[1] as String;
      final csvContent = CsvExportService.generateCsv(res);
      final bytes = Uint8List.fromList(utf8.encode(csvContent));
      final file = File(outPath);
      file.writeAsBytesSync(bytes);
    }, [result, path]);

    return path;
  }

  static Future<String?> exportTableToFile({
    required String dbPath,
    required String tableName,
    String? whereClause,
    List<dynamic>? whereArgs,
    String? sortColumn,
    bool sortAscending = true,
    String defaultFileName = 'export.csv',
  }) async {
    final dummyBytes = Uint8List(0);
    final uri = await FilePickerPlatform.instance.saveFile(
      dialogTitle: 'Export Table to CSV',
      fileName: defaultFileName,
      bytes: dummyBytes,
      mimeType: 'text/csv',
    );

    if (uri == null) return null;

    final path = uri.toFilePath();
    final req = _ExportTableRequest(
      dbPath: dbPath,
      outPath: path,
      tableName: tableName,
      whereClause: whereClause,
      whereArgs: whereArgs,
      sortColumn: sortColumn,
      sortAscending: sortAscending,
    );

    await compute(_exportTableWorker, req);
    return path;
  }

  static Future<String?> exportAllTablesZipped({
    required SqliteService sqliteService,
    required List<DbTable> tables,
    String defaultZipName = 'database_export.zip',
  }) async {
    final dbPath = sqliteService.currentFilePath;
    if (dbPath == null) return null;

    final dummyBytes = Uint8List(0);
    final uri = await FilePickerPlatform.instance.saveFile(
      dialogTitle: 'Export Entire Database to Zipped CSV',
      fileName: defaultZipName,
      bytes: dummyBytes,
      mimeType: 'application/zip',
    );

    if (uri == null) return null;

    final path = uri.toFilePath();

    final req = _ExportAllRequest(
      dbPath,
      path,
      tables.map((t) => t.name).toList(),
    );
    await compute(_exportAllTablesWorker, req);

    return path;
  }

  static String formatCellForCsv(dynamic value) {
    if (value == null) return '';
    if (value is Uint8List) {
      return escapeCsvCell(ByteFormatter.toHexSnippet(value));
    }
    return escapeCsvCell(neutralizeSpreadsheetFormula(value.toString()));
  }

  static String formatCellForTsv(dynamic value) {
    if (value == null) return '';
    if (value is Uint8List) {
      return ByteFormatter.toHexSnippet(value);
    }
    final str = neutralizeSpreadsheetFormula(value.toString());
    return str.replaceAll('\t', ' ').replaceAll('\n', ' ');
  }

  static String escapeCsvCell(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      final replaced = value.replaceAll('"', '""');
      return '"$replaced"';
    }
    return value;
  }

  static String neutralizeSpreadsheetFormula(String value) {
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
}
