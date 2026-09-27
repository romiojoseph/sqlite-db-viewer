import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/utils/byte_formatter.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../models/column_diff.dart';

class DiffColumnChangeRow extends StatelessWidget {
  final ColumnDiff columnDiff;

  const DiffColumnChangeRow({super.key, required this.columnDiff});

  String _formatValue(dynamic val) {
    if (val == null) return 'NULL';
    if (val is Uint8List) {
      return ByteFormatter.toHexSnippet(val);
    }
    return val.toString();
  }

  @override
  Widget build(BuildContext context) {
    final oldStr = _formatValue(columnDiff.oldValue);
    final newStr = _formatValue(columnDiff.newValue);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: ShapeDecoration(
        color: AppColors.neutral1,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: const BorderSide(color: AppColors.neutral4, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              columnDiff.columnName,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.neutral8,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Row(
              children: [
                const AppSvgIcon(
                  AppIcons.minus,
                  size: 9,
                  color: AppColors.error,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Expanded(
                  child: SelectableText(
                    oldStr,
                    style: AppTypography.caption.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500,
                      color: oldStr == 'NULL'
                          ? AppColors.neutral8
                          : AppColors.error,
                      fontStyle: oldStr == 'NULL'
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: AppSvgIcon(
              AppIcons.caretRight,
              size: 12,
              color: AppColors.neutral6,
            ),
          ),
          Expanded(
            child: Row(
              children: [
                const AppSvgIcon(
                  AppIcons.plus,
                  size: 9,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Expanded(
                  child: SelectableText(
                    newStr,
                    style: AppTypography.caption.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500,
                      color: newStr == 'NULL'
                          ? AppColors.neutral8
                          : AppColors.success,
                      fontStyle: newStr == 'NULL'
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
