import 'package:flutter/material.dart';

import 'package:helpi_app/app/theme.dart';
import 'package:helpi_app/features/schedule/data/review_model.dart';
import 'package:helpi_app/features/schedule/widgets/star_rating.dart';

/// Single review card - used in statistics and job_detail screens.
class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key, required this.seniorName, required this.review});

  final String seniorName;
  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: HelpiTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: HelpiTheme.avatarBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline,
                    size: 20,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    seniorName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  review.date,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: HelpiTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            StarRating(rating: review.rating),
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(review.comment, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
