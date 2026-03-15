import 'package:flutter/material.dart';

import 'package:helpi_app/core/constants/colors.dart';

class HelpiSwitch extends StatelessWidget {
  const HelpiSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.teal,
      activeTrackColor: AppColors.teal.withAlpha(77),
    );
  }
}
