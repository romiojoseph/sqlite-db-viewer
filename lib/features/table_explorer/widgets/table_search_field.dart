import '../../../shared/widgets/app_svg_icon.dart';
import 'package:flutter/material.dart';
import '../../../theme/app_spacing.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../theme/app_colors.dart';

class TableSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const TableSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      hintText: 'Filter tables & objects...',
      customPrefixIcon: const AppSvgIcon(
        AppIcons.magnifyingGlass,
        size: 14,
        color: AppColors.neutral9,
      ),
      size: AppInputSize.small,
      onChanged: onChanged,
      suffixIcon: controller.text.isNotEmpty
          ? InkWell(
              onTap: onClear,
              borderRadius: BorderRadius.circular(12),
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
    );
  }
}
