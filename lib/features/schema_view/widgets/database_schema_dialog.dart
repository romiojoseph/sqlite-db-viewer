import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/extensions/string_extensions.dart';
import '../../../data/models/db_table.dart';
import '../../../data/models/db_trigger.dart';
import '../../../data/services/schema_export_service.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class DatabaseSchemaDialog extends StatefulWidget {
  final String dbPath;
  final List<DbTable> tables;
  final List<DbTrigger> triggers;
  final ValueChanged<String>? onOpenInQueryTab;

  const DatabaseSchemaDialog({
    super.key,
    required this.dbPath,
    required this.tables,
    this.triggers = const [],
    this.onOpenInQueryTab,
  });

  static Future<void> show(
    BuildContext context, {
    required String dbPath,
    required List<DbTable> tables,
    List<DbTrigger> triggers = const [],
    ValueChanged<String>? onOpenInQueryTab,
  }) {
    return AppDialog.show<void>(
      context,
      barrierDismissible: true,
      builder: (context) => DatabaseSchemaDialog(
        dbPath: dbPath,
        tables: tables,
        triggers: triggers,
        onOpenInQueryTab: onOpenInQueryTab,
      ),
    );
  }

  @override
  State<DatabaseSchemaDialog> createState() => _DatabaseSchemaDialogState();
}

class _DatabaseSchemaDialogState extends State<DatabaseSchemaDialog> {
  late final String _formattedSql;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _formattedSql = SchemaExportService.generateCompleteSchemaSql(
      dbPath: widget.dbPath,
      tables: widget.tables,
      triggers: widget.triggers,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _formattedSql));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Complete schema SQL copied to clipboard',
          style: AppTypography.caption.copyWith(color: AppColors.neutral8),
        ),
        backgroundColor: AppColors.neutral3,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _exportSqlFile() async {
    final baseName = widget.dbPath.fileNameFromPath.replaceAll(
      RegExp(r'\.[^.]+$'),
      '',
    );
    final defaultFileName = '${baseName}_schema.sql';

    try {
      final path = await SchemaExportService.exportSchemaSqlFile(
        schemaSql: _formattedSql,
        defaultFileName: defaultFileName,
      );

      if (path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Schema SQL saved to $path'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save SQL file: $e'),
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
    final lines = _formattedSql.split('\n');

    return AppDialog(
      maxWidth: 900,
      maxHeight: 700,
      title: 'Database Schema (DDL)',
      subtitle: widget.dbPath.fileNameFromPath,
      headerTrailing: Text(
        '${widget.tables.length} Tables/Views • ${widget.triggers.length} Triggers',
        style: AppTypography.label.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.neutral7,
        ),
      ),
      footerLeading: Text(
        '${lines.length} lines  •  Formatted SQLite DDL',
        style: AppTypography.label.copyWith(color: AppColors.neutral7),
      ),
      footerActions: [
        AppButton(
          label: 'Copy SQL',
          customIcon: const AppSvgIcon(AppIcons.copy, size: 14),
          variant: AppButtonVariant.outline,
          size: AppButtonSize.small,
          onPressed: _copyToClipboard,
        ),
        AppButton(
          label: 'Save .sql File',
          customIcon: const AppSvgIcon(AppIcons.export, size: 14),
          variant: AppButtonVariant.outline,
          size: AppButtonSize.small,
          onPressed: _exportSqlFile,
        ),
      ],
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                child: Text(
                  List.generate(lines.length, (i) => '${i + 1}').join('\n'),
                  style: AppTypography.subtitle.copyWith(
                    fontFamily: 'monospace',
                    color: AppColors.neutral7,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      for (int i = 0; i < lines.length; i++) ...[
                        _buildLineSpan(lines[i]),
                        if (i < lines.length - 1) const TextSpan(text: '\n'),
                      ],
                    ],
                  ),
                  style: AppTypography.subtitle.copyWith(
                    fontFamily: 'monospace',
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextSpan _buildLineSpan(String line) {
    final isComment = line.trimLeft().startsWith('--');
    final isPragma = line.trimLeft().startsWith('PRAGMA');

    return TextSpan(
      text: line.isEmpty ? ' ' : line,
      style: TextStyle(
        color: isComment
            ? AppColors.neutral7
            : (isPragma ? AppColors.typeReal : AppColors.neutral8),
        fontWeight: isComment ? FontWeight.normal : FontWeight.w500,
      ),
    );
  }
}
