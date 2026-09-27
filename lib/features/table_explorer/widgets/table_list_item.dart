import '../../../shared/widgets/app_svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/db_table.dart';
import '../../../theme/app_theme.dart';

class TableListItem extends StatelessWidget {
  final DbTable table;
  final bool isSelected;
  final VoidCallback onTap;

  const TableListItem({
    super.key,
    required this.table,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rowCountStr = table.rowCount != null
        ? NumberFormat.compact().format(table.rowCount)
        : null;

    final selectedBg = AppColors.neutral7.withValues(alpha: 0.15);
    final selectedBorder = AppColors.neutral7.withValues(alpha: 0.4);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 1.5,
      ),
      child: Material(
        color: isSelected ? selectedBg : Colors.transparent,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: isSelected
              ? BorderSide(color: selectedBorder, width: 1.0)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: isSelected ? null : AppColors.neutral3,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                AppSvgIcon(
                  table.isView ? AppIcons.layout : AppIcons.table,
                  size: 15,
                  color: isSelected ? AppColors.neutral12 : AppColors.neutral9,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    table.name,
                    style: AppTypography.caption.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w500
                          : FontWeight.w400,
                      color: isSelected
                          ? AppColors.neutral9
                          : AppColors.neutral7,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (rowCountStr != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xxxs,
                    ),
                    decoration: ShapeDecoration(
                      color: AppColors.neutral4,
                      shape: ContinuousRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                    child: Text(
                      rowCountStr,
                      style: AppTypography.tagline.copyWith(
                        color: AppColors.neutral9,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
