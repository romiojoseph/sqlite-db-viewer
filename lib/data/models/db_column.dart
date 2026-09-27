class DbColumn {
  final int cid;
  final String name;
  final String type;
  final bool notNull;
  final dynamic defaultValue;
  final bool isPrimaryKey;

  const DbColumn({
    required this.cid,
    required this.name,
    required this.type,
    required this.notNull,
    required this.defaultValue,
    required this.isPrimaryKey,
  });

  factory DbColumn.fromRow(Map<String, dynamic> row) {
    return DbColumn(
      cid: (row['cid'] as num?)?.toInt() ?? 0,
      name: (row['name'] ?? '').toString(),
      type: (row['type'] ?? 'TEXT').toString().toUpperCase(),
      notNull: ((row['notnull'] as num?)?.toInt() ?? 0) == 1,
      defaultValue: row['dflt_value'],
      isPrimaryKey: ((row['pk'] as num?)?.toInt() ?? 0) > 0,
    );
  }

  bool get isNumeric {
    final t = type.toUpperCase();
    return t.contains('INT') ||
        t.contains('REAL') ||
        t.contains('FLOAT') ||
        t.contains('DOUBLE') ||
        t.contains('NUMERIC') ||
        t.contains('DECIMAL');
  }

  bool get isBlob {
    return type.toUpperCase().contains('BLOB');
  }
}
