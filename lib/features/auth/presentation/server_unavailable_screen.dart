import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:helpi_app/core/l10n/app_strings.dart';
import 'package:helpi_app/core/network/api_endpoints.dart';

/// Full-screen prikazuje se kad backend ne odgovara.
///
/// Auto-retry svakih 10 sekundi + ručni retry gumb.
/// Kad server odgovori, poziva [onServerBack].
class ServerUnavailableScreen extends StatefulWidget {
  final VoidCallback onServerBack;

  const ServerUnavailableScreen({super.key, required this.onServerBack});

  @override
  State<ServerUnavailableScreen> createState() =>
      _ServerUnavailableScreenState();
}

class _ServerUnavailableScreenState extends State<ServerUnavailableScreen> {
  Timer? _autoRetryTimer;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _startAutoRetry();
  }

  @override
  void dispose() {
    _autoRetryTimer?.cancel();
    super.dispose();
  }

  void _startAutoRetry() {
    _autoRetryTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkHealth(),
    );
  }

  Future<void> _checkHealth() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);

    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );
      final response = await dio.get('${ApiEndpoints.baseUrl}/health');
      if (!mounted) return;
      if (response.statusCode == 200) {
        _autoRetryTimer?.cancel();
        widget.onServerBack();
        return;
      }
    } catch (_) {
      // Still down
    }
    if (!mounted) return;
    setState(() => _isRetrying = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 80, color: theme.colorScheme.error),
                const SizedBox(height: 24),
                Text(
                  AppStrings.serverUnavailableTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.serverUnavailableMessage,
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (_isRetrying)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.serverUnavailableRetrying,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(153),
                        ),
                      ),
                    ],
                  )
                else
                  const SizedBox(height: 16),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isRetrying ? null : _checkHealth,
                  icon: const Icon(Icons.refresh),
                  label: Text(AppStrings.serverUnavailableRetry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
