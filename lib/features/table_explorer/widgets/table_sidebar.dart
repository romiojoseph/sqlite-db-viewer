import 'package:flutter/material.dart';
import '../../../data/models/db_index.dart';
import '../../../data/models/db_sequence.dart';
import '../../../data/models/db_table.dart';
import '../../../data/models/db_trigger.dart';
import '../../../shared/widgets/app_menu.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import 'sidebar_accordion_section.dart';
import 'sidebar_object_items.dart';
import 'table_list_item.dart';
import 'table_search_field.dart';

enum SidebarActiveSection { database }

class TableSidebar extends StatefulWidget {
  final String dbPath;
  final List<DbTable> tables;
  final List<DbTrigger> triggers;
  final List<DbSequence> sequences;
  final String? selectedTableName;
  final ValueChanged<DbTable> onTableSelected;
  final VoidCallback? onImportCsv;
  final VoidCallback? onImportJson;
  final VoidCallback? onOpenCompleteSchema;
  final VoidCallback onCloseDatabase;
  final VoidCallback onNewQueryTab;
  final VoidCallback onOpenSchemaGraph;
  final VoidCallback onOpenGlobalSearch;
  final VoidCallback onOpenDatabaseInfo;
  final VoidCallback onExportAllZipped;
  final VoidCallback onOpenDiffChecker;

  const TableSidebar({
    super.key,
    required this.dbPath,
    required this.tables,
    this.triggers = const [],
    this.sequences = const [],
    required this.selectedTableName,
    required this.onTableSelected,
    this.onImportCsv,
    this.onImportJson,
    this.onOpenCompleteSchema,
    required this.onCloseDatabase,
    required this.onNewQueryTab,
    required this.onOpenSchemaGraph,
    required this.onOpenGlobalSearch,
    required this.onOpenDatabaseInfo,
    required this.onExportAllZipped,
    required this.onOpenDiffChecker,
  });

  @override
  State<TableSidebar> createState() => _TableSidebarState();
}

class _TableSidebarState extends State<TableSidebar> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _filterQuery = '';

  // By default, database explorer is active and panel is open
  SidebarActiveSection _activeSection = SidebarActiveSection.database;
  bool _isPanelOpen = true;

  // Accordion expansion states — Tables opened by default, others collapsed
  bool _tablesExpanded = true;
  bool _viewsExpanded = false;
  bool _indexesExpanded = false;
  bool _sequencesExpanded = false;
  bool _triggersExpanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _openImportMenu(BuildContext targetContext) {
    final renderBox = targetContext.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final position = renderBox.localToGlobal(
      Offset(renderBox.size.width + 4.0, 0),
    );

    showAppMenu<String>(
      context: context,
      position: position,
      minWidth: 190,
      items: [
        if (widget.onImportCsv != null)
          AppMenuItem<String>(
            value: 'csv',
            label: 'Import CSV File',
            customIcon: const Padding(
              padding: EdgeInsets.only(right: AppSpacing.sm),
              child: AppSvgIcon(
                AppIcons.table,
                size: 16,
                color: AppColors.neutral8,
              ),
            ),
            onTap: widget.onImportCsv,
          ),
        if (widget.onImportJson != null)
          AppMenuItem<String>(
            value: 'json',
            label: 'Import JSON File',
            customIcon: const Padding(
              padding: EdgeInsets.only(right: AppSpacing.sm),
              child: AppSvgIcon(
                AppIcons.bracketsCurly,
                size: 16,
                color: AppColors.neutral8,
              ),
            ),
            onTap: widget.onImportJson,
          ),
      ],
    );
  }

  void _onActivityItemTapped(SidebarActiveSection section) {
    setState(() {
      if (_activeSection == section) {
        _isPanelOpen = !_isPanelOpen;
      } else {
        _activeSection = section;
        _isPanelOpen = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = _filterQuery.trim().toLowerCase();

    // Tables & Views
    final allTables = widget.tables.where((t) => !t.isView).toList();
    final allViews = widget.tables.where((t) => t.isView).toList();

    final filteredTables = q.isEmpty
        ? allTables
        : allTables.where((t) => t.name.toLowerCase().contains(q)).toList();

    final filteredViews = q.isEmpty
        ? allViews
        : allViews.where((v) => v.name.toLowerCase().contains(q)).toList();

    // Indexes
    final allIndexes = <({DbIndex index, String tableName})>[];
    for (final table in widget.tables) {
      for (final idx in table.indexes) {
        allIndexes.add((index: idx, tableName: table.name));
      }
    }
    final filteredIndexes = q.isEmpty
        ? allIndexes
        : allIndexes.where((item) {
            return item.index.name.toLowerCase().contains(q) ||
                item.tableName.toLowerCase().contains(q);
          }).toList();

    // Sequences
    final filteredSequences = q.isEmpty
        ? widget.sequences
        : widget.sequences
              .where((s) => s.name.toLowerCase().contains(q))
              .toList();

    // Triggers
    final filteredTriggers = q.isEmpty
        ? widget.triggers
        : widget.triggers.where((trg) {
            return trg.name.toLowerCase().contains(q) ||
                trg.tableName.toLowerCase().contains(q);
          }).toList();

    // If search active, auto-expand sections containing matches
    final isTablesOpen = q.isNotEmpty
        ? filteredTables.isNotEmpty
        : _tablesExpanded;
    final isViewsOpen = q.isNotEmpty
        ? filteredViews.isNotEmpty
        : _viewsExpanded;
    final isIndexesOpen = q.isNotEmpty
        ? filteredIndexes.isNotEmpty
        : _indexesExpanded;
    final isSequencesOpen = q.isNotEmpty
        ? filteredSequences.isNotEmpty
        : _sequencesExpanded;
    final isTriggersOpen = q.isNotEmpty
        ? filteredTriggers.isNotEmpty
        : _triggersExpanded;

    final hasAnyMatch =
        filteredTables.isNotEmpty ||
        filteredViews.isNotEmpty ||
        filteredIndexes.isNotEmpty ||
        filteredSequences.isNotEmpty ||
        filteredTriggers.isNotEmpty;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // VS Code Activity Bar (Far Left Strip)
        Container(
          width: 48,
          decoration: const BoxDecoration(
            color: AppColors.neutral1,
            border: Border(
              right: BorderSide(color: AppColors.neutral4, width: 1),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xs),
              // 1. Database Explorer (Active by default)
              _ActivityBarIcon(
                svgIcon: AppIcons.database,
                tooltip: 'Database Explorer',
                isActive:
                    _activeSection == SidebarActiveSection.database &&
                    _isPanelOpen,
                onTap: () =>
                    _onActivityItemTapped(SidebarActiveSection.database),
              ),
              const SizedBox(height: AppSpacing.xxs),
              // 2. Search Database (Full-Text)
              _ActivityBarIcon(
                svgIcon: AppIcons.listMagnifyingGlass,
                tooltip: 'Search Database (Full-Text)',
                isActive: false,
                onTap: widget.onOpenGlobalSearch,
              ),
              const SizedBox(height: AppSpacing.xxs),
              // 4. Schema Graph (ERD)
              _ActivityBarIcon(
                svgIcon: AppIcons.graph,
                tooltip: 'Schema Graph (ERD)',
                isActive: false,
                onTap: widget.onOpenSchemaGraph,
              ),
              const SizedBox(height: AppSpacing.xxs),
              // 5. Compare Databases (Diff)
              _ActivityBarIcon(
                svgIcon: AppIcons.splitHorizontal,
                tooltip: 'Compare Databases (Diff)',
                isActive: false,
                onTap: widget.onOpenDiffChecker,
              ),
              const SizedBox(height: AppSpacing.xxs),
              // 6. New SQL Query
              _ActivityBarIcon(
                svgIcon: AppIcons.terminalWindow,
                tooltip: 'New SQL Query',
                isActive: false,
                onTap: widget.onNewQueryTab,
              ),
              const SizedBox(height: AppSpacing.xxs),
              // Import (CSV / JSON)
              if (widget.onImportCsv != null ||
                  widget.onImportJson != null) ...[
                Builder(
                  builder: (ctx) => _ActivityBarIcon(
                    svgIcon: AppIcons.plus,
                    tooltip: 'Import Table (CSV / JSON)',
                    isActive: false,
                    onTap: () => _openImportMenu(ctx),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
              ],
              // Full Schema DDL
              if (widget.onOpenCompleteSchema != null) ...[
                _ActivityBarIcon(
                  svgIcon: AppIcons.fileSql,
                  tooltip: 'Full Schema DDL (SQL)',
                  isActive: false,
                  onTap: widget.onOpenCompleteSchema!,
                ),
                const SizedBox(height: AppSpacing.xxs),
              ],
              // Export All
              _ActivityBarIcon(
                svgIcon: AppIcons.export,
                tooltip: 'Export All (Zipped CSV)',
                isActive: false,
                onTap: widget.onExportAllZipped,
              ),
              const SizedBox(height: AppSpacing.xxs),
              // Database Info
              _ActivityBarIcon(
                svgIcon: AppIcons.info,
                tooltip: 'Database File Information',
                isActive: false,
                onTap: widget.onOpenDatabaseInfo,
              ),
              const Spacer(),
            ],
          ),
        ),

        // Sidebar Primary Panel (Database Object Tree)
        if (_isPanelOpen)
          Container(
            width: 250,
            decoration: const BoxDecoration(
              color: AppColors.neutral2,
              border: Border(
                right: BorderSide(color: AppColors.neutral4, width: 1),
              ),
            ),
            child: Column(
              children: [
                // Search Field
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xs,
                  ),
                  child: TableSearchField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _filterQuery = val),
                    onClear: () {
                      _searchController.clear();
                      setState(() => _filterQuery = '');
                    },
                  ),
                ),

                // Accordion Object Tree (Full Height)
                Expanded(
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Tables Section (Open by default)
                          SidebarAccordionSection(
                            title: 'Tables',
                            count: filteredTables.length,
                            isExpanded: isTablesOpen,
                            trailingAction:
                                (widget.onImportCsv != null ||
                                    widget.onImportJson != null)
                                ? Builder(
                                    builder: (ctx) => Tooltip(
                                      message: 'Import Table (CSV / JSON)',
                                      child: InkWell(
                                        onTap: () => _openImportMenu(ctx),
                                        borderRadius: BorderRadius.circular(
                                          4.0,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.xxs,
                                            vertical: AppSpacing.xxxs,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.neutral4,
                                            borderRadius: BorderRadius.circular(
                                              4.0,
                                            ),
                                          ),
                                          child: const AppSvgIcon(
                                            AppIcons.plus,
                                            size: 14,
                                            color: AppColors.neutral8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : null,
                            onToggle: () => setState(
                              () => _tablesExpanded = !_tablesExpanded,
                            ),
                            children: filteredTables
                                .map(
                                  (table) => TableListItem(
                                    table: table,
                                    isSelected:
                                        widget.selectedTableName == table.name,
                                    onTap: () => widget.onTableSelected(table),
                                  ),
                                )
                                .toList(),
                          ),

                          const Divider(height: 1, color: AppColors.neutral4),

                          // 2. Views Section
                          SidebarAccordionSection(
                            title: 'Views',
                            count: filteredViews.length,
                            isExpanded: isViewsOpen,
                            onToggle: () => setState(
                              () => _viewsExpanded = !_viewsExpanded,
                            ),
                            children: filteredViews
                                .map(
                                  (view) => TableListItem(
                                    table: view,
                                    isSelected:
                                        widget.selectedTableName == view.name,
                                    onTap: () => widget.onTableSelected(view),
                                  ),
                                )
                                .toList(),
                          ),

                          const Divider(height: 1, color: AppColors.neutral4),

                          // 3. Indexes Section
                          SidebarAccordionSection(
                            title: 'Indexes',
                            count: filteredIndexes.length,
                            isExpanded: isIndexesOpen,
                            onToggle: () => setState(
                              () => _indexesExpanded = !_indexesExpanded,
                            ),
                            children: filteredIndexes
                                .map(
                                  (item) => IndexListItem(
                                    index: item.index,
                                    tableName: item.tableName,
                                  ),
                                )
                                .toList(),
                          ),

                          const Divider(height: 1, color: AppColors.neutral4),

                          // 4. Sequences Section
                          SidebarAccordionSection(
                            title: 'Sequences',
                            count: filteredSequences.length,
                            isExpanded: isSequencesOpen,
                            onToggle: () => setState(
                              () => _sequencesExpanded = !_sequencesExpanded,
                            ),
                            children: filteredSequences
                                .map((seq) => SequenceListItem(sequence: seq))
                                .toList(),
                          ),

                          const Divider(height: 1, color: AppColors.neutral4),

                          // 5. Table Triggers Section
                          SidebarAccordionSection(
                            title: 'Table Triggers',
                            count: filteredTriggers.length,
                            isExpanded: isTriggersOpen,
                            onToggle: () => setState(
                              () => _triggersExpanded = !_triggersExpanded,
                            ),
                            children: filteredTriggers
                                .map((trg) => TriggerListItem(trigger: trg))
                                .toList(),
                          ),

                          if (!hasAnyMatch)
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Center(
                                child: Text(
                                  'No matching database objects',
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.neutral9,
                                  ),
                                ),
                              ),
                            ),

                          const SizedBox(height: AppSpacing.xs),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ActivityBarIcon extends StatefulWidget {
  final IconData? icon;
  final String? svgIcon;
  final String tooltip;
  final bool isActive;
  final VoidCallback onTap;

  const _ActivityBarIcon({
    this.icon,
    this.svgIcon,
    required this.tooltip,
    required this.isActive,
    required this.onTap,
  }) : assert(icon != null || svgIcon != null);

  @override
  State<_ActivityBarIcon> createState() => _ActivityBarIconState();
}

class _ActivityBarIconState extends State<_ActivityBarIcon> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive;
    final color = active
        ? AppColors.neutral12
        : (_isHovered ? AppColors.neutral12 : AppColors.neutral10);

    final Widget iconWidget = widget.svgIcon != null
        ? AppSvgIcon(widget.svgIcon!, size: 19, color: color)
        : Icon(widget.icon!, size: 19, color: color);

    return Tooltip(
      message: widget.tooltip,
      preferBelow: false,
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 48,
            height: 42,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (active)
                  Positioned(
                    left: 0,
                    top: 8,
                    bottom: 8,
                    child: Container(
                      width: 2.5,
                      decoration: const BoxDecoration(
                        color: AppColors.neutral12,
                        borderRadius: BorderRadius.horizontal(
                          right: Radius.circular(2),
                        ),
                      ),
                    ),
                  ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: ShapeDecoration(
                    color: active
                        ? AppColors.neutral4
                        : (_isHovered
                              ? AppColors.neutral3
                              : Colors.transparent),
                    shape: ContinuousRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: Center(child: iconWidget),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
