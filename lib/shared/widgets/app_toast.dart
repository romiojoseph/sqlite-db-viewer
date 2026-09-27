import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'app_svg_icon.dart';

enum AppToastType { success, error, info, warning }

class AppToast {
  AppToast._();

  static OverlayEntry? _currentEntry;
  static _AppToastWidgetState? _currentState;

  static void show(
    BuildContext context, {
    required String message,
    AppToastType type = AppToastType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (_currentState != null &&
        _currentEntry != null &&
        _currentState!.mounted) {
      _currentState!.update(message: message, type: type, duration: duration);
      return;
    }

    _currentEntry?.remove();
    _currentEntry = null;
    _currentState = null;

    final overlayState = Overlay.maybeOf(context, rootOverlay: true);
    if (overlayState == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return _AppToastWidget(
          message: message,
          type: type,
          duration: duration,
          onDismiss: () {
            if (_currentEntry == entry) {
              entry.remove();
              _currentEntry = null;
              _currentState = null;
            }
          },
          onStateCreated: (state) {
            _currentState = state;
          },
        );
      },
    );

    _currentEntry = entry;
    overlayState.insert(entry);
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      type: AppToastType.success,
      duration: duration,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 5),
  }) {
    show(
      context,
      message: message,
      type: AppToastType.error,
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      type: AppToastType.info,
      duration: duration,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      context,
      message: message,
      type: AppToastType.warning,
      duration: duration,
    );
  }
}

class _AppToastWidget extends StatefulWidget {
  final String message;
  final AppToastType type;
  final Duration duration;
  final VoidCallback onDismiss;
  final ValueChanged<_AppToastWidgetState> onStateCreated;

  const _AppToastWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
    required this.onStateCreated,
  });

  @override
  State<_AppToastWidget> createState() => _AppToastWidgetState();
}

class _AppToastWidgetState extends State<_AppToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _dismissTimer;

  late String _message;
  late AppToastType _type;
  late Duration _duration;

  @override
  void initState() {
    super.initState();
    _message = widget.message;
    _type = widget.type;
    _duration = widget.duration;
    widget.onStateCreated(this);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
    );

    _scaleAnimation = Tween<double>(begin: 0.84, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );

    _controller.forward();
    _startTimer();
  }

  void _startTimer() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(_duration, _dismiss);
  }

  void update({
    required String message,
    required AppToastType type,
    required Duration duration,
  }) {
    setState(() {
      _message = message;
      _type = type;
      _duration = duration;
    });
    _controller.forward(from: 0.7);
    _startTimer();
  }

  void _dismiss() {
    if (!mounted) return;
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Color get _accentColor {
    switch (_type) {
      case AppToastType.success:
        return AppColors.success;
      case AppToastType.error:
        return AppColors.error;
      case AppToastType.warning:
        return AppColors.warning;
      case AppToastType.info:
        return AppColors.info;
    }
  }

  String get _svgIcon {
    switch (_type) {
      case AppToastType.success:
        return AppIcons.plusCircle;
      case AppToastType.error:
      case AppToastType.warning:
      case AppToastType.info:
        return AppIcons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor;

    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Center(
        child: Material(
          type: MaterialType.transparency,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: ShapeDecoration(
                color: AppColors.neutral2,
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: accent.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                shadows: [
                  BoxShadow(
                    color: AppColors.neutral0.withValues(alpha: 0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: accent.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: AppSvgIcon(_svgIcon, size: 16, color: accent),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      _message,
                      style: AppTypography.body.copyWith(
                        color: AppColors.neutral12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  InkWell(
                    onTap: _dismiss,
                    borderRadius: BorderRadius.circular(100),
                    child: const Padding(
                      padding: EdgeInsets.all(AppSpacing.xxs),
                      child: AppSvgIcon(
                        AppIcons.x,
                        size: 14,
                        color: AppColors.neutral9,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
