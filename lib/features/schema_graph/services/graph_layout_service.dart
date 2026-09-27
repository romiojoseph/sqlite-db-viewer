import 'dart:ui';
import '../models/graph_edge.dart';
import '../models/graph_node.dart';

class GraphLayoutService {
  static Map<String, Offset> calculateInitialPositions(
    Map<String, GraphNode> nodes,
    List<GraphEdge> edges,
  ) {
    if (nodes.isEmpty) return {};

    final positions = <String, Offset>{};
    const nodeWidth = 230.0;
    const horizontalGap = 110.0;
    const verticalGap = 36.0;
    const startX = 60.0;
    const startY = 60.0;

    final inDegree = <String, int>{for (var k in nodes.keys) k: 0};
    final outDegree = <String, int>{for (var k in nodes.keys) k: 0};
    final adjacency = <String, List<String>>{for (var k in nodes.keys) k: []};

    for (final edge in edges) {
      if (nodes.containsKey(edge.fromTable) && nodes.containsKey(edge.toTable)) {
        if (!edge.isSelfReferencing) {
          outDegree[edge.fromTable] = (outDegree[edge.fromTable] ?? 0) + 1;
          inDegree[edge.toTable] = (inDegree[edge.toTable] ?? 0) + 1;
          adjacency[edge.toTable]!.add(edge.fromTable);
        }
      }
    }

    final connectedNodeNames = nodes.keys
        .where((k) => (inDegree[k]! > 0 || outDegree[k]! > 0))
        .toList();
    final standaloneNodeNames = nodes.keys
        .where((k) => (inDegree[k] == 0 && outDegree[k] == 0))
        .toList();

    // Assign layers for connected components
    final layers = <int, List<String>>{};
    final assigned = <String, int>{};

    final rootCandidates =
        connectedNodeNames.where((k) => outDegree[k] == 0).toList();
    final queue = <String>[];

    if (rootCandidates.isNotEmpty) {
      for (final root in rootCandidates) {
        assigned[root] = 0;
        layers.putIfAbsent(0, () => []).add(root);
        queue.add(root);
      }
    } else if (connectedNodeNames.isNotEmpty) {
      final first = connectedNodeNames.first;
      assigned[first] = 0;
      layers.putIfAbsent(0, () => []).add(first);
      queue.add(first);
    }

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final currentLayer = assigned[current]!;
      for (final neighbor in adjacency[current] ?? []) {
        if (!assigned.containsKey(neighbor)) {
          final nextLayer = currentLayer + 1;
          assigned[neighbor] = nextLayer;
          layers.putIfAbsent(nextLayer, () => []).add(neighbor);
          queue.add(neighbor);
        }
      }
    }

    for (final nodeName in connectedNodeNames) {
      if (!assigned.containsKey(nodeName)) {
        assigned[nodeName] = 0;
        layers.putIfAbsent(0, () => []).add(nodeName);
      }
    }

    final sortedLayerIndices = layers.keys.toList()..sort();
    double maxConnectedX = startX;

    for (final layerIdx in sortedLayerIndices) {
      final layerNodes = layers[layerIdx]!;
      final currentX = startX + layerIdx * (nodeWidth + horizontalGap);
      double currentY = startY;

      for (final name in layerNodes) {
        positions[name] = Offset(currentX, currentY);
        final colCount = nodes[name]?.columns.length ?? 4;
        final estHeight = (38.0 + colCount * 22.0).clamp(70.0, 320.0);
        currentY += estHeight + verticalGap;
      }

      if (currentX + nodeWidth > maxConnectedX) {
        maxConnectedX = currentX + nodeWidth;
      }
    }

    // Place standalone tables
    if (standaloneNodeNames.isNotEmpty) {
      final standaloneStartX =
          connectedNodeNames.isEmpty ? startX : maxConnectedX + horizontalGap;
      final columnsCount = connectedNodeNames.isEmpty ? 4 : 3;
      double gridX = standaloneStartX;
      double gridY = startY;
      var colIdx = 0;
      double rowMaxHeight = 0;

      for (final name in standaloneNodeNames) {
        positions[name] = Offset(gridX, gridY);
        final colCount = nodes[name]?.columns.length ?? 4;
        final estHeight = (38.0 + colCount * 22.0).clamp(70.0, 320.0);
        if (estHeight > rowMaxHeight) {
          rowMaxHeight = estHeight;
        }

        colIdx++;
        if (colIdx >= columnsCount) {
          colIdx = 0;
          gridX = standaloneStartX;
          gridY += rowMaxHeight + verticalGap;
          rowMaxHeight = 0;
        } else {
          gridX += nodeWidth + 50.0;
        }
      }
    }

    return positions;
  }
}
