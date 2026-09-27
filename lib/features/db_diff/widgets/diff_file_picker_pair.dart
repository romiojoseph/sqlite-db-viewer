import '../../../shared/widgets/app_svg_icon.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/string_extensions.dart';
import '../../../core/utils/byte_formatter.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class DiffFilePickerPair extends StatelessWidget {
  final String? dbPathA;
  final String? dbPathB;
  final ValueChanged<String> onSelectPathA;
  final ValueChanged<String> onSelectPathB;
  final VoidCallback? onSwap;

  const DiffFilePickerPair({
    super.key,
    required this.dbPathA,
    required this.dbPathB,
    required this.onSelectPathA,
    required this.onSelectPathB,
    this.onSwap,
  });

  Future<void> _pickFile(ValueChanged<String> onSelected, String label) async {
    final result = await FilePickerPlatform.instance.pickFiles(
      dialogTitle: 'Select $label',
      type: FileType.custom,
      allowedExtensions: AppConstants.supportedDbExtensions,
    );

    if (result.isNotEmpty && result.first.path != null) {
      onSelected(result.first.path!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSwap = onSwap != null && (dbPathA != null || dbPathB != null);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _buildPickerCard(
            context: context,
            label: 'Database A',
            path: dbPathA,
            color: AppColors.neutral8,
            onPick: () => _pickFile(onSelectPathA, 'Database A'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Tooltip(
            message: 'Swap Base & Target databases',
            child: Material(
              color: AppColors.neutral2,
              shape: ContinuousRectangleBorder(
                borderRadius: BorderRadius.circular(14.0),
                side: const BorderSide(color: AppColors.neutral3, width: 1),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14.0),
                onTap: canSwap ? onSwap : null,
                child: const Padding(
                  padding: EdgeInsets.all(AppSpacing.xs),
                  child: AppSvgIcon(
                    AppIcons.arrowsLeftRight,
                    size: 18,
                    color: AppColors.neutral11,
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: _buildPickerCard(
            context: context,
            label: 'Database B',
            path: dbPathB,
            color: AppColors.neutral8,
            onPick: () => _pickFile(onSelectPathB, 'Database B'),
          ),
        ),
      ],
    );
  }

  Widget _buildPickerCard({
    required BuildContext context,
    required String label,
    required String? path,
    required Color color,
    required VoidCallback onPick,
  }) {
    final file = path != null ? File(path) : null;
    final exists = file != null && file.existsSync();
    final sizeStr = exists ? ByteFormatter.formatSize(file.lengthSync()) : null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: ShapeDecoration(
        color: AppColors.neutral2,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
          side: BorderSide(
            color: path != null
                ? color.withValues(alpha: 0.32)
                : AppColors.neutral3,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: AppTypography.heading6.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const Spacer(),
              AppButton(
                label: path == null ? 'Browse...' : 'Change...',
                customIcon: const AppSvgIcon(
                  AppIcons.folder,
                  size: 16,
                  color: AppColors.neutral7,
                ),
                variant: AppButtonVariant.ghost,
                size: AppButtonSize.small,
                onPressed: onPick,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (path != null) ...[
            Row(
              children: [
                const AppSvgIcon(
                  AppIcons.database,
                  size: 32,
                  color: AppColors.neutral6,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        path.fileNameFromPath,
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.neutral8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        exists ? '$path ($sizeStr)' : path,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.neutral7,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
              child: Text(
                'No database file selected.',
                style: AppTypography.caption.copyWith(
                  color: AppColors.neutral7,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
