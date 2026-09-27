import 'package:flutter/material.dart';
import '../../../data/models/db_foreign_key.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class ForeignKeyBadge extends StatelessWidget {
  final DbForeignKey foreignKey;

  const ForeignKeyBadge({super.key, required this.foreignKey});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: ShapeDecoration(
        color: AppColors.neutral2,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: const BorderSide(color: AppColors.neutral4, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          const AppSvgIcon(AppIcons.key, size: 14, color: AppColors.neutral8),
          const SizedBox(width: AppSpacing.xs),
          Text(
            foreignKey.from,
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.neutral8,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: AppSvgIcon(
              AppIcons.caretRight,
              size: 12,
              color: AppColors.neutral7,
            ),
          ),
          Text(
            '${foreignKey.table}.${foreignKey.to}',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.neutral8,
            ),
          ),
          const Spacer(),
          if (foreignKey.onDelete != 'NO ACTION') ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 1,
              ),
              decoration: ShapeDecoration(
                color: AppColors.neutral4,
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
              ),
              child: Text(
                'ON DELETE ${foreignKey.onDelete}',
                style: AppTypography.tagline.copyWith(
                  fontSize: 10,
                  color: AppColors.neutral8,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          if (foreignKey.onUpdate != 'NO ACTION') ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 1,
              ),
              decoration: ShapeDecoration(
                color: AppColors.neutral4,
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
              ),
              child: Text(
                'ON UPDATE ${foreignKey.onUpdate}',
                style: AppTypography.tagline.copyWith(
                  fontSize: 10,
                  color: AppColors.neutral8,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
