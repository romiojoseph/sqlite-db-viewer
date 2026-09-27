import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/byte_formatter.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_chip.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../models/row_diff.dart';
import '../models/table_diff_result.dart';
import '../services/row_diff_service.dart';
import 'diff_column_change_row.dart';

class DiffRowDetailView extends StatefulWidget {
  final TableDiffResult tableDiff;
  final VoidCallback onBack;

  const DiffRowDetailView({
    super.key,
    required this.tableDiff,
    required this.onBack,
  });

  @override
  State<DiffRowDetailView> createState() => _DiffRowDetailViewState();
}

class _DiffRowDetailViewState extends State<DiffRowDetailView> {
  RowDiffType? _selectedFilterType;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _exportDiffCsv() async {
    final csv = RowDiffService.generateDiffCsv(widget.tableDiff);
    final bytes = Uint8List.fromList(utf8.encode(csv));

    final uri = await FilePickerPlatform.instance.saveFile(
      dialogTitle: 'Export Table Diff to CSV',
      fileName: '${widget.tableDiff.tableName}_diff.csv',
      bytes: bytes,
      mimeType: 'text/csv',
    );

    if (uri == null) return;

    final path = uri.toFilePath();

    try {
      final file = File(path);
      await file.writeAsBytes(bytes);
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported diff to $path'),
          backgroundColor: AppColors.neutral3,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final diff = widget.tableDiff;

    final filteredDiffs = diff.rowDiffs.where((r) {
      if (_selectedFilterType != null && r.type != _selectedFilterType) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final matchesPk = r.primaryKeyLabel.toLowerCase().contains(
          _searchQuery.toLowerCase(),
        );
        final matchesCols = r.changedColumns.any(
          (c) =>
              c.columnName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              c.oldValue.toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              c.newValue.toString().toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
        );
        return matchesPk || matchesCols;
      }
      return true;
    }).toList();

    return Container(
      color: AppColors.neutral1,
      child: Column(
        children: [
          Container(
            padding: AppSpacing.paddingSm,
            decoration: const BoxDecoration(
              color: AppColors.neutral2,
              border: Border(bottom: BorderSide(color: AppColors.neutral3)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const AppSvgIcon(
                    AppIcons.caretLeft,
                    size: 16,
                    color: AppColors.neutral11,
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: widget.onBack,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  diff.tableName,
                  style: AppTypography.subtitle.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.neutral9,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '(${diff.totalChanges} total changes)',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.neutral7,
                  ),
                ),
                const Spacer(),
                AppButton(
                  label: 'Export Diff CSV',
                  customIcon: const AppSvgIcon(AppIcons.export, size: 14),
                  variant: AppButtonVariant.outline,
                  size: AppButtonSize.small,
                  onPressed: _exportDiffCsv,
                ),
              ],
            ),
          ),
          if (diff.statusMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xxs,
              ),
              color: AppColors.warning.withValues(alpha: 0.1),
              child: Text(
                diff.statusMessage!,
                style: AppTypography.tagline.copyWith(color: AppColors.warning),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: const BoxDecoration(
              color: AppColors.neutral2,
              border: Border(bottom: BorderSide(color: AppColors.neutral3)),
            ),
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'All (${diff.rowDiffs.length})',
                  isSelected: _selectedFilterType == null,
                  onTap: () => setState(() => _selectedFilterType = null),
                ),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip(
                  label: '+ Added (${diff.addedRowCount})',
                  isSelected: _selectedFilterType == RowDiffType.added,
                  color: AppColors.success,
                  onTap: () =>
                      setState(() => _selectedFilterType = RowDiffType.added),
                ),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip(
                  label: '- Removed (${diff.removedRowCount})',
                  isSelected: _selectedFilterType == RowDiffType.removed,
                  color: AppColors.error,
                  onTap: () =>
                      setState(() => _selectedFilterType = RowDiffType.removed),
                ),
                const SizedBox(width: AppSpacing.xs),
                _buildFilterChip(
                  label: '~ Modified (${diff.modifiedRowCount})',
                  isSelected: _selectedFilterType == RowDiffType.modified,
                  color: AppColors.warning,
                  onTap: () => setState(
                    () => _selectedFilterType = RowDiffType.modified,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 220,
                  height: 28,
                  child: TextField(
                    controller: _searchController,
                    style: AppTypography.tagline.copyWith(
                      color: AppColors.neutral12,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Filter diff rows...',
                      hintStyle: AppTypography.tagline.copyWith(
                        color: AppColors.neutral9,
                      ),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.all(6.0),
                        child: AppSvgIcon(
                          AppIcons.magnifyingGlass,
                          size: 14,
                          color: AppColors.neutral9,
                        ),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const AppSvgIcon(
                                AppIcons.x,
                                size: 12,
                                color: AppColors.neutral10,
                              ),
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.xxs),
                        borderSide: const BorderSide(color: AppColors.neutral5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xxs,
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
              ],
            ),
          ),
          if (diff.isCapped)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xxs,
              ),
              color: AppColors.neutral3,
              child: Text(
                'Showing first ${diff.maxCap} differences. Use "Export Diff CSV" to inspect all changes.',
                style: AppTypography.tagline.copyWith(
                  fontSize: 10,
                  color: AppColors.neutral10,
                ),
              ),
            ),
          Expanded(
            child: filteredDiffs.isEmpty
                ? Center(
                    child: Text(
                      'No matching row differences found.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.neutral9,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: AppSpacing.paddingMd,
                    itemCount: filteredDiffs.length,
                    itemBuilder: (context, index) {
                      final row = filteredDiffs[index];
                      return _buildRowDiffCard(row);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    return AppChip(
      label: label,
      color: color,
      isSelected: isSelected,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxxs,
      ),
      onSelected: (_) => onTap(),
    );
  }

  Widget _buildRowDiffCard(RowDiff row) {
    Color badgeColor;
    String badgeText;
    String badgeIcon;

    if (row.isAdded) {
      badgeColor = AppColors.success;
      badgeText = 'Added';
      badgeIcon = AppIcons.plusCircle;
    } else if (row.isRemoved) {
      badgeColor = AppColors.error;
      badgeText = 'Removed';
      badgeIcon = AppIcons.minus;
    } else {
      badgeColor = AppColors.warning;
      badgeText = 'Modified (${row.changedColumns.length})';
      badgeIcon = AppIcons.pencil;
    }

    final fullData = row.rowDataB ?? row.rowDataA ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: AppSpacing.paddingSm,
      decoration: ShapeDecoration(
        color: AppColors.neutral2,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: const BorderSide(color: AppColors.neutral4, width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppSvgIcon(badgeIcon, size: 16, color: badgeColor),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    badgeText,
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w500,
                      color: badgeColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SelectableText(
                  row.primaryKeyLabel,
                  style: AppTypography.body.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral8,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
          if (row.isModified) ...[
            const SizedBox(height: AppSpacing.xs),
            for (final colDiff in row.changedColumns)
              DiffColumnChangeRow(columnDiff: colDiff),
          ] else ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xxs,
              children: fullData.entries.map((e) {
                final rawValStr = e.value == null
                    ? 'NULL'
                    : (e.value is Uint8List
                          ? ByteFormatter.toHexSnippet(e.value as Uint8List)
                          : e.value.toString());
                final valStr = rawValStr.length > 150
                    ? '${rawValStr.substring(0, 150)}...'
                    : rawValStr;
                final Color valColor = row.isAdded
                    ? AppColors.success
                    : AppColors.error;

                return Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 3.0,
                  ),
                  decoration: ShapeDecoration(
                    color: AppColors.neutral1,
                    shape: ContinuousRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: const BorderSide(
                        color: AppColors.neutral4,
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${e.key}: ',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppColors.neutral7,
                        ),
                      ),
                      Flexible(
                        child: SelectableText(
                          valStr,
                          style: AppTypography.caption.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w500,
                            color: rawValStr == 'NULL'
                                ? AppColors.neutral8
                                : valColor,
                            fontStyle: rawValStr == 'NULL'
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
