import 'package:flutter/material.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../models/app_tab.dart';

class TabItem extends StatelessWidget {
  final AppTab tab;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const TabItem({
    super.key,
    required this.tab,
    required this.isSelected,
    required this.onTap,
    required this.onClose,
  });

  Widget _buildIcon(Color color) {
    switch (tab.type) {
      case AppTabType.tableData:
        return AppSvgIcon(AppIcons.table, size: 14, color: color);
      case AppTabType.tableSchema:
        return AppSvgIcon(AppIcons.fileSql, size: 14, color: color);
      case AppTabType.customQuery:
        return AppSvgIcon(AppIcons.terminalWindow, size: 14, color: color);
      case AppTabType.schemaGraph:
        return AppSvgIcon(AppIcons.graph, size: 14, color: color);
      case AppTabType.globalSearch:
        return AppSvgIcon(AppIcons.listMagnifyingGlass, size: 14, color: color);
      case AppTabType.diffChecker:
        return AppSvgIcon(AppIcons.treeStructure, size: 14, color: color);
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = isSelected ? AppColors.neutral8 : AppColors.neutral9;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 3.0),
      child: Material(
        color: isSelected
            ? AppColors.neutral7.withValues(alpha: 0.14)
            : Colors.transparent,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(14.0),
          side: isSelected
              ? BorderSide(
                  color: AppColors.neutral7.withValues(alpha: 0.35),
                  width: 1.0,
                )
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: AppColors.neutral3,
          child: Container(
            height: 32,
            constraints: const BoxConstraints(maxWidth: 220, minWidth: 100),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 4.0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildIcon(iconColor),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    tab.title,
                    style: AppTypography.caption.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w500
                          : FontWeight.w400,
                      color: isSelected
                          ? AppColors.neutral10
                          : AppColors.neutral7,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: onClose,
                  child: Padding(
                    padding: AppSpacing.paddingXxxs,
                    child: AppSvgIcon(
                      AppIcons.x,
                      size: 12,
                      color: isSelected
                          ? AppColors.neutral10
                          : AppColors.neutral8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
