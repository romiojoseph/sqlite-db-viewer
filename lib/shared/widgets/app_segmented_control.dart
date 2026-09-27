import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class AppSegmentedItem<T> {
  final T value;
  final String label;
  final IconData? icon;
  final Widget? customIcon;
  final String? tooltip;

  const AppSegmentedItem({
    required this.value,
    required this.label,
    this.icon,
    this.customIcon,
    this.tooltip,
  });
}

class AppSegmentedControl<T> extends StatelessWidget {
  final T selectedValue;
  final List<AppSegmentedItem<T>> items;
  final ValueChanged<T> onValueChanged;

  const AppSegmentedControl({
    super.key,
    required this.selectedValue,
    required this.items,
    required this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        color: AppColors.neutral1,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.neutral4, width: 1),
        ),
      ),
      padding: AppSpacing.paddingXxxs,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          final isSelected = item.value == selectedValue;
          Widget button = InkWell(
            onTap: () => onValueChanged(item.value),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: ShapeDecoration(
                color: isSelected ? AppColors.neutral3 : Colors.transparent,
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isSelected
                      ? const BorderSide(color: AppColors.neutral5, width: 1)
                      : BorderSide.none,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.customIcon != null) ...[
                    item.customIcon!,
                    const SizedBox(width: AppSpacing.xs),
                  ] else if (item.icon != null) ...[
                    Icon(
                      item.icon,
                      size: 14,
                      color: isSelected
                          ? AppColors.neutral12
                          : AppColors.neutral10,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Text(
                    item.label,
                    style: AppTypography.caption.copyWith(
                      color: isSelected
                          ? AppColors.neutral12
                          : AppColors.neutral10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );

          if (item.tooltip != null && item.tooltip!.isNotEmpty) {
            button = Tooltip(message: item.tooltip!, child: button);
          }

          return button;
        }).toList(),
      ),
    );
  }
}
