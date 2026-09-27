class GraphEdge {
  final String fromTable;
  final String fromColumn;
  final String toTable;
  final String toColumn;
  final String? onDelete;
  final String? onUpdate;

  const GraphEdge({
    required this.fromTable,
    required this.fromColumn,
    required this.toTable,
    required this.toColumn,
    this.onDelete,
    this.onUpdate,
  });

  bool get isSelfReferencing => fromTable.toLowerCase() == toTable.toLowerCase();

  String get label => '$fromColumn -> $toColumn';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GraphEdge &&
          runtimeType == other.runtimeType &&
          fromTable == other.fromTable &&
          fromColumn == other.fromColumn &&
          toTable == other.toTable &&
          toColumn == other.toColumn;

  @override
  int get hashCode =>
      fromTable.hashCode ^
      fromColumn.hashCode ^
      toTable.hashCode ^
      toColumn.hashCode;
}
