class SchemaDiffResult {
  final String tableName;
  final bool existsInA;
  final bool existsInB;
  final bool isIdentical;
  final List<String> addedColumns;
  final List<String> removedColumns;
  final List<String> modifiedColumns;
  final List<String> addedIndexes;
  final List<String> removedIndexes;
  final List<String> modifiedIndexes;
  final List<String> addedForeignKeys;
  final List<String> removedForeignKeys;
  final String? incompatibilityReason;

  const SchemaDiffResult({
    required this.tableName,
    required this.existsInA,
    required this.existsInB,
    required this.isIdentical,
    this.addedColumns = const [],
    this.removedColumns = const [],
    this.modifiedColumns = const [],
    this.addedIndexes = const [],
    this.removedIndexes = const [],
    this.modifiedIndexes = const [],
    this.addedForeignKeys = const [],
    this.removedForeignKeys = const [],
    this.incompatibilityReason,
  });

  bool get existsInBoth => existsInA && existsInB;
  bool get onlyInA => existsInA && !existsInB;
  bool get onlyInB => !existsInA && existsInB;

  int get totalDifferences =>
      addedColumns.length +
      removedColumns.length +
      modifiedColumns.length +
      addedIndexes.length +
      removedIndexes.length +
      modifiedIndexes.length +
      addedForeignKeys.length +
      removedForeignKeys.length;
}
