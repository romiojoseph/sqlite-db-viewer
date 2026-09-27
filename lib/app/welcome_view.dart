import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import '../features/file_open/widgets/drag_drop_zone.dart';
import '../features/file_open/widgets/recent_files_list.dart';
import '../shared/widgets/app_button.dart';
import '../shared/widgets/app_svg_icon.dart';
import '../shared/widgets/window_title_bar.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class WelcomeView extends StatefulWidget {
  final List<String> recentFiles;
  final ValueChanged<String> onFileSelected;
  final ValueChanged<String> onRemoveRecentFile;
  final VoidCallback onClearRecentFiles;
  final VoidCallback onOpenDiffChecker;
  final VoidCallback onNewDatabase;

  const WelcomeView({
    super.key,
    required this.recentFiles,
    required this.onFileSelected,
    required this.onRemoveRecentFile,
    required this.onClearRecentFiles,
    required this.onOpenDiffChecker,
    required this.onNewDatabase,
  });

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    super.dispose();
  }

  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.keyW &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed)) {
      _closeWindow();
      return true;
    }
    return false;
  }

  void _closeWindow() async {
    try {
      await windowManager.close();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral1,
      body: SafeArea(
        child: Column(
          children: [
            const WindowTitleBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.xxl,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 580),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Drop Zone Card
                        DragDropZone(onFileDropped: widget.onFileSelected),
                        const SizedBox(height: AppSpacing.md),

                        // Quick action secondary buttons
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                label: 'New Database',
                                customIcon: const AppSvgIcon(
                                  AppIcons.plusCircle,
                                  size: 16,
                                ),
                                variant: AppButtonVariant.outline,
                                size: AppButtonSize.medium,
                                onPressed: widget.onNewDatabase,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: AppButton(
                                label: 'Diff / Compare',
                                customIcon: const AppSvgIcon(
                                  AppIcons.treeStructure,
                                  size: 16,
                                ),
                                variant: AppButtonVariant.outline,
                                size: AppButtonSize.medium,
                                onPressed: widget.onOpenDiffChecker,
                              ),
                            ),
                          ],
                        ),

                        // Recent Databases section
                        if (widget.recentFiles.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xl),
                          RecentFilesList(
                            recentFiles: widget.recentFiles,
                            onFileSelected: widget.onFileSelected,
                            onRemoveFile: widget.onRemoveRecentFile,
                            onClearAll: widget.onClearRecentFiles,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
