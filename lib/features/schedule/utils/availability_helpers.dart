import 'package:flutter/material.dart';

import 'package:helpi_app/features/schedule/data/availability_model.dart';
import 'package:helpi_app/features/schedule/widgets/time_slot_picker.dart';

/// Prikazuje time picker i ažurira [day.from] ili [day.to].
/// Vraća `true` ako je korisnik promijenio vrijednost.
Future<bool> pickAvailabilityTime({
  required BuildContext context,
  required DayAvailability day,
  required bool isFrom,
}) async {
  final initial = isFrom ? day.from : day.to;
  final minTime = isFrom ? null : day.from;

  final picked = await showTimeSlotPicker(
    context: context,
    initialTime: initial,
    minTime: minTime,
  );

  if (picked == null || picked == initial) return false;

  if (isFrom) {
    day.from = picked;
    // Ako je "od" >= "do", pomakni "do" za 1h naprijed.
    if (picked.hour >= day.to.hour && picked.minute >= day.to.minute) {
      day.to = TimeOfDay(hour: picked.hour + 1, minute: picked.minute);
    }
  } else {
    day.to = picked;
  }

  return true;
}
