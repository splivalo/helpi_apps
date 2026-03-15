import 'package:flutter/material.dart';

import 'package:helpi_app/core/constants/colors.dart';

/// Teal-bordered chip Wrap for displaying selected services.
class ServiceChipsWrap extends StatelessWidget {
  const ServiceChipsWrap({super.key, required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: labels.map((label) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.selectedChipBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.teal),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.teal,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
    );
  }
}
