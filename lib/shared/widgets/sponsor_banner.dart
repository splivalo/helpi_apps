import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/network/api_endpoints.dart';
import 'package:helpi_app/core/providers/sponsor_provider.dart';

/// Sponsor banner — fetches data from GET /api/Sponsors/active via
/// [activeSponsorProvider]. Renders nothing when no active sponsor exists.
class SponsorBanner extends ConsumerWidget {
  const SponsorBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sponsor = ref.watch(activeSponsorProvider);
    if (sponsor == null) return const SizedBox.shrink();
    return _buildBanner(context, sponsor);
  }

  Widget _buildBanner(BuildContext context, SponsorData sponsor) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final localLabel = sponsor.label(AppStrings.currentLocale);

    // Pick dark logo in dark mode if available, otherwise light logo.
    final logoPath =
        (isDark &&
            sponsor.darkLogoUrl != null &&
            sponsor.darkLogoUrl!.isNotEmpty)
        ? sponsor.darkLogoUrl!
        : sponsor.logoUrl;

    final fullUrl = '${ApiEndpoints.baseUrl}$logoPath';
    final isSvg = logoPath.toLowerCase().endsWith('.svg');

    final systemBottom = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: systemBottom > 0 ? systemBottom : 0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isSvg
                ? SvgPicture.network(
                    fullUrl,
                    height: 24,
                    fit: BoxFit.contain,
                    placeholderBuilder: (_) =>
                        const SizedBox(width: 24, height: 24),
                  )
                : CachedNetworkImage(
                    imageUrl: fullUrl,
                    height: 24,
                    fit: BoxFit.contain,
                    fadeInDuration: const Duration(milliseconds: 150),
                    placeholder: (_, _) => const SizedBox(width: 24, height: 24),
                    errorWidget: (_, _, _) => const SizedBox(width: 24, height: 24),
                  ),
            if (localLabel.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                localLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
