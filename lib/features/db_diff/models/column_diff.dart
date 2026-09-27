class ColumnDiff {
  final String columnName;
  final dynamic oldValue;
  final dynamic newValue;
  final bool isBlob;

  const ColumnDiff({
    required this.columnName,
    required this.oldValue,
    required this.newValue,
    this.isBlob = false,
  });
}
