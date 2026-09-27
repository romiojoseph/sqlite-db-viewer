import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/services/csv_export_service.dart';
import '../../../shared/widgets/app_menu.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import 'cell_value_renderer.dart';

class GridRow extends StatefulWidget {
  final int rowIndex;
  final int displayNumber;
  final List<String> columns;
  final List<dynamic> rowData;
  final Map<String, double> columnWidths;
  final Set<String> numericColumns;
  final bool isEven;

  const GridRow({
    super.key,
    required this.rowIndex,
    required this.displayNumber,
    required this.columns,
    required this.rowData,
    required this.columnWidths,
    required this.numericColumns,
    required this.isEven,
  });

  @override
  State<GridRow> createState() => _GridRowState();
}

class _GridRowState extends State<GridRow> {
  bool _isHovered = false;

  void _showContextMenu(BuildContext context, Offset globalPosition) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final messenger = ScaffoldMessenger.of(context);

    final selected = await showAppMenu<String>(
      context: context,
      position: globalPosition,
      minWidth: 200,
      items: const [
        AppMenuItem<String>(
          value: 'csv',
          label: 'Copy Row as CSV',
        ),
        AppMenuItem<String>(
          value: 'tsv',
          label: 'Copy Row as TSV',
        ),
        AppMenuItem<String>(
          value: 'json',
          label: 'Copy Row as JSON',
        ),
      ],
    );

    if (selected != null && mounted) {
      String textToCopy = '';
      if (selected == 'csv') {
        textToCopy = CsvExportService.formatSingleRowAsCsv(widget.columns, widget.rowData);
      } else if (selected == 'tsv') {
        textToCopy = CsvExportService.formatSingleRowAsTsv(widget.columns, widget.rowData);
      } else if (selected == 'json') {
        textToCopy = CsvExportService.formatSingleRowAsJson(widget.columns, widget.rowData);
      }

      await Clipboard.setData(ClipboardData(text: textToCopy));
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Row copied as ${selected.toUpperCase()}'),
            duration: const Duration(milliseconds: 900),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    if (_isHovered) {
      bg = AppColors.neutral4.withValues(alpha: 0.8);
    } else if (widget.isEven) {
      bg = AppColors.neutral2;
    } else {
      bg = AppColors.neutral3.withValues(alpha: 0.35);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onSecondaryTapUp: (details) => _showContextMenu(context, details.globalPosition),
        child: Container(
          height: 34,
          color: bg,
          child: Row(
            children: [
              Container(
                width: 50,
                height: 34,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: AppColors.neutral3,
                    ),
                    bottom: BorderSide(
                      color: AppColors.neutral3,
                    ),
                  ),
                ),
                child: Text(
                  widget.displayNumber.toString(),
                  style: AppTypography.tagline.copyWith(
                    color: AppColors.neutral9,
                  ),
                ),
              ),
              for (var i = 0; i < widget.columns.length; i++) ...[
                _buildCell(context, i),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCell(BuildContext context, int colIndex) {
    final colName = widget.columns[colIndex];
    final colWidth = widget.columnWidths[colName] ?? 160.0;
    final val = colIndex < widget.rowData.length ? widget.rowData[colIndex] : null;
    final isNum = widget.numericColumns.contains(colName);

    return Container(
      width: colWidth,
      height: 34,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2.0,
      ),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(
            color: AppColors.neutral3,
          ),
          bottom: BorderSide(
            color: AppColors.neutral3,
          ),
        ),
      ),
      child: ClipRect(
        child: CellValueRenderer(
          value: val,
          columnName: colName,
          isNumericColumn: isNum,
        ),
      ),
    );
  }
}
