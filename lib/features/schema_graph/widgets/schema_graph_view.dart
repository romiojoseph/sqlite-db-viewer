import 'package:flutter/material.dart';
import '../../../data/models/db_table.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../services/schema_graph_builder.dart';
import 'graph_canvas.dart';
import 'graph_toolbar.dart';

class SchemaGraphView extends StatefulWidget {
  final List<DbTable> tables;
  final ValueChanged<String> onTableSelected;

  const SchemaGraphView({
    super.key,
    required this.tables,
    required this.onTableSelected,
  });

  @override
  State<SchemaGraphView> createState() => _SchemaGraphViewState();
}

class _SchemaGraphViewState extends State<SchemaGraphView> {
  final TransformationController _transformationController =
      TransformationController();
  late SchemaGraphData _graphData;
  int _layoutKey = 0;

  @override
  void initState() {
    super.initState();
    _buildGraph();
  }

  @override
  void didUpdateWidget(SchemaGraphView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tables != widget.tables) {
      _buildGraph();
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _buildGraph() {
    setState(() {
      _graphData = SchemaGraphBuilder.build(widget.tables);
    });
  }

  void _zoomIn() {
    final matrix = _transformationController.value.clone();
    matrix.scaleByDouble(1.2, 1.2, 1.0, 1.0);
    _transformationController.value = matrix;
  }

  void _zoomOut() {
    final matrix = _transformationController.value.clone();
    matrix.scaleByDouble(0.833, 0.833, 1.0, 1.0);
    _transformationController.value = matrix;
  }

  void _resetView() {
    _transformationController.value = Matrix4.identity();
  }

  void _relayout() {
    setState(() {
      _layoutKey++;
      _graphData = SchemaGraphBuilder.build(widget.tables);
      _resetView();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tables.isEmpty) {
      return const EmptyState(
        svgIcon: AppIcons.graph,
        title: 'No Tables Found',
        subtitle: 'The open database contains zero tables or views to graph.',
      );
    }

    return Container(
      color: AppColors.neutral1,
      child: Stack(
        children: [
          Positioned.fill(
            child: GraphCanvas(
              key: ValueKey(_layoutKey),
              graphData: _graphData,
              onTableSelected: widget.onTableSelected,
              transformationController: _transformationController,
            ),
          ),
          if (!_graphData.hasRelationships)
            Positioned(
              top: 16,
              left: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppSvgIcon(
                    AppIcons.info,
                    size: 16,
                    color: AppColors.neutral7,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'No foreign keys defined; tables shown as standalone entities.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.neutral8,
                    ),
                  ),
                ],
              ),
            ),
          Positioned(
            top: 16,
            right: 16,
            child: GraphToolbar(
              onZoomIn: _zoomIn,
              onZoomOut: _zoomOut,
              onResetView: _resetView,
              onRelayout: _relayout,
              tableCount: _graphData.tableCount,
              relationshipCount: _graphData.relationshipCount,
            ),
          ),
        ],
      ),
    );
  }
}
