import 'package:graphview/GraphView.dart';
import '../../../data/models/db_table.dart';
import '../models/graph_edge.dart';
import '../models/graph_node.dart';

class SchemaGraphData {
  final Map<String, GraphNode> nodes;
  final List<GraphEdge> edges;
  final Graph graph;

  const SchemaGraphData({
    required this.nodes,
    required this.edges,
    required this.graph,
  });

  bool get isEmpty => nodes.isEmpty;
  bool get hasRelationships => edges.isNotEmpty;
  int get tableCount => nodes.length;
  int get relationshipCount => edges.length;
}

class SchemaGraphBuilder {
  static SchemaGraphData build(List<DbTable> tables) {
    final nodeMap = <String, GraphNode>{};
    final edgeList = <GraphEdge>{};
    final graph = Graph();
    final graphNodes = <String, Node>{};
    final addedVisualEdges = <String>{};

    for (final table in tables) {
      final pkColumns = table.columns
          .where((c) => c.isPrimaryKey)
          .map((c) => c.name)
          .toSet();

      final fkColumns = table.foreignKeys
          .map((fk) => fk.from)
          .toSet();

      final node = GraphNode(
        tableName: table.name,
        isView: table.isView,
        columns: table.columns,
        primaryKeyColumns: pkColumns,
        foreignKeyColumns: fkColumns,
        rowCount: table.rowCount,
      );

      nodeMap[table.name] = node;

      final gNode = Node.Id(table.name);
      graphNodes[table.name] = gNode;
      graph.addNode(gNode);
    }

    for (final table in tables) {
      final sourceNode = graphNodes[table.name];
      if (sourceNode == null) continue;

      for (final fk in table.foreignKeys) {
        final targetNode = graphNodes[fk.table];
        if (targetNode == null) continue;

        final edge = GraphEdge(
          fromTable: table.name,
          fromColumn: fk.from,
          toTable: fk.table,
          toColumn: fk.to,
          onDelete: fk.onDelete,
          onUpdate: fk.onUpdate,
        );

        edgeList.add(edge);

        if (sourceNode != targetNode) {
          final edgeKey = '${table.name}->${fk.table}';
          if (!addedVisualEdges.contains(edgeKey)) {
            addedVisualEdges.add(edgeKey);
            graph.addEdge(sourceNode, targetNode);
          }
        }
      }
    }

    return SchemaGraphData(
      nodes: nodeMap,
      edges: edgeList.toList(),
      graph: graph,
    );
  }
}
