enum AppTabType {
  tableData,
  tableSchema,
  customQuery,
  schemaGraph,
  globalSearch,
  diffChecker,
}

class AppTab {
  final String id;
  final String title;
  final AppTabType type;
  final String? tableName;
  final String? sql;

  const AppTab({
    required this.id,
    required this.title,
    required this.type,
    this.tableName,
    this.sql,
  });

  AppTab copyWith({
    String? id,
    String? title,
    AppTabType? type,
    String? tableName,
    String? sql,
  }) {
    return AppTab(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      tableName: tableName ?? this.tableName,
      sql: sql ?? this.sql,
    );
  }
}
