import 'dart:io';
import '../../../core/extensions/string_extensions.dart';
import '../../../core/utils/byte_formatter.dart';
import '../../../data/services/sqlite_service.dart';
import '../models/database_info.dart';

class DatabaseInfoService {
  final SqliteService sqliteService;

  const DatabaseInfoService({
    required this.sqliteService,
  });

  Future<DatabaseInfo?> getDatabaseInfo(String filePath) async {
    final db = sqliteService.db;
    if (db == null) return null;

    final file = File(filePath);
    final fileSizeBytes = file.existsSync() ? file.lengthSync() : 0;
    final fileSizeFormatted = ByteFormatter.formatSize(fileSizeBytes);
    final fileName = filePath.fileNameFromPath;

    var pageSize = 4096;
    var pageCount = 0;
    var encoding = 'UTF-8';
    var integrityResult = 'ok';
    var isIntegrityOk = true;
    var sqliteVersion = 'Unknown';
    var journalMode = 'DELETE';
    var userVersion = 0;
    var schemaVersion = 0;
    var tableCount = 0;
    var viewCount = 0;
    var indexCount = 0;
    var triggerCount = 0;

    try {
      final psResult = db.select('PRAGMA page_size;');
      if (psResult.isNotEmpty) {
        final val = psResult.first.values.first;
        pageSize = (val as num?)?.toInt() ?? int.tryParse(val.toString()) ?? 4096;
      }
    } catch (_) {}

    try {
      final pcResult = db.select('PRAGMA page_count;');
      if (pcResult.isNotEmpty) {
        final val = pcResult.first.values.first;
        pageCount = (val as num?)?.toInt() ?? int.tryParse(val.toString()) ?? 0;
      }
    } catch (_) {}

    try {
      final encResult = db.select('PRAGMA encoding;');
      if (encResult.isNotEmpty) {
        encoding = encResult.first.values.first?.toString() ?? 'UTF-8';
      }
    } catch (_) {}

    try {
      final verResult = db.select('SELECT sqlite_version();');
      if (verResult.isNotEmpty) {
        sqliteVersion = verResult.first.values.first?.toString() ?? 'Unknown';
      }
    } catch (_) {}

    try {
      final jmResult = db.select('PRAGMA journal_mode;');
      if (jmResult.isNotEmpty) {
        journalMode = jmResult.first.values.first?.toString().toUpperCase() ?? 'DELETE';
      }
    } catch (_) {}

    try {
      final uvResult = db.select('PRAGMA user_version;');
      if (uvResult.isNotEmpty) {
        final val = uvResult.first.values.first;
        userVersion = (val as num?)?.toInt() ?? int.tryParse(val.toString()) ?? 0;
      }
    } catch (_) {}

    try {
      final svResult = db.select('PRAGMA schema_version;');
      if (svResult.isNotEmpty) {
        final val = svResult.first.values.first;
        schemaVersion = (val as num?)?.toInt() ?? int.tryParse(val.toString()) ?? 0;
      }
    } catch (_) {}

    try {
      final intResult = db.select('PRAGMA integrity_check(1);');
      if (intResult.isNotEmpty) {
        integrityResult = intResult.first.values.first.toString();
        isIntegrityOk = integrityResult.toLowerCase() == 'ok';
      }
    } catch (e) {
      integrityResult = e.toString();
      isIntegrityOk = false;
    }

    try {
      final countsResult = db.select('''
        SELECT 
          SUM(CASE WHEN type = 'table' AND name NOT LIKE 'sqlite_%' THEN 1 ELSE 0 END) as tables,
          SUM(CASE WHEN type = 'view' THEN 1 ELSE 0 END) as views,
          SUM(CASE WHEN type = 'index' AND name NOT LIKE 'sqlite_%' THEN 1 ELSE 0 END) as indexes,
          SUM(CASE WHEN type = 'trigger' THEN 1 ELSE 0 END) as triggers
        FROM sqlite_master;
      ''');

      if (countsResult.isNotEmpty) {
        final row = countsResult.first;
        tableCount = (row['tables'] as num?)?.toInt() ?? 0;
        viewCount = (row['views'] as num?)?.toInt() ?? 0;
        indexCount = (row['indexes'] as num?)?.toInt() ?? 0;
        triggerCount = (row['triggers'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {}

    return DatabaseInfo(
      filePath: filePath,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      fileSizeFormatted: fileSizeFormatted,
      pageSize: pageSize,
      pageCount: pageCount,
      encoding: encoding,
      integrityResult: integrityResult,
      isIntegrityOk: isIntegrityOk,
      sqliteVersion: sqliteVersion,
      journalMode: journalMode,
      userVersion: userVersion,
      schemaVersion: schemaVersion,
      tableCount: tableCount,
      viewCount: viewCount,
      indexCount: indexCount,
      triggerCount: triggerCount,
    );
  }

  Future<String> runFullIntegrityCheck() async {
    final db = sqliteService.db;
    if (db == null) return 'Database not open';

    try {
      final result = db.select('PRAGMA integrity_check(100);');
      final lines = result.map((r) => r.values.first.toString()).toList();
      return lines.join('\n');
    } catch (e) {
      return 'Integrity check error: $e';
    }
  }
}
