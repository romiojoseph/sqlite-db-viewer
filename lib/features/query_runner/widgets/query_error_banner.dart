import 'package:flutter/material.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/copy_button.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class QueryErrorBanner extends StatelessWidget {
  final String error;

  const QueryErrorBanner({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: AppSpacing.paddingMd,
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.errorBackground,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSvgIcon(
            AppIcons.info,
            size: 18,
            color: AppColors.error,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Query Execution Failed',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                SelectableText(
                  error,
                  style: AppTypography.tagline.copyWith(
                    fontFamily: 'monospace',
                    color: AppColors.neutral12,
                  ),
                ),
              ],
            ),
          ),
          CopyButton(textToCopy: error, tooltip: 'Copy error message'),
        ],
      ),
    );
  }
}
