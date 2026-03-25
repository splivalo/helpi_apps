import 'package:flutter/material.dart';

/// Centralized format functions - eliminates duplicate _formatTime, _formatDate, _dayName.
class Formatters {
  Formatters._();

  /// "09:00" - padded with zeros.
  static String formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// "01.03.2026." - dd.MM.yyyy.
  static String formatDateFull(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}.';
  }

  /// "1.3.2026." - short d.M.yyyy. (used by schedule_screen).
  static String formatDateShort(DateTime date) {
    return '${date.day}.${date.month}.${date.year}.';
  }

  /// "01.03." - dd.MM. (for statistics weekly chart).
  static String formatDateCompact(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.';
  }
}
