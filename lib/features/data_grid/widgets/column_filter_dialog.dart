import '../../../shared/widgets/app_svg_icon.dart';
import 'package:flutter/material.dart';
import '../../../data/models/column_filter.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_dropdown.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

class ColumnFilterDialog extends StatefulWidget {
  final String columnName;
  final String? columnType;
  final FilterOperator initialOperator;
  final String initialValue;

  const ColumnFilterDialog({
    super.key,
    required this.columnName,
    this.columnType,
    this.initialOperator = FilterOperator.equals,
    this.initialValue = '',
  });

  static Future<ColumnFilter?> show(
    BuildContext context, {
    required String columnName,
    String? columnType,
    FilterOperator initialOperator = FilterOperator.equals,
    String initialValue = '',
  }) {
    return AppDialog.show<ColumnFilter>(
      context,
      builder: (ctx) => ColumnFilterDialog(
        columnName: columnName,
        columnType: columnType,
        initialOperator: initialOperator,
        initialValue: initialValue,
      ),
    );
  }

  @override
  State<ColumnFilterDialog> createState() => _ColumnFilterDialogState();
}

class _ColumnFilterDialogState extends State<ColumnFilterDialog> {
  late FilterOperator _selectedOperator;
  late final TextEditingController _valueController;

  @override
  void initState() {
    super.initState();
    _selectedOperator = widget.initialOperator;
    _valueController = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  bool get _requiresValue =>
      _selectedOperator != FilterOperator.isNull &&
      _selectedOperator != FilterOperator.isNotNull;

  void _applyFilter() {
    Navigator.of(context).pop(
      ColumnFilter(
        column: widget.columnName,
        operator: _selectedOperator,
        value: _requiresValue ? _valueController.text.trim() : '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: 'Filter: ${widget.columnName}',
      maxWidth: 480,
      maxHeight: 440,
      footerActions: [
        AppButton(
          label: 'Cancel',
          variant: AppButtonVariant.ghost,
          size: AppButtonSize.small,
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppButton(
          label: 'Apply Filter',
          customIcon: const AppSvgIcon(
            AppIcons.funnel,
            size: 14,
            color: AppColors.neutral1,
          ),
          variant: AppButtonVariant.primary,
          size: AppButtonSize.small,
          onPressed: _applyFilter,
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
              const SizedBox(height: AppSpacing.md),
              Text(
                'Condition',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral11,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              AppDropdown<FilterOperator>(
                value: _selectedOperator,
                height: 36,
                borderRadius: 12,
                fillColor: AppColors.neutral1,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                textStyle: AppTypography.caption.copyWith(
                  color: AppColors.neutral8,
                  fontWeight: FontWeight.w500,
                ),
                items: const [
                  AppDropdownItem(
                    value: FilterOperator.equals,
                    label: 'Equals (=)',
                  ),
                  AppDropdownItem(
                    value: FilterOperator.notEquals,
                    label: 'Not Equals (<>)',
                  ),
                  AppDropdownItem(
                    value: FilterOperator.contains,
                    label: 'Contains (LIKE %..%)',
                  ),
                  AppDropdownItem(
                    value: FilterOperator.startsWith,
                    label: 'Starts with (LIKE ..%)',
                  ),
                  AppDropdownItem(
                    value: FilterOperator.endsWith,
                    label: 'Ends with (LIKE %..)',
                  ),
                  AppDropdownItem(
                    value: FilterOperator.greaterThan,
                    label: 'Greater than (>)',
                  ),
                  AppDropdownItem(
                    value: FilterOperator.lessThan,
                    label: 'Less than (<)',
                  ),
                  AppDropdownItem(
                    value: FilterOperator.greaterOrEqual,
                    label: 'Greater or Equal (>=)',
                  ),
                  AppDropdownItem(
                    value: FilterOperator.lessOrEqual,
                    label: 'Less or Equal (<=)',
                  ),
                  AppDropdownItem(
                    value: FilterOperator.isNull,
                    label: 'Is NULL',
                  ),
                  AppDropdownItem(
                    value: FilterOperator.isNotNull,
                    label: 'Is NOT NULL',
                  ),
                ],
                onChanged: (op) {
                  setState(() {
                    _selectedOperator = op;
                  });
                },
              ),
              if (_requiresValue) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Value',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.neutral11,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                TextField(
                  controller: _valueController,
                  autofocus: true,
                  style: AppTypography.body.copyWith(
                    color: AppColors.neutral12,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter filter value...',
                    hintStyle: AppTypography.caption.copyWith(
                      color: AppColors.neutral8,
                    ),
                    filled: true,
                    fillColor: AppColors.neutral1,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: const BorderSide(color: AppColors.neutral4),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: const BorderSide(color: AppColors.neutral4),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: const BorderSide(color: AppColors.neutral7),
                    ),
                  ),
                  onSubmitted: (_) => _applyFilter(),
                ),
              ],
        ],
      ),
    );
  }
}
