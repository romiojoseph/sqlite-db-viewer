class QueryResult {
  final List<String> columns;
  final List<List<dynamic>> rows;
  final Duration executionDuration;
  final int totalRows;
  final String? error;
  final bool isSuccess;
  final bool isCapped;
  final int maxCap;

  const QueryResult({
    this.columns = const [],
    this.rows = const [],
    this.executionDuration = Duration.zero,
    this.totalRows = 0,
    this.error,
    this.isSuccess = true,
    this.isCapped = false,
    this.maxCap = 50000,
  });

  factory QueryResult.empty() {
    return const QueryResult(
      columns: [],
      rows: [],
      executionDuration: Duration.zero,
      totalRows: 0,
      isSuccess: true,
    );
  }

  factory QueryResult.failure(String errorMessage, {Duration? duration}) {
    return QueryResult(
      columns: const [],
      rows: const [],
      executionDuration: duration ?? Duration.zero,
      totalRows: 0,
      error: errorMessage,
      isSuccess: false,
    );
  }
}
