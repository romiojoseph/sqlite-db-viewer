import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_svg_icon.dart';

class OpenFileButton extends StatelessWidget {
  final ValueChanged<String> onFileSelected;
  final bool isSecondary;

  const OpenFileButton({
    super.key,
    required this.onFileSelected,
    this.isSecondary = false,
  });

  Future<void> _pickFile() async {
    final result = await FilePickerPlatform.instance.pickFiles(
      dialogTitle: 'Select SQLite Database',
      type: FileType.custom,
      allowedExtensions: AppConstants.supportedDbExtensions,
    );

    if (result.isNotEmpty && result.first.path != null) {
      onFileSelected(result.first.path!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isSecondary) {
      return AppButton(
        label: 'Open Database',
        customIcon: const AppSvgIcon(AppIcons.folderOpen, size: 16),
        variant: AppButtonVariant.outline,
        size: AppButtonSize.medium,
        onPressed: _pickFile,
      );
    }

    return AppButton(
      label: 'Open Database',
      customIcon: const AppSvgIcon(AppIcons.folderOpen, size: 18),
      variant: AppButtonVariant.primary,
      size: AppButtonSize.large,
      onPressed: _pickFile,
    );
  }
}
