import 'search_match.dart';

class SearchResult {
  final String query;
  final List<SearchMatch> matches;
  final bool isCapped;
  final int maxCap;
  final Duration duration;
  final int tablesScanned;
  final String? errorMessage;

  const SearchResult({
    required this.query,
    required this.matches,
    required this.isCapped,
    required this.maxCap,
    required this.duration,
    required this.tablesScanned,
    this.errorMessage,
  });

  bool get hasMatches => matches.isNotEmpty;
  int get matchCount => matches.length;

  int get tablesWithMatchesCount {
    return matches.map((m) => m.tableName).toSet().length;
  }

  factory SearchResult.empty(String query) {
    return SearchResult(
      query: query,
      matches: const [],
      isCapped: false,
      maxCap: 100,
      duration: Duration.zero,
      tablesScanned: 0,
    );
  }

  factory SearchResult.error(String query, String message) {
    return SearchResult(
      query: query,
      matches: const [],
      isCapped: false,
      maxCap: 100,
      duration: Duration.zero,
      tablesScanned: 0,
      errorMessage: message,
    );
  }
}
