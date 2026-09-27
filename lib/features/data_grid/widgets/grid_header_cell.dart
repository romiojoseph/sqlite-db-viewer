import 'package:flutter/material.dart';
import '../../../data/models/column_filter.dart';
import '../../../shared/widgets/app_menu.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import 'column_filter_dialog.dart';
import 'column_value_filter_dialog.dart';

class GridHeaderCell extends StatefulWidget {
  final String columnName;
  final double width;
  final bool isSorted;
  final bool sortAscending;
  final bool isFiltered;
  final List<String> activeFilterValues;
  final String? columnType;
  final VoidCallback? onSort;
  final VoidCallback? onSortAsc;
  final VoidCallback? onSortDesc;
  final VoidCallback? onClearSort;
  final ValueChanged<ColumnFilter>? onApplyFilter;
  final VoidCallback? onClearFilter;
  final Future<List<DistinctColumnValue>> Function()? onFetchDistinctValues;
  final List<DistinctColumnValue>? distinctValues;
  final ValueChanged<double>? onResize;
  final VoidCallback? onResetWidth;

  const GridHeaderCell({
    super.key,
    required this.columnName,
    required this.width,
    this.isSorted = false,
    this.sortAscending = true,
    this.isFiltered = false,
    this.activeFilterValues = const [],
    this.columnType,
    this.onSort,
    this.onSortAsc,
    this.onSortDesc,
    this.onClearSort,
    this.onApplyFilter,
    this.onClearFilter,
    this.onFetchDistinctValues,
    this.distinctValues,
    this.onResize,
    this.onResetWidth,
  });

  @override
  State<GridHeaderCell> createState() => _GridHeaderCellState();
}

class _GridHeaderCellState extends State<GridHeaderCell> {
  bool _isHandleHovered = false;
  bool _isHeaderHovered = false;

  void _showContextMenu(BuildContext context, Offset globalPosition) async {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final selected = await showAppMenu<String>(
      context: context,
      position: globalPosition,
      minWidth: 220,
      items: [
        // Sort Ascending
        AppMenuItem<String>(
          value: 'sort_asc',
          label: 'Order by ${widget.columnName} ASC',
        ),
        // Sort Descending
        AppMenuItem<String>(
          value: 'sort_desc',
          label: 'Order by ${widget.columnName} DESC',
        ),
        if (widget.isSorted)
          const AppMenuItem<String>(
            value: 'clear_sort',
            label: 'Clear sort',
          ),
        const AppMenuItem.divider(),
        // Filter by Value (distinct values checklist)
        const AppMenuItem<String>(
          value: 'filter_by_value',
          label: 'Filter by value...',
        ),
        // Quick Filters
        AppMenuItem<String>(
          value: 'filter_null',
          label: '${widget.columnName} IS NULL',
        ),
        AppMenuItem<String>(
          value: 'filter_not_null',
          label: '${widget.columnName} IS NOT NULL',
        ),
        const AppMenuItem.divider(),
        // Custom Operator Filters
        AppMenuItem<String>(
          value: 'filter_equals',
          label: '${widget.columnName} = ..',
        ),
        AppMenuItem<String>(
          value: 'filter_not_equals',
          label: '${widget.columnName} <> ..',
        ),
        AppMenuItem<String>(
          value: 'filter_greater',
          label: '${widget.columnName} > ..',
        ),
        AppMenuItem<String>(
          value: 'filter_less',
          label: '${widget.columnName} < ..',
        ),
        AppMenuItem<String>(
          value: 'filter_like',
          label: '${widget.columnName} LIKE ..',
        ),
        if (widget.isFiltered) ...[
          const AppMenuItem.divider(),
          AppMenuItem<String>(
            value: 'clear_filter',
            label: 'Clear filter on ${widget.columnName}',
            isDestructive: true,
          ),
        ],
      ],
    );

    if (!mounted || selected == null) return;

    switch (selected) {
      case 'sort_asc':
        widget.onSortAsc?.call();
        break;
      case 'sort_desc':
        widget.onSortDesc?.call();
        break;
      case 'clear_sort':
        widget.onClearSort?.call();
        break;
      case 'filter_null':
        widget.onApplyFilter?.call(
          ColumnFilter(
            column: widget.columnName,
            operator: FilterOperator.isNull,
          ),
        );
        break;
      case 'filter_not_null':
        widget.onApplyFilter?.call(
          ColumnFilter(
            column: widget.columnName,
            operator: FilterOperator.isNotNull,
          ),
        );
        break;
      case 'filter_by_value':
        _openValueFilterDialog();
        break;
      case 'filter_equals':
        _openFilterDialog(FilterOperator.equals);
        break;
      case 'filter_not_equals':
        _openFilterDialog(FilterOperator.notEquals);
        break;
      case 'filter_greater':
        _openFilterDialog(FilterOperator.greaterThan);
        break;
      case 'filter_less':
        _openFilterDialog(FilterOperator.lessThan);
        break;
      case 'filter_like':
        _openFilterDialog(FilterOperator.contains);
        break;
      case 'clear_filter':
        widget.onClearFilter?.call();
        break;
    }
  }

  void _openValueFilterDialog() async {
    List<DistinctColumnValue> values = widget.distinctValues ?? [];
    if (values.isEmpty && widget.onFetchDistinctValues != null) {
      values = await widget.onFetchDistinctValues!();
    }

    if (!mounted) return;

    final filter = await ColumnValueFilterDialog.show(
      context,
      columnName: widget.columnName,
      distinctValues: values,
      initialSelectedValues: widget.activeFilterValues,
    );

    if (filter != null && mounted) {
      widget.onApplyFilter?.call(filter);
    }
  }

  void _openFilterDialog(FilterOperator initialOperator) async {
    final filter = await ColumnFilterDialog.show(
      context,
      columnName: widget.columnName,
      columnType: widget.columnType,
      initialOperator: initialOperator,
    );
    if (filter != null && mounted) {
      widget.onApplyFilter?.call(filter);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHeaderHovered = true),
      onExit: (_) => setState(() => _isHeaderHovered = false),
      child: Container(
        width: widget.width,
        height: 38,
        decoration: BoxDecoration(
          color: widget.isFiltered ? AppColors.neutral4 : AppColors.neutral3,
          border: const Border(
            right: BorderSide(color: AppColors.neutral4),
            bottom: BorderSide(color: AppColors.neutral4, width: 1.0),
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onSecondaryTapDown: (details) {
                  _showContextMenu(context, details.globalPosition);
                },
                child: InkWell(
                  onTap: widget.onSort,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.columnName,
                            style: AppTypography.caption.copyWith(
                              fontWeight: FontWeight.w500,
                              color: (widget.isSorted || widget.isFiltered)
                                  ? AppColors.neutral12
                                  : AppColors.neutral9,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.isFiltered) ...[
                          const SizedBox(width: AppSpacing.xxxs),
                          const Tooltip(
                            message: 'Filtered column',
                            child: AppSvgIcon(
                              AppIcons.funnelSimple,
                              size: 13,
                              color: AppColors.neutral12,
                            ),
                          ),
                        ],
                        if (widget.isSorted) ...[
                          const SizedBox(width: AppSpacing.xxxs),
                          AppSvgIcon(
                            widget.sortAscending
                                ? AppIcons.caretUp
                                : AppIcons.caretDown,
                            size: 13,
                            color: AppColors.neutral12,
                          ),
                        ],
                        if (_isHeaderHovered ||
                            widget.isSorted ||
                            widget.isFiltered) ...[
                          const SizedBox(width: AppSpacing.xxxs),
                          GestureDetector(
                            onTapDown: (details) {
                              _showContextMenu(context, details.globalPosition);
                            },
                            child: const Padding(
                              padding: AppSpacing.paddingXxxs,
                              child: AppSvgIcon(
                                AppIcons.caretDown,
                                size: 12,
                                color: AppColors.neutral10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (widget.onResize != null)
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                width: 10,
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  onEnter: (_) => setState(() => _isHandleHovered = true),
                  onExit: (_) => setState(() => _isHandleHovered = false),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragUpdate: (details) {
                      widget.onResize!(details.delta.dx);
                    },
                    onDoubleTap: widget.onResetWidth,
                    child: Container(
                      width: 10,
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 2,
                        height: double.infinity,
                        color: _isHandleHovered
                            ? AppColors.neutral8
                            : Colors.transparent,
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
