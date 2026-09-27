import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqlite3/sqlite3.dart';

class SqlImportRequest {
  final String dbPath;
  final String sqlFilePath;

  const SqlImportRequest({required this.dbPath, required this.sqlFilePath});
}

class SqlImportResult {
  final String dbPath;
  final String? tempDirPath;
  final int statementsExecuted;

  const SqlImportResult({
    required this.dbPath,
    this.tempDirPath,
    required this.statementsExecuted,
  });
}

/// Validates that an imported SQL script contains only permitted DDL/DML statements.
List<String> parseAndValidateSqlStatements(String sql) {
  final statements = <String>[];
  final currentStatement = StringBuffer();
  final sanitizedStatement = StringBuffer();
  final currentWord = StringBuffer();
  var inSingleQuotes = false;
  var inDoubleQuotes = false;
  var inBackticks = false;
  var inBrackets = false;
  var beginEndDepth = 0;

  void flushWord() {
    if (currentWord.isEmpty) return;
    final word = currentWord.toString().toUpperCase();
    currentWord.clear();

    final isTrigger = RegExp(
      r'^\s*CREATE\s+(TEMP\s+|TEMPORARY\s+)?TRIGGER\b',
      caseSensitive: false,
    ).hasMatch(sanitizedStatement.toString());

    if (isTrigger) {
      if (word == 'BEGIN' || word == 'CASE') {
        beginEndDepth++;
      } else if (word == 'END') {
        if (beginEndDepth > 0) {
          beginEndDepth--;
        }
      }
    }
  }

  for (var i = 0; i < sql.length; i++) {
    final char = sql[i];
    final nextChar = (i + 1 < sql.length) ? sql[i + 1] : '';

    if (inSingleQuotes) {
      currentStatement.write(char);
      if (char == "'") {
        if (nextChar == "'") {
          currentStatement.write(nextChar);
          i++;
        } else {
          inSingleQuotes = false;
        }
      }
    } else if (inDoubleQuotes) {
      currentStatement.write(char);
      if (char == '"') {
        if (nextChar == '"') {
          currentStatement.write(nextChar);
          i++;
        } else {
          inDoubleQuotes = false;
        }
      }
    } else if (inBackticks) {
      currentStatement.write(char);
      if (char == '`') {
        inBackticks = false;
      }
    } else if (inBrackets) {
      currentStatement.write(char);
      if (char == ']') {
        inBrackets = false;
      }
    } else {
      if (char == "'") {
        flushWord();
        inSingleQuotes = true;
        currentStatement.write(char);
      } else if (char == '"') {
        flushWord();
        inDoubleQuotes = true;
        currentStatement.write(char);
      } else if (char == '`') {
        flushWord();
        inBackticks = true;
        currentStatement.write(char);
      } else if (char == '[') {
        flushWord();
        inBrackets = true;
        currentStatement.write(char);
      } else if (char == '-' && nextChar == '-') {
        // Line comment: skip
        flushWord();
        i += 2;
        while (i < sql.length && sql[i] != '\n' && sql[i] != '\r') {
          i++;
        }
        currentStatement.write(' ');
      } else if (char == '/' && nextChar == '*') {
        // Block comment: skip
        flushWord();
        i += 2;
        while (i + 1 < sql.length && !(sql[i] == '*' && sql[i + 1] == '/')) {
          i++;
        }
        i++;
        currentStatement.write(' ');
      } else if (char == ';') {
        flushWord();
        currentStatement.write(';');
        sanitizedStatement.write(';');

        final isTrigger = RegExp(
          r'^\s*CREATE\s+(TEMP\s+|TEMPORARY\s+)?TRIGGER\b',
          caseSensitive: false,
        ).hasMatch(sanitizedStatement.toString());

        if (!isTrigger || beginEndDepth == 0) {
          final stmt = currentStatement.toString().trim();
          final sanitized = sanitizedStatement.toString().trim();
          if (stmt.isNotEmpty && stmt != ';') {
            _validateSingleStatement(stmt, sanitized);
            statements.add(stmt);
          }
          currentStatement.clear();
          sanitizedStatement.clear();
          beginEndDepth = 0;
        }
      } else {
        if (RegExp(r'[a-zA-Z0-9_]').hasMatch(char)) {
          currentWord.write(char);
        } else {
          flushWord();
        }
        currentStatement.write(char);
        sanitizedStatement.write(char);
      }
    }
  }

  flushWord();
  final remaining = currentStatement.toString().trim();
  final remainingSanitized = sanitizedStatement.toString().trim();
  if (remaining.isNotEmpty && remaining != ';') {
    _validateSingleStatement(remaining, remainingSanitized);
    statements.add(remaining);
  }

  return statements;
}

const _allowedFirstKeywords = {
  'CREATE',
  'INSERT',
  'UPDATE',
  'DELETE',
  'BEGIN',
  'COMMIT',
  'ROLLBACK',
  'SAVEPOINT',
  'RELEASE',
  'PRAGMA',
};

const _allowedPragmas = {
  'FOREIGN_KEYS',
  'ENCODING',
  'USER_VERSION',
  'APPLICATION_ID',
  'AUTO_VACUUM',
  'CACHE_SIZE',
  'PAGE_SIZE',
  'SYNCHRONOUS',
  'TEMP_STORE',
  'THREADS',
  'WAL_AUTOCHECKPOINT',
  'QUERY_ONLY',
  'LEGACY_FILE_FORMAT',
  'DEFAULT_SYNCHRONOUS',
};

void _validateSingleStatement(String fullStmt, String sanitizedStmt) {
  final trimmed = sanitizedStmt.trim();
  if (trimmed.isEmpty) return;

  final firstTokenMatch = RegExp(r'^[a-zA-Z_]+').firstMatch(trimmed);
  if (firstTokenMatch == null) {
    throw Exception('Invalid SQL statement syntax: $fullStmt');
  }

  final firstWord = firstTokenMatch.group(0)!.toUpperCase();
  if (!_allowedFirstKeywords.contains(firstWord)) {
    throw Exception(
      'Restricted SQL statement "$firstWord". Only table definitions, inserts, updates, deletes, transactions, and safe pragmas are allowed in imported scripts.',
    );
  }

  if (firstWord == 'PRAGMA') {
    final pragmaMatch = RegExp(
      r'^PRAGMA\s+([a-zA-Z0-9_]+\.)?([a-zA-Z0-9_]+)',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (pragmaMatch != null) {
      final pragmaName = pragmaMatch.group(2)!.toUpperCase();
      if (!_allowedPragmas.contains(pragmaName)) {
        throw Exception('Restricted PRAGMA "$pragmaName" in SQL script.');
      }
    } else {
      throw Exception('Malformed PRAGMA statement in SQL script.');
    }
  }

  // Deny-list defense in depth for extension functions or external operations
  final forbiddenSubstrings = [
    RegExp(r'\bATTACH\b', caseSensitive: false),
    RegExp(r'\bDETACH\b', caseSensitive: false),
    RegExp(r'\bVACUUM\b', caseSensitive: false),
    RegExp(r'\bload_extension\b', caseSensitive: false),
    RegExp(r'\breadfile\b', caseSensitive: false),
    RegExp(r'\bwritefile\b', caseSensitive: false),
    RegExp(r'\bedit\b', caseSensitive: false),
  ];

  for (final pattern in forbiddenSubstrings) {
    if (pattern.hasMatch(trimmed)) {
      throw Exception(
        'SQL script contains forbidden operation: ${pattern.pattern}',
      );
    }
  }
}

void validateSqlScriptSafety(String sql) {
  parseAndValidateSqlStatements(sql);
}

/// Worker executed in isolate to build SQLite DB from a .sql script
SqlImportResult importSqlWorker(SqlImportRequest request) {
  final file = File(request.sqlFilePath);
  if (!file.existsSync()) {
    throw Exception('SQL file does not exist at "${request.sqlFilePath}".');
  }

  String rawContent = file.readAsStringSync(encoding: utf8);
  if (rawContent.startsWith('\uFEFF')) {
    rawContent = rawContent.substring(1);
  }

  final statements = parseAndValidateSqlStatements(rawContent);

  final db = sqlite3.open(request.dbPath);
  var statementCount = 0;
  try {
    db.execute('PRAGMA foreign_keys = OFF;');
    for (final stmt in statements) {
      db.execute(stmt);
      statementCount++;
    }
  } finally {
    db.close();
  }

  return SqlImportResult(
    dbPath: request.dbPath,
    statementsExecuted: statementCount,
  );
}

class SqlFileHelper {
  SqlFileHelper._();

  /// Checks whether a file starts with standard SQLite binary header
  static bool isBinarySqliteFile(String filePath) {
    try {
      final file = File(filePath);
      if (!file.existsSync()) return false;
      final length = file.lengthSync();
      if (length < 16) return false;

      final raf = file.openSync(mode: FileMode.read);
      final headerBytes = raf.readSync(16);
      raf.closeSync();

      const sqliteHeader = 'SQLite format 3\x00';
      final headerStr = String.fromCharCodes(headerBytes);
      return headerStr == sqliteHeader;
    } catch (_) {
      return false;
    }
  }

  /// Creates a temporary SQLite database from a plaintext .sql script
  static Future<SqlImportResult> createTempDbFromSqlScript(
    String sqlFilePath,
  ) async {
    final tempDir = Directory.systemTemp.createTempSync('sqlite_viewer_sql_');
    final baseName = File(sqlFilePath).uri.pathSegments.last.replaceAll(
      RegExp(r'\.sql$', caseSensitive: false),
      '',
    );
    final tempDbPath =
        '${tempDir.path}${Platform.pathSeparator}${baseName.isEmpty ? "imported" : baseName}.db';

    final req = SqlImportRequest(dbPath: tempDbPath, sqlFilePath: sqlFilePath);

    try {
      final result = await compute(importSqlWorker, req);
      return SqlImportResult(
        dbPath: result.dbPath,
        tempDirPath: tempDir.path,
        statementsExecuted: result.statementsExecuted,
      );
    } catch (e) {
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
      rethrow;
    }
  }
}
