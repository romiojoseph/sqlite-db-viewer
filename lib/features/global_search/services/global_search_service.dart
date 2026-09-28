import 'package:flutter/foundation.dart';
import 'package:sqlite3/sqlite3.dart';
import '../../../core/utils/sql_readonly_guard.dart';
import '../../../data/models/db_table.dart';
import '../../../data/services/sqlite_service.dart';
import '../models/search_match.dart';
import '../models/search_result.dart';

class _SearchWorkerRequest {
  final String dbPath;
  final String query;
  final List<DbTable> tables;
  final int maxMatches;
  final bool caseSensitive;

  const _SearchWorkerRequest({
    required this.dbPath,
    required this.query,
    required this.tables,
    required this.maxMatches,
    required this.caseSensitive,
  });
}

SearchResult _searchWorker(_SearchWorkerRequest request) {
  final uri = SqlReadonlyGuard.toImmutableUri(request.dbPath);
  final db = sqlite3.open(uri, mode: OpenMode.readOnly, uri: true);
  final stopwatch = Stopwatch()..start();
  final matches = <SearchMatch>[];
  var isCapped = false;
  var tablesScanned = 0;
  final trimmed = request.query;
  final targetParam = request.caseSensitive ? trimmed : trimmed.toLowerCase();

  db.createFunction(
    functionName: 'dart_lower',
    argumentCount: const AllowedArgumentCount(1),
    deterministic: true,
    function: (args) {
      final arg = args.first;
      if (arg == null) return null;
      return arg.toString().toLowerCase();
    },
  );

  try {
    for (final table in request.tables) {
      tablesScanned++;

      final searchableCols = table.columns.where((c) => !c.isBlob).toList();
      if (searchableCols.isEmpty) continue;

      final remainingCap = request.maxMatches - matches.length;
      if (remainingCap <= 0) {
        isCapped = true;
        break;
      }

      final escapedTable = table.name.replaceAll('"', '""');
      final whereClauses = searchableCols
          .map((c) {
            final escapedCol = c.name.replaceAll('"', '""');
            if (request.caseSensitive) {
              return 'INSTR("$escapedCol", ?) > 0';
            } else {
              return 'INSTR(dart_lower("$escapedCol"), ?) > 0';
            }
          })
          .join(' OR ');

      final sql = 'SELECT * FROM "$escapedTable" WHERE $whereClauses LIMIT ?;';
      final params = <dynamic>[
        ...List<dynamic>.filled(searchableCols.length, targetParam),
        remainingCap,
      ];

      try {
        final resultSet = db.select(sql, params);
        final pkCols = table.columns.where((c) => c.isPrimaryKey).toList();

        var rowIndex = 0;
        for (final row in resultSet) {
          rowIndex++;
          final rowMap = <String, dynamic>{};
          for (final colName in resultSet.columnNames) {
            rowMap[colName] = row[colName];
          }

          String rowId;
          if (pkCols.isNotEmpty) {
            rowId = pkCols
                .map((pk) => '${pk.name}: ${row[pk.name]}')
                .join(', ');
          } else {
            rowId = 'Record #$rowIndex';
          }

          for (final col in searchableCols) {
            final rawVal = row[col.name];
            if (rawVal == null) continue;

            final strVal = rawVal.toString();
            final searchTarget = request.caseSensitive
                ? strVal
                : strVal.toLowerCase();
            final matchIdx = searchTarget.indexOf(targetParam);

            if (matchIdx >= 0) {
              matches.add(
                SearchMatch(
                  tableName: table.name,
                  columnName: col.name,
                  rowIdentifier: rowId,
                  matchedText: strVal,
                  matchIndex: matchIdx,
                  matchLength: trimmed.length,
                  rowData: rowMap,
                ),
              );

              if (matches.length >= request.maxMatches) {
                isCapped = true;
                break;
              }
            }
          }

          if (matches.length >= request.maxMatches) {
            isCapped = true;
            break;
          }
        }
      } catch (_) {
        continue;
      }

      if (isCapped) break;
    }
  } finally {
    db.close();
  }

  stopwatch.stop();

  return SearchResult(
    query: trimmed,
    matches: matches,
    isCapped: isCapped,
    maxCap: request.maxMatches,
    duration: stopwatch.elapsed,
    tablesScanned: tablesScanned,
  );
}

class GlobalSearchService {
  final SqliteService sqliteService;

  const GlobalSearchService({required this.sqliteService});

  Future<SearchResult> search({
    required String query,
    required List<DbTable> tables,
    int maxMatches = 100,
    bool caseSensitive = false,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return SearchResult.empty(trimmed);
    }

    final dbPath = sqliteService.currentFilePath;
    if (dbPath == null) {
      return SearchResult.error(trimmed, 'Database is not open.');
    }

    final req = _SearchWorkerRequest(
      dbPath: dbPath,
      query: trimmed,
      tables: tables,
      maxMatches: maxMatches,
      caseSensitive: caseSensitive,
    );

    return await compute(_searchWorker, req);
  }
}
