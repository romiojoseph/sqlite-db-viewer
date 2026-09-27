import 'column_diff.dart';

enum RowDiffType {
  added,
  removed,
  modified,
}

class RowDiff {
  final RowDiffType type;
  final String primaryKeyLabel;
  final Map<String, dynamic>? rowDataA;
  final Map<String, dynamic>? rowDataB;
  final List<ColumnDiff> changedColumns;

  const RowDiff({
    required this.type,
    required this.primaryKeyLabel,
    this.rowDataA,
    this.rowDataB,
    this.changedColumns = const [],
  });

  bool get isAdded => type == RowDiffType.added;
  bool get isRemoved => type == RowDiffType.removed;
  bool get isModified => type == RowDiffType.modified;
}
