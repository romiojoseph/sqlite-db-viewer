class ReadonlyValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ReadonlyValidationResult({
    required this.isValid,
    this.errorMessage,
  });

  factory ReadonlyValidationResult.valid() {
    return const ReadonlyValidationResult(isValid: true);
  }

  factory ReadonlyValidationResult.invalid(String message) {
    return ReadonlyValidationResult(isValid: false, errorMessage: message);
  }
}

class SqlReadonlyGuard {
  SqlReadonlyGuard._();

  static const Set<String> _forbiddenKeywords = {
    'INSERT',
    'UPDATE',
    'DELETE',
    'DROP',
    'CREATE',
    'ALTER',
    'TRUNCATE',
    'REPLACE',
    'ATTACH',
    'DETACH',
    'VACUUM',
    'REINDEX',
    'GRANT',
    'REVOKE',
    'BEGIN',
    'COMMIT',
    'ROLLBACK',
    'SAVEPOINT',
    'RELEASE',
    'UPSERT',
    'MERGE',
    'EXEC',
    'EXECUTE',
    'CALL',
    'LOCK',
  };

  /// PRAGMAs that accept arguments (table/index names or count limits) for inspection only
  static const Set<String> _allowedPragmasWithArgs = {
    'table_info',
    'table_xinfo',
    'index_list',
    'index_info',
    'index_xinfo',
    'foreign_key_list',
    'foreign_key_check',
    'integrity_check',
    'quick_check',
  };

  /// PRAGMAs that are safe for reading when queried without arguments or assignment
  static const Set<String> _allowedNoArgPragmas = {
    'database_list',
    'collation_list',
    'compile_options',
    'user_version',
    'schema_version',
    'freelist_count',
    'page_count',
    'page_size',
    'max_page_count',
    'encoding',
    'journal_mode',
    'synchronous',
    'foreign_keys',
    'auto_vacuum',
    'cache_size',
    'data_version',
    'locking_mode',
    'secure_delete',
    'temp_store',
    'wal_autocheckpoint',
  };

  static ReadonlyValidationResult validate(String sql) {
    final sanitized = _stripComments(sql).trim();

    if (sanitized.isEmpty) {
      return ReadonlyValidationResult.invalid('Query cannot be empty');
    }

    final statements = _splitStatements(sanitized);

    if (statements.isEmpty) {
      return ReadonlyValidationResult.invalid('Query cannot be empty');
    }

    for (final statement in statements) {
      final trimmed = statement.trim();
      if (trimmed.isEmpty) continue;

      final validation = _validateSingleStatement(trimmed);
      if (!validation.isValid) {
        return validation;
      }
    }

    return ReadonlyValidationResult.valid();
  }

  static ReadonlyValidationResult _validateSingleStatement(String statement) {
    // Unwrap leading/trailing outer parentheses if any, e.g. ((SELECT 1))
    var unwrapped = statement.trim();
    while (unwrapped.startsWith('(') && unwrapped.endsWith(')')) {
      final inner = unwrapped.substring(1, unwrapped.length - 1).trim();
      if (inner.isEmpty) break;
      unwrapped = inner;
    }

    final firstToken = _extractFirstToken(unwrapped).toUpperCase();

    if (firstToken.isEmpty) {
      return ReadonlyValidationResult.invalid('Invalid query syntax');
    }

    if (_forbiddenKeywords.contains(firstToken)) {
      return ReadonlyValidationResult.invalid(
        'Write and schema modification operations ($firstToken) are strictly forbidden in read-only mode.',
      );
    }

    if (firstToken == 'SELECT' || firstToken == 'VALUES') {
      return _validateSelectStatement(unwrapped);
    }

    if (firstToken == 'WITH') {
      return _validateWithStatement(unwrapped);
    }

    if (firstToken == 'EXPLAIN') {
      final match = RegExp(r'^EXPLAIN\s+(QUERY\s+PLAN\s+)?', caseSensitive: false).firstMatch(unwrapped);
      if (match != null) {
        final afterExplain = unwrapped.substring(match.end).trim();
        return _validateSingleStatement(afterExplain);
      }
      return ReadonlyValidationResult.invalid('Invalid EXPLAIN query syntax');
    }

    if (firstToken == 'PRAGMA') {
      return _validatePragma(unwrapped);
    }

    return ReadonlyValidationResult.invalid(
      'Only read-only SELECT, EXPLAIN, and safe PRAGMA queries are allowed. Statement starting with "$firstToken" was rejected.',
    );
  }

  static ReadonlyValidationResult _validateSelectStatement(String statement) {
    final clean = _stripStringLiterals(statement);
    final match = RegExp(
      r'\b(ATTACH\s+DATABASE|DETACH\s+DATABASE)\b',
      caseSensitive: false,
    ).firstMatch(clean);

    if (match != null) {
      return ReadonlyValidationResult.invalid(
        'Database attaching/detaching is forbidden in read-only mode.',
      );
    }

    return ReadonlyValidationResult.valid();
  }

  static ReadonlyValidationResult _validateWithStatement(String statement) {
    final clean = _stripStringLiterals(statement);
    
    final match = RegExp(
      r'\b(INSERT|UPDATE|DELETE|REPLACE|DROP|CREATE|ALTER|ATTACH|DETACH|VACUUM|REINDEX)\b',
      caseSensitive: false,
    ).firstMatch(clean);

    if (match != null) {
      final token = match.group(0)!.toUpperCase();
      return ReadonlyValidationResult.invalid(
        'Data modification keyword ($token) is forbidden within CTE expressions.',
      );
    }

    return ReadonlyValidationResult.valid();
  }

  static ReadonlyValidationResult _validatePragma(String pragmaStatement) {
    if (pragmaStatement.contains('=')) {
      return ReadonlyValidationResult.invalid(
        'PRAGMA assignment/modification statements are strictly forbidden in read-only mode.',
      );
    }

    var clean = pragmaStatement.trim();
    if (clean.endsWith(';')) {
      clean = clean.substring(0, clean.length - 1).trim();
    }

    // Match PRAGMA [schema.]name[(args)]
    final match = RegExp(
      r'^PRAGMA\s+(?:([a-zA-Z0-9_]+)\.)?([a-zA-Z0-9_]+)(?:\s*\((.*?)\))?$',
      caseSensitive: false,
    ).firstMatch(clean);

    if (match == null) {
      return ReadonlyValidationResult.invalid('Invalid PRAGMA format.');
    }

    final pragmaName = (match.group(2) ?? '').toLowerCase();
    final hasArgs = match.group(3) != null && match.group(3)!.trim().isNotEmpty;

    if (pragmaName == 'writable_schema') {
      return ReadonlyValidationResult.invalid(
        'PRAGMA writable_schema is strictly prohibited.',
      );
    }

    if (hasArgs) {
      if (_allowedPragmasWithArgs.contains(pragmaName)) {
        return ReadonlyValidationResult.valid();
      }
      return ReadonlyValidationResult.invalid(
        'Setting values via PRAGMA "$pragmaName(...)" is strictly forbidden in read-only mode.',
      );
    } else {
      if (_allowedPragmasWithArgs.contains(pragmaName) ||
          _allowedNoArgPragmas.contains(pragmaName)) {
        return ReadonlyValidationResult.valid();
      }
      return ReadonlyValidationResult.invalid(
        'PRAGMA "$pragmaName" is not recognized or not allowed in read-only mode.',
      );
    }
  }

  static String _stripComments(String sql) {
    final buffer = StringBuffer();
    var inSingleQuotes = false;
    var inDoubleQuotes = false;
    var inBackticks = false;
    var inBrackets = false;

    for (var i = 0; i < sql.length; i++) {
      final char = sql[i];
      final nextChar = (i + 1 < sql.length) ? sql[i + 1] : '';

      if (inSingleQuotes) {
        buffer.write(char);
        if (char == "'") {
          if (nextChar == "'") {
            buffer.write(nextChar);
            i++;
          } else {
            inSingleQuotes = false;
          }
        }
      } else if (inDoubleQuotes) {
        buffer.write(char);
        if (char == '"') {
          if (nextChar == '"') {
            buffer.write(nextChar);
            i++;
          } else {
            inDoubleQuotes = false;
          }
        }
      } else if (inBackticks) {
        buffer.write(char);
        if (char == '`') {
          if (nextChar == '`') {
            buffer.write(nextChar);
            i++;
          } else {
            inBackticks = false;
          }
        }
      } else if (inBrackets) {
        buffer.write(char);
        if (char == ']') {
          inBrackets = false;
        }
      } else {
        if (char == "'") {
          inSingleQuotes = true;
          buffer.write(char);
        } else if (char == '"') {
          inDoubleQuotes = true;
          buffer.write(char);
        } else if (char == '`') {
          inBackticks = true;
          buffer.write(char);
        } else if (char == '[') {
          inBrackets = true;
          buffer.write(char);
        } else if (char == '-' && nextChar == '-') {
          i += 2;
          while (i < sql.length && sql[i] != '\n' && sql[i] != '\r') {
            i++;
          }
          buffer.write(' ');
        } else if (char == '/' && nextChar == '*') {
          i += 2;
          while (i + 1 < sql.length && !(sql[i] == '*' && sql[i + 1] == '/')) {
            i++;
          }
          i++; // skip /
          buffer.write(' ');
        } else {
          buffer.write(char);
        }
      }
    }

    return buffer.toString();
  }

  static String _stripStringLiterals(String sql) {
    final buffer = StringBuffer();
    var inSingleQuotes = false;
    var inDoubleQuotes = false;
    var inBackticks = false;
    var inBrackets = false;

    for (var i = 0; i < sql.length; i++) {
      final char = sql[i];
      final nextChar = (i + 1 < sql.length) ? sql[i + 1] : '';

      if (inSingleQuotes) {
        if (char == "'") {
          if (nextChar == "'") {
            i++;
          } else {
            inSingleQuotes = false;
            buffer.write("''");
          }
        }
      } else if (inDoubleQuotes) {
        if (char == '"') {
          if (nextChar == '"') {
            i++;
          } else {
            inDoubleQuotes = false;
            buffer.write('""');
          }
        }
      } else if (inBackticks) {
        if (char == '`') {
          if (nextChar == '`') {
            i++;
          } else {
            inBackticks = false;
            buffer.write('``');
          }
        }
      } else if (inBrackets) {
        if (char == ']') {
          inBrackets = false;
          buffer.write('[]');
        }
      } else {
        if (char == "'") {
          inSingleQuotes = true;
        } else if (char == '"') {
          inDoubleQuotes = true;
        } else if (char == '`') {
          inBackticks = true;
        } else if (char == '[') {
          inBrackets = true;
        } else {
          buffer.write(char);
        }
      }
    }

    return buffer.toString();
  }

  static List<String> _splitStatements(String sql) {
    final statements = <String>[];
    var current = StringBuffer();
    var inSingleQuotes = false;
    var inDoubleQuotes = false;
    var inBackticks = false;
    var inBrackets = false;

    for (var i = 0; i < sql.length; i++) {
      final char = sql[i];
      final nextChar = (i + 1 < sql.length) ? sql[i + 1] : '';

      if (inSingleQuotes) {
        current.write(char);
        if (char == "'") {
          if (nextChar == "'") {
            current.write(nextChar);
            i++;
          } else {
            inSingleQuotes = false;
          }
        }
      } else if (inDoubleQuotes) {
        current.write(char);
        if (char == '"') {
          if (nextChar == '"') {
            current.write(nextChar);
            i++;
          } else {
            inDoubleQuotes = false;
          }
        }
      } else if (inBackticks) {
        current.write(char);
        if (char == '`') {
          if (nextChar == '`') {
            current.write(nextChar);
            i++;
          } else {
            inBackticks = false;
          }
        }
      } else if (inBrackets) {
        current.write(char);
        if (char == ']') {
          inBrackets = false;
        }
      } else {
        if (char == "'") {
          inSingleQuotes = true;
          current.write(char);
        } else if (char == '"') {
          inDoubleQuotes = true;
          current.write(char);
        } else if (char == '`') {
          inBackticks = true;
          current.write(char);
        } else if (char == '[') {
          inBrackets = true;
          current.write(char);
        } else if (char == ';') {
          final st = current.toString().trim();
          if (st.isNotEmpty) {
            statements.add(st);
          }
          current.clear();
        } else {
          current.write(char);
        }
      }
    }

    final remaining = current.toString().trim();
    if (remaining.isNotEmpty) {
      statements.add(remaining);
    }

    return statements;
  }

  static String _extractFirstToken(String statement) {
    var trimmed = statement.trim();
    while (trimmed.startsWith('(')) {
      trimmed = trimmed.substring(1).trim();
    }
    final match = RegExp(r'^[a-zA-Z_]+').firstMatch(trimmed);
    return match?.group(0) ?? '';
  }
}
