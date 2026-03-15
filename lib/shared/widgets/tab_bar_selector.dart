import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:helpi_app/core/constants/colors.dart';

/// Custom tab bar s coral underline stilom.
class TabBarSelector extends StatelessWidget {
  const TabBarSelector({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTap,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < tabs.length; i++) ...[
          if (i > 0) const SizedBox(width: 24),
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onTap(i);
              },
              child: Column(
                children: [
                  Text(
                    tabs[i],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: selectedIndex == i
                          ? AppColors.coral
                          : AppColors.inactive,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: selectedIndex == i
                          ? AppColors.coral
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
