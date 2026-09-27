import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../theme/app_spacing.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/string_extensions.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import 'blob_cell_preview.dart';
import 'cell_detail_dialog.dart';

class CellValueRenderer extends StatefulWidget {
  final dynamic value;
  final String columnName;
  final bool isNumericColumn;

  const CellValueRenderer({
    super.key,
    required this.value,
    required this.columnName,
    this.isNumericColumn = false,
  });

  @override
  State<CellValueRenderer> createState() => _CellValueRendererState();
}

class _CellValueRendererState extends State<CellValueRenderer> {
  bool _isHovered = false;

  void _showTextDialog(BuildContext context, String text) {
    CellDetailDialog.show(
      context,
      columnName: widget.columnName,
      rawText: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.value == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxs,
            vertical: AppSpacing.xxxs,
          ),
          decoration: BoxDecoration(
            color: AppColors.neutral0.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(3.0),
          ),
          child: Text(
            'Null',
            style: AppTypography.label.copyWith(
              fontStyle: FontStyle.italic,
              color: AppColors.neutral7,
              letterSpacing: 1,
            ),
          ),
        ),
      );
    }

    if (widget.value is Uint8List) {
      return Align(
        alignment: Alignment.centerLeft,
        child: BlobCellPreview(bytes: widget.value as Uint8List),
      );
    }

    final str = widget.value.toString();
    final isLong =
        str.length > AppConstants.maxTextCellPreviewLength ||
        str.contains('\n');

    final preview = isLong
        ? str
            .replaceAll('\n', ' ')
            .truncate(AppConstants.maxTextCellPreviewLength)
        : str;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  preview,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.neutral8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_isHovered) const SizedBox(width: 18),
            ],
          ),
          if (_isHovered)
            Positioned(
              right: 0,
              child: InkWell(
                onTap: () => _showTextDialog(context, str),
                borderRadius: BorderRadius.circular(3.0),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xxxs),
                  decoration: BoxDecoration(
                    color: AppColors.neutral3,
                    borderRadius: BorderRadius.circular(3.0),
                  ),
                  child: const AppSvgIcon(
                    AppIcons.arrowSquareOut,
                    size: 12,
                    color: AppColors.neutral9,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
