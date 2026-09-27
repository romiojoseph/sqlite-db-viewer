import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'app_svg_icon.dart';

class DialogCloseButton extends StatefulWidget {
  final VoidCallback onTap;

  const DialogCloseButton({super.key, required this.onTap});

  @override
  State<DialogCloseButton> createState() => _DialogCloseButtonState();
}

class _DialogCloseButtonState extends State<DialogCloseButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          child: AppSvgIcon(
            AppIcons.x,
            size: 20,
            color: _isHovered ? AppColors.neutral9 : AppColors.neutral6,
          ),
        ),
      ),
    );
  }
}
