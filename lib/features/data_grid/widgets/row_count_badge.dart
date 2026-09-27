import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class RowCountBadge extends StatelessWidget {
  final int count;
  final Duration? duration;

  const RowCountBadge({super.key, required this.count, this.duration});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final formattedCount = formatter.format(count);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppSvgIcon(
          AppIcons.tableFill,
          size: 18,
          color: AppColors.neutral8,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '$formattedCount rows',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.neutral9,
          ),
        ),
        if (duration != null && duration! > Duration.zero) ...[
          const SizedBox(width: AppSpacing.xs),
          Text(
            '(${duration!.inMilliseconds} ms)',
            style: AppTypography.tagline.copyWith(color: AppColors.neutral9),
          ),
        ],
      ],
    );
  }
}
