import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/services/sql_file_helper.dart';
import '../../../data/services/sqlite_service.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/window_title_bar.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../models/diff_session.dart';
import '../models/schema_diff_result.dart';
import '../models/table_diff_result.dart';
import '../services/row_diff_service.dart';
import '../services/schema_diff_service.dart';
import 'diff_empty_state.dart';
import 'diff_file_picker_pair.dart';
import 'diff_row_detail_view.dart';
import 'diff_summary_tree.dart';
import 'diff_table_selector.dart';

class DiffSetupView extends StatefulWidget {
  final VoidCallback onClose;
  final String? initialDbPathA;
  final String? initialDbPathB;
  final bool isEmbedded;

  const DiffSetupView({
    super.key,
    required this.onClose,
    this.initialDbPathA,
    this.initialDbPathB,
    this.isEmbedded = false,
  });

  @override
  State<DiffSetupView> createState() => _DiffSetupViewState();
}

class _DiffSetupViewState extends State<DiffSetupView> {
  final SqliteService _serviceA = SqliteService();
  final SqliteService _serviceB = SqliteService();

  String? _dbPathA;
  String? _dbPathB;

  Map<String, SchemaDiffResult> _schemaDiffs = {};
  Set<String> _selectedTables = {};
  DiffSession? _diffSession;
  String? _selectedTableDetail;

  bool _isLoadingSchemas = false;
  bool _isComparing = false;
  String? _errorMessage;
  String? _tempImportDirA;
  String? _tempImportDirB;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
    _dbPathA = widget.initialDbPathA;
    _dbPathB = widget.initialDbPathB;

    if (_dbPathA != null && _dbPathB != null) {
      _loadSchemas();
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    _serviceA.close();
    _serviceB.close();
    _cleanupTempDirs();
    super.dispose();
  }

  void _cleanupTempDirs() {
    final remaining = <String?>[];
    for (final dirPath in [_tempImportDirA, _tempImportDirB]) {
      if (dirPath != null) {
        try {
          final dir = Directory(dirPath);
          if (dir.existsSync()) {
            dir.deleteSync(recursive: true);
          }
        } catch (_) {
          remaining.add(dirPath);
        }
      }
    }
    _tempImportDirA = remaining.contains(_tempImportDirA)
        ? _tempImportDirA
        : null;
    _tempImportDirB = remaining.contains(_tempImportDirB)
        ? _tempImportDirB
        : null;
  }

  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyW &&
          (HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed)) {
        widget.onClose();
        return true;
      }
      if ((event.logicalKey == LogicalKeyboardKey.keyR &&
              (HardwareKeyboard.instance.isControlPressed ||
                  HardwareKeyboard.instance.isMetaPressed)) ||
          event.logicalKey == LogicalKeyboardKey.f5) {
        if (_dbPathA != null &&
            _dbPathB != null &&
            !_isLoadingSchemas &&
            !_isComparing) {
          _loadSchemas();
          return true;
        }
      }
    }
    return false;
  }

  void _onPathASelected(String path) {
    setState(() {
      _dbPathA = path;
      _diffSession = null;
      _selectedTableDetail = null;
    });
    if (_dbPathB != null) {
      _loadSchemas();
    }
  }

  void _onPathBSelected(String path) {
    setState(() {
      _dbPathB = path;
      _diffSession = null;
      _selectedTableDetail = null;
    });
    if (_dbPathA != null) {
      _loadSchemas();
    }
  }

  void _onSwapDatabases() {
    if (_dbPathA == null && _dbPathB == null) return;
    setState(() {
      final temp = _dbPathA;
      _dbPathA = _dbPathB;
      _dbPathB = temp;
      _diffSession = null;
      _selectedTableDetail = null;
    });
    if (_dbPathA != null && _dbPathB != null) {
      _loadSchemas();
    }
  }

  Future<void> _loadSchemas() async {
    final pathA = _dbPathA;
    final pathB = _dbPathB;

    if (pathA == null || pathB == null) return;
    if (!File(pathA).existsSync() || !File(pathB).existsSync()) {
      setState(() {
        _errorMessage = 'One or both selected database files do not exist.';
      });
      return;
    }

    final previousSelectedDetail = _selectedTableDetail;

    setState(() {
      _isLoadingSchemas = true;
      _errorMessage = null;
      _diffSession = null;
    });

    // Yield control so Flutter paints the loading indicator
    await Future.delayed(const Duration(milliseconds: 120));

    try {
      _serviceA.close();
      _serviceB.close();
      _cleanupTempDirs();

      String actualA = pathA;
      if (!SqlFileHelper.isBinarySqliteFile(pathA)) {
        final resA = await SqlFileHelper.createTempDbFromSqlScript(pathA);
        actualA = resA.dbPath;
        _tempImportDirA = resA.tempDirPath;
      }

      String actualB = pathB;
      if (!SqlFileHelper.isBinarySqliteFile(pathB)) {
        final resB = await SqlFileHelper.createTempDbFromSqlScript(pathB);
        actualB = resB.dbPath;
        _tempImportDirB = resB.tempDirPath;
      }

      _serviceA.open(actualA);
      _serviceB.open(actualB);

      final schemaService = SchemaDiffService(
        serviceA: _serviceA,
        serviceB: _serviceB,
      );

      final diffs = schemaService.compareSchemas();

      if (!mounted) return;

      setState(() {
        _schemaDiffs = diffs;
        _selectedTables = diffs.keys.toSet();
        _isLoadingSchemas = false;
        if (previousSelectedDetail != null &&
            diffs.containsKey(previousSelectedDetail)) {
          _selectedTableDetail = previousSelectedDetail;
        }
      });

      await _runComparison();

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Diff comparison refreshed across ${diffs.length} table${diffs.length == 1 ? '' : 's'}.',
              style: AppTypography.caption.copyWith(color: AppColors.neutral12),
            ),
            backgroundColor: AppColors.neutral3,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            width: 380,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingSchemas = false;
        _errorMessage = 'Failed to load and compare database schemas: $e';
      });
    }
  }

  Future<void> _runComparison() async {
    final pathA = _dbPathA;
    final pathB = _dbPathB;

    if (pathA == null || pathB == null || _selectedTables.isEmpty) return;

    setState(() {
      _isComparing = true;
      _errorMessage = null;
    });

    // Allow UI to render comparison spinner
    await Future.delayed(const Duration(milliseconds: 60));

    final stopwatch = Stopwatch()..start();
    final rowService = RowDiffService(serviceA: _serviceA, serviceB: _serviceB);
    final tableResults = <String, TableDiffResult>{};
    final tablesAMap = {for (final t in _serviceA.getTables()) t.name: t};

    try {
      for (final tableName in _selectedTables) {
        final schemaDiff =
            _schemaDiffs[tableName] ??
            SchemaDiffResult(
              tableName: tableName,
              existsInA: true,
              existsInB: true,
              isIdentical: true,
            );

        final result = await rowService.diffTable(
          tableName,
          schemaDiff,
          tableA: tablesAMap[tableName],
        );
        tableResults[tableName] = result;
      }

      stopwatch.stop();

      final session = DiffSession(
        dbPathA: pathA,
        dbPathB: pathB,
        selectedTables: _selectedTables.toList(),
        tableResults: tableResults,
        duration: stopwatch.elapsed,
      );

      if (!mounted) return;

      setState(() {
        _diffSession = session;
        _isComparing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isComparing = false;
        _errorMessage = 'Comparison failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = Column(
      children: [
        if (_errorMessage != null)
          Padding(
            padding: AppSpacing.paddingMd,
            child: ErrorBanner(
              message: _errorMessage!,
              onClose: () => setState(() => _errorMessage = null),
            ),
          ),
        Expanded(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  0,
                ),
                child: Column(
                  children: [
                    DiffFilePickerPair(
                      dbPathA: _dbPathA,
                      dbPathB: _dbPathB,
                      onSelectPathA: _onPathASelected,
                      onSelectPathB: _onPathBSelected,
                      onSwap: _onSwapDatabases,
                    ),
                    if (_schemaDiffs.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      DiffTableSelector(
                        schemaDiffs: _schemaDiffs,
                        selectedTables: _selectedTables,
                        onRefresh: (!_isLoadingSchemas && !_isComparing)
                            ? _loadSchemas
                            : null,
                        onSelectionChanged: (set) {
                          setState(() {
                            _selectedTables = set;
                          });
                          _runComparison();
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(child: _buildResultsSection()),
            ],
          ),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return body;
    }

    return Scaffold(
      backgroundColor: AppColors.neutral0,
      body: SafeArea(
        child: Column(
          children: [
            WindowTitleBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Database Diff Checker',
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutral8,
                    ),
                  ),
                  if (_dbPathA != null && _dbPathB != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    AppButton(
                      customIcon: const AppSvgIcon(
                        AppIcons.arrowClockwise,
                        size: 14,
                      ),
                      variant: AppButtonVariant.ghost,
                      size: AppButtonSize.small,
                      tooltip: 'Re-compare / Refresh Diff',
                      onPressed: (!_isLoadingSchemas && !_isComparing)
                          ? _loadSchemas
                          : null,
                    ),
                  ],
                  const SizedBox(width: AppSpacing.xxs),
                  AppButton(
                    customIcon: const AppSvgIcon(AppIcons.x, size: 14),
                    variant: AppButtonVariant.ghost,
                    size: AppButtonSize.small,
                    tooltip: 'Close Diff Checker',
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    if (_dbPathA == null || _dbPathB == null) {
      return DiffEmptyState.setupRequired();
    }

    if (_isLoadingSchemas) {
      return const LoadingIndicator(
        message: 'Inspecting schemas from both databases...',
      );
    }

    if (_isComparing) {
      return const LoadingIndicator(
        message: 'Comparing rows and hashes across selected tables...',
      );
    }

    if (_selectedTables.isEmpty) {
      return DiffEmptyState.noTablesSelected();
    }

    final session = _diffSession;
    if (session == null) {
      return DiffEmptyState.setupRequired();
    }

    if (_selectedTableDetail != null &&
        session.tableResults.containsKey(_selectedTableDetail)) {
      final tableResult = session.tableResults[_selectedTableDetail]!;
      return DiffRowDetailView(
        tableDiff: tableResult,
        onBack: () => setState(() => _selectedTableDetail = null),
      );
    }

    return DiffSummaryTree(
      session: session,
      onSelectTable: (name) => setState(() => _selectedTableDetail = name),
    );
  }
}
