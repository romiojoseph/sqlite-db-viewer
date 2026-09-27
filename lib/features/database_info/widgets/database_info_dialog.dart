import 'package:flutter/material.dart';
import '../../../core/extensions/string_extensions.dart';
import '../../../data/models/db_table.dart';
import '../../../data/services/sqlite_service.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/copy_button.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../models/database_info.dart';
import '../services/database_info_service.dart';
import 'info_metric_tile.dart';

class DatabaseInfoDialog extends StatefulWidget {
  final String dbPath;
  final SqliteService sqliteService;
  final List<DbTable> tables;
  final VoidCallback onExportAllZipped;

  const DatabaseInfoDialog({
    super.key,
    required this.dbPath,
    required this.sqliteService,
    required this.tables,
    required this.onExportAllZipped,
  });

  static Future<void> show(
    BuildContext context, {
    required String dbPath,
    required SqliteService sqliteService,
    required List<DbTable> tables,
    required VoidCallback onExportAllZipped,
  }) {
    return AppDialog.show<void>(
      context,
      barrierDismissible: true,
      builder: (ctx) => DatabaseInfoDialog(
        dbPath: dbPath,
        sqliteService: sqliteService,
        tables: tables,
        onExportAllZipped: onExportAllZipped,
      ),
    );
  }

  @override
  State<DatabaseInfoDialog> createState() => _DatabaseInfoDialogState();
}

class _DatabaseInfoDialogState extends State<DatabaseInfoDialog> {
  late final DatabaseInfoService _infoService;
  DatabaseInfo? _info;
  bool _isLoading = true;
  bool _isRunningDeepCheck = false;
  String? _deepCheckResult;

  @override
  void initState() {
    super.initState();
    _infoService = DatabaseInfoService(sqliteService: widget.sqliteService);
    _loadInfo();
  }

  void _loadInfo() async {
    final info = await _infoService.getDatabaseInfo(widget.dbPath);
    if (!mounted) return;
    setState(() {
      _info = info;
      _isLoading = false;
    });
  }

  void _runDeepCheck() async {
    setState(() {
      _isRunningDeepCheck = true;
      _deepCheckResult = null;
    });

    final result = await _infoService.runFullIntegrityCheck();
    if (!mounted) return;

    setState(() {
      _deepCheckResult = result;
      _isRunningDeepCheck = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      maxWidth: 800,
      maxHeight: 680,
      contentPadding: EdgeInsets.zero,
      title: 'Database File Information',
      subtitle: widget.dbPath.fileNameFromPath,
      headerTrailing: Text(
        '${widget.tables.length} Tables/Views',
        style: AppTypography.label.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.neutral7,
        ),
      ),
      footerLeading: _info != null
          ? Text(
              'SQLite ${_info!.sqliteVersion} • ${_info!.fileSizeFormatted}',
              style: AppTypography.label.copyWith(color: AppColors.neutral7),
            )
          : null,
      footerActions: [
        AppButton(
          label: 'Export All (Zipped CSV)',
          variant: AppButtonVariant.outline,
          size: AppButtonSize.small,
          onPressed: () {
            Navigator.of(context).pop();
            widget.onExportAllZipped();
          },
        ),
      ],
      child: _isLoading
          ? const Center(
              child: LoadingIndicator(
                message: 'Inspecting database metrics...',
              ),
            )
          : _info == null
          ? Center(
              child: Text(
                'Failed to load database details.',
                style: AppTypography.caption.copyWith(color: AppColors.error),
              ),
            )
          : _buildContent(_info!),
    );
  }

  Widget _buildContent(DatabaseInfo info) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  info.filePath,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.neutral8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              CopyButton(textToCopy: info.filePath, tooltip: 'Copy path'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PRAGMA integrity_check: ${info.integrityResult.toUpperCase()}',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w500,
                        color: info.isIntegrityOk
                            ? AppColors.neutral8
                            : AppColors.error,
                      ),
                    ),
                    Text(
                      info.isIntegrityOk
                          ? 'Database file is clean and free of corruption.'
                          : 'Integrity issues reported by SQLite engine.',
                      style: AppTypography.label.copyWith(
                        color: AppColors.neutral7,
                      ),
                    ),
                  ],
                ),
              ),
              AppButton(
                label: 'Deep Check',
                variant: AppButtonVariant.outline,
                size: AppButtonSize.small,
                isLoading: _isRunningDeepCheck,
                onPressed: _isRunningDeepCheck ? null : _runDeepCheck,
              ),
            ],
          ),
          if (_deepCheckResult != null) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: Text(
                _deepCheckResult!,
                style: AppTypography.subtitle.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.neutral8,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: InfoMetricTile(
                  label: 'File Size',
                  value: info.fileSizeFormatted,
                  subtitle: '${info.fileSizeBytes} bytes',
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: InfoMetricTile(
                  label: 'Page Size',
                  value: '${info.pageSize} bytes',
                  subtitle: '${info.pageCount} total pages',
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: InfoMetricTile(
                  label: 'Text Encoding',
                  value: info.encoding,
                  subtitle: 'SQLite text format',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: InfoMetricTile(
                  label: 'SQLite Version',
                  value: info.sqliteVersion,
                  subtitle: 'Engine runtime version',
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: InfoMetricTile(
                  label: 'Journal Mode',
                  value: info.journalMode,
                  subtitle: 'Transaction log mode',
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: InfoMetricTile(
                  label: 'Schema & User Version',
                  value: 'S: ${info.schemaVersion} · U: ${info.userVersion}',
                  subtitle: 'PRAGMA versions',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: InfoMetricTile(
                  label: 'Database Objects',
                  value: '${info.tableCount} Tables · ${info.viewCount} Views',
                  subtitle:
                      '${info.indexCount} Indexes · ${info.triggerCount} Triggers',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
