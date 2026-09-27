import 'app_svg_icon.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'app_menu.dart';

class AppDropdownItem<T> {
  final T value;
  final String label;
  final IconData? icon;
  final Widget? customIcon;

  const AppDropdownItem({
    required this.value,
    required this.label,
    this.icon,
    this.customIcon,
  });
}

class AppDropdown<T> extends StatefulWidget {
  final T? value;
  final List<AppDropdownItem<T>> items;
  final ValueChanged<T> onChanged;
  final String? label;
  final String? hintText;
  final double? width;
  final double height;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;
  final Color? fillColor;
  final double borderRadius;

  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
    this.hintText,
    this.width,
    this.height = 32.0,
    this.textStyle,
    this.padding,
    this.fillColor,
    this.borderRadius = 14.0,
  });

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  bool _isHovered = false;

  void _openMenu() {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final position = button.localToGlobal(Offset(0, button.size.height + 4));

    showAppMenu<T>(
      context: context,
      position: position,
      minWidth: button.size.width,
      items: widget.items.map((item) {
        return AppMenuItem<T>(
          value: item.value,
          label: item.label,
          icon: item.icon,
          customIcon: item.customIcon,
          onTap: () {
            widget.onChanged(item.value);
          },
        );
      }).toList(),
    ).then((selected) {
      if (selected != null) {
        widget.onChanged(selected);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    AppDropdownItem<T>? selectedItem;
    for (final item in widget.items) {
      if (item.value == widget.value) {
        selectedItem = item;
        break;
      }
    }

    final displayLabel = selectedItem?.label ?? widget.hintText ?? '';

    final defaultTextStyle = widget.textStyle ??
        AppTypography.caption.copyWith(
          color: selectedItem != null
              ? AppColors.neutral12
              : AppColors.neutral8,
          fontWeight: FontWeight.w500,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTypography.caption.copyWith(
              color: AppColors.neutral10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
        ],
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _openMenu,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: widget.width,
              height: widget.height,
              padding: widget.padding ??
                  const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              decoration: ShapeDecoration(
                color: widget.fillColor ?? AppColors.neutral2,
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  side: BorderSide(
                    color: _isHovered ? AppColors.neutral6 : AppColors.neutral4,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selectedItem?.customIcon != null) ...[
                    selectedItem!.customIcon!,
                    const SizedBox(width: AppSpacing.xs),
                  ] else if (selectedItem?.icon != null) ...[
                    Icon(selectedItem!.icon, size: 14, color: AppColors.neutral10),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Flexible(
                    fit: widget.width != null ? FlexFit.tight : FlexFit.loose,
                    child: Text(
                      displayLabel,
                      style: defaultTextStyle.copyWith(
                        color: selectedItem != null
                            ? (defaultTextStyle.color ?? AppColors.neutral12)
                            : AppColors.neutral8,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  AppSvgIcon(
                    AppIcons.caretDown,
                    size: 13,
                    color: _isHovered ? AppColors.neutral12 : AppColors.neutral9,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
