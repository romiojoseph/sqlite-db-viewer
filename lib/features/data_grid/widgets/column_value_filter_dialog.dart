import '../../../shared/widgets/app_svg_icon.dart';
import 'package:flutter/material.dart';
import '../../../data/models/column_filter.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class ColumnValueFilterDialog extends StatefulWidget {
  final String columnName;
  final List<DistinctColumnValue> distinctValues;
  final List<String> initialSelectedValues;

  const ColumnValueFilterDialog({
    super.key,
    required this.columnName,
    required this.distinctValues,
    this.initialSelectedValues = const [],
  });

  static Future<ColumnFilter?> show(
    BuildContext context, {
    required String columnName,
    required List<DistinctColumnValue> distinctValues,
    List<String> initialSelectedValues = const [],
  }) {
    return AppDialog.show<ColumnFilter>(
      context,
      builder: (ctx) => ColumnValueFilterDialog(
        columnName: columnName,
        distinctValues: distinctValues,
        initialSelectedValues: initialSelectedValues,
      ),
    );
  }

  @override
  State<ColumnValueFilterDialog> createState() =>
      _ColumnValueFilterDialogState();
}

class _ColumnValueFilterDialogState extends State<ColumnValueFilterDialog> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Set<String> _selectedValues = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedValues.addAll(widget.initialSelectedValues);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<DistinctColumnValue> get _filteredValues {
    if (_searchQuery.isEmpty) return widget.distinctValues;
    return widget.distinctValues.where((item) {
      final str = item.isNull ? '(null)' : item.value.toString().toLowerCase();
      return str.contains(_searchQuery);
    }).toList();
  }

  String _itemKey(DistinctColumnValue item) {
    return item.isNull ? '__NULL__' : item.value.toString();
  }

  void _toggleItem(DistinctColumnValue item) {
    final key = _itemKey(item);
    setState(() {
      if (_selectedValues.contains(key)) {
        _selectedValues.remove(key);
      } else {
        _selectedValues.add(key);
      }
    });
  }

  void _selectAll() {
    setState(() {
      for (final item in _filteredValues) {
        _selectedValues.add(_itemKey(item));
      }
    });
  }

  void _clearAll() {
    setState(() {
      _selectedValues.clear();
    });
  }

  void _applyFilter() {
    if (_selectedValues.isEmpty) {
      Navigator.of(context).pop(null);
      return;
    }

    Navigator.of(context).pop(
      ColumnFilter(
        column: widget.columnName,
        operator: FilterOperator.inList,
        values: _selectedValues.toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedItems = _filteredValues;
    final allFilteredSelected =
        displayedItems.isNotEmpty &&
        displayedItems.every(
          (item) => _selectedValues.contains(_itemKey(item)),
        );
    final someFilteredSelected = displayedItems.any(
      (item) => _selectedValues.contains(_itemKey(item)),
    );

    final content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
              Text(
                'Choose value(s) to filter by:',
                style: AppTypography.caption.copyWith(
                  color: AppColors.neutral11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              // Search Field
              TextField(
                controller: _searchController,
                style: AppTypography.body.copyWith(
                  color: AppColors.neutral12,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: 'Search values...',
                  hintStyle: AppTypography.caption.copyWith(
                    color: AppColors.neutral8,
                  ),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: AppSvgIcon(
                      AppIcons.magnifyingGlass,
                      size: 16,
                      color: AppColors.neutral9,
                    ),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const AppSvgIcon(
                            AppIcons.x,
                            size: 14,
                            color: AppColors.neutral10,
                          ),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.neutral1,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(color: AppColors.neutral4),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(color: AppColors.neutral4),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(color: AppColors.neutral7),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Distinct Values Table
              Expanded(
                child: Container(
                  decoration: ShapeDecoration(
                    color: AppColors.neutral1,
                    shape: ContinuousRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      side: const BorderSide(color: AppColors.neutral4),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Table Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 4.0,
                        ),
                        decoration: const BoxDecoration(
                          color: AppColors.neutral3,
                          border: Border(
                            bottom: BorderSide(color: AppColors.neutral4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: allFilteredSelected
                                  ? true
                                  : (someFilteredSelected ? null : false),
                              tristate: true,
                              activeColor: AppColors.neutral6,
                              checkColor: AppColors.neutral12,
                              visualDensity: VisualDensity.compact,
                              onChanged: (val) {
                                if (val == true) {
                                  _selectAll();
                                } else {
                                  _clearAll();
                                }
                              },
                            ),
                            const SizedBox(width: AppSpacing.xxs),
                            Expanded(
                              child: Text(
                                'Value',
                                style: AppTypography.tagline.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.neutral11,
                                ),
                              ),
                            ),
                            Text(
                              'Count',
                              style: AppTypography.tagline.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.neutral11,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                        ),
                      ),

                      // Table Body List
                      Expanded(
                        child: displayedItems.isEmpty
                            ? Center(
                                child: Text(
                                  'No matching values',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.neutral8,
                                  ),
                                ),
                              )
                            : Scrollbar(
                                controller: _scrollController,
                                thumbVisibility: true,
                                child: ListView.separated(
                                  controller: _scrollController,
                                  itemCount: displayedItems.length,
                                  separatorBuilder: (_, _) => const Divider(
                                    height: 1,
                                    color: AppColors.neutral4,
                                  ),
                                  itemBuilder: (context, index) {
                                    final item = displayedItems[index];
                                    final key = _itemKey(item);
                                    final isChecked = _selectedValues.contains(
                                      key,
                                    );

                                    return InkWell(
                                      onTap: () => _toggleItem(item),
                                      hoverColor: AppColors.neutral3,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.xs,
                                          vertical: 3.0,
                                        ),
                                        child: Row(
                                          children: [
                                            Checkbox(
                                              value: isChecked,
                                              activeColor: AppColors.neutral6,
                                              checkColor: AppColors.neutral12,
                                              visualDensity:
                                                  VisualDensity.compact,
                                              onChanged: (_) =>
                                                  _toggleItem(item),
                                            ),
                                            const SizedBox(
                                              width: AppSpacing.xxs,
                                            ),
                                            Expanded(
                                              child: item.isNull
                                                  ? Text(
                                                      '(NULL)',
                                                      style: AppTypography
                                                          .caption
                                                          .copyWith(
                                                            color: AppColors
                                                                .neutral9,
                                                            fontStyle: FontStyle
                                                                .italic,
                                                            fontFamily:
                                                                'monospace',
                                                          ),
                                                    )
                                                  : Text(
                                                      item.value.toString(),
                                                      style: AppTypography
                                                          .caption
                                                          .copyWith(
                                                            color: AppColors
                                                                .neutral12,
                                                            fontFamily:
                                                                'monospace',
                                                          ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6.0,
                                                    vertical: 1.0,
                                                  ),
                                              decoration: ShapeDecoration(
                                                color: AppColors.neutral4,
                                                shape:
                                                    ContinuousRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6.0,
                                                          ),
                                                    ),
                                              ),
                                              child: Text(
                                                '${item.count}',
                                                style: AppTypography.tagline
                                                    .copyWith(
                                                      color:
                                                          AppColors.neutral10,
                                                      fontSize: 10,
                                                      fontFamily: 'monospace',
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(
                                              width: AppSpacing.xs,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      );

    return AppDialog(
      title: 'Filter by \'${widget.columnName}\'',
      maxWidth: 500,
      maxHeight: 620,
      footerLeading: AppButton(
        label: 'Clear All',
        variant: AppButtonVariant.ghost,
        size: AppButtonSize.small,
        onPressed: _selectedValues.isNotEmpty ? _clearAll : null,
      ),
      footerActions: [
        AppButton(
          label: 'Cancel',
          variant: AppButtonVariant.ghost,
          size: AppButtonSize.small,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          label: _selectedValues.isNotEmpty
              ? 'Apply (${_selectedValues.length})'
              : 'Apply',
          variant: AppButtonVariant.primary,
          size: AppButtonSize.small,
          onPressed: _selectedValues.isNotEmpty ? _applyFilter : null,
        ),
      ],
      child: content,
    );
  }
}
