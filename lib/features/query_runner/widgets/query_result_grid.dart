import 'package:flutter/material.dart';
import '../../../data/models/query_result.dart';
import '../../../data/services/csv_export_service.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../data_grid/widgets/paginated_data_grid.dart';
import 'query_error_banner.dart';
import 'query_input_box.dart';

class QueryResultGrid extends StatelessWidget {
  final TextEditingController inputController;
  final QueryResult? result;
  final bool isExecuting;
  final VoidCallback onExecute;
  final int currentPage;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPageSizeChanged;

  const QueryResultGrid({
    super.key,
    required this.inputController,
    required this.result,
    required this.isExecuting,
    required this.onExecute,
    required this.currentPage,
    required this.pageSize,
    required this.onPageChanged,
    required this.onPageSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        QueryInputBox(
          controller: inputController,
          onExecute: onExecute,
          isExecuting: isExecuting,
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (isExecuting) {
      return const LoadingIndicator(message: 'Executing SQL query...');
    }

    final res = result;
    if (res == null) {
      return const EmptyState(
        svgIcon: AppIcons.play,
        title: 'Run a Query',
        subtitle: 'Write a SELECT query above and press "Run" or Ctrl+Enter.',
      );
    }

    if (!res.isSuccess && res.error != null) {
      return Align(
        alignment: Alignment.topCenter,
        child: QueryErrorBanner(error: res.error!),
      );
    }

    if (res.columns.isEmpty) {
      return const EmptyState(
        svgIcon: AppIcons.plusCircle,
        title: 'Query Completed',
        subtitle: 'Statement executed with no tabular output.',
      );
    }

    final startIndex = (currentPage * pageSize).clamp(0, res.rows.length);
    final endIndex = (startIndex + pageSize).clamp(0, res.rows.length);
    final pageRows = res.rows.sublist(startIndex, endIndex);

    final pageResult = QueryResult(
      columns: res.columns,
      rows: pageRows,
      executionDuration: res.executionDuration,
      totalRows: res.rows.length,
      isSuccess: true,
      isCapped: res.isCapped,
      maxCap: res.maxCap,
    );

    final grid = PaginatedDataGrid(
      result: pageResult,
      currentPage: currentPage,
      pageSize: pageSize,
      totalRows: res.rows.length,
      onPageChanged: onPageChanged,
      onPageSizeChanged: onPageSizeChanged,
      exportDefaultName: 'query_result.csv',
      onExportCsv: () async => await CsvExportService.exportToFile(
        res,
        defaultFileName: 'query_result.csv',
      ),
    );

    if (res.isCapped) {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: const BoxDecoration(
              color: AppColors.neutral2,
              border: Border(bottom: BorderSide(color: AppColors.neutral5)),
            ),
            child: Row(
              children: [
                const AppSvgIcon(
                  AppIcons.info,
                  size: 14,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Result capped at ${res.maxCap} rows. Additional rows were truncated.',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: grid),
        ],
      );
    }

    return grid;
  }
}
