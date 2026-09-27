import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/utils/byte_formatter.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/copy_button.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class BlobCellPreview extends StatelessWidget {
  final Uint8List bytes;

  const BlobCellPreview({super.key, required this.bytes});

  void _showBlobDialog(BuildContext context) {
    final isImage = ByteFormatter.isImageBlob(bytes);
    final sizeStr = ByteFormatter.formatSize(bytes.length);
    final hexFull = ByteFormatter.toHexSnippet(bytes, maxBytes: bytes.length);

    AppDialog.show<void>(
      context,
      builder: (_) {
        return AppDialog(
          title: isImage
              ? 'BLOB Image Preview ($sizeStr)'
              : 'BLOB Data ($sizeStr)',
          headerTrailing: CopyButton(
            textToCopy: hexFull,
            tooltip: 'Copy hex string',
          ),
          maxWidth: 620,
          maxHeight: 560,
          child: isImage
              ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.memory(bytes, fit: BoxFit.contain),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Format: ${ByteFormatter.getImageType(bytes)} | Size: $sizeStr (${bytes.length} bytes)',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.neutral8,
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      padding: AppSpacing.paddingMd,
                      decoration: BoxDecoration(
                        color: AppColors.neutral3,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: AppColors.neutral5),
                      ),
                      child: SelectableText(
                        hexFull,
                        style: AppTypography.tagline.copyWith(
                          fontFamily: 'monospace',
                          color: AppColors.neutral8,
                        ),
                      ),
                    ),
                  ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isImage = ByteFormatter.isImageBlob(bytes);
    final sizeStr = ByteFormatter.formatSize(bytes.length);

    return InkWell(
      onTap: () => _showBlobDialog(context),
      borderRadius: BorderRadius.circular(4.0),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 2.0,
        ),
        decoration: BoxDecoration(
          color: AppColors.typeBlob.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4.0),
          border: Border.all(color: AppColors.typeBlob.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isImage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(2.0),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const AppSvgIcon(
                      AppIcons.info,
                      size: 14,
                      color: AppColors.typeBlob,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                '${ByteFormatter.getImageType(bytes)} ($sizeStr)',
                style: AppTypography.tagline.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral11,
                ),
              ),
            ] else ...[
              const AppSvgIcon(
                AppIcons.cards,
                size: 13,
                color: AppColors.typeBlob,
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                'BLOB ($sizeStr)',
                style: AppTypography.tagline.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.typeBlob,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
