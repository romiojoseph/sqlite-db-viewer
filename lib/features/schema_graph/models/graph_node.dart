import '../../../data/models/db_column.dart';

class GraphNode {
  final String tableName;
  final bool isView;
  final List<DbColumn> columns;
  final Set<String> primaryKeyColumns;
  final Set<String> foreignKeyColumns;
  final int? rowCount;

  const GraphNode({
    required this.tableName,
    required this.isView,
    required this.columns,
    required this.primaryKeyColumns,
    required this.foreignKeyColumns,
    this.rowCount,
  });

  bool isPrimaryKey(String columnName) => primaryKeyColumns.contains(columnName);
  bool isForeignKey(String columnName) => foreignKeyColumns.contains(columnName);
}
