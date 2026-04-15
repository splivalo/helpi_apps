import 'package:flutter/material.dart';

import 'package:helpi_app/core/constants/colors.dart';
import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/utils/formatters.dart';
import 'package:helpi_app/shared/widgets/star_rating.dart';

/// Inline review card - grey background with stars, date, and optional comment.
/// Tapping opens a dialog showing the full comment.
class ReviewInlineCard extends StatelessWidget {
  const ReviewInlineCard({
    super.key,
    required this.rating,
    required this.date,
    this.comment = '',
    this.compact = false,
  });

  final int rating;
  final DateTime date;
  final String comment;
  final bool compact;

  void _showFullReview(BuildContext context) {
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.reviewTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StarRating(rating: rating, size: 22),
                const Spacer(),
                Text(
                  AppFormatters.date(date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(comment, style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final starSize = compact ? 14.0 : 18.0;
    final dateFontSize = compact ? 11.0 : 12.0;
    final hPad = compact ? 10.0 : 12.0;
    final vPad = compact ? 8.0 : 10.0;
    final radius = compact ? 10.0 : 12.0;

    return GestureDetector(
      onTap: comment.isNotEmpty ? () => _showFullReview(context) : null,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.light
              ? const Color(0xFFFCFAF7)
              : const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StarRating(rating: rating, size: starSize),
                const Spacer(),
                Text(
                  AppFormatters.date(date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: dateFontSize,
                  ),
                ),
              ],
            ),
            if (comment.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  comment,
                  style: compact
                      ? theme.textTheme.bodySmall?.copyWith(fontSize: 12)
                      : theme.textTheme.bodySmall,
                  maxLines: compact ? 2 : null,
                  overflow: compact ? TextOverflow.ellipsis : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
