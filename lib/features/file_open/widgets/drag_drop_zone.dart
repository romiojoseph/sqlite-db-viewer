import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../theme/app_theme.dart';
import 'open_file_button.dart';

class DragDropZone extends StatefulWidget {
  final ValueChanged<String> onFileDropped;

  const DragDropZone({super.key, required this.onFileDropped});

  @override
  State<DragDropZone> createState() => _DragDropZoneState();
}

class _DragDropZoneState extends State<DragDropZone> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (details) => setState(() => _isDragging = true),
      onDragExited: (details) => setState(() => _isDragging = false),
      onDragDone: (details) {
        setState(() => _isDragging = false);
        if (details.files.isNotEmpty) {
          final firstFile = details.files.first;
          widget.onFileDropped(firstFile.path);
        }
      },
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: AppCurves.standard,
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 580),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.xxl,
        ),
        decoration: ShapeDecoration(
          color: _isDragging ? AppColors.neutral3 : AppColors.neutral2,
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.circular(36.0),
            side: BorderSide(
              color: _isDragging ? AppColors.neutral6 : AppColors.neutral3,
              width: _isDragging ? 1.5 : 1.0,
            ),
          ),
          shadows: [
            BoxShadow(
              color: AppColors.neutral0.withValues(alpha: 0.3),
              blurRadius: 24.0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isDragging)
              Container(
                width: 64,
                height: 64,
                decoration: ShapeDecoration(
                  color: AppColors.neutral4,
                  shape: ContinuousRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                child: const Center(
                  child: AppSvgIcon(
                    AppIcons.arrowSquareUp,
                    size: 32,
                    color: AppColors.neutral12,
                  ),
                ),
              )
            else
              Image.asset('assets/images/app_icon.png', width: 64, height: 64),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Drag & drop SQLite database here',
              style: AppTypography.heading5.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.neutral9,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Supports .db, .sqlite, .sqlite3, .sql',
              style: AppTypography.body.copyWith(color: AppColors.neutral7),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            OpenFileButton(onFileSelected: widget.onFileDropped),
          ],
        ),
      ),
    );
  }
}
