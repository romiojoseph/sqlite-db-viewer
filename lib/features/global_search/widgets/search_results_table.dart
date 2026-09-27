import 'package:flutter/material.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../models/search_match.dart';

class SearchResultsTable extends StatefulWidget {
  final List<SearchMatch> matches;
  final ValueChanged<String> onNavigateToTable;

  const SearchResultsTable({
    super.key,
    required this.matches,
    required this.onNavigateToTable,
  });

  @override
  State<SearchResultsTable> createState() => _SearchResultsTableState();
}

class _SearchResultsTableState extends State<SearchResultsTable> {
  final ScrollController _horizontalHeaderController = ScrollController();
  final ScrollController _horizontalBodyController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  static const double _indexWidth = 50.0;
  static const double _tableWidth = 160.0;
  static const double _columnWidth = 150.0;
  static const double _rowIdWidth = 130.0;
  static const double _minMatchWidth = 350.0;

  @override
  void initState() {
    super.initState();
    _horizontalBodyController.addListener(_syncHeaderScroll);
  }

  void _syncHeaderScroll() {
    if (_horizontalHeaderController.hasClients &&
        _horizontalHeaderController.offset !=
            _horizontalBodyController.offset) {
      _horizontalHeaderController.jumpTo(_horizontalBodyController.offset);
    }
  }

  @override
  void dispose() {
    _horizontalBodyController.removeListener(_syncHeaderScroll);
    _horizontalHeaderController.dispose();
    _horizontalBodyController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double fixedWidths =
            _indexWidth + _tableWidth + _columnWidth + _rowIdWidth;
        final double availableForMatch = constraints.maxWidth - fixedWidths;
        final double matchWidth = availableForMatch > _minMatchWidth
            ? availableForMatch
            : _minMatchWidth;
        final double totalWidth = fixedWidths + matchWidth;

        return Column(
          children: [
            // Table Header Row
            Container(
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.neutral2,
                border: Border(
                  bottom: BorderSide(color: AppColors.neutral4, width: 1.0),
                ),
              ),
              child: SingleChildScrollView(
                controller: _horizontalHeaderController,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: SizedBox(
                  width: totalWidth,
                  child: Row(
                    children: [
                      _buildHeaderCell(
                        '#',
                        _indexWidth,
                        alignment: Alignment.center,
                      ),
                      _buildHeaderCell('Table', _tableWidth),
                      _buildHeaderCell('Column', _columnWidth),
                      _buildHeaderCell('Row Identifier', _rowIdWidth),
                      _buildHeaderCell(
                        'Matched Value',
                        matchWidth,
                        showRightBorder: false,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Table Body Rows
            Expanded(
              child: Scrollbar(
                controller: _verticalController,
                thumbVisibility: true,
                child: Scrollbar(
                  controller: _horizontalBodyController,
                  thumbVisibility: true,
                  notificationPredicate: (notif) => notif.depth == 1,
                  child: SingleChildScrollView(
                    controller: _verticalController,
                    child: SingleChildScrollView(
                      controller: _horizontalBodyController,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: totalWidth,
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: widget.matches.length,
                          itemBuilder: (context, index) {
                            final match = widget.matches[index];
                            return _SearchResultRow(
                              index: index + 1,
                              match: match,
                              indexWidth: _indexWidth,
                              tableWidth: _tableWidth,
                              columnWidth: _columnWidth,
                              rowIdWidth: _rowIdWidth,
                              matchWidth: matchWidth,
                              isEven: index.isEven,
                              onNavigateToTable: widget.onNavigateToTable,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeaderCell(
    String label,
    double width, {
    Alignment alignment = Alignment.centerLeft,
    bool showRightBorder = true,
  }) {
    return Container(
      width: width,
      height: 36,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(
          right: showRightBorder
              ? const BorderSide(color: AppColors.neutral3, width: 1.0)
              : BorderSide.none,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.tagline.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.neutral8,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _SearchResultRow extends StatefulWidget {
  final int index;
  final SearchMatch match;
  final double indexWidth;
  final double tableWidth;
  final double columnWidth;
  final double rowIdWidth;
  final double matchWidth;
  final bool isEven;
  final ValueChanged<String> onNavigateToTable;

  const _SearchResultRow({
    required this.index,
    required this.match,
    required this.indexWidth,
    required this.tableWidth,
    required this.columnWidth,
    required this.rowIdWidth,
    required this.matchWidth,
    required this.isEven,
    required this.onNavigateToTable,
  });

  @override
  State<_SearchResultRow> createState() => _SearchResultRowState();
}

class _SearchResultRowState extends State<_SearchResultRow> {
  bool _isHovered = false;

  TextSpan _buildHighlightedSpan(String text, int matchIndex, int matchLength) {
    if (matchIndex < 0 || matchIndex + matchLength > text.length) {
      return TextSpan(
        text: text,
        style: AppTypography.caption.copyWith(
          fontFamily: 'monospace',
          color: AppColors.neutral8,
        ),
      );
    }

    final prefix = text.substring(0, matchIndex);
    final highlight = text.substring(matchIndex, matchIndex + matchLength);
    final suffix = text.substring(matchIndex + matchLength);

    return TextSpan(
      style: AppTypography.caption.copyWith(
        fontFamily: 'monospace',
        color: AppColors.neutral8,
      ),
      children: [
        TextSpan(text: prefix),
        TextSpan(
          text: highlight,
          style: AppTypography.caption.copyWith(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
            color: AppColors.neutral9,
            backgroundColor: AppColors.neutral4,
          ),
        ),
        TextSpan(text: suffix),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final rowBg = _isHovered
        ? AppColors.neutral3
        : (widget.isEven ? AppColors.neutral1 : AppColors.neutral2);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        constraints: const BoxConstraints(minHeight: 36),
        decoration: BoxDecoration(
          color: rowBg,
          border: const Border(
            bottom: BorderSide(color: AppColors.neutral3, width: 1.0),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // # Index
            Container(
              width: widget.indexWidth,
              height: 36,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: AppColors.neutral3, width: 1.0),
                ),
              ),
              child: Text(
                '${widget.index}',
                style: AppTypography.tagline.copyWith(
                  color: AppColors.neutral8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Table Name with link / open action
            Container(
              width: widget.tableWidth,
              height: 36,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: AppColors.neutral3, width: 1.0),
                ),
              ),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => widget.onNavigateToTable(match.tableName),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          match.tableName,
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.neutral8,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const AppSvgIcon(
                        AppIcons.arrowSquareOut,
                        size: 13,
                        color: AppColors.neutral8,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Column Name
            Container(
              width: widget.columnWidth,
              height: 36,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: AppColors.neutral3, width: 1.0),
                ),
              ),
              child: SelectableText(
                match.columnName,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.neutral8,
                ),
                maxLines: 1,
              ),
            ),

            // Row Identifier
            Container(
              width: widget.rowIdWidth,
              height: 36,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: AppColors.neutral3, width: 1.0),
                ),
              ),
              child: SelectableText(
                match.rowIdentifier,
                style: AppTypography.caption.copyWith(
                  fontFamily: 'monospace',
                  color: AppColors.neutral8,
                ),
                maxLines: 1,
              ),
            ),

            // Matched Value (with highlight, fully selectable)
            Container(
              width: widget.matchWidth,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              child: SelectableText.rich(
                _buildHighlightedSpan(
                  match.matchedText,
                  match.matchIndex,
                  match.matchLength,
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
