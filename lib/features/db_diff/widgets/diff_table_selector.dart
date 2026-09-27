import 'package:flutter/material.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_chip.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../models/schema_diff_result.dart';

class DiffTableSelector extends StatelessWidget {
  final Map<String, SchemaDiffResult> schemaDiffs;
  final Set<String> selectedTables;
  final ValueChanged<Set<String>> onSelectionChanged;
  final VoidCallback? onRefresh;

  const DiffTableSelector({
    super.key,
    required this.schemaDiffs,
    required this.selectedTables,
    required this.onSelectionChanged,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final tableNames = schemaDiffs.keys.toList()..sort();
    final isAllSelected = selectedTables.length == tableNames.length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: ShapeDecoration(
        color: AppColors.neutral2,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
          side: const BorderSide(color: AppColors.neutral3, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Tables to Compare (${selectedTables.length}/${tableNames.length} selected)',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral8,
                ),
              ),
              const Spacer(),
              if (onRefresh != null) ...[
                Tooltip(
                  message: 'Re-compare / Refresh Diff',
                  child: IconButton(
                    icon: const AppSvgIcon(AppIcons.arrowClockwise, size: 14),
                    visualDensity: VisualDensity.compact,
                    color: AppColors.neutral10,
                    onPressed: onRefresh,
                  ),
                ),
                const SizedBox(width: AppSpacing.xxs),
              ],
              AppButton(
                label: isAllSelected ? 'Deselect All' : 'Select All',
                variant: AppButtonVariant.text,
                size: AppButtonSize.small,
                onPressed: () {
                  if (isAllSelected) {
                    onSelectionChanged(<String>{});
                  } else {
                    onSelectionChanged(tableNames.toSet());
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: tableNames.map((name) {
              final isSelected = selectedTables.contains(name);
              final diff = schemaDiffs[name];

              Color badgeColor = AppColors.neutral8;
              String? tag;
              if (diff != null) {
                if (diff.onlyInA) {
                  tag = 'Only in A';
                  badgeColor = AppColors.error;
                } else if (diff.onlyInB) {
                  tag = 'Only in B';
                  badgeColor = AppColors.success;
                }
              }

              return AppChip(
                label: name,
                subtitle: tag,
                color: tag != null ? badgeColor : null,
                isSelected: isSelected,
                onSelected: (val) {
                  final newSet = Set<String>.from(selectedTables);
                  if (val) {
                    newSet.add(name);
                  } else {
                    newSet.remove(name);
                  }
                  onSelectionChanged(newSet);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
