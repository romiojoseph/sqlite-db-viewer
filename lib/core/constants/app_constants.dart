class AppConstants {
  AppConstants._();

  static const String appName = 'DB Viewer';
  static const List<String> supportedDbExtensions = [
    'db',
    'sqlite',
    'sqlite3',
    'db3',
    's3db',
    'sl3',
    'sql',
  ];
  static const int defaultPageSize = 50;
  static const List<int> pageSizeOptions = [25, 50, 100, 250, 500];
  static const String prefRecentFiles = 'sqlite_viewer_recent_files';
  static const int maxRecentFiles = 10;
  static const int maxTextCellPreviewLength = 120;
}
