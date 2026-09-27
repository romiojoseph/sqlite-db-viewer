import '../../../shared/widgets/app_svg_icon.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../models/graph_node.dart';
import 'node_column_row.dart';

class TableNodeBox extends StatefulWidget {
  final GraphNode node;
  final ValueChanged<String> onTableTapped;
  final ValueChanged<String>? onNodeSelected;
  final bool isSelected;
  final bool isConnected;

  const TableNodeBox({
    super.key,
    required this.node,
    required this.onTableTapped,
    this.onNodeSelected,
    this.isSelected = false,
    this.isConnected = false,
  });

  @override
  State<TableNodeBox> createState() => _TableNodeBoxState();
}

class _TableNodeBoxState extends State<TableNodeBox> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final rowCountStr = widget.node.rowCount != null
        ? NumberFormat.compact().format(widget.node.rowCount)
        : null;

    Color borderColor = AppColors.neutral4;
    if (widget.isSelected) {
      borderColor = AppColors.neutral4;
    } else if (widget.isConnected) {
      borderColor = AppColors.neutral5;
    } else if (_isHovered) {
      borderColor = AppColors.neutral5;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          widget.onNodeSelected?.call(widget.node.tableName);
        },
        child: Material(
          color: AppColors.neutral2,
          shape: ContinuousRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
            side: BorderSide(
              color: borderColor,
              width: (widget.isSelected || widget.isConnected) ? 2 : 2.0,
            ),
          ),
          elevation: widget.isSelected ? 6.0 : (_isHovered ? 4.0 : 2.0),
          shadowColor: AppColors.neutral0.withValues(alpha: 0.4),
          clipBehavior: Clip.antiAlias,
          child: Container(
            width: 230,
            constraints: const BoxConstraints(maxHeight: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? AppColors.neutral4
                          : AppColors.neutral3,
                      border: const Border(
                        bottom: BorderSide(color: AppColors.neutral4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const AppSvgIcon(
                          AppIcons.tableFill,
                          size: 18,
                          color: AppColors.neutral8,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Expanded(
                          child: Text(
                            widget.node.tableName,
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.neutral9,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (rowCountStr != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 2.0,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.neutral0,
                              borderRadius: BorderRadius.circular(100.0),
                            ),
                            child: Text(
                              rowCountStr,
                              style: AppTypography.tagline.copyWith(
                                color: AppColors.neutral8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: AppSpacing.xxs),
                        Tooltip(
                          message: 'Open table data',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(4.0),
                            onTap: () =>
                                widget.onTableTapped(widget.node.tableName),
                            child: const Padding(
                              padding: AppSpacing.paddingXxxs,
                              child: AppSvgIcon(
                                AppIcons.arrowSquareOut,
                                size: 16,
                                color: AppColors.neutral7,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: widget.node.columns.length,
                    itemBuilder: (context, index) {
                      final col = widget.node.columns[index];
                      final isPk = widget.node.isPrimaryKey(col.name);
                      final isFk = widget.node.isForeignKey(col.name);

                      return NodeColumnRow(
                        column: col,
                        isPrimaryKey: isPk,
                        isForeignKey: isFk,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
