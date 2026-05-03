import 'package:flutter/material.dart';

import 'package:helpi_app/app/theme.dart';

/// Centralized snackbar helper - eliminates duplicate SnackBar calls with hardcoded colors.
void showHelpiSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: isError ? HelpiTheme.coral : HelpiTheme.teal,
    ),
  );
}
