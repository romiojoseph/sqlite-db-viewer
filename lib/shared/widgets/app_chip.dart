import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'app_svg_icon.dart';

class AppChip extends StatefulWidget {
  final String label;
  final String? subtitle;
  final String? svgIcon;
  final bool isSelected;
  final bool isEnabled;
  final ValueChanged<bool>? onSelected;
  final VoidCallback? onDeleted;
  final bool showCheckmark;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  const AppChip({
    super.key,
    required this.label,
    this.subtitle,
    this.svgIcon,
    this.isSelected = false,
    this.isEnabled = true,
    this.onSelected,
    this.onDeleted,
    this.showCheckmark = false,
    this.color,
    this.padding,
  });

  @override
  State<AppChip> createState() => _AppChipState();
}

class _AppChipState extends State<AppChip> {
  bool _isHovered = false;
  Color? _previousBackground;
  Color? _previousBorder;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final isEnabled = widget.isEnabled;
    final isInteractive = isEnabled && (widget.onSelected != null);
    final accent = widget.color;

    Color bgColor;
    Color borderColor;
    Color textColor;
    Color iconColor;

    if (!isEnabled) {
      bgColor = AppColors.neutral2;
      borderColor = AppColors.neutral3;
      textColor = AppColors.neutral6;
      iconColor = AppColors.neutral6;
    } else if (accent != null) {
      if (isSelected) {
        bgColor = accent.withValues(alpha: _isHovered ? 0.25 : 0.15);
        borderColor = accent.withValues(alpha: _isHovered ? 0.8 : 0.5);
        textColor = accent;
        iconColor = accent;
      } else if (_isHovered) {
        bgColor = accent.withValues(alpha: 0.1);
        borderColor = accent.withValues(alpha: 0.4);
        textColor = accent;
        iconColor = accent;
      } else {
        bgColor = AppColors.neutral2;
        borderColor = AppColors.neutral4;
        textColor = accent.withValues(alpha: 0.85);
        iconColor = accent.withValues(alpha: 0.7);
      }
    } else {
      if (isSelected) {
        bgColor = _isHovered ? AppColors.neutral4 : AppColors.neutral3;
        borderColor = _isHovered ? AppColors.neutral5 : AppColors.neutral6;
        textColor = AppColors.neutral8;
        iconColor = AppColors.neutral8;
      } else if (_isHovered) {
        bgColor = AppColors.neutral3;
        borderColor = AppColors.neutral4;
        textColor = AppColors.neutral10;
        iconColor = AppColors.neutral10;
      } else {
        bgColor = AppColors.neutral0;
        borderColor = AppColors.neutral3;
        textColor = AppColors.neutral8;
        iconColor = AppColors.neutral8;
      }
    }

    return MouseRegion(
      onEnter: (_) {
        if (isInteractive) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (isInteractive) setState(() => _isHovered = false);
      },
      cursor: isInteractive
          ? SystemMouseCursors.click
          : (isEnabled
                ? SystemMouseCursors.basic
                : SystemMouseCursors.forbidden),
      child: TweenAnimationBuilder<Color?>(
        duration: const Duration(milliseconds: 150),
        tween: ColorTween(begin: _previousBackground ?? bgColor, end: bgColor),
        onEnd: () => setState(() => _previousBackground = bgColor),
        builder: (context, animatedBackground, child) {
          return TweenAnimationBuilder<Color?>(
            duration: const Duration(milliseconds: 150),
            tween: ColorTween(
              begin: _previousBorder ?? borderColor,
              end: borderColor,
            ),
            onEnd: () => setState(() => _previousBorder = borderColor),
            builder: (context, animatedBorder, child) {
              return Material(
                color: animatedBackground ?? bgColor,
                shape: ContinuousRectangleBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  side: BorderSide(
                    color: animatedBorder ?? borderColor,
                    width: 1.0,
                  ),
                ),
                clipBehavior: Clip.none,
                child: InkWell(
                  customBorder: const ContinuousRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  onTap: isInteractive
                      ? () => widget.onSelected!(!isSelected)
                      : null,
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: Padding(
                    padding:
                        widget.padding ??
                        const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm + 2,
                          vertical: AppSpacing.xxs + 2,
                        ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected && widget.showCheckmark) ...[
                          AppSvgIcon(
                            AppIcons.cards,
                            size: 14,
                            color: iconColor,
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                        ] else if (widget.svgIcon != null) ...[
                          AppSvgIcon(
                            widget.svgIcon!,
                            size: 12,
                            color: iconColor,
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                        ],
                        Text(
                          widget.label,
                          style: AppTypography.caption.copyWith(
                            color: textColor,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(width: AppSpacing.xxs),
                          Text(
                            widget.subtitle!,
                            style: AppTypography.caption.copyWith(
                              color: isSelected
                                  ? (accent ?? AppColors.neutral10)
                                  : (accent?.withValues(alpha: 0.9) ??
                                        AppColors.neutral8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (widget.onDeleted != null && isEnabled) ...[
                          const SizedBox(width: AppSpacing.xxs),
                          GestureDetector(
                            onTap: widget.onDeleted,
                            child: AppSvgIcon(
                              AppIcons.x,
                              size: 10,
                              color: _isHovered
                                  ? AppColors.neutral11
                                  : AppColors.neutral8,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
