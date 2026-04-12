import 'package:flutter/material.dart';

/// Centralized colors for Helpi app.
class AppColors {
  AppColors._();

  // -- Primary palette --
  static const Color coral = Color(0xFFEF5B5B);
  static const Color teal = Color(0xFF009D9D);

  // -- Semantic --
  static const Color error = Color(0xFFC62828);
  static const Color success = Color(0xFF4CAF50);
  static const Color info = Color(0xFF1976D2);

  // -- Neutrals --
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF757575);
  static const Color border = Color(0xFFE0E0E0);
  static const Color inactive = Color(0xFF9E9E9E);
  static const Color background = Color(0xFFF9F7F4);
  static const Color surface = Colors.white;

  // -- Status backgrounds --
  static const Color statusGreenBg = Color(0xFFE8F5E9);
  static const Color statusBlueBg = Color(0xFFE8F1FB);
  static const Color statusRedBg = Color(0xFFFFEBEE);

  // -- Chip / selection --
  static const Color selectedChipBg = Color(0xFFE0F5F5);

  // -- Dark mode neutrals --
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF2C2C2C);
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFF9E9E9E);
  static const Color darkBorder = Color(0xFF3A3A3A);

  // -- Reusable button styles --
  static final ButtonStyle coralOutlinedStyle = OutlinedButton.styleFrom(
    foregroundColor: coral,
    side: const BorderSide(color: coral, width: 2),
  );

  static final ButtonStyle tealSmallOutlinedStyle = OutlinedButton.styleFrom(
    foregroundColor: teal,
    side: const BorderSide(color: teal),
    padding: const EdgeInsets.symmetric(horizontal: 10),
    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    minimumSize: Size.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  static final ButtonStyle coralSmallOutlinedStyle = OutlinedButton.styleFrom(
    foregroundColor: coral,
    side: const BorderSide(color: coral),
    padding: const EdgeInsets.symmetric(horizontal: 10),
    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    minimumSize: Size.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );
}
