import 'package:flutter/material.dart';
import '../../../data/models/db_column.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class ColumnRow extends StatelessWidget {
  final DbColumn column;
  final bool isEven;

  const ColumnRow({super.key, required this.column, required this.isEven});

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
    final rowBg = isEven
        ? AppColors.neutral2
        : AppColors.neutral3.withValues(alpha: 0.5);

    return Container(
      color: rowBg,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          SizedBox(
            child: column.isPrimaryKey
                ? const Tooltip(
                    message: 'Primary Key',
                    child: AppSvgIcon(
                      AppIcons.key,
                      size: 16,
                      color: AppColors.neutral8,
                    ),
                  )
                : Text(
                    '#${column.cid}',
                    style: AppTypography.tagline.copyWith(
                      color: AppColors.neutral7,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 3,
            child: SelectableText(
              column.name,
              style: AppTypography.caption.copyWith(
                fontWeight: column.isPrimaryKey
                    ? FontWeight.w500
                    : FontWeight.w400,
                color: AppColors.neutral8,
              ),
              maxLines: 1,
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(color: typeColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  column.type.isEmpty ? 'NONE' : column.type,
                  style: AppTypography.tagline.copyWith(
                    fontWeight: FontWeight.w600,
                    color: typeColor,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              column.notNull ? 'NOT NULL' : 'NULL',
              style: AppTypography.tagline.copyWith(
                color: column.notNull ? AppColors.neutral8 : AppColors.neutral7,
                fontWeight: column.notNull
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              column.defaultValue != null
                  ? column.defaultValue.toString()
                  : '-',
              style: AppTypography.tagline.copyWith(
                color: AppColors.neutral7,
                fontStyle: column.defaultValue == null
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
