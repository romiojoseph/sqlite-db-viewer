import 'dart:math';
import 'package:flutter/material.dart';
import '../../../data/models/column_filter.dart';
import '../../../data/models/query_result.dart';
import '../../../data/services/csv_export_service.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_chip.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import 'grid_header_cell.dart';
import 'grid_row.dart';
import 'pagination_controls.dart';
import 'row_count_badge.dart';

class PaginatedDataGrid extends StatefulWidget {
  final QueryResult result;
  final int currentPage;
  final int pageSize;
  final int totalRows;
  final String? sortColumn;
  final bool sortAscending;
  final List<ColumnFilter> filters;
  final ValueChanged<int>? onPageChanged;
  final ValueChanged<int>? onPageSizeChanged;
  final ValueChanged<String>? onSortChanged;
  final ValueChanged<String>? onSortAsc;
  final ValueChanged<String>? onSortDesc;
  final VoidCallback? onClearSort;
  final ValueChanged<List<ColumnFilter>>? onFiltersChanged;
  final Future<List<DistinctColumnValue>> Function(String columnName)?
  onFetchDistinctValues;
  final String? exportDefaultName;
  final Future<String?> Function()? onExportCsv;
  final Widget? trailingHeaderAction;

  const PaginatedDataGrid({
    super.key,
    required this.result,
    this.currentPage = 0,
    this.pageSize = 50,
    this.totalRows = 0,
    this.sortColumn,
    this.sortAscending = true,
    this.filters = const [],
    this.onPageChanged,
    this.onPageSizeChanged,
    this.onSortChanged,
    this.onSortAsc,
    this.onSortDesc,
    this.onClearSort,
    this.onFiltersChanged,
    this.onFetchDistinctValues,
    this.exportDefaultName,
    this.onExportCsv,
    this.trailingHeaderAction,
  });

  @override
  State<PaginatedDataGrid> createState() => _PaginatedDataGridState();
}

class _PaginatedDataGridState extends State<PaginatedDataGrid> {
  final ScrollController _horizontalHeaderController = ScrollController();
  final ScrollController _horizontalBodyController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final Map<String, double> _customColumnWidths = {};

  // Memoized — only recomputed when widget.result changes
  Map<String, double> _naturalColumnWidths = {};
  Set<String> _numericColumns = {};

  bool _isSyncingScroll = false;

  @override
  void initState() {
    super.initState();
    _horizontalBodyController.addListener(_syncHeaderFromHorizontalBody);
    _horizontalHeaderController.addListener(_syncBodyFromHorizontalHeader);
    _naturalColumnWidths = _calculateColumnWidths(
      widget.result.columns,
      widget.result.rows,
    );
    _numericColumns = _detectNumericColumns(
      widget.result.columns,
      widget.result.rows,
    );
  }

  @override
  void didUpdateWidget(PaginatedDataGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.result, oldWidget.result)) {
      _naturalColumnWidths = _calculateColumnWidths(
        widget.result.columns,
        widget.result.rows,
      );
      _numericColumns = _detectNumericColumns(
        widget.result.columns,
        widget.result.rows,
      );
      // Drop custom widths for columns no longer present
      _customColumnWidths.removeWhere(
        (key, _) => !widget.result.columns.contains(key),
      );
    }
  }

  void _syncHeaderFromHorizontalBody() {
    if (_isSyncingScroll) return;
    if (_horizontalHeaderController.hasClients) {
      _isSyncingScroll = true;
      _horizontalHeaderController.jumpTo(_horizontalBodyController.offset);
      _isSyncingScroll = false;
    }
  }

  void _syncBodyFromHorizontalHeader() {
    if (_isSyncingScroll) return;
    if (_horizontalBodyController.hasClients) {
      _isSyncingScroll = true;
      _horizontalBodyController.jumpTo(_horizontalHeaderController.offset);
      _isSyncingScroll = false;
    }
  }

  @override
  void dispose() {
    _horizontalBodyController.removeListener(_syncHeaderFromHorizontalBody);
    _horizontalHeaderController.removeListener(_syncBodyFromHorizontalHeader);
    _horizontalHeaderController.dispose();
    _horizontalBodyController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  void _onResizeColumn(
    String col,
    double delta,
    Map<String, double> currentEffectiveWidths,
  ) {
    setState(() {
      final current =
          _customColumnWidths[col] ?? (currentEffectiveWidths[col] ?? 160.0);
      final newWidth = (current + delta).clamp(60.0, 1500.0);
      _customColumnWidths[col] = newWidth;
    });
  }

  void _onResetColumnWidth(String col) {
    setState(() {
      _customColumnWidths.remove(col);
    });
  }

  void _applyFilter(ColumnFilter filter) {
    final updated = List<ColumnFilter>.from(widget.filters);
    final existingIdx = updated.indexWhere((f) => f.column == filter.column);
    if (existingIdx >= 0) {
      updated[existingIdx] = filter;
    } else {
      updated.add(filter);
    }
    widget.onFiltersChanged?.call(updated);
  }

  void _removeFilterForColumn(String column) {
    final updated = widget.filters.where((f) => f.column != column).toList();
    widget.onFiltersChanged?.call(updated);
  }

  void _removeFilter(ColumnFilter filter) {
    final updated = List<ColumnFilter>.from(widget.filters)..remove(filter);
    widget.onFiltersChanged?.call(updated);
  }

  Future<List<DistinctColumnValue>> _extractDistinctValues(String col) async {
    if (widget.onFetchDistinctValues != null) {
      return await widget.onFetchDistinctValues!(col);
    }

    final colIdx = widget.result.columns.indexOf(col);
    if (colIdx < 0) return [];

    final counts = <dynamic, int>{};
    for (final row in widget.result.rows) {
      if (colIdx < row.length) {
        final val = row[colIdx];
        counts[val] = (counts[val] ?? 0) + 1;
      }
    }

    final list = counts.entries.map((e) {
      return DistinctColumnValue(value: e.key, count: e.value);
    }).toList();

    list.sort((a, b) => b.count.compareTo(a.count));
    return list;
  }

  Map<String, double> _calculateColumnWidths(
    List<String> columns,
    List<List<dynamic>> rows,
  ) {
    final widths = <String, double>{};
    for (var i = 0; i < columns.length; i++) {
      final col = columns[i];
      double maxLen = col.length.toDouble() * 10.0 + 40.0;
      for (var r = 0; r < rows.length && r < 30; r++) {
        if (i < rows[r].length) {
          final cellStr = rows[r][i]?.toString() ?? '';
          final cellLen = cellStr.length * 8.5 + 24.0;
          if (cellLen > maxLen) maxLen = cellLen;
        }
      }
      widths[col] = maxLen.clamp(100.0, 380.0);
    }
    return widths;
  }

  Set<String> _detectNumericColumns(
    List<String> columns,
    List<List<dynamic>> rows,
  ) {
    final numeric = <String>{};
    for (var i = 0; i < columns.length; i++) {
      var allNum = true;
      var hasValue = false;
      for (var r = 0; r < rows.length && r < 30; r++) {
        if (i < rows[r].length) {
          final val = rows[r][i];
          if (val != null) {
            hasValue = true;
            if (val is! num && double.tryParse(val.toString()) == null) {
              allNum = false;
              break;
            }
          }
        }
      }
      if (hasValue && allNum) {
        numeric.add(columns[i]);
      }
    }
    return numeric;
  }

  void _handleExportCsv() async {
    final String? path;
    if (widget.onExportCsv != null) {
      path = await widget.onExportCsv!();
    } else {
      path = await CsvExportService.exportToFile(
        widget.result,
        defaultFileName: widget.exportDefaultName ?? 'export.csv',
      );
    }
    if (path != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported successfully to $path'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final columns = widget.result.columns;
    final rows = widget.result.rows;

    if (columns.isEmpty) {
      return const EmptyState(
        svgIcon: AppIcons.table,
        title: 'No Data',
        subtitle: 'The selected table or query returned no columns.',
      );
    }

    final naturalColumnWidths = _naturalColumnWidths;
    final numericColumns = _numericColumns;
    final naturalTotalWidth = naturalColumnWidths.values.fold<double>(
      50.0,
      (prev, w) => prev + w,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        const rowNumberWidth = 50.0;
        final remainingWidth = (availableWidth - rowNumberWidth).clamp(
          0.0,
          double.infinity,
        );

        final bool shouldExpandEqually =
            columns.isNotEmpty && naturalTotalWidth < availableWidth;
        final Map<String, double> baseColumnWidths;

        if (shouldExpandEqually) {
          final equalWidth = remainingWidth / columns.length;
          baseColumnWidths = {for (final col in columns) col: equalWidth};
        } else {
          baseColumnWidths = naturalColumnWidths;
        }

        final columnWidths = <String, double>{
          for (final col in columns)
            col: _customColumnWidths[col] ?? (baseColumnWidths[col] ?? 160.0),
        };

        final totalColumnsWidth = columnWidths.values.fold<double>(
          0.0,
          (prev, w) => prev + w,
        );
        final totalContentWidth = max(
          availableWidth,
          totalColumnsWidth + rowNumberWidth,
        );

        return Column(
          children: [
            // Top Toolbar
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: const BoxDecoration(
                color: AppColors.neutral2,
                border: Border(bottom: BorderSide(color: AppColors.neutral4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RowCountBadge(
                    count: widget.totalRows > 0
                        ? widget.totalRows
                        : rows.length,
                    duration: widget.result.executionDuration,
                  ),
                  Row(
                    children: [
                      if (widget.trailingHeaderAction != null) ...[
                        widget.trailingHeaderAction!,
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      AppButton(
                        label: 'Export CSV',
                        customIcon: const AppSvgIcon(AppIcons.export, size: 14),
                        variant: AppButtonVariant.outline,
                        size: AppButtonSize.small,
                        onPressed: rows.isNotEmpty ? _handleExportCsv : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Active Filters Banner (if any)
            if (widget.filters.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 4.0,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.neutral2,
                  border: Border(bottom: BorderSide(color: AppColors.neutral4)),
                ),
                child: Row(
                  children: [
                    const AppSvgIcon(
                      AppIcons.funnelSimple,
                      size: 14,
                      color: AppColors.neutral10,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Filters:',
                      style: AppTypography.tagline.copyWith(
                        color: AppColors.neutral10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final f in widget.filters) ...[
                              Padding(
                                padding: const EdgeInsets.only(
                                  right: AppSpacing.xs,
                                ),
                                child: AppChip(
                                  label: f.toDisplayString(),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs,
                                    vertical: AppSpacing.xxxs,
                                  ),
                                  onDeleted: () => _removeFilter(f),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    AppButton(
                      label: 'Clear all',
                      variant: AppButtonVariant.text,
                      size: AppButtonSize.small,
                      onPressed: () => widget.onFiltersChanged?.call([]),
                    ),
                  ],
                ),
              ),

            // Header Row
            Container(
              height: 38,
              decoration: const BoxDecoration(color: AppColors.neutral3),
              child: SingleChildScrollView(
                controller: _horizontalHeaderController,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: SizedBox(
                  width: totalContentWidth,
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          border: Border(
                            right: BorderSide(color: AppColors.neutral4),
                            bottom: BorderSide(
                              color: AppColors.neutral4,
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: Text(
                          '#',
                          style: AppTypography.tagline.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.neutral9,
                          ),
                        ),
                      ),
                      for (final col in columns) ...[
                        Builder(
                          builder: (context) {
                            final colFilter = widget.filters
                                .where((f) => f.column == col)
                                .firstOrNull;
                            final isFiltered = colFilter != null;
                            final activeValues =
                                colFilter?.values.isNotEmpty == true
                                ? colFilter!.values
                                : (colFilter?.value.isNotEmpty == true
                                      ? [colFilter!.value]
                                      : <String>[]);

                            return GridHeaderCell(
                              columnName: col,
                              width: columnWidths[col] ?? 160.0,
                              isSorted: widget.sortColumn == col,
                              sortAscending: widget.sortAscending,
                              isFiltered: isFiltered,
                              activeFilterValues: activeValues,
                              onSort: widget.onSortChanged != null
                                  ? () => widget.onSortChanged!(col)
                                  : null,
                              onSortAsc: widget.onSortAsc != null
                                  ? () => widget.onSortAsc!(col)
                                  : (widget.onSortChanged != null
                                        ? () {
                                            if (widget.sortColumn != col ||
                                                !widget.sortAscending) {
                                              widget.onSortChanged!(col);
                                            }
                                          }
                                        : null),
                              onSortDesc: widget.onSortDesc != null
                                  ? () => widget.onSortDesc!(col)
                                  : (widget.onSortChanged != null
                                        ? () {
                                            if (widget.sortColumn != col ||
                                                widget.sortAscending) {
                                              widget.onSortChanged!(col);
                                            }
                                          }
                                        : null),
                              onClearSort:
                                  widget.onClearSort ??
                                  (widget.sortColumn == col
                                      ? () => widget.onSortChanged?.call(col)
                                      : null),
                              onApplyFilter: widget.onFiltersChanged != null
                                  ? (filter) => _applyFilter(filter)
                                  : null,
                              onClearFilter: widget.onFiltersChanged != null
                                  ? () => _removeFilterForColumn(col)
                                  : null,
                              onFetchDistinctValues: () =>
                                  _extractDistinctValues(col),
                              onResize: (delta) =>
                                  _onResizeColumn(col, delta, columnWidths),
                              onResetWidth: () => _onResetColumnWidth(col),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Body Rows
            Expanded(
              child: rows.isEmpty
                  ? const EmptyState(
                      svgIcon: AppIcons.table,
                      title: 'No Rows Found',
                      subtitle: 'This table or filter returned zero records.',
                    )
                  : Scrollbar(
                      controller: _verticalController,
                      thumbVisibility: true,
                      child: Scrollbar(
                        controller: _horizontalBodyController,
                        thumbVisibility: true,
                        notificationPredicate: (notif) => notif.depth == 1,
                        child: ListView.builder(
                          controller: _verticalController,
                          itemCount: rows.length,
                          itemExtent: 34.0,
                          itemBuilder: (context, index) {
                            final displayNum =
                                (widget.currentPage * widget.pageSize) +
                                index +
                                1;
                            return SingleChildScrollView(
                              controller: index == 0 ? _horizontalBodyController : null,
                              scrollDirection: Axis.horizontal,
                              physics: const NeverScrollableScrollPhysics(),
                              child: SizedBox(
                                width: totalContentWidth,
                                child: GridRow(
                                  key: ValueKey(displayNum),
                                  rowIndex: index,
                                  displayNumber: displayNum,
                                  columns: columns,
                                  rowData: rows[index],
                                  columnWidths: columnWidths,
                                  numericColumns: numericColumns,
                                  isEven: index.isEven,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
            ),

            // Pagination Controls
            if (widget.onPageChanged != null &&
                widget.onPageSizeChanged != null)
              PaginationControls(
                currentPage: widget.currentPage,
                pageSize: widget.pageSize,
                totalRows: widget.totalRows,
                onPageChanged: widget.onPageChanged!,
                onPageSizeChanged: widget.onPageSizeChanged!,
              ),
          ],
        );
      },
    );
  }
}
