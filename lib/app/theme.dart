import 'package:flutter/material.dart';

import 'package:helpi_app/core/constants/colors.dart';

/// Helpi theme - soft, warm, accessible.
class HelpiTheme {
  HelpiTheme._();

  // -- Color aliases (student screens use HelpiTheme.xyz) --
  static const Color teal = AppColors.teal;
  static const Color coral = AppColors.coral;
  static const Color textSecondary = AppColors.textSecondary;
  static const Color border = AppColors.border;
  static const Color offWhite = AppColors.background;
  static const Color barBg = Color(0xFFE0E0E0);
  static const Color avatarBg = Color(0xFFE8F1FB);
  static const Color star = Color(0xFFFFC107);

  // -- ButtonStyle aliases --
  static final ButtonStyle coralOutlinedStyle = AppColors.coralOutlinedStyle;

  // Pastel colors for cards
  static const Color cardMint = Color(0xFFE8F5F1);
  static const Color cardLavender = Color(0xFFF0EBFA);
  static const Color cardCream = Color(0xFFFFF8E7);
  static const Color cardBlue = Color(0xFFE8F1FB);

  // -- Button dimensions --
  static const double buttonHeight = 56.0;
  static const double buttonRadius = 16.0;
  static const double cardRadius = 16.0;

  // -- Theme --
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.coral,
      primaryContainer: Color(0xFFFFE8E5),
      secondary: AppColors.teal,
      secondaryContainer: Color(0xFFD4F0F0),
      error: AppColors.error,
      surface: AppColors.surface,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.background,

    // -- AppBar --
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    ),

    // -- Text --
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      bodySmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      labelLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),

    // -- Elevated Button (large, rounded) --
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.coral,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    ),

    // -- Outlined Button --
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.teal,
        minimumSize: const Size(double.infinity, buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
        side: const BorderSide(color: AppColors.teal, width: 2),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    ),

    // -- Text Button --
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.teal,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),

    // -- Card --
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      shadowColor: Colors.black.withAlpha(15),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    // -- Input Decoration --
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        borderSide: const BorderSide(color: AppColors.teal, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      labelStyle: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
      hintStyle: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
    ),

    // -- Bottom Navigation --
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.teal,
      unselectedItemColor: const Color(0xFFB0B0B0),
      selectedLabelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(fontSize: 14),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    // -- Floating Action Button --
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.teal,
      foregroundColor: Colors.white,
      elevation: 2,
    ),

    // -- Divider --
    dividerTheme: const DividerThemeData(
      color: Color(0xFFEEEEEE),
      thickness: 1,
      space: 1,
    ),

    // -- DatePicker / TimePicker - no uppercase buttons --
    datePickerTheme: DatePickerThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      headerBackgroundColor: AppColors.teal,
      headerForegroundColor: Colors.white,
      headerHeadlineStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      headerHelpStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        if (states.contains(WidgetState.disabled)) {
          return AppColors.textSecondary.withAlpha(100);
        }
        return AppColors.textPrimary;
      }),
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.teal;
        return null;
      }),
      todayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return AppColors.teal;
      }),
      todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.teal;
        return null;
      }),
      todayBorder: const BorderSide(color: AppColors.teal),
      yearForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return AppColors.textPrimary;
      }),
      yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.teal;
        return null;
      }),
      cancelButtonStyle: TextButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
      confirmButtonStyle: TextButton.styleFrom(
        foregroundColor: AppColors.teal,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
    ),
    timePickerTheme: TimePickerThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      confirmButtonStyle: TextButton.styleFrom(
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
      cancelButtonStyle: TextButton.styleFrom(
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
    ),
  );

  // -- Dark Theme --
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.coral,
      primaryContainer: Color(0xFF5C2020),
      secondary: AppColors.teal,
      secondaryContainer: Color(0xFF1A4A4A),
      error: AppColors.error,
      surface: AppColors.darkSurface,
      outline: AppColors.darkBorder,
      outlineVariant: AppColors.darkBorder,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.darkTextPrimary,
      onSurfaceVariant: AppColors.darkTextSecondary,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.darkBackground,

    // -- AppBar --
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBackground,
      foregroundColor: AppColors.darkTextPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.darkTextPrimary,
      ),
    ),

    // -- Text --
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        color: AppColors.darkTextPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.darkTextPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.darkTextPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: AppColors.darkTextPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.darkTextPrimary,
      ),
      bodySmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.darkTextSecondary,
      ),
      labelLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),

    // -- Elevated Button --
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.coral,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    ),

    // -- Outlined Button --
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.teal,
        minimumSize: const Size(double.infinity, buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
        side: const BorderSide(color: AppColors.teal, width: 2),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    ),

    // -- Text Button --
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.teal,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),

    // -- Card --
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      shadowColor: Colors.black.withAlpha(30),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    // -- Input Decoration --
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        borderSide: const BorderSide(color: AppColors.teal, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      labelStyle: const TextStyle(
        fontSize: 16,
        color: AppColors.darkTextSecondary,
      ),
      hintStyle: const TextStyle(
        fontSize: 16,
        color: AppColors.darkTextSecondary,
      ),
    ),

    // -- Bottom Navigation --
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkSurface,
      selectedItemColor: AppColors.teal,
      unselectedItemColor: Color(0xFF707070),
      selectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 14),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    // -- Floating Action Button --
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.teal,
      foregroundColor: Colors.white,
      elevation: 2,
    ),

    // -- Divider --
    dividerTheme: const DividerThemeData(
      color: AppColors.darkBorder,
      thickness: 1,
      space: 1,
    ),

    // -- DatePicker / TimePicker --
    datePickerTheme: DatePickerThemeData(
      backgroundColor: AppColors.darkSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      headerBackgroundColor: AppColors.teal,
      headerForegroundColor: Colors.white,
      headerHeadlineStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      headerHelpStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        if (states.contains(WidgetState.disabled)) {
          return AppColors.darkTextSecondary.withAlpha(100);
        }
        return AppColors.darkTextPrimary;
      }),
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.teal;
        return null;
      }),
      todayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return AppColors.teal;
      }),
      todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.teal;
        return null;
      }),
      todayBorder: const BorderSide(color: AppColors.teal),
      yearForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return AppColors.darkTextPrimary;
      }),
      yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.teal;
        return null;
      }),
      cancelButtonStyle: TextButton.styleFrom(
        foregroundColor: AppColors.darkTextSecondary,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
      confirmButtonStyle: TextButton.styleFrom(
        foregroundColor: AppColors.teal,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
    ),
    timePickerTheme: TimePickerThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      confirmButtonStyle: TextButton.styleFrom(
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
      cancelButtonStyle: TextButton.styleFrom(
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
    ),
  );
}
