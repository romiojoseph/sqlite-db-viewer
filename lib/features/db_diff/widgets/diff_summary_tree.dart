import 'package:flutter/material.dart';
import '../../../shared/widgets/app_chip.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../models/diff_session.dart';
import 'diff_empty_state.dart';
import 'diff_table_summary_row.dart';

class DiffSummaryTree extends StatefulWidget {
  final DiffSession session;
  final ValueChanged<String> onSelectTable;

  const DiffSummaryTree({
    super.key,
    required this.session,
    required this.onSelectTable,
  });

  @override
  State<DiffSummaryTree> createState() => _DiffSummaryTreeState();
}

class _DiffSummaryTreeState extends State<DiffSummaryTree> {
  int _selectedFilter = 0;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final results = session.tableResults.values.toList();

    final filtered = results.where((r) {
      if (_selectedFilter == 1) return r.isChanged;
      if (_selectedFilter == 2) return r.isIdentical;
      return true;
    }).toList();

    final summaryParts = [
      '${session.changedTablesCount} changed',
      '${session.identicalTablesCount} identical',
      if (session.notComparedTablesCount > 0)
        '${session.notComparedTablesCount} not compared',
      if (session.errorTablesCount > 0) '${session.errorTablesCount} error',
    ].join(', ');

    final String resultTitle;
    final Color resultColor;
    if (session.hasConfirmedDifferences) {
      resultTitle = 'Comparison Result: Differences Detected';
      resultColor = AppColors.neutral8;
    } else if (session.isInconclusive) {
      resultTitle = 'Comparison Result: Inconclusive (Caps Exceeded or Errors)';
      resultColor = AppColors.warning;
    } else if (session.areDatabasesIdentical) {
      resultTitle = 'Comparison Result: Identical Databases';
      resultColor = AppColors.success;
    } else {
      resultTitle = 'Comparison Result: No Tables Selected';
      resultColor = AppColors.neutral8;
    }

    return Container(
      color: AppColors.neutral1,
      child: Column(
        children: [
          Container(
            padding: AppSpacing.paddingMd,
            decoration: const BoxDecoration(
              color: AppColors.neutral2,
              border: Border(bottom: BorderSide(color: AppColors.neutral5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          resultTitle,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: resultColor,
                          ),
                        ),
                        Text(
                          '${results.length} tables compared in ${session.duration.inMilliseconds} ms · $summaryParts',
                          style: AppTypography.label.copyWith(
                            color: AppColors.neutral7,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (session.hasConfirmedDifferences) ...[
                      _summaryStat(
                        '+${session.totalAddedRows} Added',
                        AppColors.success,
                      ),
                      const SizedBox(width: AppSpacing.xs - AppSpacing.xxxs),
                      _summaryStat(
                        '-${session.totalRemovedRows} Removed',
                        AppColors.error,
                      ),
                      const SizedBox(width: AppSpacing.xs - AppSpacing.xxxs),
                      _summaryStat(
                        '~${session.totalModifiedRows} Modified',
                        AppColors.warning,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _filterChip('All Tables (${results.length})', 0),
                    const SizedBox(width: AppSpacing.xs),
                    _filterChip(
                      'Changed (${session.changedTablesCount})',
                      1,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _filterChip(
                      'Identical (${session.identicalTablesCount})',
                      2,
                      color: AppColors.success,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? (session.areDatabasesIdentical
                      ? DiffEmptyState.identical()
                      : Center(
                          child: Text(
                            'No tables match the selected filter.',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.neutral9,
                            ),
                          ),
                        ))
                : ListView.builder(
                    padding: AppSpacing.paddingMd,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return DiffTableSummaryRow(
                        tableDiff: item,
                        onTap: () => widget.onSelectTable(item.tableName),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _summaryStat(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs - AppSpacing.xxxs,
        vertical: AppSpacing.xxxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: AppTypography.tagline.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _filterChip(String label, int index, {Color? color}) {
    final isSelected = _selectedFilter == index;

    return AppChip(
      label: label,
      color: color,
      isSelected: isSelected,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      onSelected: (_) => setState(() => _selectedFilter = index),
    );
  }
}
