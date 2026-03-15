import 'package:flutter/material.dart';

import 'package:helpi_app/app/theme.dart';

/// White card container with border — reusable section wrapper.
class HelpiCard extends StatelessWidget {
  const HelpiCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HelpiTheme.border),
      ),
      child: child,
    );
  }
}
