import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

enum AppInputSize { small, medium, large }

class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? customPrefixIcon;
  final VoidCallback? onPrefixTap;
  final Widget? suffixIcon;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final AppInputSize size;
  final FocusNode? focusNode;
  final int? maxLines;
  final int? minLines;
  final TextStyle? style;
  final TextStyle? hintStyle;

  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.errorText,
    this.prefixIcon,
    this.customPrefixIcon,
    this.onPrefixTap,
    this.suffixIcon,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.obscureText = false,
    this.onChanged,
    this.onSubmitted,
    this.size = AppInputSize.medium,
    this.focusNode,
    this.maxLines = 1,
    this.minLines,
    this.style,
    this.hintStyle,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _effectiveFocusNode;
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _effectiveFocusNode = widget.focusNode ?? FocusNode();
    _effectiveFocusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _effectiveFocusNode.dispose();
    } else {
      _effectiveFocusNode.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {
        _isFocused = _effectiveFocusNode.hasFocus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError =
        widget.errorText != null && widget.errorText!.isNotEmpty;

    final bool hasPrefix =
        widget.customPrefixIcon != null || widget.prefixIcon != null;
    final bool hasSuffix = widget.suffixIcon != null;

    final double minHeight;
    final double horizontalPadding;
    final TextStyle baseTextStyle;
    final TextStyle baseHintStyle;
    final double iconSize;

    switch (widget.size) {
      case AppInputSize.small:
        minHeight = 32.0;
        horizontalPadding = AppSpacing.sm;
        baseTextStyle = AppTypography.caption;
        baseHintStyle = AppTypography.caption.copyWith(
          color: AppColors.neutral8,
        );
        iconSize = 16.0;
        break;
      case AppInputSize.medium:
        minHeight = 40.0;
        horizontalPadding = AppSpacing.md;
        baseTextStyle = AppTypography.body;
        baseHintStyle = AppTypography.body.copyWith(
          color: AppColors.neutral8,
        );
        iconSize = 18.0;
        break;
      case AppInputSize.large:
        minHeight = 48.0;
        horizontalPadding = AppSpacing.lg;
        baseTextStyle = AppTypography.subtitle;
        baseHintStyle = AppTypography.subtitle.copyWith(
          color: AppColors.neutral8,
        );
        iconSize = 20.0;
        break;
    }

    final isMultiline = (widget.maxLines == null || widget.maxLines! > 1);

    final TextStyle textStyle = widget.style ?? baseTextStyle;
    final TextStyle hintStyle = widget.hintStyle ?? baseHintStyle;

    final EdgeInsets contentPadding = EdgeInsets.only(
      left: hasPrefix ? AppSpacing.xs : horizontalPadding,
      right: hasSuffix ? AppSpacing.xs : horizontalPadding,
      top: isMultiline ? AppSpacing.sm : 0,
      bottom: isMultiline ? AppSpacing.sm : 0,
    );

    Color fillColor = AppColors.neutral1;
    BorderSide borderSide = const BorderSide(
      color: AppColors.neutral3,
      width: 1,
    );
    Color iconColor = AppColors.neutral8;
    Color textColor = AppColors.neutral11;

    if (!widget.enabled) {
      fillColor = AppColors.neutral2;
      borderSide = const BorderSide(color: AppColors.neutral3, width: 1);
      iconColor = AppColors.neutral7;
      textColor = AppColors.neutral7;
    } else if (hasError) {
      fillColor = AppColors.errorBackground.withValues(alpha: 0.12);
      borderSide = const BorderSide(color: AppColors.error, width: 1.2);
      iconColor = AppColors.error;
      textColor = AppColors.neutral12;
    } else if (_isFocused) {
      borderSide = const BorderSide(color: AppColors.neutral6, width: 1);
      iconColor = AppColors.neutral12;
      textColor = AppColors.neutral12;
    } else if (_isHovered) {
      borderSide = const BorderSide(color: AppColors.neutral5, width: 1);
      iconColor = AppColors.neutral11;
      textColor = AppColors.neutral12;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: BoxConstraints(minHeight: minHeight),
            decoration: ShapeDecoration(
              color: fillColor,
              shape: ContinuousRectangleBorder(
                borderRadius: BorderRadius.circular(
                  widget.size == AppInputSize.small
                      ? 16
                      : widget.size == AppInputSize.medium
                      ? 20
                      : 24,
                ),
                side: borderSide,
              ),
            ),
            child: Row(
              crossAxisAlignment: isMultiline
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                if (hasPrefix) ...[
                  Padding(
                    padding: EdgeInsets.only(
                      left: AppSpacing.sm,
                      top: isMultiline ? AppSpacing.xs : 0,
                    ),
                    child: widget.onPrefixTap != null
                        ? IconButton(
                            icon:
                                widget.customPrefixIcon ??
                                Icon(
                                  widget.prefixIcon,
                                  size: iconSize,
                                  color: iconColor,
                                ),
                            color: iconColor,
                            onPressed: widget.enabled
                                ? widget.onPrefixTap
                                : null,
                            splashRadius: 16,
                            visualDensity: VisualDensity.compact,
                          )
                        : (widget.customPrefixIcon ??
                              Icon(
                                widget.prefixIcon,
                                size: iconSize,
                                color: iconColor,
                              )),
                  ),
                ],
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _effectiveFocusNode,
                    enabled: widget.enabled,
                    readOnly: widget.readOnly,
                    autofocus: widget.autofocus,
                    obscureText: widget.obscureText,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    maxLines: widget.maxLines,
                    minLines: widget.minLines,
                    style: textStyle.copyWith(color: textColor),
                    cursorColor: AppColors.neutral8,
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: hintStyle,
                      contentPadding: contentPadding,
                      filled: false,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (widget.suffixIcon != null) ...[
                  Padding(
                    padding: EdgeInsets.only(
                      right: AppSpacing.sm,
                      top: isMultiline ? AppSpacing.xs : 0,
                    ),
                    child: widget.suffixIcon!,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            widget.errorText!,
            style: AppTypography.caption.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}
