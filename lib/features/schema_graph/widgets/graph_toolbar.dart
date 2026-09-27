import '../../../shared/widgets/app_svg_icon.dart';
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class GraphToolbar extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onResetView;
  final VoidCallback onRelayout;
  final int tableCount;
  final int relationshipCount;

  const GraphToolbar({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onResetView,
    required this.onRelayout,
    required this.tableCount,
    required this.relationshipCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: ShapeDecoration(
        color: AppColors.neutral2,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
          side: const BorderSide(color: AppColors.neutral3),
        ),
        shadows: [
          BoxShadow(
            color: AppColors.neutral0.withValues(alpha: 0.3),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xxxs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$tableCount tables',
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.neutral8,
                  ),
                ),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  '•',
                  style: AppTypography.label.copyWith(
                    color: AppColors.neutral8,
                  ),
                ),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  '$relationshipCount relations',
                  style: AppTypography.label.copyWith(
                    color: AppColors.neutral8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          const SizedBox(
            height: 18,
            child: VerticalDivider(width: 1, color: AppColors.neutral4),
          ),
          const SizedBox(width: AppSpacing.sm),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppSvgIcon(
                AppIcons.key,
                size: 12,
                color: AppColors.neutral8,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                'PK',
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.neutral8,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const AppSvgIcon(
                AppIcons.key,
                size: 11,
                color: AppColors.neutral8,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                'FK',
                style: AppTypography.label.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.neutral8,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          const SizedBox(
            height: 18,
            child: VerticalDivider(width: 1, color: AppColors.neutral4),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            icon: const AppSvgIcon(
              AppIcons.plus,
              size: 14,
              color: AppColors.neutral8,
            ),
            tooltip: 'Zoom In',
            visualDensity: VisualDensity.compact,
            onPressed: onZoomIn,
          ),
          IconButton(
            icon: const AppSvgIcon(
              AppIcons.minus,
              size: 14,
              color: AppColors.neutral8,
            ),
            tooltip: 'Zoom Out',
            visualDensity: VisualDensity.compact,
            onPressed: onZoomOut,
          ),
          IconButton(
            icon: const AppSvgIcon(
              AppIcons.layout,
              size: 14,
              color: AppColors.neutral8,
            ),
            tooltip: 'Reset View',
            visualDensity: VisualDensity.compact,
            onPressed: onResetView,
          ),
          IconButton(
            icon: const AppSvgIcon(
              AppIcons.arrowClockwise,
              size: 15,
              color: AppColors.neutral8,
            ),
            tooltip: 'Re-run Layout',
            visualDensity: VisualDensity.compact,
            onPressed: onRelayout,
          ),
        ],
      ),
    );
  }
}
