import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'dialog_close_button.dart';

class AppDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? headerTrailing;
  final bool showCloseButton;
  final VoidCallback? onClose;
  final double maxWidth;
  final double maxHeight;
  final Widget child;
  final Widget? footerLeading;
  final List<Widget>? footerActions;
  final Widget? customFooter;
  final EdgeInsetsGeometry contentPadding;
  final Color contentColor;

  const AppDialog({
    super.key,
    required this.title,
    this.subtitle,
    this.headerTrailing,
    this.showCloseButton = true,
    this.onClose,
    this.maxWidth = 800,
    this.maxHeight = 680,
    required this.child,
    this.footerLeading,
    this.footerActions,
    this.customFooter,
    this.contentPadding = const EdgeInsets.all(AppSpacing.md),
    this.contentColor = AppColors.neutral1,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasFooter =
        customFooter != null ||
        footerLeading != null ||
        (footerActions != null && footerActions!.isNotEmpty);

    return Dialog(
      backgroundColor: AppColors.neutral2,
      shape: ContinuousRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
        side: const BorderSide(color: AppColors.neutral4, width: 1),
      ),
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      child: SelectionArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.neutral3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: AppTypography.heading6.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.neutral8,
                            ),
                          ),
                          if (subtitle != null) ...[
                            Text(
                              subtitle!,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.neutral7,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    ?headerTrailing,
                    if (showCloseButton)
                      DialogCloseButton(
                        onTap: onClose ?? () => Navigator.of(context).pop(),
                      ),
                  ],
                ),
              ),

              // Body
              Expanded(
                child: Container(
                  color: contentColor,
                  padding: contentPadding,
                  child: child,
                ),
              ),

              // Footer
              if (hasFooter)
                customFooter ??
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.neutral3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          footerLeading ?? const SizedBox.shrink(),
                          if (footerActions != null && footerActions!.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (
                                  int i = 0;
                                  i < footerActions!.length;
                                  i++
                                ) ...[
                                  if (i > 0) const SizedBox(width: AppSpacing.xs),
                                  footerActions![i],
                                ],
                              ],
                            ),
                        ],
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
