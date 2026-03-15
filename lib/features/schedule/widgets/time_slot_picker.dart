import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:helpi_app/core/l10n/app_strings.dart';

/// Dozvoljeni sati za radno vrijeme studenta.
const _minHour = 8;
const _maxHour = 20;

/// Svi dozvoljeni sati: 8, 9, 10 … 20.
final _hours = List.generate(_maxHour - _minHour + 1, (i) => _minHour + i);

/// Dozvoljene minute: 00, 15, 30, 45.
const _minutes = [0, 15, 30, 45];

/// Prikazuje bottom-sheet picker s dva wheela (sati 8–20 + minute 00/15/30/45).
///
/// [minTime] — minimalno dozvoljeno vrijeme (koristi se za "Do" picker da
/// spriječi odabir vremena ≤ "Od"). Ako je null, nema ograničenja.
///
/// Vraća [TimeOfDay] ako korisnik potvrdi, `null` ako odustane.
Future<TimeOfDay?> showTimeSlotPicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  TimeOfDay? minTime,
}) {
  // Snap initial time na najbliži valjani slot.
  var hourIndex = _hours.indexOf(initialTime.hour);
  if (hourIndex < 0) {
    hourIndex = initialTime.hour < _minHour ? 0 : _hours.length - 1;
  }
  var minuteIndex = _minutes.indexOf(initialTime.minute);
  if (minuteIndex < 0) {
    // Snap na najbliži 15-min interval.
    minuteIndex = 0;
    for (var i = _minutes.length - 1; i >= 0; i--) {
      if (initialTime.minute >= _minutes[i]) {
        minuteIndex = i;
        break;
      }
    }
  }

  // Ako initialTime < minTime, snap gore.
  if (minTime != null) {
    final initTotal = _hours[hourIndex] * 60 + _minutes[minuteIndex];
    final minTotal = minTime.hour * 60 + minTime.minute;
    if (initTotal <= minTotal) {
      // Pomakni na prvi slot nakon minTime.
      final snapped = _snapAfterMin(minTime);
      hourIndex = _hours.indexOf(snapped.hour);
      minuteIndex = _minutes.indexOf(snapped.minute);
      if (hourIndex < 0) hourIndex = _hours.length - 1;
      if (minuteIndex < 0) minuteIndex = 0;
    }
  }

  final theme = Theme.of(context);
  final teal = theme.colorScheme.secondary;

  return showModalBottomSheet<TimeOfDay>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      var selectedHour = _hours[hourIndex];
      var selectedMinute = _minutes[minuteIndex];

      final hourController = FixedExtentScrollController(
        initialItem: hourIndex,
      );
      final minuteController = FixedExtentScrollController(
        initialItem: minuteIndex,
      );

      /// Osigurava da odabrano vrijeme nije ≤ minTime.
      void enforceMin() {
        if (minTime == null) return;
        final current = selectedHour * 60 + selectedMinute;
        final minTotal = minTime.hour * 60 + minTime.minute;
        if (current <= minTotal) {
          final snapped = _snapAfterMin(minTime);
          final newHourIdx = _hours.indexOf(snapped.hour);
          final newMinIdx = _minutes.indexOf(snapped.minute);
          if (newHourIdx >= 0 && newHourIdx != _hours.indexOf(selectedHour)) {
            selectedHour = snapped.hour;
            hourController.jumpToItem(newHourIdx);
          }
          if (newMinIdx >= 0 && newMinIdx != _minutes.indexOf(selectedMinute)) {
            selectedMinute = snapped.minute;
            minuteController.jumpToItem(newMinIdx);
          }
        }
      }

      return SafeArea(
        child: SizedBox(
          height: 300,
          child: Column(
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        AppStrings.cancel,
                        style: TextStyle(color: teal, fontSize: 16),
                      ),
                    ),
                    Text(
                      AppStrings.selectTime,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(
                        ctx,
                        TimeOfDay(hour: selectedHour, minute: selectedMinute),
                      ),
                      child: Text(
                        AppStrings.confirm,
                        style: TextStyle(
                          color: teal,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // ── Wheels ──
              Expanded(
                child: Row(
                  children: [
                    // Sati wheel
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: hourController,
                        itemExtent: 44,
                        onSelectedItemChanged: (i) {
                          selectedHour = _hours[i];
                          enforceMin();
                        },
                        children: _hours
                            .map(
                              (h) => Center(
                                child: Text(
                                  h.toString().padLeft(2, '0'),
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),

                    // Separator
                    const Text(
                      ':',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    // Minute wheel
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: minuteController,
                        itemExtent: 44,
                        onSelectedItemChanged: (i) {
                          selectedMinute = _minutes[i];
                          enforceMin();
                        },
                        children: _minutes
                            .map(
                              (m) => Center(
                                child: Text(
                                  m.toString().padLeft(2, '0'),
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Vraća prvi 15-min slot strogo nakon [min].
TimeOfDay _snapAfterMin(TimeOfDay min) {
  final totalMin = min.hour * 60 + min.minute;
  // Sljedeći 15-min slot.
  final next = ((totalMin ~/ 15) + 1) * 15;
  final hour = next ~/ 60;
  final minute = next % 60;
  // Clamp unutar dozvoljenog raspona.
  if (hour > _maxHour || (hour == _maxHour && minute > 0)) {
    return TimeOfDay(hour: _maxHour, minute: 0);
  }
  if (hour < _minHour) {
    return TimeOfDay(hour: _minHour, minute: 0);
  }
  return TimeOfDay(hour: hour, minute: minute);
}
