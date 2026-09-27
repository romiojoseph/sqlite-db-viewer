import 'package:flutter/material.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/empty_state.dart';

class DiffEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String svgIcon;

  const DiffEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.svgIcon = AppIcons.treeStructure,
  });

  factory DiffEmptyState.identical() {
    return const DiffEmptyState(
      svgIcon: AppIcons.plusCircle,
      title: 'Databases are Identical',
      subtitle: 'No differences found across all selected tables and schemas.',
    );
  }

  factory DiffEmptyState.noTablesSelected() {
    return const DiffEmptyState(
      svgIcon: AppIcons.table,
      title: 'No Tables Selected',
      subtitle: 'Select at least one table above to run comparison.',
    );
  }

  factory DiffEmptyState.setupRequired() {
    return const DiffEmptyState(
      svgIcon: AppIcons.treeStructure,
      title: 'Select Two Databases',
      subtitle: 'Choose Database A and Database B above to compare schema and data differences.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      svgIcon: svgIcon,
      title: title,
      subtitle: subtitle,
    );
  }
}
