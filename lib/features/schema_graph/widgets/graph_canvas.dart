import 'package:flutter/material.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../models/graph_edge.dart';
import '../models/graph_node.dart';
import '../services/graph_layout_service.dart';
import '../services/schema_graph_builder.dart';
import 'table_node_box.dart';

class GraphCanvas extends StatefulWidget {
  final SchemaGraphData graphData;
  final ValueChanged<String> onTableSelected;
  final TransformationController transformationController;

  const GraphCanvas({
    super.key,
    required this.graphData,
    required this.onTableSelected,
    required this.transformationController,
  });

  @override
  State<GraphCanvas> createState() => _GraphCanvasState();
}

class _GraphCanvasState extends State<GraphCanvas> {
  Map<String, Offset> _nodePositions = {};
  String? _selectedTable;

  @override
  void initState() {
    super.initState();
    _initPositions();
  }

  @override
  void didUpdateWidget(GraphCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.graphData != widget.graphData) {
      _initPositions();
    }
  }

  void _initPositions() {
    _nodePositions = GraphLayoutService.calculateInitialPositions(
      widget.graphData.nodes,
      widget.graphData.edges,
    );
  }

  Set<String> _getConnectedTables(String tableName) {
    final connected = <String>{};
    for (final edge in widget.graphData.edges) {
      if (edge.fromTable.toLowerCase() == tableName.toLowerCase()) {
        connected.add(edge.toTable);
      } else if (edge.toTable.toLowerCase() == tableName.toLowerCase()) {
        connected.add(edge.fromTable);
      }
    }
    return connected;
  }

  List<GraphEdge> _getEdgesForTable(String tableName) {
    return widget.graphData.edges.where((e) {
      return e.fromTable.toLowerCase() == tableName.toLowerCase() ||
          e.toTable.toLowerCase() == tableName.toLowerCase();
    }).toList();
  }

  void _onNodeSelected(String tableName) {
    setState(() {
      if (_selectedTable == tableName) {
        _selectedTable = null;
      } else {
        _selectedTable = tableName;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final connectedSet = _selectedTable != null
        ? _getConnectedTables(_selectedTable!)
        : null;

    final tableEdges = _selectedTable != null
        ? _getEdgesForTable(_selectedTable!)
        : null;

    // Calculate canvas bounds
    double maxX = 1200.0;
    double maxY = 900.0;
    for (final pos in _nodePositions.values) {
      if (pos.dx + 400 > maxX) maxX = pos.dx + 400;
      if (pos.dy + 500 > maxY) maxY = pos.dy + 500;
    }

    return Stack(
      children: [
        InteractiveViewer(
          transformationController: widget.transformationController,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(1200.0),
          minScale: 0.1,
          maxScale: 3.5,
          child: SizedBox(
            width: maxX,
            height: maxY,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RelationshipPainter(
                      nodePositions: _nodePositions,
                      nodes: widget.graphData.nodes,
                      edges: widget.graphData.edges,
                      selectedTable: _selectedTable,
                    ),
                  ),
                ),
                for (final entry in widget.graphData.nodes.entries)
                  if (_nodePositions.containsKey(entry.key))
                    Positioned(
                      left: _nodePositions[entry.key]!.dx,
                      top: _nodePositions[entry.key]!.dy,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            _nodePositions[entry.key] =
                                _nodePositions[entry.key]! + details.delta;
                          });
                        },
                        child: TableNodeBox(
                          node: entry.value,
                          onTableTapped: widget.onTableSelected,
                          onNodeSelected: _onNodeSelected,
                          isSelected: _selectedTable == entry.key,
                          isConnected:
                              connectedSet?.contains(entry.key) ?? false,
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
        if (_selectedTable != null &&
            tableEdges != null &&
            tableEdges.isNotEmpty)
          Positioned(
            left: 16,
            bottom: 16,
            child: Material(
              color: AppColors.neutral1,
              shape: ContinuousRectangleBorder(
                borderRadius: BorderRadius.circular(24.0),
                side: const BorderSide(color: AppColors.neutral3, width: 1.0),
              ),
              elevation: 6.0,
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 380,
                  maxHeight: 240,
                ),
                padding: AppSpacing.paddingLg,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Relationships: $_selectedTable',
                              style: AppTypography.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.neutral7,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const AppSvgIcon(
                            AppIcons.x,
                            size: 16,
                            color: AppColors.neutral6,
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            setState(() {
                              _selectedTable = null;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: tableEdges.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 8, color: AppColors.neutral4),
                        itemBuilder: (context, idx) {
                          final edge = tableEdges[idx];
                          final isSource =
                              edge.fromTable.toLowerCase() ==
                              _selectedTable!.toLowerCase();

                          return Row(
                            children: [
                              AppSvgIcon(
                                isSource
                                    ? AppIcons.caretRight
                                    : AppIcons.caretLeft,
                                size: 12,
                                color: AppColors.neutral7,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  '${edge.fromTable}.${edge.fromColumn} -> ${edge.toTable}.${edge.toColumn}',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.neutral7,
                                    fontFamily: 'monospace',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RelationshipPainter extends CustomPainter {
  final Map<String, Offset> nodePositions;
  final Map<String, GraphNode> nodes;
  final List<GraphEdge> edges;
  final String? selectedTable;

  const _RelationshipPainter({
    required this.nodePositions,
    required this.nodes,
    required this.edges,
    this.selectedTable,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const nodeWidth = 230.0;

    for (final edge in edges) {
      final fromPos = nodePositions[edge.fromTable];
      final toPos = nodePositions[edge.toTable];
      if (fromPos == null || toPos == null) continue;

      final isFromSelected =
          selectedTable != null &&
          edge.fromTable.toLowerCase() == selectedTable!.toLowerCase();
      final isToSelected =
          selectedTable != null &&
          edge.toTable.toLowerCase() == selectedTable!.toLowerCase();
      final isHighlighted = isFromSelected || isToSelected;
      final isDimmed = selectedTable != null && !isHighlighted;

      final Color strokeColor;
      final double strokeWidth;
      if (isHighlighted) {
        strokeColor = AppColors.neutral6;
        strokeWidth = 2.0;
      } else if (isDimmed) {
        strokeColor = AppColors.neutral3;
        strokeWidth = 1.0;
      } else {
        strokeColor = AppColors.neutral4;
        strokeWidth = 1.6;
      }

      final paint = Paint()
        ..color = strokeColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (edge.isSelfReferencing) {
        final start = Offset(fromPos.dx + nodeWidth, fromPos.dy + 24);
        final end = Offset(fromPos.dx + nodeWidth - 24, fromPos.dy);
        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..cubicTo(
            start.dx + 40,
            start.dy - 10,
            end.dx + 30,
            end.dy - 40,
            end.dx,
            end.dy,
          );
        canvas.drawPath(path, paint);
        _drawArrow(canvas, Offset(end.dx + 10, end.dy - 10), end, paint);
        continue;
      }

      final fromNode = nodes[edge.fromTable];
      final toNode = nodes[edge.toTable];

      final fromColIdx =
          fromNode?.columns.indexWhere((c) => c.name == edge.fromColumn) ?? 0;
      final toColIdx =
          toNode?.columns.indexWhere((c) => c.name == edge.toColumn) ?? 0;

      final fromYOffset =
          (38.0 + (fromColIdx >= 0 ? fromColIdx : 0) * 22.0 + 11.0).clamp(
            20.0,
            300.0,
          );
      final toYOffset = (38.0 + (toColIdx >= 0 ? toColIdx : 0) * 22.0 + 11.0)
          .clamp(20.0, 300.0);

      final Offset sourceAnchor;
      final Offset targetAnchor;
      final double dx = (toPos.dx - fromPos.dx).abs();

      if (fromPos.dx + nodeWidth <= toPos.dx) {
        sourceAnchor = Offset(fromPos.dx + nodeWidth, fromPos.dy + fromYOffset);
        targetAnchor = Offset(toPos.dx, toPos.dy + toYOffset);
      } else if (toPos.dx + nodeWidth <= fromPos.dx) {
        sourceAnchor = Offset(fromPos.dx, fromPos.dy + fromYOffset);
        targetAnchor = Offset(toPos.dx + nodeWidth, toPos.dy + toYOffset);
      } else {
        if (fromPos.dy < toPos.dy) {
          sourceAnchor = Offset(
            fromPos.dx + nodeWidth * 0.5,
            fromPos.dy + fromYOffset,
          );
          targetAnchor = Offset(toPos.dx + nodeWidth * 0.5, toPos.dy);
        } else {
          sourceAnchor = Offset(fromPos.dx + nodeWidth * 0.5, fromPos.dy);
          targetAnchor = Offset(
            toPos.dx + nodeWidth * 0.5,
            toPos.dy + toYOffset,
          );
        }
      }

      final path = Path()..moveTo(sourceAnchor.dx, sourceAnchor.dy);
      final curvature = (dx * 0.5).clamp(30.0, 140.0);

      if (sourceAnchor.dx < targetAnchor.dx) {
        path.cubicTo(
          sourceAnchor.dx + curvature,
          sourceAnchor.dy,
          targetAnchor.dx - curvature,
          targetAnchor.dy,
          targetAnchor.dx,
          targetAnchor.dy,
        );
      } else {
        path.cubicTo(
          sourceAnchor.dx - curvature,
          sourceAnchor.dy,
          targetAnchor.dx + curvature,
          targetAnchor.dy,
          targetAnchor.dx,
          targetAnchor.dy,
        );
      }

      canvas.drawPath(path, paint);

      final dotPaint = Paint()
        ..color = strokeColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(sourceAnchor, isHighlighted ? 3.5 : 2.5, dotPaint);

      final arrowFrom = Offset(
        targetAnchor.dx + (sourceAnchor.dx < targetAnchor.dx ? -8 : 8),
        targetAnchor.dy,
      );
      _drawArrow(canvas, arrowFrom, targetAnchor, paint);
    }
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Paint paint) {
    final dir = (to - from);
    if (dir.distance == 0) return;
    final unit = dir / dir.distance;
    final normal = Offset(-unit.dy, unit.dx);
    const arrowSize = 6.0;

    final p1 = to - unit * arrowSize + normal * (arrowSize * 0.6);
    final p2 = to - unit * arrowSize - normal * (arrowSize * 0.6);

    final arrowPath = Path()
      ..moveTo(to.dx, to.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();

    final fillPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;
    canvas.drawPath(arrowPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _RelationshipPainter oldDelegate) {
    return oldDelegate.nodePositions != nodePositions ||
        oldDelegate.selectedTable != selectedTable ||
        oldDelegate.edges != edges;
  }
}
