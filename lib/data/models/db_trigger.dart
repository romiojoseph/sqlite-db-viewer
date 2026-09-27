class DbTrigger {
  final String name;
  final String tableName;
  final String? sql;

  const DbTrigger({
    required this.name,
    required this.tableName,
    this.sql,
  });
}
