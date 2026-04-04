import 'package:flutter/foundation.dart';

import 'package:helpi_app/core/services/app_api_service.dart';

/// Centralizirane cijene za Helpi app.
/// Defaults se koriste dok se ne učitaju iz API-ja.
class AppPricing {
  AppPricing._();

  static int hourlyRate = 14; // €/h standard (default, updated from API)
  static int sundayRate = 21; // €/h Sunday (default, updated from API)

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
      debugPrint('[AppPricing] loaded: hourly=$hourlyRate, sunday=$sundayRate');
    }
  }
}
