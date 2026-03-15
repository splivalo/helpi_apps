import 'package:flutter/material.dart';

import 'package:helpi_app/app/theme.dart';

/// Zvjezdice za prikaz ocjene (read-only) ili interaktivni odabir.
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.rating,
    this.size = 20,
    this.onTap,
  });

  /// Trenutna ocjena (0-5).
  final int rating;

  /// Veličina zvjezdice.
  final double size;

  /// Ako je non-null, zvjezdice su interaktivne.
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final icon = Icon(
          i < rating ? Icons.star : Icons.star_border,
          size: size,
          color: HelpiTheme.star,
        );

        if (onTap != null) {
          return GestureDetector(
            onTap: () => onTap!(i + 1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: icon,
            ),
          );
        }
        return icon;
      }),
    );
  }
}
