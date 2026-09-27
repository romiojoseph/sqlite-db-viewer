class DbForeignKey {
  final int id;
  final int seq;
  final String table;
  final String from;
  final String to;
  final String onUpdate;
  final String onDelete;
  final String match;

  const DbForeignKey({
    required this.id,
    required this.seq,
    required this.table,
    required this.from,
    required this.to,
    required this.onUpdate,
    required this.onDelete,
    required this.match,
  });

  factory DbForeignKey.fromRow(Map<String, dynamic> row) {
    return DbForeignKey(
      id: (row['id'] as num?)?.toInt() ?? 0,
      seq: (row['seq'] as num?)?.toInt() ?? 0,
      table: (row['table'] ?? '').toString(),
      from: (row['from'] ?? '').toString(),
      to: (row['to'] ?? '').toString(),
      onUpdate: (row['on_update'] ?? 'NO ACTION').toString(),
      onDelete: (row['on_delete'] ?? 'NO ACTION').toString(),
      match: (row['match'] ?? 'NONE').toString(),
    );
  }
}
