import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, text, danger }

enum AppButtonSize { small, medium, large }

class AppButton extends StatefulWidget {
  final String? label;
  final IconData? icon;
  final Widget? customIcon;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool fullWidth;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? hoverBackgroundColor;
  final Color? hoverForegroundColor;
  final Color? disabledBackgroundColor;
  final Color? disabledForegroundColor;
  final String? tooltip;

  const AppButton({
    super.key,
    this.label,
    this.icon,
    this.customIcon,
    required this.onPressed,
    this.variant = AppButtonVariant.secondary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.fullWidth = false,
    this.backgroundColor,
    this.foregroundColor,
    this.hoverBackgroundColor,
    this.hoverForegroundColor,
    this.disabledBackgroundColor,
    this.disabledForegroundColor,
    this.tooltip,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  Color? _previousBackground;
  Color? _previousBorder;
  Color? _previousForeground;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null || widget.isLoading;

    final double height;
    final EdgeInsets padding;
    final TextStyle textStyle;
    final double iconSize;

    final FontWeight fontWeight = widget.variant == AppButtonVariant.text
        ? FontWeight.w500
        : FontWeight.w600;

    switch (widget.size) {
      case AppButtonSize.small:
        height = 32.0;
        padding = const EdgeInsets.symmetric(horizontal: AppSpacing.sm);
        textStyle = AppTypography.caption.copyWith(fontWeight: fontWeight);
        iconSize = 16.0;
        break;
      case AppButtonSize.medium:
        height = 40.0;
        padding = const EdgeInsets.symmetric(horizontal: AppSpacing.md);
        textStyle = AppTypography.body.copyWith(fontWeight: fontWeight);
        iconSize = 18.0;
        break;
      case AppButtonSize.large:
        height = 48.0;
        padding = const EdgeInsets.symmetric(horizontal: AppSpacing.lg);
        textStyle = AppTypography.subtitle.copyWith(fontWeight: fontWeight);
        iconSize = 20.0;
        break;
    }

    Color backgroundColor;
    Color foregroundColor;
    BorderSide borderSide = BorderSide.none;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        if (isDisabled) {
          backgroundColor = AppColors.neutral4;
          foregroundColor = AppColors.neutral8;
        } else if (_isHovered) {
          backgroundColor = AppColors.primary10;
          foregroundColor = AppColors.neutral12;
        } else {
          backgroundColor = AppColors.primary9;
          foregroundColor = AppColors.neutral12;
        }
        break;

      case AppButtonVariant.secondary:
        if (isDisabled) {
          backgroundColor = AppColors.neutral2;
          foregroundColor = AppColors.neutral8;
          borderSide = const BorderSide(color: AppColors.neutral3, width: 1);
        } else if (_isHovered) {
          backgroundColor = AppColors.neutral4;
          foregroundColor = AppColors.neutral12;
          borderSide = const BorderSide(color: AppColors.neutral6, width: 1);
        } else {
          backgroundColor = AppColors.neutral3;
          foregroundColor = AppColors.neutral11;
          borderSide = const BorderSide(color: AppColors.neutral5, width: 1);
        }
        break;

      case AppButtonVariant.outline:
        backgroundColor = _isHovered && !isDisabled
            ? AppColors.neutral3
            : Colors.transparent;
        if (isDisabled) {
          foregroundColor = AppColors.neutral6;
          borderSide = const BorderSide(color: AppColors.neutral3, width: 1);
        } else if (_isHovered) {
          foregroundColor = AppColors.neutral11;
          borderSide = const BorderSide(color: AppColors.neutral6, width: 1);
        } else {
          foregroundColor = AppColors.neutral8;
          borderSide = const BorderSide(color: AppColors.neutral5, width: 1);
        }
        break;

      case AppButtonVariant.ghost:
        if (isDisabled) {
          backgroundColor = Colors.transparent;
          foregroundColor = AppColors.neutral6;
        } else if (_isHovered) {
          backgroundColor = AppColors.neutral3;
          foregroundColor = AppColors.neutral11;
        } else {
          backgroundColor = Colors.transparent;
          foregroundColor = AppColors.neutral8;
        }
        break;

      case AppButtonVariant.text:
        backgroundColor = Colors.transparent;
        if (isDisabled) {
          foregroundColor = AppColors.neutral6;
        } else if (_isHovered) {
          foregroundColor = AppColors.primary4;
        } else {
          foregroundColor = AppColors.neutral8;
        }
        break;

      case AppButtonVariant.danger:
        if (isDisabled) {
          backgroundColor = AppColors.neutral3;
          foregroundColor = AppColors.neutral8;
        } else if (_isHovered) {
          backgroundColor = AppColors.error;
          foregroundColor = AppColors.neutral12;
        } else {
          backgroundColor = AppColors.errorBackground;
          foregroundColor = AppColors.error;
          borderSide = BorderSide(
            color: AppColors.error.withValues(alpha: 0.4),
            width: 1,
          );
        }
        break;
    }

    if (widget.backgroundColor != null) {
      backgroundColor = widget.backgroundColor!;
    }
    if (widget.foregroundColor != null) {
      foregroundColor = widget.foregroundColor!;
    }
    if (isDisabled && widget.disabledBackgroundColor != null) {
      backgroundColor = widget.disabledBackgroundColor!;
    }
    if (isDisabled && widget.disabledForegroundColor != null) {
      foregroundColor = widget.disabledForegroundColor!;
    }
    if (_isHovered && !isDisabled && widget.hoverBackgroundColor != null) {
      backgroundColor = widget.hoverBackgroundColor!;
    }
    if (_isHovered && !isDisabled && widget.hoverForegroundColor != null) {
      foregroundColor = widget.hoverForegroundColor!;
    }

    final BorderRadius borderRadius;
    switch (widget.size) {
      case AppButtonSize.small:
        borderRadius = const BorderRadius.all(Radius.circular(16));
        break;
      case AppButtonSize.medium:
        borderRadius = const BorderRadius.all(Radius.circular(20));
        break;
      case AppButtonSize.large:
        borderRadius = const BorderRadius.all(Radius.circular(24));
        break;
    }

    final Color borderColor = (_isFocused && !isDisabled)
        ? AppColors.primary4
        : borderSide.color;
    final double borderWidth = (_isFocused && !isDisabled)
        ? 1.5
        : borderSide.width;

    Widget buttonWidget = FocusableActionDetector(
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: height,
        constraints: BoxConstraints(
          minWidth: widget.label == null ? height : 0,
        ),
        child: TweenAnimationBuilder<Color?>(
          duration: const Duration(milliseconds: 150),
          tween: ColorTween(begin: _previousBackground, end: backgroundColor),
          onEnd: () => setState(() => _previousBackground = backgroundColor),
          builder: (context, animatedBackground, child) {
            return TweenAnimationBuilder<Color?>(
              duration: const Duration(milliseconds: 150),
              tween: ColorTween(begin: _previousBorder, end: borderColor),
              onEnd: () => setState(() => _previousBorder = borderColor),
              builder: (context, animatedBorder, child) {
                return Material(
                  color: animatedBackground ?? backgroundColor,
                  shape: ContinuousRectangleBorder(
                    borderRadius: borderRadius,
                    side: borderWidth > 0
                        ? BorderSide(
                            color: animatedBorder ?? borderColor,
                            width: borderWidth,
                          )
                        : BorderSide.none,
                  ),
                  clipBehavior: Clip.none,
                  child: InkWell(
                    customBorder: ContinuousRectangleBorder(
                      borderRadius: borderRadius,
                    ),
                    onTap: isDisabled ? null : widget.onPressed,
                    mouseCursor: isDisabled
                        ? SystemMouseCursors.forbidden
                        : SystemMouseCursors.click,
                    hoverColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    splashColor: AppColors.neutral12.withValues(alpha: 0.08),
                    highlightColor: AppColors.neutral12.withValues(alpha: 0.04),
                    child: Padding(
                      padding: widget.label == null ? EdgeInsets.zero : padding,
                      child: Center(
                        widthFactor: widget.fullWidth ? double.infinity : 1.0,
                        child: TweenAnimationBuilder<Color?>(
                          duration: const Duration(milliseconds: 150),
                          tween: ColorTween(
                            begin: _previousForeground,
                            end: foregroundColor,
                          ),
                          onEnd: () => setState(
                            () => _previousForeground = foregroundColor,
                          ),
                          builder: (context, animatedColor, child) {
                            final color = animatedColor ?? foregroundColor;
                            return _buildContent(iconSize, textStyle, color);
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      buttonWidget = Tooltip(message: widget.tooltip!, child: buttonWidget);
    }

    return buttonWidget;
  }

  Widget _buildContent(double iconSize, TextStyle textStyle, Color color) {
    final iconWidget = widget.isLoading
        ? SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          )
        : widget.customIcon ??
              (widget.icon != null
                  ? Icon(widget.icon!, size: iconSize, color: color)
                  : null);

    if (iconWidget != null && widget.label != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconWidget,
          const SizedBox(width: AppSpacing.xxs + 2),
          Text(widget.label!, style: textStyle.copyWith(color: color)),
        ],
      );
    } else if (iconWidget != null) {
      return iconWidget;
    } else {
      return Text(widget.label ?? '', style: textStyle.copyWith(color: color));
    }
  }
}
