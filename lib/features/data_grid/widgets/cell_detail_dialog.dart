import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class CellDetailDialog extends StatefulWidget {
  final String columnName;
  final String rawText;

  const CellDetailDialog({
    super.key,
    required this.columnName,
    required this.rawText,
  });

  static void show(
    BuildContext context, {
    required String columnName,
    required String rawText,
  }) {
    AppDialog.show<void>(
      context,
      builder: (_) =>
          CellDetailDialog(columnName: columnName, rawText: rawText),
    );
  }

  @override
  State<CellDetailDialog> createState() => _CellDetailDialogState();
}

class _CellDetailDialogState extends State<CellDetailDialog> {
  final ScrollController _verticalCtrl = ScrollController();
  final ScrollController _horizontalCtrl = ScrollController();

  @override
  void dispose() {
    _verticalCtrl.dispose();
    _horizontalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lineCount = '\n'.allMatches(widget.rawText).length + 1;
    final bytes = utf8.encode(widget.rawText).length;
    final sizeLabel = bytes < 1024
        ? '$bytes B'
        : '${(bytes / 1024).toStringAsFixed(1)} KB';

    return AppDialog(
      title: 'Column: ${widget.columnName}',
      maxWidth: 820,
      maxHeight: 600,
      footerLeading: Text(
        '$lineCount lines • $sizeLabel',
        style: AppTypography.label.copyWith(color: AppColors.neutral7),
      ),
      child: Container(
        color: AppColors.neutral1,
        padding: AppSpacing.paddingMd,
        child: Scrollbar(
          controller: _verticalCtrl,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _verticalCtrl,
            child: Scrollbar(
              controller: _horizontalCtrl,
              thumbVisibility: true,
              notificationPredicate: (notif) => notif.depth == 1,
              child: SingleChildScrollView(
                controller: _horizontalCtrl,
                scrollDirection: Axis.horizontal,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 700),
                  child: SelectableText(
                    widget.rawText,
                    style: AppTypography.body.copyWith(
                      fontFamily: 'monospace',
                      color: AppColors.neutral8,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
