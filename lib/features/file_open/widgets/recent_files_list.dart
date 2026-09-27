import 'package:flutter/material.dart';
import '../../../core/extensions/string_extensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class RecentFilesList extends StatelessWidget {
  final List<String> recentFiles;
  final ValueChanged<String> onFileSelected;
  final ValueChanged<String> onRemoveFile;
  final VoidCallback onClearAll;

  const RecentFilesList({
    super.key,
    required this.recentFiles,
    required this.onFileSelected,
    required this.onRemoveFile,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    if (recentFiles.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 580),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Databases',
                  style: AppTypography.subtitle.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.neutral8,
                  ),
                ),
                AppButton(
                  label: 'Clear All',
                  variant: AppButtonVariant.text,
                  size: AppButtonSize.small,
                  onPressed: onClearAll,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentFiles.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 2.4, color: AppColors.neutral2),
              itemBuilder: (context, index) {
                final path = recentFiles[index];
                final fileName = path.fileNameFromPath;
                final isSql = fileName.toLowerCase().endsWith('.sql');

                return ListTile(
                  dense: true,
                  shape: ContinuousRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  leading: AppSvgIcon(
                    isSql ? AppIcons.fileSql : AppIcons.database,
                    size: 32,
                    color: AppColors.neutral7,
                  ),
                  title: Text(
                    fileName,
                    style: AppTypography.subtitle.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppColors.neutral8,
                    ),
                  ),
                  subtitle: Text(
                    path,
                    style: AppTypography.label.copyWith(
                      color: AppColors.neutral7,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const AppSvgIcon(
                      AppIcons.x,
                      size: 14,
                      color: AppColors.neutral9,
                    ),
                    color: AppColors.neutral9,
                    tooltip: 'Remove from recents',
                    splashRadius: 16,
                    onPressed: () => onRemoveFile(path),
                  ),
                  onTap: () => onFileSelected(path),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
