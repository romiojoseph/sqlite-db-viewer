import 'package:flutter/material.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_dropdown.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class SearchInputHeader extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final bool isSearching;
  final int maxMatches;
  final ValueChanged<int> onMaxMatchesChanged;
  final bool caseSensitive;
  final ValueChanged<bool> onCaseSensitiveChanged;

  const SearchInputHeader({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.isSearching,
    required this.maxMatches,
    required this.onMaxMatchesChanged,
    required this.caseSensitive,
    required this.onCaseSensitiveChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.neutral2,
        border: Border(bottom: BorderSide(color: AppColors.neutral3, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: controller,
                  hintText: 'Search across all tables & text columns...',
                  customPrefixIcon: const AppSvgIcon(
                    AppIcons.magnifyingGlass,
                    size: 15,
                    color: AppColors.neutral9,
                  ),
                  size: AppInputSize.medium,
                  onSubmitted: (_) => onSearch(),
                  suffixIcon: controller.text.isNotEmpty
                      ? InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => controller.clear(),
                          child: const Padding(
                            padding: AppSpacing.paddingXxs,
                            child: AppSvgIcon(
                              AppIcons.x,
                              size: 14,
                              color: AppColors.neutral9,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton(
                label: 'Search',
                customIcon: const AppSvgIcon(
                  AppIcons.magnifyingGlass,
                  size: 15,
                  color: AppColors.neutral12,
                ),
                variant: AppButtonVariant.primary,
                size: AppButtonSize.medium,
                isLoading: isSearching,
                onPressed: isSearching ? null : onSearch,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Text(
                'Result cap:',
                style: AppTypography.caption.copyWith(
                  color: AppColors.neutral8,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AppDropdown<int>(
                value: maxMatches,
                height: 26,
                borderRadius: 16,
                fillColor: AppColors.neutral3,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                textStyle: AppTypography.label.copyWith(
                  color: AppColors.neutral8,
                  fontWeight: FontWeight.w500,
                ),
                items: const [
                  AppDropdownItem<int>(value: 50, label: '50'),
                  AppDropdownItem<int>(value: 100, label: '100'),
                  AppDropdownItem<int>(value: 250, label: '250'),
                  AppDropdownItem<int>(value: 500, label: '500'),
                ],
                onChanged: onMaxMatchesChanged,
              ),
              const SizedBox(width: AppSpacing.md),
              InkWell(
                borderRadius: BorderRadius.circular(4.0),
                onTap: () => onCaseSensitiveChanged(!caseSensitive),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.0,
                    vertical: 2.0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: Checkbox(
                          value: caseSensitive,
                          onChanged: (val) =>
                              onCaseSensitiveChanged(val ?? false),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs - AppSpacing.xxxs),
                      Text(
                        'Case sensitive',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.neutral8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
