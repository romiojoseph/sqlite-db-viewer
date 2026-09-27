import 'table_diff_result.dart';

class DiffSession {
  final String dbPathA;
  final String dbPathB;
  final List<String> selectedTables;
  final Map<String, TableDiffResult> tableResults;
  final Duration duration;

  const DiffSession({
    required this.dbPathA,
    required this.dbPathB,
    required this.selectedTables,
    required this.tableResults,
    required this.duration,
  });

  bool get areDatabasesIdentical {
    if (tableResults.isEmpty) return false;
    return tableResults.values.every((t) => t.isIdentical);
  }

  bool get hasConfirmedDifferences => changedTablesCount > 0;

  bool get isInconclusive =>
      !areDatabasesIdentical &&
      !hasConfirmedDifferences &&
      (notComparedTablesCount > 0 || errorTablesCount > 0);

  int get changedTablesCount {
    return tableResults.values.where((t) => t.isChanged).length;
  }

  int get identicalTablesCount {
    return tableResults.values.where((t) => t.isIdentical).length;
  }

  int get notComparedTablesCount {
    return tableResults.values
        .where((t) => t.status == TableDiffStatus.notCompared)
        .length;
  }

  int get errorTablesCount {
    return tableResults.values
        .where((t) => t.status == TableDiffStatus.error)
        .length;
  }

  int get totalAddedRows =>
      tableResults.values.fold(0, (sum, t) => sum + t.addedRowCount);

  int get totalRemovedRows =>
      tableResults.values.fold(0, (sum, t) => sum + t.removedRowCount);

  int get totalModifiedRows =>
      tableResults.values.fold(0, (sum, t) => sum + t.modifiedRowCount);
}
