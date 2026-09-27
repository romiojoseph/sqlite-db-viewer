import 'row_diff.dart';
import 'schema_diff_result.dart';

enum TableDiffStatus {
  identical,
  schemaChanged,
  dataChanged,
  onlyInA,
  onlyInB,
  hashOnlyChanged,
  hashOnlyIdentical,
  emptyInBoth,
  notCompared,
  error,
}

class TableDiffResult {
  final String tableName;
  final TableDiffStatus status;
  final SchemaDiffResult schemaDiff;
  final List<RowDiff> rowDiffs;
  final int addedRowCount;
  final int removedRowCount;
  final int modifiedRowCount;
  final int totalRowsA;
  final int totalRowsB;
  final bool isCapped;
  final int maxCap;
  final bool hasPrimaryKey;
  final List<String> primaryKeyColumns;
  final String? statusMessage;

  const TableDiffResult({
    required this.tableName,
    required this.status,
    required this.schemaDiff,
    this.rowDiffs = const [],
    this.addedRowCount = 0,
    this.removedRowCount = 0,
    this.modifiedRowCount = 0,
    this.totalRowsA = 0,
    this.totalRowsB = 0,
    this.isCapped = false,
    this.maxCap = 500,
    this.hasPrimaryKey = true,
    this.primaryKeyColumns = const [],
    this.statusMessage,
  });

  bool get isIdentical =>
      status == TableDiffStatus.identical ||
      status == TableDiffStatus.hashOnlyIdentical ||
      status == TableDiffStatus.emptyInBoth;

  bool get isChanged =>
      status == TableDiffStatus.schemaChanged ||
      status == TableDiffStatus.dataChanged ||
      status == TableDiffStatus.onlyInA ||
      status == TableDiffStatus.onlyInB ||
      status == TableDiffStatus.hashOnlyChanged;

  int get totalChanges => addedRowCount + removedRowCount + modifiedRowCount;
}
