import 'package:flutter/material.dart';

/// Model dostupnosti za jedan dan u tjednu.
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

/// Drži listu dostupnosti po danima — dijeli se između onboardinga i profila.
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

  /// Ima li barem 1 dan uključen?
  bool get hasAnyDayEnabled => value.any((d) => d.enabled);

  /// Ručno obavijesti listenere.
  void notify() => notifyListeners();

  /// Resetiraj na default.
  void reset() {
    value = _defaultAvailability();
  }
}
