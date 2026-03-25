import 'package:flutter/material.dart';

/// Star display for rating - display-only or interactive.
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.rating,
    this.size = 18,
    this.onTap,
  });

  final int rating;
  final double size;

  /// Ako je null -> display-only. Inače -> interaktivan (tap na zvijezdu).
  final ValueChanged<int>? onTap;

  static const _starColor = Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final star = Icon(
          i < rating ? Icons.star : Icons.star_border,
          color: _starColor,
          size: size,
        );

        if (onTap != null) {
          return GestureDetector(
            onTap: () => onTap!(i + 1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: star,
            ),
          );
        }
        return star;
      }),
    );
  }
}
