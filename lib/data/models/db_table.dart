import 'db_column.dart';
import 'db_foreign_key.dart';
import 'db_index.dart';

class DbTable {
  final String name;
  final String type;
  final String? sql;
  final int? rowCount;
  final List<DbColumn> columns;
  final List<DbIndex> indexes;
  final List<DbForeignKey> foreignKeys;

  const DbTable({
    required this.name,
    required this.type,
    this.sql,
    this.rowCount,
    this.columns = const [],
    this.indexes = const [],
    this.foreignKeys = const [],
  });

  bool get isView => type.toLowerCase() == 'view';

  DbTable copyWith({
    String? name,
    String? type,
    String? sql,
    int? rowCount,
    List<DbColumn>? columns,
    List<DbIndex>? indexes,
    List<DbForeignKey>? foreignKeys,
  }) {
    return DbTable(
      name: name ?? this.name,
      type: type ?? this.type,
      sql: sql ?? this.sql,
      rowCount: rowCount ?? this.rowCount,
      columns: columns ?? this.columns,
      indexes: indexes ?? this.indexes,
      foreignKeys: foreignKeys ?? this.foreignKeys,
    );
  }
}
