import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import '../../core/extensions/string_extensions.dart';
import '../models/db_table.dart';
import '../models/db_trigger.dart';

class SchemaExportService {
  SchemaExportService._();

  /// Formats raw DDL statement with proper indentation and capitalized keywords.
  static String formatSqlStatement(String rawSql) {
    var trimmed = rawSql.trim();
    if (trimmed.isEmpty) return '';
    if (!trimmed.endsWith(';')) trimmed = '$trimmed;';

    // Check if it's a CREATE TABLE statement
    final tablePrefixMatch = RegExp(
      r'^(CREATE\s+(?:TEMP|TEMPORARY\s+)?TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?)([^(]+)\(',
      caseSensitive: false,
    ).firstMatch(trimmed);

    if (tablePrefixMatch != null) {
      final prefix = tablePrefixMatch.group(1)!.trim();
      final tableName = tablePrefixMatch.group(2)!.trim();
      final openParenIndex = tablePrefixMatch.end - 1;

      final body = _extractMatchingParenContent(trimmed, openParenIndex);
      if (body != null) {
        final parts = _splitSqlColumnDefinitions(body);
        final formattedParts = parts
            .map((p) => '  ${_formatSqlKeywords(p.trim())}')
            .join(',\n');
        return '${_formatSqlKeywords(prefix)} $tableName (\n$formattedParts\n);';
      }
    }

    // Check if it's a CREATE VIEW statement
    final createViewMatch = RegExp(
      r'^(CREATE\s+(?:TEMP|TEMPORARY\s+)?VIEW\s+(?:IF\s+NOT\s+EXISTS\s+)?)(.+?)\s+AS\s+([\s\S]+);?$',
      caseSensitive: false,
    ).firstMatch(trimmed);

    if (createViewMatch != null) {
      final prefix = createViewMatch.group(1)!.trim();
      final viewName = createViewMatch.group(2)!.trim();
      final query = createViewMatch.group(3)!.trim();
      return '${_formatSqlKeywords(prefix)} $viewName AS\n  $query;';
    }

    return _formatSqlKeywords(trimmed);
  }

  /// Extracts the content between an opening parenthesis and its balanced closing parenthesis.
  static String? _extractMatchingParenContent(String sql, int openIndex) {
    var depth = 0;
    var inSingleQuote = false;
    var inDoubleQuote = false;
    var inSquareBracket = false;

    for (var i = openIndex; i < sql.length; i++) {
      final char = sql[i];

      if (char == "'" && !inDoubleQuote && !inSquareBracket) {
        inSingleQuote = !inSingleQuote;
      } else if (char == '"' && !inSingleQuote && !inSquareBracket) {
        inDoubleQuote = !inDoubleQuote;
      } else if (char == '[' && !inSingleQuote && !inDoubleQuote) {
        inSquareBracket = true;
      } else if (char == ']' && inSquareBracket) {
        inSquareBracket = false;
      } else if (!inSingleQuote && !inDoubleQuote && !inSquareBracket) {
        if (char == '(') {
          depth++;
        } else if (char == ')') {
          depth--;
          if (depth == 0) {
            return sql.substring(openIndex + 1, i).trim();
          }
        }
      }
    }
    return null;
  }

  /// Splits comma-separated column definitions without splitting commas inside parentheses.
  static List<String> _splitSqlColumnDefinitions(String body) {
    final parts = <String>[];
    final buffer = StringBuffer();
    var parenDepth = 0;
    var inSingleQuote = false;
    var inDoubleQuote = false;

    for (var i = 0; i < body.length; i++) {
      final char = body[i];

      if (char == "'" && !inDoubleQuote) {
        inSingleQuote = !inSingleQuote;
        buffer.write(char);
      } else if (char == '"' && !inSingleQuote) {
        inDoubleQuote = !inDoubleQuote;
        buffer.write(char);
      } else if (inSingleQuote || inDoubleQuote) {
        buffer.write(char);
      } else if (char == '(') {
        parenDepth++;
        buffer.write(char);
      } else if (char == ')') {
        if (parenDepth > 0) parenDepth--;
        buffer.write(char);
      } else if (char == ',' && parenDepth == 0) {
        final def = buffer.toString().trim();
        if (def.isNotEmpty) {
          parts.add(def);
        }
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    final remaining = buffer.toString().trim();
    if (remaining.isNotEmpty) {
      parts.add(remaining);
    }

    return parts;
  }

  static String _formatSqlKeywords(String sql) {
    final buffer = StringBuffer();
    var i = 0;
    final currentWord = StringBuffer();

    void flushWord() {
      if (currentWord.isNotEmpty) {
        buffer.write(_replaceKeywordsInChunk(currentWord.toString()));
        currentWord.clear();
      }
    }

    while (i < sql.length) {
      final char = sql[i];
      final nextChar = (i + 1 < sql.length) ? sql[i + 1] : '';

      if (char == "'") {
        flushWord();
        buffer.write(char);
        i++;
        while (i < sql.length) {
          final c = sql[i];
          final nc = (i + 1 < sql.length) ? sql[i + 1] : '';
          buffer.write(c);
          if (c == "'") {
            if (nc == "'") {
              buffer.write(nc);
              i += 2;
              continue;
            } else {
              break;
            }
          }
          i++;
        }
      } else if (char == '"') {
        flushWord();
        buffer.write(char);
        i++;
        while (i < sql.length) {
          final c = sql[i];
          final nc = (i + 1 < sql.length) ? sql[i + 1] : '';
          buffer.write(c);
          if (c == '"') {
            if (nc == '"') {
              buffer.write(nc);
              i += 2;
              continue;
            } else {
              break;
            }
          }
          i++;
        }
      } else if (char == '[') {
        flushWord();
        buffer.write(char);
        i++;
        while (i < sql.length && sql[i] != ']') {
          buffer.write(sql[i]);
          i++;
        }
        if (i < sql.length) {
          buffer.write(sql[i]);
        }
      } else if (char == '-' && nextChar == '-') {
        flushWord();
        buffer.write(char);
        buffer.write(nextChar);
        i += 2;
        while (i < sql.length && sql[i] != '\n' && sql[i] != '\r') {
          buffer.write(sql[i]);
          i++;
        }
        continue;
      } else if (char == '/' && nextChar == '*') {
        flushWord();
        buffer.write(char);
        buffer.write(nextChar);
        i += 2;
        while (i + 1 < sql.length && !(sql[i] == '*' && sql[i + 1] == '/')) {
          buffer.write(sql[i]);
          i++;
        }
        if (i + 1 < sql.length) {
          buffer.write(sql[i]);
          buffer.write(sql[i + 1]);
          i += 2;
        }
        continue;
      } else {
        currentWord.write(char);
      }
      i++;
    }

    flushWord();
    return buffer.toString();
  }

  static String _replaceKeywordsInChunk(String text) {
    var result = text;
    final keywords = [
      'PRIMARY KEY',
      'AUTOINCREMENT',
      'NOT NULL',
      'DEFAULT',
      'FOREIGN KEY',
      'REFERENCES',
      'ON DELETE',
      'ON UPDATE',
      'CASCADE',
      'SET NULL',
      'SET DEFAULT',
      'NO ACTION',
      'RESTRICT',
      'UNIQUE',
      'CHECK',
      'CREATE TABLE',
      'CREATE TEMPORARY TABLE',
      'CREATE TEMP TABLE',
      'CREATE VIEW',
      'CREATE TEMPORARY VIEW',
      'CREATE TEMP VIEW',
      'CREATE INDEX',
      'CREATE UNIQUE INDEX',
      'CREATE TRIGGER',
      'IF NOT EXISTS',
      'INTEGER',
      'TEXT',
      'REAL',
      'BLOB',
      'NUMERIC',
      'VARCHAR',
      'BOOLEAN',
      'DATETIME',
      'BIGINT',
      'FLOAT',
      'DOUBLE',
    ];

    for (final kw in keywords) {
      final pattern = RegExp(
        '\\b${kw.replaceAll(' ', '\\s+')}\\b',
        caseSensitive: false,
      );
      result = result.replaceAllMapped(pattern, (_) => kw);
    }
    return result;
  }

  /// Generates full database schema as a single formatted SQL script.
  static String generateCompleteSchemaSql({
    required String dbPath,
    required List<DbTable> tables,
    List<DbTrigger> triggers = const [],
  }) {
    final buffer = StringBuffer();
    final dbName = dbPath.fileNameFromPath;
    final now = DateTime.now()
        .toIso8601String()
        .replaceAll('T', ' ')
        .substring(0, 19);

    final baseTables = tables.where((t) => !t.isView).toList();
    final views = tables.where((t) => t.isView).toList();

    // 1. Header Banner
    buffer.writeln(
      '-- ========================================================',
    );
    buffer.writeln('-- SQLite Database Schema Dump');
    buffer.writeln('-- Database File: $dbName');
    buffer.writeln('-- Generated At:  $now');
    buffer.writeln(
      '-- Tables: ${baseTables.length} | Views: ${views.length} | Triggers: ${triggers.length}',
    );
    buffer.writeln(
      '-- ========================================================',
    );
    buffer.writeln();
    buffer.writeln('PRAGMA foreign_keys = OFF;');
    buffer.writeln();

    // 2. Tables Section
    if (baseTables.isNotEmpty) {
      buffer.writeln(
        '-- --------------------------------------------------------',
      );
      buffer.writeln('-- Section: Tables (${baseTables.length})');
      buffer.writeln(
        '-- --------------------------------------------------------',
      );
      buffer.writeln();

      for (final table in baseTables) {
        if (table.sql != null && table.sql!.isNotEmpty) {
          buffer.writeln('-- Table: ${table.name}');
          buffer.writeln(formatSqlStatement(table.sql!));
          buffer.writeln();
        }
      }
    }

    // 3. Views Section
    if (views.isNotEmpty) {
      buffer.writeln(
        '-- --------------------------------------------------------',
      );
      buffer.writeln('-- Section: Views (${views.length})');
      buffer.writeln(
        '-- --------------------------------------------------------',
      );
      buffer.writeln();

      for (final view in views) {
        if (view.sql != null && view.sql!.isNotEmpty) {
          buffer.writeln('-- View: ${view.name}');
          buffer.writeln(formatSqlStatement(view.sql!));
          buffer.writeln();
        }
      }
    }

    // 4. Standalone Indexes Section
    final standaloneIndexes = <String>[];
    for (final table in tables) {
      for (final idx in table.indexes) {
        // Only include explicit/custom created indexes (origin == 'c')
        if (idx.origin == 'c' && idx.name.isNotEmpty) {
          if (idx.sql != null && idx.sql!.trim().isNotEmpty) {
            final formatted = idx.sql!.trim().endsWith(';')
                ? idx.sql!.trim()
                : '${idx.sql!.trim()};';
            standaloneIndexes.add(formatted);
          } else {
            final uniqueStr = idx.unique ? 'UNIQUE ' : '';
            final escapedIndex = idx.name.replaceAll('"', '""');
            final escapedTable = table.name.replaceAll('"', '""');
            final cols = idx.columns
                .map((c) => '"${c.replaceAll('"', '""')}"')
                .join(', ');
            standaloneIndexes.add(
              'CREATE ${uniqueStr}INDEX IF NOT EXISTS "$escapedIndex" ON "$escapedTable" ($cols);',
            );
          }
        }
      }
    }

    if (standaloneIndexes.isNotEmpty) {
      buffer.writeln(
        '-- --------------------------------------------------------',
      );
      buffer.writeln('-- Section: Indexes (${standaloneIndexes.length})');
      buffer.writeln(
        '-- --------------------------------------------------------',
      );
      buffer.writeln();

      for (final idxSql in standaloneIndexes) {
        buffer.writeln(idxSql);
      }
      buffer.writeln();
    }

    // 5. Triggers Section
    if (triggers.isNotEmpty) {
      buffer.writeln(
        '-- --------------------------------------------------------',
      );
      buffer.writeln('-- Section: Triggers (${triggers.length})');
      buffer.writeln(
        '-- --------------------------------------------------------',
      );
      buffer.writeln();

      for (final trg in triggers) {
        if (trg.sql != null && trg.sql!.isNotEmpty) {
          buffer.writeln('-- Trigger: ${trg.name} ON ${trg.tableName}');
          buffer.writeln(formatSqlStatement(trg.sql!));
          buffer.writeln();
        }
      }
    }

    buffer.writeln('PRAGMA foreign_keys = ON;');
    return buffer.toString();
  }

  /// Prompts user to save schema SQL to a `.sql` file.
  static Future<String?> exportSchemaSqlFile({
    required String schemaSql,
    required String defaultFileName,
  }) async {
    final bytes = Uint8List.fromList(utf8.encode(schemaSql));
    final uri = await FilePickerPlatform.instance.saveFile(
      dialogTitle: 'Save Database Schema (SQL)',
      fileName: defaultFileName,
      bytes: bytes,
      mimeType: 'application/sql',
    );

    if (uri == null) return null;

    final path = uri.toFilePath();
    final file = File(path);
    await file.writeAsBytes(bytes);

    return path;
  }
}
