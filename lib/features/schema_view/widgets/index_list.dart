import 'package:flutter/material.dart';
import '../../../data/models/db_index.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class IndexList extends StatelessWidget {
  final List<DbIndex> indexes;

  const IndexList({super.key, required this.indexes});

  @override
  Widget build(BuildContext context) {
    if (indexes.isEmpty) {
      return Padding(
        padding: AppSpacing.paddingMd,
        child: Text(
          'No indexes defined on this table.',
          style: AppTypography.caption.copyWith(
            color: AppColors.neutral7,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: indexes.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        final item = indexes[index];

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
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
              AppSvgIcon(
                item.unique ? AppIcons.key : AppIcons.treeStructure,
                size: 16,
                color: AppColors.neutral8,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.name,
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.neutral8,
                          ),
                        ),
                        if (item.unique) ...[
                          const SizedBox(width: AppSpacing.xs),
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
                              'UNIQUE',
                              style: AppTypography.tagline.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.neutral8,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (item.columns.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxxs),
                      Text(
                        'Columns: (${item.columns.join(', ')})',
                        style: AppTypography.tagline.copyWith(
                          color: AppColors.neutral7,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
