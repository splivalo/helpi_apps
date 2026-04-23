import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Parses a sponsor JSON map into [SponsorData]. Returns null if invalid.
SponsorData? parseSponsor(Map<String, dynamic> json) {
  final logoUrl = json['logoUrl'] as String? ?? '';
  if (logoUrl.isEmpty) return null;

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
}

/// Synchronous provider — populated by DataLoader at login.
/// No loading state = no layout shift.
final activeSponsorProvider = StateProvider<SponsorData?>((ref) => null);
