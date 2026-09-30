import 'app_svg_icon.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class WindowTitleBar extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final List<Widget>? actions;
  final bool showWindowButtons;
  final double height;

  const WindowTitleBar({
    super.key,
    this.leading,
    this.title,
    this.actions,
    this.showWindowButtons = true,
    this.height = 38,
  });

  bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  @override
  Widget build(BuildContext context) {
    final defaultTitle = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'DB Lens',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.neutral9,
          ),
        ),
      ],
    );

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: AppColors.neutral1,
        border: Border(bottom: BorderSide(color: AppColors.neutral2, width: 2)),
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.md),
              child: leading!,
            ),
          ],
          Expanded(
            child: _isDesktop
                ? DragToMoveArea(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onDoubleTap: () async {
                        try {
                          final isMax = await windowManager.isMaximized();
                          if (isMax) {
                            await windowManager.unmaximize();
                          } else {
                            await windowManager.maximize();
                          }
                        } catch (_) {}
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        alignment: Alignment.centerLeft,
                        child:
                            title ??
                            (leading == null
                                ? defaultTitle
                                : const SizedBox.shrink()),
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    alignment: Alignment.centerLeft,
                    child:
                        title ??
                        (leading == null
                            ? defaultTitle
                            : const SizedBox.shrink()),
                  ),
          ),
          ...?actions,
          if (showWindowButtons && _isDesktop) const WindowCaptionButtons(),
        ],
      ),
    );
  }
}

class WindowCaptionButtons extends StatefulWidget {
  const WindowCaptionButtons({super.key});

  @override
  State<WindowCaptionButtons> createState() => _WindowCaptionButtonsState();
}

class _WindowCaptionButtonsState extends State<WindowCaptionButtons>
    with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _checkMaximizedState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  void _checkMaximizedState() async {
    try {
      final isMax = await windowManager.isMaximized();
      if (mounted) {
        setState(() {
          _isMaximized = isMax;
        });
      }
    } catch (_) {}
  }

  @override
  void onWindowMaximize() {
    if (mounted) setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) setState(() => _isMaximized = false);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WindowCaptionButton(
          svgIcon: AppIcons.minus,
          iconSize: 12,
          tooltip: 'Minimize',
          onTap: () async {
            try {
              await windowManager.minimize();
            } catch (_) {}
          },
        ),
        _WindowCaptionButton(
          svgIcon: _isMaximized ? AppIcons.cards : AppIcons.squareBold,
          iconSize: 12,
          tooltip: _isMaximized ? 'Restore' : 'Maximize',
          onTap: () async {
            try {
              if (_isMaximized) {
                await windowManager.unmaximize();
              } else {
                await windowManager.maximize();
              }
            } catch (_) {}
          },
        ),
        _WindowCaptionButton(
          svgIcon: AppIcons.x,
          iconSize: 12,
          tooltip: 'Close',
          isClose: true,
          onTap: () async {
            try {
              await windowManager.close();
            } catch (_) {}
          },
        ),
      ],
    );
  }
}

class _WindowCaptionButton extends StatefulWidget {
  final String svgIcon;
  final double iconSize;
  final String tooltip;
  final VoidCallback onTap;
  final bool isClose;

  const _WindowCaptionButton({
    required this.svgIcon,
    required this.iconSize,
    required this.tooltip,
    required this.onTap,
    this.isClose = false,
  });

  @override
  State<_WindowCaptionButton> createState() => _WindowCaptionButtonState();
}

class _WindowCaptionButtonState extends State<_WindowCaptionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = Colors.transparent;
    Color iconColor = AppColors.neutral10;

    if (_isHovered) {
      if (widget.isClose) {
        backgroundColor = AppColors.error;
        iconColor = AppColors.neutral12;
      } else {
        backgroundColor = AppColors.neutral4;
        iconColor = AppColors.neutral12;
      }
    }

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 44,
            height: double.infinity,
            color: backgroundColor,
            alignment: Alignment.center,
            child: AppSvgIcon(
              widget.svgIcon,
              size: widget.iconSize,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
