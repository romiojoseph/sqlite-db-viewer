import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'app_svg_icon.dart';

class AppCheckbox extends StatefulWidget {
  final bool? value;
  final ValueChanged<bool?>? onChanged;
  final bool tristate;
  final double size;

  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.tristate = false,
    this.size = 16.0,
  });

  @override
  State<AppCheckbox> createState() => _AppCheckboxState();
}

class _AppCheckboxState extends State<AppCheckbox> {
  bool _isHovered = false;

  void _handleTap() {
    if (widget.onChanged == null) return;
    if (widget.tristate) {
      if (widget.value == null) {
        widget.onChanged!(true);
      } else if (widget.value == true) {
        widget.onChanged!(false);
      } else {
        widget.onChanged!(null);
      }
    } else {
      widget.onChanged!(!(widget.value ?? false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isChecked = widget.value == true;
    final isIndeterminate = widget.value == null && widget.tristate;
    final isActive = isChecked || isIndeterminate;
    final isEnabled = widget.onChanged != null;

    final Color bgColor;
    final Color borderColor;

    if (!isEnabled) {
      bgColor = AppColors.neutral2;
      borderColor = AppColors.neutral4;
    } else if (isActive) {
      bgColor = _isHovered ? AppColors.primary10 : AppColors.primary9;
      borderColor = _isHovered ? AppColors.primary8 : AppColors.primary9;
    } else {
      bgColor = _isHovered ? AppColors.neutral3 : AppColors.neutral2;
      borderColor = _isHovered ? AppColors.neutral6 : AppColors.neutral4;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTap: isEnabled ? _handleTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: widget.size,
          height: widget.size,
          decoration: ShapeDecoration(
            color: bgColor,
            shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.circular(6.0),
              side: BorderSide(
                color: borderColor,
                width: 1.0,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: isChecked
              ? const AppSvgIcon(
                  AppIcons.check,
                  size: 10,
                  color: AppColors.neutral12,
                )
              : isIndeterminate
                  ? const AppSvgIcon(
                      AppIcons.minus,
                      size: 10,
                      color: AppColors.neutral12,
                    )
                  : null,
        ),
      ),
    );
  }
}
