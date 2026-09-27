enum FilterOperator {
  equals('=', '='),
  notEquals('<>', '<>'),
  greaterThan('>', '>'),
  lessThan('<', '<'),
  greaterOrEqual('>=', '>='),
  lessOrEqual('<=', '<='),
  contains('LIKE', 'contains'),
  startsWith('LIKE', 'starts with'),
  endsWith('LIKE', 'ends with'),
  isNull('IS NULL', 'is NULL'),
  isNotNull('IS NOT NULL', 'is NOT NULL'),
  inList('IN', 'in');

  final String sqlOperator;
  final String label;
  const FilterOperator(this.sqlOperator, this.label);
}

class SqlCondition {
  final String clause;
  final List<dynamic> args;
  
  const SqlCondition(this.clause, this.args);
}

class DistinctColumnValue {
  final dynamic value;
  final int count;

  const DistinctColumnValue({
    required this.value,
    required this.count,
  });

  bool get isNull => value == null;

  String get displayValue => isNull ? '(NULL)' : value.toString();
}

class ColumnFilter {
  final String column;
  final FilterOperator operator;
  final String value;
  final List<String> values;

  const ColumnFilter({
    required this.column,
    required this.operator,
    this.value = '',
    this.values = const [],
  });

  SqlCondition toSql() {
    final escapedCol = column.replaceAll('"', '""');

    switch (operator) {
      case FilterOperator.isNull:
        return SqlCondition('"$escapedCol" IS NULL', []);
      case FilterOperator.isNotNull:
        return SqlCondition('"$escapedCol" IS NOT NULL', []);
      case FilterOperator.contains:
        return SqlCondition('"$escapedCol" LIKE ?', ['%$value%']);
      case FilterOperator.startsWith:
        return SqlCondition('"$escapedCol" LIKE ?', ['$value%']);
      case FilterOperator.endsWith:
        return SqlCondition('"$escapedCol" LIKE ?', ['%$value']);
      case FilterOperator.equals:
        return SqlCondition('"$escapedCol" = ?', [value]);
      case FilterOperator.notEquals:
        return SqlCondition('"$escapedCol" <> ?', [value]);
      case FilterOperator.greaterThan:
        return SqlCondition('"$escapedCol" > ?', [value]);
      case FilterOperator.lessThan:
        return SqlCondition('"$escapedCol" < ?', [value]);
      case FilterOperator.greaterOrEqual:
        return SqlCondition('"$escapedCol" >= ?', [value]);
      case FilterOperator.lessOrEqual:
        return SqlCondition('"$escapedCol" <= ?', [value]);
      case FilterOperator.inList:
        if (values.isEmpty) return const SqlCondition('1=1', []);
        final hasNull = values.contains('__NULL__') || values.contains('NULL');
        final nonNullValues =
            values.where((v) => v != '__NULL__' && v != 'NULL').toList();
        if (nonNullValues.isEmpty && hasNull) {
          return SqlCondition('"$escapedCol" IS NULL', []);
        }
        
        final placeholders = List.filled(nonNullValues.length, '?').join(', ');
        
        if (hasNull) {
          return SqlCondition(
            '("$escapedCol" IN ($placeholders) OR "$escapedCol" IS NULL)',
            nonNullValues,
          );
        }
        return SqlCondition('"$escapedCol" IN ($placeholders)', nonNullValues);
    }
  }

  String toDisplayString() {
    switch (operator) {
      case FilterOperator.isNull:
        return '$column IS NULL';
      case FilterOperator.isNotNull:
        return '$column IS NOT NULL';
      case FilterOperator.contains:
        return "$column LIKE '%$value%'";
      case FilterOperator.startsWith:
        return "$column LIKE '$value%'";
      case FilterOperator.endsWith:
        return "$column LIKE '%$value'";
      case FilterOperator.equals:
        return "$column = '$value'";
      case FilterOperator.notEquals:
        return "$column <> '$value'";
      case FilterOperator.greaterThan:
        return "$column > '$value'";
      case FilterOperator.lessThan:
        return "$column < '$value'";
      case FilterOperator.greaterOrEqual:
        return "$column >= '$value'";
      case FilterOperator.lessOrEqual:
        return "$column <= '$value'";
      case FilterOperator.inList:
        if (values.length == 1) {
          return values.first == '__NULL__'
              ? '$column IS NULL'
              : "$column = '${values.first}'";
        }
        final preview = values
            .take(2)
            .map((v) => v == '__NULL__' ? 'NULL' : "'$v'")
            .join(', ');
        return '$column IN ($preview${values.length > 2 ? ', +${values.length - 2}' : ''})';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColumnFilter &&
          runtimeType == other.runtimeType &&
          column == other.column &&
          operator == other.operator &&
          value == other.value &&
          _listEquals(values, other.values);

  @override
  int get hashCode => Object.hash(column, operator, value, Object.hashAll(values));

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
