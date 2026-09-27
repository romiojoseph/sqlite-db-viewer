import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:sqlite3/sqlite3.dart';
import '../core/constants/app_constants.dart';
import '../data/services/recent_files_service.dart';
import '../data/services/sql_file_helper.dart';
import '../data/services/sqlite_service.dart';
import '../features/db_diff/widgets/diff_setup_view.dart';
import '../theme/app_theme.dart';
import 'database_view.dart';
import 'welcome_view.dart';

class SqliteApp extends StatefulWidget {
  const SqliteApp({super.key});

  @override
  State<SqliteApp> createState() => _SqliteAppState();
}

class _SqliteAppState extends State<SqliteApp> {
  final SqliteService _sqliteService = SqliteService();
  String? _currentDbPath;
  String? _displayFilePath;
  List<String> _recentFiles = [];
  bool _isDiffCheckerOpen = false;
  String? _diffInitialPathA;

  final Set<String> _pendingTempDirs = {};

  @override
  void initState() {
    super.initState();
    _loadRecentFiles();
  }

  @override
  void dispose() {
    _sqliteService.close();
    _cleanupTempDirs();
    super.dispose();
  }

  void _cleanupTempDirs() {
    final toRemove = <String>[];
    for (final dirPath in _pendingTempDirs) {
      try {
        final dir = Directory(dirPath);
        if (dir.existsSync()) {
          dir.deleteSync(recursive: true);
        }
        toRemove.add(dirPath);
      } catch (_) {}
    }
    _pendingTempDirs.removeAll(toRemove);
  }

  Future<void> _loadRecentFiles() async {
    final recents = await RecentFilesService.getRecentFiles();
    setState(() {
      _recentFiles = recents;
    });
  }

  Future<void> _createNewDatabase() async {
    try {
      final dummyBytes = Uint8List(0);
      final uri = await FilePickerPlatform.instance.saveFile(
        dialogTitle: 'Create New SQLite Database',
        fileName: 'new_database.db',
        bytes: dummyBytes,
        mimeType: 'application/x-sqlite3',
      );

      if (uri == null) return;

      var filePath = uri.toFilePath();
      if (!filePath.endsWith('.db') &&
          !filePath.endsWith('.sqlite') &&
          !filePath.endsWith('.sqlite3')) {
        filePath = '$filePath.db';
      }

      final db = sqlite3.open(filePath);
      db.execute('PRAGMA user_version = 1;');
      db.close();

      _openDatabase(filePath);
    } catch (e) {
      _showErrorSnackBar('Failed to create database: $e');
    }
  }

  void _openDatabase(String filePath) async {
    if (!File(filePath).existsSync()) {
      _showErrorSnackBar('Database file does not exist: $filePath');
      _removeRecentFile(filePath);
      return;
    }

    try {
      _sqliteService.close();
      _cleanupTempDirs();

      String dbPathToOpen = filePath;
      String displayPath = filePath;

      if (!SqlFileHelper.isBinarySqliteFile(filePath)) {
        // Plaintext SQL script: compile into a temporary SQLite database
        final importResult = await SqlFileHelper.createTempDbFromSqlScript(
          filePath,
        );
        dbPathToOpen = importResult.dbPath;
        if (importResult.tempDirPath != null) {
          _pendingTempDirs.add(importResult.tempDirPath!);
        }
      }

      _sqliteService.open(dbPathToOpen);
      await RecentFilesService.addRecentFile(filePath);
      final updatedRecents = await RecentFilesService.getRecentFiles();

      setState(() {
        _currentDbPath = dbPathToOpen;
        _displayFilePath = displayPath;
        _recentFiles = updatedRecents;
        _isDiffCheckerOpen = false;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to open database: $e');
    }
  }

  void _closeDatabase() {
    _sqliteService.close();
    _cleanupTempDirs();
    setState(() {
      _currentDbPath = null;
      _displayFilePath = null;
    });
  }

  void _openDiffChecker([String? initialPathA]) {
    setState(() {
      _isDiffCheckerOpen = true;
      _diffInitialPathA = initialPathA ?? _displayFilePath ?? _currentDbPath;
    });
  }

  void _closeDiffChecker() {
    setState(() {
      _isDiffCheckerOpen = false;
      _diffInitialPathA = null;
    });
  }

  void _removeRecentFile(String path) async {
    await RecentFilesService.removeRecentFile(path);
    final updated = await RecentFilesService.getRecentFiles();
    setState(() {
      _recentFiles = updated;
    });
  }

  void _clearRecentFiles() async {
    await RecentFilesService.clearRecentFiles();
    setState(() {
      _recentFiles = [];
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget homeView;

    if (_isDiffCheckerOpen) {
      homeView = DiffSetupView(
        onClose: _closeDiffChecker,
        initialDbPathA: _diffInitialPathA,
      );
    } else if (_currentDbPath != null) {
      homeView = DatabaseView(
        dbPath: _currentDbPath!,
        displayFilePath: _displayFilePath,
        sqliteService: _sqliteService,
        onCloseDatabase: _closeDatabase,
        onOpenDiffChecker: () => _openDiffChecker(_currentDbPath),
      );
    } else {
      homeView = WelcomeView(
        recentFiles: _recentFiles,
        onFileSelected: _openDatabase,
        onRemoveRecentFile: _removeRecentFile,
        onClearRecentFiles: _clearRecentFiles,
        onOpenDiffChecker: () => _openDiffChecker(),
        onNewDatabase: _createNewDatabase,
      );
    }

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: homeView,
    );
  }
}
