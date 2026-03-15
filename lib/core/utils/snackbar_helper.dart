import 'package:flutter/material.dart';

import 'package:helpi_app/app/theme.dart';

/// Centralizirani snackbar helper — eliminira duplicirane SnackBar pozive s hardkodiranim bojama.
void showHelpiSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: HelpiTheme.teal),
  );
}
