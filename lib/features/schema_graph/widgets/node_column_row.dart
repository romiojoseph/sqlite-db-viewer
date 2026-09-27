import '../../../shared/widgets/app_svg_icon.dart';
import 'package:flutter/material.dart';
import '../../../data/models/db_column.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class NodeColumnRow extends StatelessWidget {
  final DbColumn column;
  final bool isPrimaryKey;
  final bool isForeignKey;

  const NodeColumnRow({
    super.key,
    required this.column,
    required this.isPrimaryKey,
    required this.isForeignKey,
  });

  Color _getTypeColor(String type) {
    final t = type.toUpperCase();
    if (t.contains('INT')) return AppColors.typeInteger;
    if (t.contains('TEXT') || t.contains('CHAR') || t.contains('CLOB')) {
      return AppColors.typeText;
    }
    if (t.contains('BLOB')) return AppColors.typeBlob;
    if (t.contains('REAL') || t.contains('FLOA') || t.contains('DOUB')) {
      return AppColors.typeReal;
    }
    return AppColors.neutral9;
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _getTypeColor(column.type);

    Color nameColor = AppColors.neutral8;
    FontWeight nameWeight = FontWeight.normal;

    if (isPrimaryKey) {
      nameColor = AppColors.secondary6;
      nameWeight = FontWeight.w600;
    } else if (isForeignKey) {
      nameColor = AppColors.primary5;
      nameWeight = FontWeight.w600;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3.0,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.neutral4, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          if (isPrimaryKey && isForeignKey) ...[
            const AppSvgIcon(
              AppIcons.key,
              size: 14,
              color: AppColors.secondary6,
            ),
            const SizedBox(width: AppSpacing.xs),
            const AppSvgIcon(
              AppIcons.splitHorizontal,
              size: 14,
              color: AppColors.primary5,
            ),
          ] else if (isPrimaryKey) ...[
            const AppSvgIcon(
              AppIcons.key,
              size: 13,
              color: AppColors.secondary6,
            ),
          ] else if (isForeignKey) ...[
            const AppSvgIcon(
              AppIcons.splitHorizontal,
              size: 12,
              color: AppColors.primary5,
            ),
          ] else ...[
            SizedBox(
              width: 13,
              height: 13,
              child: Center(
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.neutral6,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              column.name,
              style: AppTypography.label.copyWith(
                color: nameColor,
                fontWeight: nameWeight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            column.type.isEmpty ? 'NONE' : column.type,
            style: AppTypography.tagline.copyWith(
              color: typeColor,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
