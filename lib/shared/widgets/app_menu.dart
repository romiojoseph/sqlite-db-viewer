import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class AppMenuItem<T> {
  final T? value;
  final String? label;
  final IconData? icon;
  final Widget? customIcon;
  final bool isDestructive;
  final bool isDivider;
  final VoidCallback? onTap;

  const AppMenuItem({
    this.value,
    this.label,
    this.icon,
    this.customIcon,
    this.isDestructive = false,
    this.isDivider = false,
    this.onTap,
  });

  const AppMenuItem.divider()
    : value = null,
      label = null,
      icon = null,
      customIcon = null,
      isDestructive = false,
      isDivider = true,
      onTap = null;
}

Future<T?> showAppMenu<T>({
  required BuildContext context,
  required Offset position,
  required List<AppMenuItem<T>> items,
  double minWidth = 180.0,
  double? maxWidth,
}) {
  return Navigator.of(context).push<T>(
    _AppMenuRoute<T>(
      position: position,
      items: items,
      minWidth: minWidth,
      maxWidth: maxWidth,
    ),
  );
}

class _AppMenuRoute<T> extends PopupRoute<T> {
  final Offset position;
  final List<AppMenuItem<T>> items;
  final double minWidth;
  final double? maxWidth;

  _AppMenuRoute({
    required this.position,
    required this.items,
    required this.minWidth,
    this.maxWidth,
  });

  @override
  Color? get barrierColor => AppColors.neutral0.withValues(alpha: 0.15);

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss Menu';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 120);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 100);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _AppMenuWidget<T>(
      position: position,
      items: items,
      minWidth: minWidth,
      maxWidth: maxWidth,
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutQuad,
      reverseCurve: Curves.easeInQuad,
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, -0.04),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

class _AppMenuWidget<T> extends StatelessWidget {
  final Offset position;
  final List<AppMenuItem<T>> items;
  final double minWidth;
  final double? maxWidth;

  const _AppMenuWidget({
    required this.position,
    required this.items,
    required this.minWidth,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final effectiveMaxWidth = math.max(
      minWidth,
      maxWidth ?? math.max(minWidth, 320.0),
    );

    return CustomSingleChildLayout(
      delegate: _AppMenuLayoutDelegate(
        position: position,
        screenSize: screenSize,
        padding: mediaQuery.padding,
      ),
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            minWidth: minWidth,
            maxWidth: effectiveMaxWidth,
          ),
          decoration: ShapeDecoration(
            color: AppColors.neutral2,
            shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppColors.neutral4, width: 1),
            ),
            shadows: [
              BoxShadow(
                color: AppColors.neutral0.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppColors.neutral0.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppSpacing.xxs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: items.map((item) {
              if (item.isDivider) {
                return Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                  color: AppColors.neutral4,
                );
              }
              return _AppMenuItemTile<T>(item: item);
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _AppMenuItemTile<T> extends StatefulWidget {
  final AppMenuItem<T> item;

  const _AppMenuItemTile({required this.item});

  @override
  State<_AppMenuItemTile<T>> createState() => _AppMenuItemTileState<T>();
}

class _AppMenuItemTileState<T> extends State<_AppMenuItemTile<T>> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final Color textColor = item.isDestructive
        ? AppColors.error
        : _isHovered
        ? AppColors.neutral12
        : AppColors.neutral11;

    final Color iconColor = item.isDestructive
        ? AppColors.error
        : _isHovered
        ? AppColors.neutral12
        : AppColors.neutral9;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pop(item.value);
          item.onTap?.call();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: ShapeDecoration(
            color: _isHovered
                ? (item.isDestructive
                      ? AppColors.errorBackground.withValues(alpha: 0.4)
                      : AppColors.neutral3)
                : Colors.transparent,
            shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            children: [
              if (item.customIcon != null)
                item.customIcon!
              else if (item.icon != null) ...[
                Icon(item.icon, size: 16, color: iconColor),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  item.label ?? '',
                  style: AppTypography.caption.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppMenuLayoutDelegate extends SingleChildLayoutDelegate {
  final Offset position;
  final Size screenSize;
  final EdgeInsets padding;

  _AppMenuLayoutDelegate({
    required this.position,
    required this.screenSize,
    required this.padding,
  });

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints.loose(screenSize);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    double x = position.dx;
    double y = position.dy;

    const double margin = 8.0;

    if (x + childSize.width > screenSize.width - margin) {
      x = position.dx - childSize.width;
    }
    if (x < margin) {
      x = margin;
    }

    if (y + childSize.height > screenSize.height - margin) {
      y = position.dy - childSize.height;
    }
    if (y < margin) {
      y = margin;
    }

    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_AppMenuLayoutDelegate oldDelegate) {
    return position != oldDelegate.position ||
        screenSize != oldDelegate.screenSize;
  }
}
