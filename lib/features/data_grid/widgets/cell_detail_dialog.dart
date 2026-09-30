import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/widgets/app_button.dart';
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

  @override
  void dispose() {
    _verticalCtrl.dispose();
    super.dispose();
  }

  String _formatContent(String text) {
    try {
      final decoded = jsonDecode(text);
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(decoded);
    } catch (_) {
      return text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedText = _formatContent(widget.rawText);
    final lineCount = '\n'.allMatches(formattedText).length + 1;
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
      footerActions: [
        AppButton(
          label: 'Close',
          variant: AppButtonVariant.ghost,
          size: AppButtonSize.small,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
      child: Container(
        color: AppColors.neutral1,
        child: Scrollbar(
          controller: _verticalCtrl,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _verticalCtrl,
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              top: AppSpacing.md,
              bottom: AppSpacing.md,
              right: AppSpacing.xl,
            ),
            child: SelectableText(
              formattedText,
              contextMenuBuilder: (context, editableTextState) {
                final text = editableTextState.textEditingValue.text;
                final selection = editableTextState.textEditingValue.selection;
                final hasSelection =
                    !selection.isCollapsed &&
                    selection.start >= 0 &&
                    selection.end <= text.length;

                final List<ContextMenuButtonItem> buttonItems = [
                  ContextMenuButtonItem(
                    type: ContextMenuButtonType.copy,
                    label: 'Copy',
                    onPressed: () {
                      final selectedText = hasSelection
                          ? selection.textInside(text)
                          : text;
                      Clipboard.setData(ClipboardData(text: selectedText));
                      editableTextState.hideToolbar();
                    },
                  ),
                  ContextMenuButtonItem(
                    type: ContextMenuButtonType.selectAll,
                    label: 'Select all',
                    onPressed: () {
                      editableTextState.selectAll(
                        SelectionChangedCause.toolbar,
                      );
                    },
                  ),
                ];

                return AdaptiveTextSelectionToolbar.buttonItems(
                  anchors: editableTextState.contextMenuAnchors,
                  buttonItems: buttonItems,
                );
              },
              style: AppTypography.body.copyWith(
                fontFamily: 'monospace',
                color: AppColors.neutral8,
                height: 1.45,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
