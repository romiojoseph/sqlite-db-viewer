import '../../../data/models/db_table.dart';
import '../../../data/services/sqlite_service.dart';
import '../models/schema_diff_result.dart';

class SchemaDiffService {
  final SqliteService serviceA;
  final SqliteService serviceB;

  const SchemaDiffService({required this.serviceA, required this.serviceB});

  Map<String, SchemaDiffResult> compareSchemas({List<String>? targetTables}) {
    final tablesA = {for (final t in serviceA.getTables()) t.name: t};
    final tablesB = {for (final t in serviceB.getTables()) t.name: t};

    final allNames = <String>{...tablesA.keys, ...tablesB.keys}.toList()
      ..sort();
    final results = <String, SchemaDiffResult>{};

    for (final name in allNames) {
      if (targetTables != null && !targetTables.contains(name)) {
        continue;
      }

      final tableA = tablesA[name];
      final tableB = tablesB[name];

      if (tableA != null && tableB == null) {
        results[name] = SchemaDiffResult(
          tableName: name,
          existsInA: true,
          existsInB: false,
          isIdentical: false,
          incompatibilityReason: 'Table exists only in Database A',
        );
        continue;
      }

      if (tableA == null && tableB != null) {
        results[name] = SchemaDiffResult(
          tableName: name,
          existsInA: false,
          existsInB: true,
          isIdentical: false,
          incompatibilityReason: 'Table exists only in Database B',
        );
        continue;
      }

      if (tableA != null && tableB != null) {
        final diff = _compareTableSchemas(tableA, tableB);
        results[name] = diff;
      }
    }

    return results;
  }

  SchemaDiffResult _compareTableSchemas(DbTable tableA, DbTable tableB) {
    final colsA = {for (final c in tableA.columns) c.name: c};
    final colsB = {for (final c in tableB.columns) c.name: c};

    final addedColumns = colsB.keys
        .where((k) => !colsA.containsKey(k))
        .toList();
    final removedColumns = colsA.keys
        .where((k) => !colsB.containsKey(k))
        .toList();
    final modifiedColumns = <String>[];

    for (final colName in colsA.keys) {
      if (colsB.containsKey(colName)) {
        final colA = colsA[colName]!;
        final colB = colsB[colName]!;

        if (colA.type.toUpperCase() != colB.type.toUpperCase() ||
            colA.notNull != colB.notNull ||
            colA.defaultValue != colB.defaultValue ||
            colA.isPrimaryKey != colB.isPrimaryKey) {
          modifiedColumns.add(colName);
        }
      }
    }

    final indexesA = {for (final idx in tableA.indexes) idx.name: idx};
    final indexesB = {for (final idx in tableB.indexes) idx.name: idx};

    final addedIndexes = indexesB.keys
        .where((k) => !indexesA.containsKey(k))
        .toList();
    final removedIndexes = indexesA.keys
        .where((k) => !indexesB.containsKey(k))
        .toList();
    final modifiedIndexes = <String>[];

    for (final idxName in indexesA.keys) {
      if (indexesB.containsKey(idxName)) {
        final idxA = indexesA[idxName]!;
        final idxB = indexesB[idxName]!;
        final sqlMatch =
            (idxA.sql == null && idxB.sql == null) ||
            _normalizeSql(idxA.sql ?? '') == _normalizeSql(idxB.sql ?? '');
        if (idxA.unique != idxB.unique ||
            idxA.columns.join(',') != idxB.columns.join(',') ||
            idxA.origin != idxB.origin ||
            idxA.partial != idxB.partial ||
            !sqlMatch) {
          modifiedIndexes.add(idxName);
        }
      }
    }

    final fksA = {
      for (final fk in tableA.foreignKeys)
        '${fk.from}->${fk.table}.${fk.to}(upd:${fk.onUpdate},del:${fk.onDelete},match:${fk.match})':
            fk,
    };
    final fksB = {
      for (final fk in tableB.foreignKeys)
        '${fk.from}->${fk.table}.${fk.to}(upd:${fk.onUpdate},del:${fk.onDelete},match:${fk.match})':
            fk,
    };

    final addedFks = fksB.keys.where((k) => !fksA.containsKey(k)).toList();
    final removedFks = fksA.keys.where((k) => !fksB.containsKey(k)).toList();

    final pksA = tableA.columns
        .where((c) => c.isPrimaryKey)
        .map((c) => c.name)
        .toList();
    final pksB = tableB.columns
        .where((c) => c.isPrimaryKey)
        .map((c) => c.name)
        .toList();
    final pkOrderMatches =
        pksA.length == pksB.length && pksA.join(',') == pksB.join(',');

    final sqlA = _normalizeSql(tableA.sql ?? '');
    final sqlB = _normalizeSql(tableB.sql ?? '');
    final ddlMatches = sqlA == sqlB;

    final isIdentical =
        addedColumns.isEmpty &&
        removedColumns.isEmpty &&
        modifiedColumns.isEmpty &&
        addedIndexes.isEmpty &&
        removedIndexes.isEmpty &&
        modifiedIndexes.isEmpty &&
        addedFks.isEmpty &&
        removedFks.isEmpty &&
        pkOrderMatches &&
        ddlMatches;

    return SchemaDiffResult(
      tableName: tableA.name,
      existsInA: true,
      existsInB: true,
      isIdentical: isIdentical,
      addedColumns: addedColumns,
      removedColumns: removedColumns,
      modifiedColumns: modifiedColumns,
      addedIndexes: addedIndexes,
      removedIndexes: removedIndexes,
      modifiedIndexes: modifiedIndexes,
      addedForeignKeys: addedFks,
      removedForeignKeys: removedFks,
      incompatibilityReason: isIdentical
          ? null
          : 'Schema structure mismatch between databases',
    );
  }

  static String _normalizeSql(String sql) {
    if (sql.isEmpty) return '';
    final buffer = StringBuffer();
    var i = 0;
    var lastCharWasSpace = true;

    const punctuation = '(),;=<>+-*/';

    while (i < sql.length) {
      final char = sql[i];
      final nextChar = (i + 1 < sql.length) ? sql[i + 1] : '';

      // Skip line comment
      if (char == '-' && nextChar == '-') {
        i += 2;
        while (i < sql.length && sql[i] != '\n' && sql[i] != '\r') {
          i++;
        }
        final currentStr = buffer.toString();
        if (!lastCharWasSpace &&
            currentStr.isNotEmpty &&
            !punctuation.contains(currentStr[currentStr.length - 1])) {
          buffer.write(' ');
          lastCharWasSpace = true;
        }
        continue;
      }

      // Skip block comment
      if (char == '/' && nextChar == '*') {
        i += 2;
        while (i + 1 < sql.length && !(sql[i] == '*' && sql[i + 1] == '/')) {
          i++;
        }
        i += 2;
        final currentStr = buffer.toString();
        if (!lastCharWasSpace &&
            currentStr.isNotEmpty &&
            !punctuation.contains(currentStr[currentStr.length - 1])) {
          buffer.write(' ');
          lastCharWasSpace = true;
        }
        continue;
      }

      // Single quote literal: preserve casing and whitespace
      if (char == "'") {
        buffer.write("'");
        i++;
        while (i < sql.length) {
          final c = sql[i];
          buffer.write(c);
          if (c == "'") {
            if (i + 1 < sql.length && sql[i + 1] == "'") {
              i++;
              buffer.write(sql[i]);
            } else {
              i++;
              break;
            }
          }
          i++;
        }
        lastCharWasSpace = false;
        continue;
      }

      // Double quote identifier: preserve content
      if (char == '"') {
        buffer.write('"');
        i++;
        while (i < sql.length) {
          final c = sql[i];
          buffer.write(c);
          if (c == '"') {
            if (i + 1 < sql.length && sql[i + 1] == '"') {
              i++;
              buffer.write(sql[i]);
            } else {
              i++;
              break;
            }
          }
          i++;
        }
        lastCharWasSpace = false;
        continue;
      }

      // Backtick identifier: preserve content
      if (char == '`') {
        buffer.write('`');
        i++;
        while (i < sql.length) {
          final c = sql[i];
          buffer.write(c);
          if (c == '`') {
            i++;
            break;
          }
          i++;
        }
        lastCharWasSpace = false;
        continue;
      }

      // Square bracket identifier: preserve content
      if (char == '[') {
        buffer.write('[');
        i++;
        while (i < sql.length) {
          final c = sql[i];
          buffer.write(c);
          if (c == ']') {
            i++;
            break;
          }
          i++;
        }
        lastCharWasSpace = false;
        continue;
      }

      // Punctuation outside quotes: strip any preceding space, write punctuation, ignore subsequent spaces
      if (punctuation.contains(char)) {
        final currentStr = buffer.toString();
        if (currentStr.endsWith(' ')) {
          final trimmed = currentStr.trimRight();
          buffer.clear();
          buffer.write(trimmed);
        }
        buffer.write(char);
        lastCharWasSpace = true;
        i++;
        continue;
      }

      // Whitespace outside quotes
      if (char == ' ' || char == '\t' || char == '\n' || char == '\r') {
        final currentStr = buffer.toString();
        if (!lastCharWasSpace &&
            currentStr.isNotEmpty &&
            !punctuation.contains(currentStr[currentStr.length - 1])) {
          buffer.write(' ');
          lastCharWasSpace = true;
        }
        i++;
        continue;
      }

      // Standard tokens: lowercase
      buffer.write(char.toLowerCase());
      lastCharWasSpace = false;
      i++;
    }

    var result = buffer.toString().trim();
    while (result.endsWith(';')) {
      result = result.substring(0, result.length - 1).trimRight();
    }
    return result;
  }
}
