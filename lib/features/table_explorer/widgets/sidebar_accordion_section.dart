import '../../../shared/widgets/app_svg_icon.dart';
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class SidebarAccordionSection extends StatelessWidget {
  final String title;
  final String? svgIcon;
  final IconData? icon;
  final Color? iconColor;
  final int count;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget? trailingAction;
  final List<Widget> children;

  const SidebarAccordionSection({
    super.key,
    required this.title,
    this.svgIcon,
    this.icon,
    this.iconColor,
    required this.count,
    required this.isExpanded,
    required this.onToggle,
    this.trailingAction,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSvgIcon =
        svgIcon ?? (isExpanded ? AppIcons.folderOpen : AppIcons.folderSimple);
    final effectiveIconColor = isExpanded
        ? AppColors.secondary6
        : (iconColor ?? AppColors.neutral10);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggle,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: AppColors.neutral3,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs + 1.0,
              ),
              child: Row(
                children: [
                  AppSvgIcon(
                    effectiveSvgIcon,
                    size: 16,
                    color: effectiveIconColor,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.caption.copyWith(
                        fontWeight: isExpanded
                            ? FontWeight.w500
                            : FontWeight.w400,
                        color: isExpanded
                            ? AppColors.neutral9
                            : AppColors.neutral7,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xxxs,
                    ),
                    decoration: ShapeDecoration(
                      color: AppColors.neutral4,
                      shape: ContinuousRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                    child: Text(
                      '$count',
                      style: AppTypography.tagline.copyWith(
                        color: AppColors.neutral9,
                      ),
                    ),
                  ),
                  if (trailingAction != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    trailingAction!,
                  ],
                ],
              ),
            ),
          ),
        ),

        // Section Body
        if (isExpanded)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.xs,
                      ),
                      child: Text(
                        'None found',
                        style: AppTypography.tagline.copyWith(
                          color: AppColors.neutral8,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ]
                : children,
          ),
      ],
    );
  }
}
