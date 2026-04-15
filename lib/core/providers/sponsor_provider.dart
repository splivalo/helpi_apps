import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:helpi_app/core/services/app_api_service.dart';

/// Active sponsor data from backend.
class SponsorData {
  const SponsorData({
    required this.name,
    required this.logoUrl,
    this.darkLogoUrl,
    this.linkUrl,
    required this.labelMap,
  });

  final String name;
  final String logoUrl;
  final String? darkLogoUrl;
  final String? linkUrl;
  final Map<String, String> labelMap;

  /// Returns the label for the given locale, with fallback to 'hr'.
  String label(String locale) => labelMap[locale] ?? labelMap['hr'] ?? '';
}

/// Fetches the first active sponsor once and caches it for the app lifetime.
final activeSponsorProvider = FutureProvider<SponsorData?>((ref) async {
  final api = AppApiService();
  final result = await api.getActiveSponsor();
  if (!result.success || result.data == null) return null;

  final json = result.data!;
  final logoUrl = json['logoUrl'] as String? ?? '';
  if (logoUrl.isEmpty) return null;

  // Label is a JSON map: {"hr": "Uz podršku", "en": "Supported by"}
  final Map<String, String> labelMap = {};
  final rawLabel = json['label'];
  if (rawLabel is Map) {
    for (final e in rawLabel.entries) {
      labelMap[e.key.toString()] = e.value.toString();
    }
  } else if (rawLabel is String) {
    labelMap['hr'] = rawLabel;
  }

  return SponsorData(
    name: json['name'] as String? ?? '',
    logoUrl: logoUrl,
    darkLogoUrl: json['darkLogoUrl'] as String?,
    linkUrl: json['linkUrl'] as String?,
    labelMap: labelMap,
  );
});
