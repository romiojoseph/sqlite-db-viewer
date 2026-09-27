import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_constants.dart';
import '../core/extensions/string_extensions.dart';
import '../data/models/column_filter.dart';
import '../data/models/db_sequence.dart';
import '../data/models/db_table.dart';
import '../data/models/db_trigger.dart';
import '../data/models/query_result.dart';
import '../data/services/csv_export_service.dart';
import '../data/services/csv_import_service.dart';
import '../data/services/sqlite_service.dart';
import '../features/data_grid/widgets/paginated_data_grid.dart';
import '../features/database_info/widgets/database_info_dialog.dart';
import '../features/db_diff/widgets/diff_setup_view.dart';
import '../features/global_search/widgets/global_search_view.dart';
import '../features/query_runner/widgets/query_result_grid.dart';
import '../features/schema_graph/widgets/schema_graph_view.dart';
import '../features/schema_view/widgets/database_schema_dialog.dart';
import '../features/schema_view/widgets/schema_table.dart';
import '../features/table_explorer/widgets/table_sidebar.dart';
import '../features/tabs/models/app_tab.dart';
import '../features/tabs/widgets/query_tab_bar.dart';
import '../shared/widgets/app_button.dart';
import '../shared/widgets/app_dialog.dart';
import '../shared/widgets/app_svg_icon.dart';
import '../shared/widgets/empty_state.dart';
import '../shared/widgets/error_banner.dart';
import '../shared/widgets/loading_indicator.dart';
import '../shared/widgets/window_title_bar.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class DatabaseView extends StatefulWidget {
  final String dbPath;
  final String? displayFilePath;
  final SqliteService sqliteService;
  final VoidCallback onCloseDatabase;
  final VoidCallback onOpenDiffChecker;

  const DatabaseView({
    super.key,
    required this.dbPath,
    this.displayFilePath,
    required this.sqliteService,
    required this.onCloseDatabase,
    required this.onOpenDiffChecker,
  });

  @override
  State<DatabaseView> createState() => _DatabaseViewState();
}

class _DatabaseViewState extends State<DatabaseView> {
  List<DbTable> _tables = [];
  List<DbTrigger> _triggers = [];
  List<DbSequence> _sequences = [];
  bool _isLoadingTables = true;
  String? _errorMessage;
  final List<AppTab> _tabs = [];
  String _selectedTabId = '';
  int _queryCounter = 1;

  final Map<String, QueryResult> _tableDataCache = {};
  final Map<String, int> _tableCurrentPage = {};
  final Map<String, int> _tablePageSize = {};
  final Map<String, String?> _tableSortColumn = {};
  final Map<String, bool> _tableSortAscending = {};
  final Map<String, List<ColumnFilter>> _tableFilters = {};
  final Map<String, bool> _tableLoading = {};

  final Map<String, TextEditingController> _queryControllers = {};
  final Map<String, QueryResult?> _queryResults = {};
  final Map<String, bool> _queryExecuting = {};
  final Map<String, int> _queryCurrentPage = {};
  final Map<String, int> _queryPageSize = {};

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
    _loadDatabaseTables();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    for (final controller in _queryControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.keyW &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed)) {
      _handleCloseShortcut();
      return true;
    }
    return false;
  }

  Future<void> _loadDatabaseTables() async {
    setState(() {
      _isLoadingTables = true;
      _errorMessage = null;
    });

    try {
      final filePath = widget.dbPath;
      final tables = await compute(fetchTablesMetadataInIsolate, filePath);
      widget.sqliteService.open(filePath);
      final triggers = widget.sqliteService.getTriggers();
      final sequences = widget.sqliteService.getSequences();

      if (!mounted) return;
      setState(() {
        _tables = tables;
        _triggers = triggers;
        _sequences = sequences;
        _isLoadingTables = false;
      });

      if (tables.isNotEmpty) {
        _openTableTab(tables.first);
      } else {
        _addNewQueryTab();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingTables = false;
        _errorMessage = 'Failed to inspect database schema: $e';
      });
    }
  }

  Future<void> _refreshDatabase() async {
    setState(() {
      _isLoadingTables = true;
      _errorMessage = null;
    });

    try {
      final filePath = widget.dbPath;
      final tables = await compute(fetchTablesMetadataInIsolate, filePath);
      widget.sqliteService.open(filePath);
      final triggers = widget.sqliteService.getTriggers();
      final sequences = widget.sqliteService.getSequences();

      if (!mounted) return;
      setState(() {
        _tables = tables;
        _triggers = triggers;
        _sequences = sequences;
        _isLoadingTables = false;
        _tableDataCache.clear();
      });

      final active = _activeTab;
      if (active != null && active.tableName != null) {
        _loadTableData(active.tableName!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingTables = false;
        _errorMessage = 'Failed to refresh database: $e';
      });
    }
  }

  void _openTableTab(DbTable table) {
    final tabId = 'table_${table.name}';
    final existingIndex = _tabs.indexWhere((t) => t.id == tabId);

    if (existingIndex >= 0) {
      setState(() {
        _selectedTabId = tabId;
      });
    } else {
      final newTab = AppTab(
        id: tabId,
        title: table.name,
        type: AppTabType.tableData,
        tableName: table.name,
      );
      setState(() {
        _tabs.add(newTab);
        _selectedTabId = tabId;
      });
    }

    _loadTableData(table.name);
  }

  void _openSchemaTab(String tableName) {
    final tabId = 'schema_$tableName';
    final existingIndex = _tabs.indexWhere((t) => t.id == tabId);

    if (existingIndex >= 0) {
      setState(() {
        _selectedTabId = tabId;
      });
    } else {
      final newTab = AppTab(
        id: tabId,
        title: '$tableName (Schema)',
        type: AppTabType.tableSchema,
        tableName: tableName,
      );
      setState(() {
        _tabs.add(newTab);
        _selectedTabId = tabId;
      });
    }
  }

  void _openSchemaGraphTab() {
    const tabId = 'schema_graph_erd';
    final existingIndex = _tabs.indexWhere((t) => t.id == tabId);

    if (existingIndex >= 0) {
      setState(() {
        _selectedTabId = tabId;
      });
    } else {
      const newTab = AppTab(
        id: tabId,
        title: 'Schema Graph',
        type: AppTabType.schemaGraph,
      );
      setState(() {
        _tabs.add(newTab);
        _selectedTabId = tabId;
      });
    }
  }

  void _openGlobalSearchTab() {
    const tabId = 'global_db_search';
    final existingIndex = _tabs.indexWhere((t) => t.id == tabId);

    if (existingIndex >= 0) {
      setState(() {
        _selectedTabId = tabId;
      });
    } else {
      const newTab = AppTab(
        id: tabId,
        title: 'Full-Text Search',
        type: AppTabType.globalSearch,
      );
      setState(() {
        _tabs.add(newTab);
        _selectedTabId = tabId;
      });
    }
  }

  void _openDiffCheckerTab() {
    const tabId = 'db_diff_checker';
    final existingIndex = _tabs.indexWhere((t) => t.id == tabId);

    if (existingIndex >= 0) {
      setState(() {
        _selectedTabId = tabId;
      });
    } else {
      const newTab = AppTab(
        id: tabId,
        title: 'Database Diff',
        type: AppTabType.diffChecker,
      );
      setState(() {
        _tabs.add(newTab);
        _selectedTabId = tabId;
      });
    }
  }

  void _showDatabaseInfoDialog() {
    DatabaseInfoDialog.show(
      context,
      dbPath: widget.dbPath,
      sqliteService: widget.sqliteService,
      tables: _tables,
      onExportAllZipped: _handleExportAllTablesZipped,
    );
  }

  void _showCompleteSchemaDialog() {
    DatabaseSchemaDialog.show(
      context,
      dbPath: widget.dbPath,
      tables: _tables,
      triggers: _triggers,
      onOpenInQueryTab: (sql) => _addNewQueryTab(initialSql: sql),
    );
  }

  void _handleExportAllTablesZipped() async {
    final baseName = widget.dbPath.fileNameFromPath.replaceAll(
      RegExp(r'\.[^.]+$'),
      '',
    );
    final defaultZip = '${baseName}_export.zip';

    final path = await CsvExportService.exportAllTablesZipped(
      sqliteService: widget.sqliteService,
      tables: _tables,
      defaultZipName: defaultZip,
    );

    if (!mounted) return;

    if (path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported all tables to $path'),
          backgroundColor: AppColors.neutral3,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _addNewQueryTab({String? initialSql}) {
    final tabId = 'query_${_queryCounter++}';
    final title = 'Query ${_queryCounter - 1}';
    final sqlToUse =
        initialSql ??
        (_tables.isNotEmpty
            ? 'SELECT * FROM "${_tables.first.name.replaceAll('"', '""')}" LIMIT 50;'
            : 'SELECT 1;');

    final controller = TextEditingController(text: sqlToUse);
    _queryControllers[tabId] = controller;
    _queryPageSize[tabId] = AppConstants.defaultPageSize;
    _queryCurrentPage[tabId] = 0;

    final newTab = AppTab(
      id: tabId,
      title: title,
      type: AppTabType.customQuery,
      sql: sqlToUse,
    );

    setState(() {
      _tabs.add(newTab);
      _selectedTabId = tabId;
    });
  }

  void _closeTab(AppTab tab) {
    final index = _tabs.indexWhere((t) => t.id == tab.id);
    if (index < 0) return;

    if (tab.type == AppTabType.customQuery) {
      _queryControllers[tab.id]?.dispose();
      _queryControllers.remove(tab.id);
      _queryResults.remove(tab.id);
      _queryExecuting.remove(tab.id);
      _queryCurrentPage.remove(tab.id);
      _queryPageSize.remove(tab.id);
    }

    setState(() {
      _tabs.removeAt(index);
      if (_selectedTabId == tab.id) {
        if (_tabs.isNotEmpty) {
          final nextIndex = (index - 1).clamp(0, _tabs.length - 1);
          _selectedTabId = _tabs[nextIndex].id;
        } else {
          _selectedTabId = '';
        }
      }
    });
  }

  void _loadTableData(String tableName) async {
    final page = _tableCurrentPage[tableName] ?? 0;
    final size = _tablePageSize[tableName] ?? AppConstants.defaultPageSize;
    final sortCol = _tableSortColumn[tableName];
    final sortAsc = _tableSortAscending[tableName] ?? true;
    final filters = _tableFilters[tableName] ?? [];

    final sqlConditions = filters.map((f) => f.toSql()).toList();
    final whereClause = sqlConditions.isNotEmpty
        ? sqlConditions.map((c) => c.clause).join(' AND ')
        : null;
    final whereArgs = sqlConditions.isNotEmpty
        ? sqlConditions.expand((c) => c.args).toList()
        : null;

    setState(() {
      _tableLoading[tableName] = true;
    });

    try {
      final req = TableDataFetchRequest(
        filePath: widget.dbPath,
        tableName: tableName,
        limit: size,
        offset: page * size,
        sortColumn: sortCol,
        sortAscending: sortAsc,
        whereClause: whereClause,
        whereArgs: whereArgs,
      );

      final result = await compute(fetchTableDataInIsolate, req);

      if (!mounted) return;
      setState(() {
        _tableDataCache[tableName] = result;
        _tableLoading[tableName] = false;
      });
    } catch (e) {
      if (!mounted) return;
      final fallbackResult = widget.sqliteService.getTableData(
        tableName,
        limit: size,
        offset: page * size,
        sortColumn: sortCol,
        sortAscending: sortAsc,
        whereClause: whereClause,
        whereArgs: whereArgs,
      );
      setState(() {
        _tableDataCache[tableName] = fallbackResult;
        _tableLoading[tableName] = false;
      });
    }
  }

  void _handleTableSort(String tableName, String column) {
    final currentSort = _tableSortColumn[tableName];
    final currentAsc = _tableSortAscending[tableName] ?? true;

    if (currentSort == column) {
      if (currentAsc) {
        _tableSortAscending[tableName] = false;
      } else {
        _tableSortColumn[tableName] = null;
        _tableSortAscending[tableName] = true;
      }
    } else {
      _tableSortColumn[tableName] = column;
      _tableSortAscending[tableName] = true;
    }

    _loadTableData(tableName);
  }

  void _handleTableSortAsc(String tableName, String column) {
    _tableSortColumn[tableName] = column;
    _tableSortAscending[tableName] = true;
    _loadTableData(tableName);
  }

  void _handleTableSortDesc(String tableName, String column) {
    _tableSortColumn[tableName] = column;
    _tableSortAscending[tableName] = false;
    _loadTableData(tableName);
  }

  void _handleTableClearSort(String tableName) {
    _tableSortColumn[tableName] = null;
    _tableSortAscending[tableName] = true;
    _loadTableData(tableName);
  }

  void _handleTableFiltersChanged(
    String tableName,
    List<ColumnFilter> filters,
  ) {
    setState(() {
      _tableFilters[tableName] = filters;
      _tableCurrentPage[tableName] = 0;
    });
    _loadTableData(tableName);
  }

  void _handleTablePageChange(String tableName, int newPage) {
    setState(() {
      _tableCurrentPage[tableName] = newPage;
    });
    _loadTableData(tableName);
  }

  void _handleTablePageSizeChange(String tableName, int newSize) {
    setState(() {
      _tablePageSize[tableName] = newSize;
      _tableCurrentPage[tableName] = 0;
    });
    _loadTableData(tableName);
  }

  void _executeQuery(String tabId) {
    final controller = _queryControllers[tabId];
    if (controller == null) return;

    final sql = controller.text.trim();
    if (sql.isEmpty) return;

    setState(() {
      _queryExecuting[tabId] = true;
      _queryCurrentPage[tabId] = 0;
    });

    final result = widget.sqliteService.executeCustomQuery(sql);

    setState(() {
      _queryResults[tabId] = result;
      _queryExecuting[tabId] = false;
    });
  }

  AppTab? get _activeTab {
    final idx = _tabs.indexWhere((t) => t.id == _selectedTabId);
    return idx >= 0 ? _tabs[idx] : null;
  }

  DbTable? _findTable(String? name) {
    if (name == null) return null;
    final idx = _tables.indexWhere((t) => t.name == name);
    return idx >= 0 ? _tables[idx] : null;
  }

  void _handleCloseShortcut() {
    final active = _activeTab;
    if (active != null) {
      _closeTab(active);
    } else {
      widget.onCloseDatabase();
    }
  }

  Future<void> _handleImportCsv() async {
    try {
      final result = await FilePickerPlatform.instance.pickFiles(
        dialogTitle: 'Select CSV File to Import as Table',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result.isEmpty) return;

      final validPaths = result
          .map((f) => f.path)
          .where((p) => p != null && p.isNotEmpty)
          .cast<String>()
          .toList();

      if (validPaths.isEmpty) return;
      if (!mounted) return;

      final confirmed = await AppDialog.show<bool>(
        context,
        builder: (ctx) => AppDialog(
          title: 'Confirm Database Modification',
          maxWidth: 500,
          maxHeight: 260,
          contentPadding: const EdgeInsets.all(AppSpacing.md),
          footerActions: [
            AppButton(
              label: 'Cancel',
              variant: AppButtonVariant.ghost,
              size: AppButtonSize.small,
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            AppButton(
              label: 'Proceed with Import',
              variant: AppButtonVariant.primary,
              size: AppButtonSize.small,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              'Importing CSV will write changes directly to the database file on disk:\n\n${widget.dbPath}\n\nDo you want to proceed?',
              style: AppTypography.body.copyWith(color: AppColors.neutral10),
            ),
          ),
        ),
      );

      if (confirmed != true) return;

      setState(() {
        _isLoadingTables = true;
      });

      final importedSummaries = <String>[];

      for (final path in validPaths) {
        final importRes = await CsvImportService.importCsv(
          dbPath: widget.dbPath,
          csvFilePath: path,
        );
        importedSummaries.add(
          "'${importRes.tableName}' (${importRes.rowsImported} rows, ${importRes.isNewTable ? 'New' : 'Updated'})",
        );
      }

      await _refreshDatabase();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully imported: ${importedSummaries.join(', ')}',
              style: AppTypography.caption.copyWith(color: AppColors.neutral12),
            ),
            backgroundColor: AppColors.neutral3,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTables = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV Import failed: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeTab;

    return Scaffold(
      backgroundColor: AppColors.neutral1,
      body: SafeArea(
        child: Column(
          children: [
            WindowTitleBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    (widget.displayFilePath ?? widget.dbPath).fileNameFromPath,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.neutral10,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  AppButton(
                    customIcon: const AppSvgIcon(
                      AppIcons.arrowClockwise,
                      size: 14,
                    ),
                    variant: AppButtonVariant.ghost,
                    size: AppButtonSize.small,
                    tooltip: 'Refresh Database',
                    onPressed: _refreshDatabase,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  AppButton(
                    customIcon: const AppSvgIcon(AppIcons.x, size: 14),
                    variant: AppButtonVariant.ghost,
                    size: AppButtonSize.small,
                    tooltip: 'Close Database',
                    onPressed: widget.onCloseDatabase,
                  ),
                ],
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: AppSpacing.paddingMd,
                child: ErrorBanner(
                  message: _errorMessage!,
                  onClose: () => setState(() => _errorMessage = null),
                ),
              ),
            Expanded(
              child: _isLoadingTables
                  ? const LoadingIndicator(
                      message: 'Reading database schema...',
                    )
                  : Row(
                      children: [
                        TableSidebar(
                          dbPath: widget.dbPath,
                          tables: _tables,
                          triggers: _triggers,
                          sequences: _sequences,
                          selectedTableName: active?.tableName,
                          onTableSelected: _openTableTab,
                          onImportCsv: _handleImportCsv,
                          onOpenCompleteSchema: _showCompleteSchemaDialog,
                          onCloseDatabase: widget.onCloseDatabase,
                          onNewQueryTab: () => _addNewQueryTab(),
                          onOpenSchemaGraph: _openSchemaGraphTab,
                          onOpenGlobalSearch: _openGlobalSearchTab,
                          onOpenDatabaseInfo: _showDatabaseInfoDialog,
                          onExportAllZipped: _handleExportAllTablesZipped,
                          onOpenDiffChecker: _openDiffCheckerTab,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              if (_tabs.isNotEmpty)
                                QueryTabBar(
                                  tabs: _tabs,
                                  selectedTabId: _selectedTabId,
                                  onTabSelected: (tab) =>
                                      setState(() => _selectedTabId = tab.id),
                                  onTabClosed: _closeTab,
                                  onNewQueryTab: () => _addNewQueryTab(),
                                ),
                              Expanded(child: _buildMainContent(active)),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(AppTab? active) {
    if (active == null) {
      return const EmptyState(
        svgIcon: AppIcons.cards,
        title: 'No Tabs Open',
        subtitle:
            'Select a table from the sidebar or click "New SQL Query" to start.',
      );
    }

    switch (active.type) {
      case AppTabType.tableData:
        return _buildTableDataView(active.tableName ?? '');
      case AppTabType.tableSchema:
        return _buildTableSchemaView(active.tableName ?? '');
      case AppTabType.customQuery:
        return _buildCustomQueryView(active.id);
      case AppTabType.schemaGraph:
        return SchemaGraphView(
          tables: _tables,
          onTableSelected: (tableName) {
            final table = _findTable(tableName);
            if (table != null) {
              _openTableTab(table);
            }
          },
        );
      case AppTabType.globalSearch:
        return GlobalSearchView(
          sqliteService: widget.sqliteService,
          tables: _tables,
          onNavigateToTable: (tableName) {
            final table = _findTable(tableName);
            if (table != null) {
              _openTableTab(table);
            }
          },
        );
      case AppTabType.diffChecker:
        return DiffSetupView(
          onClose: () => _closeTab(active),
          initialDbPathA: widget.dbPath,
          isEmbedded: true,
        );
    }
  }

  Future<String?> _handleExportTableCsv(String tableName) async {
    final sortCol = _tableSortColumn[tableName];
    final sortAsc = _tableSortAscending[tableName] ?? true;
    final filters = _tableFilters[tableName] ?? [];

    final sqlConditions = filters.map((f) => f.toSql()).toList();
    final whereClause = sqlConditions.isNotEmpty
        ? sqlConditions.map((c) => c.clause).join(' AND ')
        : null;
    final whereArgs = sqlConditions.isNotEmpty
        ? sqlConditions.expand((c) => c.args).toList()
        : null;

    try {
      final exportPath = await CsvExportService.exportTableToFile(
        dbPath: widget.dbPath,
        tableName: tableName,
        whereClause: whereClause,
        whereArgs: whereArgs,
        sortColumn: sortCol,
        sortAscending: sortAsc,
        defaultFileName: '$tableName.csv',
      );

      if (exportPath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported $tableName to $exportPath'),
            backgroundColor: AppColors.neutral3,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return exportPath;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    }
  }

  Widget _buildTableDataView(String tableName) {
    final isLoading = _tableLoading[tableName] ?? false;
    final cachedResult = _tableDataCache[tableName];
    final table = _findTable(tableName);

    if (isLoading && cachedResult == null) {
      return const LoadingIndicator(message: 'Loading table records...');
    }

    if (cachedResult == null) {
      return const EmptyState(
        svgIcon: AppIcons.table,
        title: 'No Data Loaded',
        subtitle: 'Click to load table records.',
      );
    }

    if (!cachedResult.isSuccess && cachedResult.error != null) {
      return Padding(
        padding: AppSpacing.paddingLg,
        child: ErrorBanner(message: cachedResult.error!),
      );
    }

    final currentPage = _tableCurrentPage[tableName] ?? 0;
    final pageSize = _tablePageSize[tableName] ?? AppConstants.defaultPageSize;
    final totalRows = table?.rowCount ?? cachedResult.totalRows;
    final sortCol = _tableSortColumn[tableName];
    final sortAsc = _tableSortAscending[tableName] ?? true;
    final filters = _tableFilters[tableName] ?? [];

    return PaginatedDataGrid(
      result: cachedResult,
      currentPage: currentPage,
      pageSize: pageSize,
      totalRows: totalRows,
      sortColumn: sortCol,
      sortAscending: sortAsc,
      filters: filters,
      onPageChanged: (newPage) => _handleTablePageChange(tableName, newPage),
      onPageSizeChanged: (newSize) =>
          _handleTablePageSizeChange(tableName, newSize),
      onSortChanged: (col) => _handleTableSort(tableName, col),
      onSortAsc: (col) => _handleTableSortAsc(tableName, col),
      onSortDesc: (col) => _handleTableSortDesc(tableName, col),
      onClearSort: () => _handleTableClearSort(tableName),
      onFiltersChanged: (newFilters) =>
          _handleTableFiltersChanged(tableName, newFilters),
      onFetchDistinctValues: (col) async =>
          widget.sqliteService.getDistinctColumnValues(tableName, col),
      exportDefaultName: '$tableName.csv',
      onExportCsv: () => _handleExportTableCsv(tableName),
      trailingHeaderAction: AppButton(
        label: 'View Schema',
        customIcon: const AppSvgIcon(AppIcons.fileSql, size: 14),
        variant: AppButtonVariant.outline,
        size: AppButtonSize.small,
        onPressed: () => _openSchemaTab(tableName),
      ),
    );
  }

  Widget _buildTableSchemaView(String tableName) {
    final table = _findTable(tableName);
    if (table == null) {
      return const EmptyState(
        svgIcon: AppIcons.fileSql,
        title: 'Schema Not Found',
        subtitle: 'Table definition could not be located.',
      );
    }

    return SchemaTable(
      table: table,
      allTables: _tables,
      triggers: _triggers,
      onNavigateToTable: (targetName) {
        final target = _findTable(targetName);
        if (target != null) {
          _openTableTab(target);
        }
      },
    );
  }

  Widget _buildCustomQueryView(String tabId) {
    final controller = _queryControllers[tabId] ?? TextEditingController();
    final result = _queryResults[tabId];
    final isExecuting = _queryExecuting[tabId] ?? false;
    final currentPage = _queryCurrentPage[tabId] ?? 0;
    final pageSize = _queryPageSize[tabId] ?? AppConstants.defaultPageSize;

    return QueryResultGrid(
      inputController: controller,
      result: result,
      isExecuting: isExecuting,
      onExecute: () => _executeQuery(tabId),
      currentPage: currentPage,
      pageSize: pageSize,
      onPageChanged: (newPage) {
        setState(() {
          _queryCurrentPage[tabId] = newPage;
        });
      },
      onPageSizeChanged: (newSize) {
        setState(() {
          _queryPageSize[tabId] = newSize;
          _queryCurrentPage[tabId] = 0;
        });
      },
    );
  }
}
