import 'package:flutter/foundation.dart';

import 'package:helpi_app/core/services/app_api_service.dart';

/// Centralizirane cijene za Helpi app.
/// Defaults se koriste dok se ne učitaju iz API-ja.
///
// TODO(stripe-integration): Backend JobInstanceRepository.UpdateToInProgressAsync
//   has the PaymentStatus check commented out. When Stripe is fully integrated,
//   uncomment: if (instance?.PaymentStatus != PaymentStatus.Paid) return null;
//   Without it, sessions transition InProgress→Completed without charging.
class AppPricing {
  AppPricing._();

  static int hourlyRate = 14; // €/h standard (default, updated from API)
  static int sundayRate = 21; // €/h Sunday (default, updated from API)
  static int studentCancelCutoffHours = 6; // default, updated from API
  static int seniorCancelCutoffHours = 1; // default, updated from API
  static bool studentCancelEnabled = true; // default, updated from API
  static bool availabilityChangeEnabled = true; // default, updated from API
  static int availabilityChangeCutoffHours = 24; // default, updated from API

  /// Cijena za [hours] sati na [weekday] (1=Mon…7=Sun).
  static int priceForDay(int weekday, int hours) {
    final rate = weekday == DateTime.sunday ? sundayRate : hourlyRate;
    return rate * hours;
  }

  /// Format: "14,00 €"
  static String formatPrice(int euros) => '$euros,00 €';

  /// Učitaj cijene iz backend API-ja. Pozovi na login i na SettingsChanged.
  static Future<void> loadFromApi(AppApiService api) async {
    final result = await api.fetchPricingConfig();
    if (result.success && result.data != null) {
      final config = result.data!;
      hourlyRate = (config['jobHourlyRate'] as num?)?.toInt() ?? 14;
      sundayRate = (config['sundayHourlyRate'] as num?)?.toInt() ?? 21;
      studentCancelCutoffHours =
          (config['studentCancelCutoffHours'] as num?)?.toInt() ?? 6;
      seniorCancelCutoffHours =
          (config['seniorCancelCutoffHours'] as num?)?.toInt() ?? 1;
      studentCancelEnabled = config['studentCancelEnabled'] as bool? ?? true;
      availabilityChangeEnabled =
          config['availabilityChangeEnabled'] as bool? ?? true;
      availabilityChangeCutoffHours =
          (config['availabilityChangeCutoffHours'] as num?)?.toInt() ?? 24;
      debugPrint(
        '[AppPricing] loaded: hourly=$hourlyRate, sunday=$sundayRate, '
        'studentCutoff=${studentCancelCutoffHours}h, '
        'seniorCutoff=${seniorCancelCutoffHours}h, '
        'cancelEnabled=$studentCancelEnabled, '
        'availabilityEnabled=$availabilityChangeEnabled',
      );
    }
  }
}
