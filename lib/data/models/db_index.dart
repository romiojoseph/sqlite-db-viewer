class DbIndex {
  final int seq;
  final String name;
  final bool unique;
  final String origin;
  final bool partial;
  final List<String> columns;
  final String? sql;

  const DbIndex({
    required this.seq,
    required this.name,
    required this.unique,
    required this.origin,
    required this.partial,
    this.columns = const [],
    this.sql,
  });

  factory DbIndex.fromRow(
    Map<String, dynamic> row, {
    List<String> columns = const [],
    String? sql,
  }) {
    return DbIndex(
      seq: (row['seq'] as num?)?.toInt() ?? 0,
      name: (row['name'] ?? '').toString(),
      unique: ((row['unique'] as num?)?.toInt() ?? 0) == 1,
      origin: (row['origin'] ?? '').toString(),
      partial: ((row['partial'] as num?)?.toInt() ?? 0) == 1,
      columns: columns,
      sql: sql ?? row['sql']?.toString(),
    );
  }

  DbIndex copyWith({List<String>? columns, String? sql}) {
    return DbIndex(
      seq: seq,
      name: name,
      unique: unique,
      origin: origin,
      partial: partial,
      columns: columns ?? this.columns,
      sql: sql ?? this.sql,
    );
  }
}
