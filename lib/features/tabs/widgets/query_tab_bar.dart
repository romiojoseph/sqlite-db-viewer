import '../../../shared/widgets/app_svg_icon.dart';
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../models/app_tab.dart';
import 'tab_item.dart';

class QueryTabBar extends StatelessWidget {
  final List<AppTab> tabs;
  final String selectedTabId;
  final ValueChanged<AppTab> onTabSelected;
  final ValueChanged<AppTab> onTabClosed;
  final VoidCallback onNewQueryTab;

  const QueryTabBar({
    super.key,
    required this.tabs,
    required this.selectedTabId,
    required this.onTabSelected,
    required this.onTabClosed,
    required this.onNewQueryTab,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: const BoxDecoration(
        color: AppColors.neutral1,
        border: Border(
          bottom: BorderSide(
            color: AppColors.neutral4,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final tab = tabs[index];
                return TabItem(
                  tab: tab,
                  isSelected: tab.id == selectedTabId,
                  onTap: () => onTabSelected(tab),
                  onClose: () => onTabClosed(tab),
                );
              },
            ),
          ),
          Tooltip(
            message: 'New SQL Query Tab',
            child: InkWell(
              onTap: onNewQueryTab,
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: AppColors.neutral4,
                      width: 1,
                    ),
                  ),
                ),
                child: const AppSvgIcon(
                  AppIcons.plus,
                  size: 16,
                  color: AppColors.neutral10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
