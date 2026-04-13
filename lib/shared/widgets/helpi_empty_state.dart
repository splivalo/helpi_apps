import 'package:flutter/material.dart';

/// Unified empty-state placeholder used across the app.
///
/// Full-page variant (default): centred icon + title + optional subtitle.
/// Inline variant ([HelpiEmptyState.inline]): compact row with small icon + text,
/// used inside form sections (e.g. "no saved cards").
class HelpiEmptyState extends StatelessWidget {
  const HelpiEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  }) : _inline = false;

  const HelpiEmptyState.inline({
    super.key,
    required this.icon,
    required this.title,
  }) : subtitle = null,
       _inline = true;

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool _inline;

  @override
  Widget build(BuildContext context) {
    if (_inline) return _buildInline(context);
    return _buildFullPage(context);
  }

  Widget _buildInline(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant.withAlpha(130);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildFullPage(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.onSurfaceVariant.withAlpha(100);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 80, color: iconColor),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withAlpha(160),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
