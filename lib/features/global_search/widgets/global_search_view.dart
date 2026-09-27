import 'package:flutter/material.dart';
import '../../../data/models/db_table.dart';
import '../../../data/services/sqlite_service.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../models/search_result.dart';
import '../services/global_search_service.dart';
import 'search_input_header.dart';
import 'search_results_table.dart';

class GlobalSearchView extends StatefulWidget {
  final SqliteService sqliteService;
  final List<DbTable> tables;
  final ValueChanged<String> onNavigateToTable;

  const GlobalSearchView({
    super.key,
    required this.sqliteService,
    required this.tables,
    required this.onNavigateToTable,
  });

  @override
  State<GlobalSearchView> createState() => _GlobalSearchViewState();
}

class _GlobalSearchViewState extends State<GlobalSearchView> {
  late final GlobalSearchService _searchService;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  SearchResult? _lastResult;
  int _maxMatches = 100;
  bool _caseSensitive = false;

  @override
  void initState() {
    super.initState();
    _searchService = GlobalSearchService(sqliteService: widget.sqliteService);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    final result = await _searchService.search(
      query: query,
      tables: widget.tables,
      maxMatches: _maxMatches,
      caseSensitive: _caseSensitive,
    );

    if (!mounted) return;

    setState(() {
      _lastResult = result;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.neutral1,
      child: Column(
        children: [
          SearchInputHeader(
            controller: _searchController,
            onSearch: _handleSearch,
            isSearching: _isSearching,
            maxMatches: _maxMatches,
            onMaxMatchesChanged: (val) => setState(() => _maxMatches = val),
            caseSensitive: _caseSensitive,
            onCaseSensitiveChanged: (val) =>
                setState(() => _caseSensitive = val),
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isSearching) {
      return const LoadingIndicator(
        message: 'Scanning all text columns across database...',
      );
    }

    final result = _lastResult;
    if (result == null) {
      return const EmptyState(
        svgIcon: AppIcons.listMagnifyingGlass,
        title: 'Full-Text Database Search',
        subtitle:
            'Enter a search term above to scan all tables and text columns.',
      );
    }

    if (!result.hasMatches) {
      return EmptyState(
        svgIcon: AppIcons.magnifyingGlass,
        title: 'No Matches Found',
        subtitle:
            'No records matched "${result.query}" across ${result.tablesScanned} scanned tables.',
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: const BoxDecoration(
            color: AppColors.neutral2,
            border: Border(
              bottom: BorderSide(color: AppColors.neutral4, width: 1),
            ),
          ),
          child: Row(
            children: [
              Text(
                'Found ${result.matchCount} matches across ${result.tablesWithMatchesCount} tables (${result.duration.inMilliseconds} ms)',
                style: AppTypography.body.copyWith(
                  color: AppColors.neutral8,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (result.isCapped)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppSvgIcon(
                        AppIcons.info,
                        size: 12,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        'Capped at ${result.maxCap} matches',
                        style: AppTypography.tagline.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: SearchResultsTable(
            matches: result.matches,
            onNavigateToTable: widget.onNavigateToTable,
          ),
        ),
      ],
    );
  }
}
