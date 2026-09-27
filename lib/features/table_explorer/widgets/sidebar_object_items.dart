import '../../../shared/widgets/app_svg_icon.dart';
import 'package:flutter/material.dart';
import '../../../data/models/db_index.dart';
import '../../../data/models/db_sequence.dart';
import '../../../data/models/db_trigger.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class TriggerListItem extends StatelessWidget {
  final DbTrigger trigger;
  final VoidCallback? onTap;

  const TriggerListItem({super.key, required this.trigger, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 1.5,
      ),
      child: Material(
        color: Colors.transparent,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: AppColors.neutral3,
          onTap: onTap ?? () => _showTriggerDialog(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                const SizedBox(width: AppSpacing.xs),
                const AppSvgIcon(
                  AppIcons.play,
                  size: 14,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        trigger.name,
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w400,
                          color: AppColors.neutral8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (trigger.tableName.isNotEmpty)
                        Text(
                          'on ${trigger.tableName}',
                          style: AppTypography.tagline.copyWith(
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
          ),
        ),
      ),
    );
  }

  void _showTriggerDialog(BuildContext context) {
    AppDialog.show<void>(
      context,
      builder: (_) => AppDialog(
        title: 'Trigger: ${trigger.name}',
        subtitle: 'Target table: ${trigger.tableName}',
        maxWidth: 560,
        maxHeight: 500,
        child: SingleChildScrollView(
          child: SelectableText(
            trigger.sql ?? '-- No SQL definition available',
            style: AppTypography.body.copyWith(color: AppColors.neutral8),
          ),
        ),
      ),
    );
  }
}

class IndexListItem extends StatelessWidget {
  final DbIndex index;
  final String tableName;
  final VoidCallback? onTap;

  const IndexListItem({
    super.key,
    required this.index,
    required this.tableName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colsStr = index.columns.isNotEmpty ? index.columns.join(', ') : null;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 1.5,
      ),
      child: Material(
        color: Colors.transparent,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: AppColors.neutral3,
          onTap: onTap ?? () => _showIndexDialog(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        index.name,
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w400,
                          color: AppColors.neutral8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'on $tableName${colsStr != null ? ' ($colsStr)' : ''}',
                        style: AppTypography.tagline.copyWith(
                          color: AppColors.neutral7,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (index.unique)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6.0,
                      vertical: 2.0,
                    ),
                    decoration: ShapeDecoration(
                      color: AppColors.neutral0,
                      shape: ContinuousRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                        side: const BorderSide(
                          color: AppColors.neutral3,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Text(
                      'UNIQUE',
                      style: AppTypography.tagline.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutral8,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showIndexDialog(BuildContext context) {
    AppDialog.show<void>(
      context,
      builder: (_) => AppDialog(
        title: 'Index: ${index.name}',
        maxWidth: 500,
        maxHeight: 320,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPropertyRow('Target Table', tableName),
            const SizedBox(height: AppSpacing.xs),
            _buildPropertyRow(
              'Indexed Columns',
              index.columns.isNotEmpty ? index.columns.join(', ') : 'All',
            ),
            const SizedBox(height: AppSpacing.xs),
            _buildPropertyRow('Type', index.unique ? 'UNIQUE INDEX' : 'INDEX'),
            const SizedBox(height: AppSpacing.xs),
            _buildPropertyRow(
              'Origin',
              index.origin.isNotEmpty ? index.origin : 'CREATE INDEX',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.neutral7,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            value,
            style: AppTypography.caption.copyWith(
              color: AppColors.neutral8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class SequenceListItem extends StatelessWidget {
  final DbSequence sequence;
  final VoidCallback? onTap;

  const SequenceListItem({super.key, required this.sequence, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 1.5,
      ),
      child: Material(
        color: Colors.transparent,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: AppColors.neutral3,
          onTap: onTap ?? () => _showSequenceDialog(context),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    sequence.name,
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w400,
                      color: AppColors.neutral8,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xxxs,
                  ),
                  decoration: ShapeDecoration(
                    color: AppColors.neutral4,
                    shape: ContinuousRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                  ),
                  child: Text(
                    'seq: ${sequence.seq}',
                    style: AppTypography.tagline.copyWith(
                      color: AppColors.neutral9,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSequenceDialog(BuildContext context) {
    AppDialog.show<void>(
      context,
      builder: (_) => AppDialog(
        title: 'Sequence: ${sequence.name}',
        maxWidth: 480,
        maxHeight: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPropertyRow('Table Name', sequence.name),
            const SizedBox(height: AppSpacing.xs),
            _buildPropertyRow('Current Sequence (seq)', '${sequence.seq}'),
            const SizedBox(height: AppSpacing.xs),
            _buildPropertyRow('Type', 'AUTOINCREMENT SEQUENCE'),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.neutral7,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            value,
            style: AppTypography.caption.copyWith(
              color: AppColors.neutral8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
