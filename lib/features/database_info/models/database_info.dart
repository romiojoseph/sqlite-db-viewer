class DatabaseInfo {
  final String filePath;
  final String fileName;
  final int fileSizeBytes;
  final String fileSizeFormatted;
  final int pageSize;
  final int pageCount;
  final String encoding;
  final String integrityResult;
  final bool isIntegrityOk;
  final String sqliteVersion;
  final String journalMode;
  final int userVersion;
  final int schemaVersion;
  final int tableCount;
  final int viewCount;
  final int indexCount;
  final int triggerCount;

  const DatabaseInfo({
    required this.filePath,
    required this.fileName,
    required this.fileSizeBytes,
    required this.fileSizeFormatted,
    required this.pageSize,
    required this.pageCount,
    required this.encoding,
    required this.integrityResult,
    required this.isIntegrityOk,
    required this.sqliteVersion,
    required this.journalMode,
    required this.userVersion,
    required this.schemaVersion,
    required this.tableCount,
    required this.viewCount,
    required this.indexCount,
    required this.triggerCount,
  });
}
