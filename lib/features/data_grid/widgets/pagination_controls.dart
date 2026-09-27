import '../../../shared/widgets/app_dropdown.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int pageSize;
  final int totalRows;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;

  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.pageSize,
    required this.totalRows,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final totalPages = (totalRows / pageSize).ceil().clamp(1, 999999);
    final startRow = totalRows == 0 ? 0 : (currentPage * pageSize) + 1;
    final endRow = ((currentPage + 1) * pageSize).clamp(0, totalRows);
    final formatter = NumberFormat('#,###');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: const BoxDecoration(
        color: AppColors.neutral2,
        border: Border(top: BorderSide(color: AppColors.neutral4, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Page size:',
                style: AppTypography.caption.copyWith(
                  color: AppColors.neutral7,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AppDropdown<int>(
                value: pageSize,
                height: 26,
                borderRadius: 16,
                fillColor: AppColors.neutral1,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                textStyle: AppTypography.label.copyWith(
                  color: AppColors.neutral8,
                  fontWeight: FontWeight.w500,
                ),
                items: AppConstants.pageSizeOptions.map((size) {
                  return AppDropdownItem<int>(
                    value: size,
                    label: size.toString(),
                  );
                }).toList(),
                onChanged: onPageSizeChanged,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Showing ${formatter.format(startRow)} - ${formatter.format(endRow)} of ${formatter.format(totalRows)}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.neutral8,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const AppSvgIcon(AppIcons.caretLineLeft, size: 16),
                tooltip: 'First Page',
                visualDensity: VisualDensity.compact,
                onPressed: currentPage > 0 ? () => onPageChanged(0) : null,
              ),
              IconButton(
                icon: const AppSvgIcon(AppIcons.caretLeft, size: 16),
                tooltip: 'Previous Page',
                visualDensity: VisualDensity.compact,
                onPressed: currentPage > 0
                    ? () => onPageChanged(currentPage - 1)
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Text(
                  '${currentPage + 1} / $totalPages',
                  style: AppTypography.label.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.neutral8,
                  ),
                ),
              ),
              IconButton(
                icon: const AppSvgIcon(AppIcons.caretRight, size: 16),
                tooltip: 'Next Page',
                visualDensity: VisualDensity.compact,
                onPressed: currentPage < totalPages - 1
                    ? () => onPageChanged(currentPage + 1)
                    : null,
              ),
              IconButton(
                icon: const AppSvgIcon(AppIcons.caretLineRight, size: 16),
                tooltip: 'Last Page',
                visualDensity: VisualDensity.compact,
                onPressed: currentPage < totalPages - 1
                    ? () => onPageChanged(totalPages - 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
