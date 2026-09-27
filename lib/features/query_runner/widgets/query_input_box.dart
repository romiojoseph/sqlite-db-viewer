import '../../../shared/widgets/app_svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/sql_readonly_guard.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class QueryInputBox extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onExecute;
  final bool isExecuting;

  const QueryInputBox({
    super.key,
    required this.controller,
    required this.onExecute,
    this.isExecuting = false,
  });

  @override
  State<QueryInputBox> createState() => _QueryInputBoxState();
}

class _QueryInputBoxState extends State<QueryInputBox> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sqlText = widget.controller.text;
    final validation = sqlText.trim().isNotEmpty
        ? SqlReadonlyGuard.validate(sqlText)
        : null;

    final hasValidationError = validation != null && !validation.isValid;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.enter, control: true): () {
          if (!hasValidationError && !widget.isExecuting) {
            widget.onExecute();
          }
        },
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): () {
          if (!hasValidationError && !widget.isExecuting) {
            widget.onExecute();
          }
        },
      },
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.neutral2,
          border: Border(
            bottom: BorderSide(color: AppColors.neutral4, width: 1.0),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar
            Row(
              children: [
                Text(
                  'SQL Query',
                  style: AppTypography.subtitle.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral8,
                  ),
                ),
                const Spacer(),
                if (hasValidationError) ...[
                  Text(
                    validation.errorMessage ?? 'Invalid read-only query',
                    style: AppTypography.tagline.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                if (sqlText.isNotEmpty) ...[
                  AppButton(
                    label: 'Clear',
                    variant: AppButtonVariant.ghost,
                    size: AppButtonSize.small,
                    onPressed: () {
                      widget.controller.clear();
                      setState(() {});
                    },
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                AppButton(
                  label: 'Run Query',
                  customIcon: const AppSvgIcon(
                    AppIcons.play,
                    size: 13,
                    color: AppColors.neutral12,
                  ),
                  tooltip: 'Execute query (Ctrl+Enter)',
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.small,
                  isLoading: widget.isExecuting,
                  onPressed: (hasValidationError || widget.isExecuting)
                      ? null
                      : widget.onExecute,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),

            // Code Editor Box
            AppTextField(
              controller: widget.controller,
              focusNode: _focusNode,
              maxLines: 5,
              minLines: 3,
              size: AppInputSize.medium,
              hintText:
                  '-- Enter SELECT query (e.g. SELECT * FROM sqlite_master;)...',
              style: AppTypography.caption.copyWith(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.45,
              ),
              hintStyle: AppTypography.caption.copyWith(
                fontFamily: 'monospace',
                fontSize: 13,
                color: hasValidationError
                    ? AppColors.error.withValues(alpha: 0.7)
                    : AppColors.neutral7,
                height: 1.45,
              ),
              errorText: hasValidationError ? '' : null,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }
}
