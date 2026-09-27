import '../../../shared/widgets/app_svg_icon.dart';
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../models/table_diff_result.dart';

class DiffTableSummaryRow extends StatelessWidget {
  final TableDiffResult tableDiff;
  final VoidCallback onTap;

  const DiffTableSummaryRow({
    super.key,
    required this.tableDiff,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: ShapeDecoration(
        color: AppColors.neutral2,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: BorderSide(
            color: tableDiff.isIdentical
                ? AppColors.neutral3
                : AppColors.neutral4,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8.0),
          onTap: onTap,
          child: Padding(
            padding: AppSpacing.paddingSm,
            child: Row(
              children: [
                Text(
                  tableDiff.tableName,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.neutral8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (tableDiff.statusMessage != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    tableDiff.statusMessage!,
                    style: AppTypography.label.copyWith(
                      color: AppColors.neutral7,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(width: AppSpacing.sm),
                _buildBadges(),
                const Spacer(),
                Text(
                  '${tableDiff.totalRowsA} rows (A) → ${tableDiff.totalRowsB} rows (B)',
                  style: AppTypography.label.copyWith(
                    color: AppColors.neutral8,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                const AppSvgIcon(
                  AppIcons.caretRight,
                  size: 14,
                  color: AppColors.neutral6,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadges() {
    switch (tableDiff.status) {
      case TableDiffStatus.identical:
      case TableDiffStatus.emptyInBoth:
        return _badge('IDENTICAL', AppColors.success, AppIcons.plusCircle);
      case TableDiffStatus.hashOnlyIdentical:
        return _badge(
          'COUNT & HASH MATCH',
          AppColors.success,
          AppIcons.plusCircle,
        );
      case TableDiffStatus.hashOnlyChanged:
        return _badge(
          'COUNT OR HASH MISMATCH',
          AppColors.warning,
          AppIcons.info,
        );
      case TableDiffStatus.schemaChanged:
        return _badge(
          'SCHEMA CHANGED (${tableDiff.schemaDiff.totalDifferences})',
          AppColors.warning,
          AppIcons.treeStructure,
        );
      case TableDiffStatus.onlyInA:
        return _badge('ONLY IN A', AppColors.error, AppIcons.minus);
      case TableDiffStatus.onlyInB:
        return _badge('ONLY IN B', AppColors.success, AppIcons.plus);
      case TableDiffStatus.notCompared:
        return _badge(
          'NOT COMPARED (EXCEEDS CAP)',
          AppColors.neutral9,
          AppIcons.info,
        );
      case TableDiffStatus.error:
        return _badge('ERROR', AppColors.error, AppIcons.info);
      case TableDiffStatus.dataChanged:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tableDiff.addedRowCount > 0) ...[
              _badge(
                '+${tableDiff.addedRowCount} Added',
                AppColors.success,
                AppIcons.plus,
              ),
              const SizedBox(width: AppSpacing.xxs),
            ],
            if (tableDiff.removedRowCount > 0) ...[
              _badge(
                '-${tableDiff.removedRowCount} Removed',
                AppColors.error,
                AppIcons.minus,
              ),
              const SizedBox(width: AppSpacing.xxs),
            ],
            if (tableDiff.modifiedRowCount > 0) ...[
              _badge(
                '~${tableDiff.modifiedRowCount} Modified',
                AppColors.warning,
                AppIcons.pencil,
              ),
            ],
          ],
        );
    }
  }

  Widget _badge(String label, Color color, String svgIcon) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.xxs),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSvgIcon(svgIcon, size: 10, color: color),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: AppTypography.tagline.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
