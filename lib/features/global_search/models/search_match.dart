class SearchMatch {
  final String tableName;
  final String columnName;
  final String rowIdentifier;
  final String matchedText;
  final int matchIndex;
  final int matchLength;
  final Map<String, dynamic> rowData;

  const SearchMatch({
    required this.tableName,
    required this.columnName,
    required this.rowIdentifier,
    required this.matchedText,
    required this.matchIndex,
    required this.matchLength,
    required this.rowData,
  });
}
