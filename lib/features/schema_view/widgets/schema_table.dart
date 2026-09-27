import 'package:flutter/material.dart';
import '../../../data/models/db_foreign_key.dart';
import '../../../data/models/db_table.dart';
import '../../../data/models/db_trigger.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import 'column_row.dart';
import 'foreign_key_badge.dart';
import 'index_list.dart';

enum TablePropertySection {
  columns,
  keys,
  foreignKeys,
  indexes,
  references,
  triggers,
  ddl,
  virtualStats,
}

class InboundReference {
  final String sourceTable;
  final DbForeignKey foreignKey;

  const InboundReference({required this.sourceTable, required this.foreignKey});
}

class SchemaTable extends StatefulWidget {
  final DbTable table;
  final List<DbTable> allTables;
  final List<DbTrigger> triggers;
  final ValueChanged<String>? onNavigateToTable;

  const SchemaTable({
    super.key,
    required this.table,
    this.allTables = const [],
    this.triggers = const [],
    this.onNavigateToTable,
  });

  @override
  State<SchemaTable> createState() => _SchemaTableState();
}

class _SchemaTableState extends State<SchemaTable> {
  TablePropertySection _selectedSection = TablePropertySection.columns;
  final TextEditingController _columnSearchController = TextEditingController();
  String _columnSearchQuery = '';

  @override
  void dispose() {
    _columnSearchController.dispose();
    super.dispose();
  }

  List<InboundReference> get _inboundReferences {
    final refs = <InboundReference>[];
    for (final otherTable in widget.allTables) {
      for (final fk in otherTable.foreignKeys) {
        if (fk.table.toLowerCase() == widget.table.name.toLowerCase()) {
          refs.add(
            InboundReference(sourceTable: otherTable.name, foreignKey: fk),
          );
        }
      }
    }
    return refs;
  }

  List<DbTrigger> get _tableTriggers {
    return widget.triggers
        .where(
          (t) => t.tableName.toLowerCase() == widget.table.name.toLowerCase(),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final inboundRefs = _inboundReferences;
    final tableTriggers = _tableTriggers;
    final primaryKeys = widget.table.columns
        .where((c) => c.isPrimaryKey)
        .toList();
    final uniqueIndexes = widget.table.indexes.where((i) => i.unique).toList();
    final totalKeysCount = primaryKeys.length + uniqueIndexes.length;

    return Container(
      color: AppColors.neutral1,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Property Navigation Sidebar
          Container(
            width: 190,
            decoration: const BoxDecoration(
              color: AppColors.neutral2,
              border: Border(right: BorderSide(color: AppColors.neutral4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Table Info
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.neutral4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.table.name,
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.neutral8,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Navigation Items List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    children: [
                      _buildNavItem(
                        section: TablePropertySection.columns,
                        svgIcon: AppIcons.table,
                        label: 'Columns',
                        count: widget.table.columns.length,
                      ),
                      _buildNavItem(
                        section: TablePropertySection.keys,
                        svgIcon: AppIcons.key,
                        label: 'Keys',
                        count: totalKeysCount,
                      ),
                      _buildNavItem(
                        section: TablePropertySection.foreignKeys,
                        svgIcon: AppIcons.splitHorizontal,
                        label: 'Foreign Keys',
                        count: widget.table.foreignKeys.length,
                      ),
                      _buildNavItem(
                        section: TablePropertySection.indexes,
                        svgIcon: AppIcons.treeStructure,
                        label: 'Indexes',
                        count: widget.table.indexes.length,
                      ),
                      _buildNavItem(
                        section: TablePropertySection.references,
                        svgIcon: AppIcons.treeStructure,
                        label: 'References',
                        count: inboundRefs.length,
                      ),
                      _buildNavItem(
                        section: TablePropertySection.triggers,
                        svgIcon: AppIcons.play,
                        label: 'Triggers',
                        count: tableTriggers.length,
                      ),
                      _buildNavItem(
                        section: TablePropertySection.ddl,
                        svgIcon: AppIcons.fileSql,
                        label: 'DDL',
                      ),
                      _buildNavItem(
                        section: TablePropertySection.virtualStats,
                        svgIcon: AppIcons.info,
                        label: 'Virtual / Stats',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right Content Area
          Expanded(
            child: _buildSectionContent(
              inboundRefs: inboundRefs,
              tableTriggers: tableTriggers,
              primaryKeys: primaryKeys,
              uniqueIndexes: uniqueIndexes,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required TablePropertySection section,
    String? svgIcon,
    IconData? icon,
    required String label,
    int? count,
  }) {
    final isSelected = _selectedSection == section;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 1,
      ),
      child: Material(
        color: isSelected ? AppColors.neutral3 : Colors.transparent,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          customBorder: const ContinuousRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          hoverColor: AppColors.neutral3,
          onTap: () => setState(() => _selectedSection = section),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                if (svgIcon != null)
                  AppSvgIcon(
                    svgIcon,
                    size: 14,
                    color: isSelected ? AppColors.neutral8 : AppColors.neutral7,
                  )
                else if (icon != null)
                  Icon(
                    icon,
                    size: 14,
                    color: isSelected ? AppColors.neutral8 : AppColors.neutral7,
                  ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.caption.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w500
                          : FontWeight.normal,
                      color: isSelected
                          ? AppColors.neutral8
                          : AppColors.neutral7,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (count != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xxxs,
                    ),
                    decoration: ShapeDecoration(
                      color: AppColors.neutral4,
                      shape: ContinuousRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                    child: Text(
                      '$count',
                      style: AppTypography.tagline.copyWith(
                        color: AppColors.neutral8,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionContent({
    required List<InboundReference> inboundRefs,
    required List<DbTrigger> tableTriggers,
    required List<dynamic> primaryKeys,
    required List<dynamic> uniqueIndexes,
  }) {
    switch (_selectedSection) {
      case TablePropertySection.columns:
        return _buildColumnsView();
      case TablePropertySection.keys:
        return _buildKeysView(primaryKeys, uniqueIndexes);
      case TablePropertySection.foreignKeys:
        return _buildForeignKeysView();
      case TablePropertySection.indexes:
        return _buildIndexesView();
      case TablePropertySection.references:
        return _buildReferencesView(inboundRefs);
      case TablePropertySection.triggers:
        return _buildTriggersView(tableTriggers);
      case TablePropertySection.ddl:
        return _buildDdlView();
      case TablePropertySection.virtualStats:
        return _buildVirtualStatsView(inboundRefs, tableTriggers);
    }
  }

  Widget _buildColumnsView() {
    final filtered = widget.table.columns.where((col) {
      if (_columnSearchQuery.isEmpty) return true;
      final q = _columnSearchQuery.toLowerCase();
      return col.name.toLowerCase().contains(q) ||
          col.type.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: const BoxDecoration(
            color: AppColors.neutral2,
            border: Border(bottom: BorderSide(color: AppColors.neutral4)),
          ),
          child: Row(
            children: [
              Text(
                'Columns (${widget.table.columns.length})',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.neutral8,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 220,
                child: AppTextField(
                  controller: _columnSearchController,
                  hintText: 'Filter columns...',
                  size: AppInputSize.small,
                  customPrefixIcon: const AppSvgIcon(
                    AppIcons.magnifyingGlass,
                    size: 14,
                    color: AppColors.neutral7,
                  ),
                  suffixIcon: _columnSearchQuery.isNotEmpty
                      ? InkWell(
                          onTap: () {
                            _columnSearchController.clear();
                            setState(() => _columnSearchQuery = '');
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: AppSpacing.paddingXxs,
                            child: AppSvgIcon(
                              AppIcons.x,
                              size: 12,
                              color: AppColors.neutral7,
                            ),
                          ),
                        )
                      : null,
                  onChanged: (v) => setState(() => _columnSearchQuery = v),
                ),
              ),
            ],
          ),
        ),

        // Table Header
        Container(
          color: AppColors.neutral3,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  'PK',
                  style: AppTypography.tagline.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral7,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 3,
                child: Text(
                  'COLUMN NAME',
                  style: AppTypography.tagline.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral7,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'DATA TYPE',
                  style: AppTypography.tagline.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral7,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'NULLABILITY',
                  style: AppTypography.tagline.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral7,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'DEFAULT',
                  style: AppTypography.tagline.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral7,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Column Rows List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'No matching columns found',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.neutral7,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return ColumnRow(
                      column: filtered[index],
                      isEven: index.isEven,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildKeysView(
    List<dynamic> primaryKeys,
    List<dynamic> uniqueIndexes,
  ) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Primary Key',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.neutral8,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (primaryKeys.isEmpty)
            Text(
              'No explicit PRIMARY KEY defined on this table.',
              style: AppTypography.caption.copyWith(
                color: AppColors.neutral7,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Container(
              decoration: ShapeDecoration(
                color: AppColors.neutral2,
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  side: const BorderSide(color: AppColors.neutral4, width: 1.0),
                ),
              ),
              child: Column(
                children: [
                  for (final col in primaryKeys)
                    ListTile(
                      dense: true,
                      leading: const AppSvgIcon(
                        AppIcons.key,
                        size: 16,
                        color: AppColors.neutral8,
                      ),
                      title: Text(
                        col.name,
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.neutral8,
                        ),
                      ),
                      subtitle: Text(
                        'Type: ${col.type.isEmpty ? "TEXT" : col.type}',
                        style: AppTypography.tagline.copyWith(
                          color: AppColors.neutral7,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: AppSpacing.xxxs,
                        ),
                        decoration: ShapeDecoration(
                          color: AppColors.neutral4,
                          shape: ContinuousRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                        ),
                        child: Text(
                          'PRIMARY KEY',
                          style: AppTypography.tagline.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.neutral8,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Unique Constraints & Unique Indexes (${uniqueIndexes.length})',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.neutral8,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (uniqueIndexes.isEmpty)
            Text(
              'No unique constraints or unique indexes found.',
              style: AppTypography.caption.copyWith(
                color: AppColors.neutral7,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            IndexList(indexes: uniqueIndexes.cast()),
        ],
      ),
    );
  }

  Widget _buildForeignKeysView() {
    return SingleChildScrollView(
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Outbound Foreign Keys (${widget.table.foreignKeys.length})',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.neutral8,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Foreign keys defined on "${widget.table.name}" pointing to parent tables:',
            style: AppTypography.tagline.copyWith(color: AppColors.neutral7),
          ),
          const SizedBox(height: AppSpacing.md),
          if (widget.table.foreignKeys.isEmpty)
            Text(
              'No outbound foreign key relationships defined on this table.',
              style: AppTypography.caption.copyWith(
                color: AppColors.neutral7,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            for (final fk in widget.table.foreignKeys)
              ForeignKeyBadge(foreignKey: fk),
        ],
      ),
    );
  }

  Widget _buildIndexesView() {
    return SingleChildScrollView(
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Indexes (${widget.table.indexes.length})',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.neutral8,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          IndexList(indexes: widget.table.indexes),
        ],
      ),
    );
  }

  Widget _buildReferencesView(List<InboundReference> inboundRefs) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inbound References (${inboundRefs.length})',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.neutral8,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Other tables that reference "${widget.table.name}" via foreign keys:',
            style: AppTypography.tagline.copyWith(color: AppColors.neutral7),
          ),
          const SizedBox(height: AppSpacing.md),
          if (inboundRefs.isEmpty)
            Text(
              'No other tables currently reference "${widget.table.name}".',
              style: AppTypography.caption.copyWith(
                color: AppColors.neutral7,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            for (final ref in inboundRefs)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: ShapeDecoration(
                  color: AppColors.neutral2,
                  shape: ContinuousRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    side: const BorderSide(color: AppColors.neutral4, width: 1.0),
                  ),
                ),
                child: Row(
                  children: [
                    const AppSvgIcon(
                      AppIcons.splitHorizontal,
                      size: 16,
                      color: AppColors.neutral8,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${ref.sourceTable}.${ref.foreignKey.from}',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutral8,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                      child: AppSvgIcon(
                        AppIcons.caretRight,
                        size: 14,
                        color: AppColors.neutral7,
                      ),
                    ),
                    Text(
                      '${widget.table.name}.${ref.foreignKey.to}',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutral8,
                      ),
                    ),
                    const Spacer(),
                    if (widget.onNavigateToTable != null)
                      AppButton(
                        label: 'Open ${ref.sourceTable}',
                        customIcon: const AppSvgIcon(
                          AppIcons.arrowSquareOut,
                          size: 12,
                        ),
                        variant: AppButtonVariant.outline,
                        size: AppButtonSize.small,
                        onPressed: () =>
                            widget.onNavigateToTable!(ref.sourceTable),
                      ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildTriggersView(List<DbTrigger> tableTriggers) {
    return SingleChildScrollView(
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Triggers (${tableTriggers.length})',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.neutral8,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Triggers defined to execute on "${widget.table.name}":',
            style: AppTypography.tagline.copyWith(color: AppColors.neutral7),
          ),
          const SizedBox(height: AppSpacing.md),
          if (tableTriggers.isEmpty)
            Text(
              'No triggers defined for this table.',
              style: AppTypography.caption.copyWith(
                color: AppColors.neutral7,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            for (final trg in tableTriggers)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding: AppSpacing.paddingMd,
                decoration: ShapeDecoration(
                  color: AppColors.neutral2,
                  shape: ContinuousRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    side: const BorderSide(color: AppColors.neutral4, width: 1.0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const AppSvgIcon(
                          AppIcons.play,
                          size: 16,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          trg.name,
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.neutral8,
                          ),
                        ),
                      ],
                    ),
                    if (trg.sql != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        width: double.infinity,
                        padding: AppSpacing.paddingSm,
                        decoration: ShapeDecoration(
                          color: AppColors.neutral1,
                          shape: ContinuousRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                            side: const BorderSide(color: AppColors.neutral4, width: 1.0),
                          ),
                        ),
                        child: SelectableText(
                          trg.sql!,
                          style: AppTypography.body.copyWith(
                            color: AppColors.neutral8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildDdlView() {
    final ddlSql = widget.table.sql ?? '-- No DDL available';

    return SingleChildScrollView(
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DDL SQL Definition',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.neutral8,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: AppSpacing.paddingMd,
            decoration: ShapeDecoration(
              color: AppColors.neutral2,
              shape: ContinuousRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
                side: const BorderSide(color: AppColors.neutral4, width: 1.0),
              ),
            ),
            child: SelectableText(
              ddlSql,
              style: AppTypography.body.copyWith(color: AppColors.neutral8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVirtualStatsView(
    List<InboundReference> inboundRefs,
    List<DbTrigger> tableTriggers,
  ) {
    final isVirtual =
        widget.table.sql != null &&
        widget.table.sql!.toUpperCase().contains('VIRTUAL TABLE');

    return SingleChildScrollView(
      padding: AppSpacing.paddingLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Table Properties & SQLite Stats',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.neutral8,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: AppSpacing.paddingMd,
            decoration: ShapeDecoration(
              color: AppColors.neutral2,
              shape: ContinuousRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
                side: const BorderSide(color: AppColors.neutral4, width: 1.0),
              ),
            ),
            child: Column(
              children: [
                _buildStatRow('Object Name', widget.table.name),
                const Divider(height: 16, color: AppColors.neutral4),
                _buildStatRow(
                  'Object Type',
                  widget.table.isView
                      ? 'VIEW'
                      : (isVirtual ? 'VIRTUAL TABLE' : 'BASE TABLE'),
                ),
                const Divider(height: 16, color: AppColors.neutral4),
                _buildStatRow(
                  'Row Count',
                  widget.table.rowCount != null
                      ? '${widget.table.rowCount} rows'
                      : 'Unknown',
                ),
                const Divider(height: 16, color: AppColors.neutral4),
                _buildStatRow(
                  'Columns Count',
                  '${widget.table.columns.length}',
                ),
                const Divider(height: 16, color: AppColors.neutral4),
                _buildStatRow(
                  'Indexes Count',
                  '${widget.table.indexes.length}',
                ),
                const Divider(height: 16, color: AppColors.neutral4),
                _buildStatRow(
                  'Outbound Foreign Keys',
                  '${widget.table.foreignKeys.length}',
                ),
                const Divider(height: 16, color: AppColors.neutral4),
                _buildStatRow('Inbound References', '${inboundRefs.length}'),
                const Divider(height: 16, color: AppColors.neutral4),
                _buildStatRow('Associated Triggers', '${tableTriggers.length}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.neutral7,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: AppTypography.caption.copyWith(
            color: AppColors.neutral8,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
