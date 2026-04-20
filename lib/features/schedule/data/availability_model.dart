import 'package:flutter/material.dart';

/// Availability model for one day of the week.
class DayAvailability {
  DayAvailability({
    required this.dayKey,
    this.enabled = false,
    this.from = const TimeOfDay(hour: 8, minute: 0),
    this.to = const TimeOfDay(hour: 16, minute: 0),
  });

  /// Ključ za AppStrings (npr. 'dayMonFull').
  final String dayKey;

  bool enabled;
  TimeOfDay from;
  TimeOfDay to;
}

/// Holds availability list by day - shared between onboarding and profile.
class AvailabilityNotifier extends ValueNotifier<List<DayAvailability>> {
  AvailabilityNotifier() : super(_defaultAvailability());

  static List<DayAvailability> _defaultAvailability() => [
    DayAvailability(
      dayKey: 'dayMonFull',
      from: const TimeOfDay(hour: 8, minute: 0),
      to: const TimeOfDay(hour: 16, minute: 0),
    ),
    DayAvailability(
      dayKey: 'dayTueFull',
      from: const TimeOfDay(hour: 8, minute: 0),
      to: const TimeOfDay(hour: 16, minute: 0),
    ),
    DayAvailability(
      dayKey: 'dayWedFull',
      from: const TimeOfDay(hour: 8, minute: 0),
      to: const TimeOfDay(hour: 16, minute: 0),
    ),
    DayAvailability(
      dayKey: 'dayThuFull',
      from: const TimeOfDay(hour: 8, minute: 0),
      to: const TimeOfDay(hour: 16, minute: 0),
    ),
    DayAvailability(
      dayKey: 'dayFriFull',
      from: const TimeOfDay(hour: 8, minute: 0),
      to: const TimeOfDay(hour: 16, minute: 0),
    ),
    DayAvailability(
      dayKey: 'daySatFull',
      from: const TimeOfDay(hour: 8, minute: 0),
      to: const TimeOfDay(hour: 16, minute: 0),
    ),
    DayAvailability(
      dayKey: 'daySunFull',
      from: const TimeOfDay(hour: 8, minute: 0),
      to: const TimeOfDay(hour: 16, minute: 0),
    ),
  ];

  /// Day key -> DayOfWeek (1=Pon, 2=Uto, ... 7=Ned).
  static int dayKeyToWeekday(String dayKey) {
    switch (dayKey) {
      case 'dayMonFull':
        return 1;
      case 'dayTueFull':
        return 2;
      case 'dayWedFull':
        return 3;
      case 'dayThuFull':
        return 4;
      case 'dayFriFull':
        return 5;
      case 'daySatFull':
        return 6;
      case 'daySunFull':
        return 7;
      default:
        return 1;
    }
  }

  /// DayOfWeek -> day key.
  static String _weekdayToDayKey(int weekday) {
    switch (weekday) {
      case 1:
        return 'dayMonFull';
      case 2:
        return 'dayTueFull';
      case 3:
        return 'dayWedFull';
      case 4:
        return 'dayThuFull';
      case 5:
        return 'dayFriFull';
      case 6:
        return 'daySatFull';
      case 7:
        return 'daySunFull';
      default:
        return 'dayMonFull';
    }
  }

  /// Load availability from backend JSON.
  void loadFromBackend(List<Map<String, dynamic>> slots) {
    // Resetiraj na default (sve disabled)
    final days = _defaultAvailability();

    for (final slot in slots) {
      final dayOfWeek = (slot['dayOfWeek'] as num?)?.toInt() ?? 1;
      final startTime = slot['startTime'] as String? ?? '08:00:00';
      final endTime = slot['endTime'] as String? ?? '16:00:00';

      final dayKey = _weekdayToDayKey(dayOfWeek);
      final dayIndex = days.indexWhere((d) => d.dayKey == dayKey);

      if (dayIndex != -1) {
        days[dayIndex].enabled = true;
        days[dayIndex].from = _parseTime(startTime);
        days[dayIndex].to = _parseTime(endTime);
      }
    }

    value = days;
  }

  /// Parse "HH:mm:ss" ili "HH:mm" string u TimeOfDay.
  static TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Convert current availability to backend API format.
  List<Map<String, dynamic>> toBackendPayload(int studentId) {
    return value
        .where((d) => d.enabled)
        .map(
          (d) => {
            'studentId': studentId,
            'dayOfWeek': dayKeyToWeekday(d.dayKey),
            'startTime':
                '${d.from.hour.toString().padLeft(2, '0')}:${d.from.minute.toString().padLeft(2, '0')}:00',
            'endTime':
                '${d.to.hour.toString().padLeft(2, '0')}:${d.to.minute.toString().padLeft(2, '0')}:00',
          },
        )
        .toList();
  }

  /// Ima li barem 1 dan uključen?
  bool get hasAnyDayEnabled => value.any((d) => d.enabled);

  /// Ručno obavijesti listenere.
  void notify() => notifyListeners();

  /// Resetiraj na default.
  void reset() {
    value = _defaultAvailability();
  }
}
