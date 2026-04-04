import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:helpi_app/core/constants/pricing.dart';
import 'package:helpi_app/core/network/token_storage.dart';
import 'package:helpi_app/core/providers/auth_provider.dart';
import 'package:helpi_app/core/providers/jobs_provider.dart';
import 'package:helpi_app/core/providers/signalr_provider.dart';
import 'package:helpi_app/core/services/app_api_service.dart';

/// Listens to SignalR events and auto-refreshes data.
///
/// Backend šalje "ReceiveNotification" s HNotificationDto koji sadrži
/// notification type. On every relevant event, we refresh data
/// for the current user.
class RealTimeSyncService {
  RealTimeSyncService(this._ref) {
    _init();
  }

  static const _refreshingNotificationTypes = {
    1, // paymentSuccess
    2, // paymentFailed
    4, // jobRequest
    7, // jobCompleted
    8, // jobCancelled
    9, // jobRescheduled
    12, // orderCancelled
    15, // contractAdded
    16, // contractUpdated
    17, // contractDeleted
    22, // reassignmentStarted
    23, // reassignmentCompleted
    30, // newOrderAdded
    32, // orderBackToProcessing
  };

  final Ref _ref;
  final _api = AppApiService();
  final _tokenStorage = TokenStorage();
  bool _listening = false;

  void _init() {
    _ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.isLoggedIn && !next.isSuspended && !_listening) {
        _startListening();
        // Load dynamic pricing from backend
        AppPricing.loadFromApi(_api);
        // Initial data load via provider
        if (next.userType == 'Student') {
          _ref.read(jobsProvider.notifier).loadJobs();
        }
      } else if (prev != null && prev.isLoggedIn && !next.isLoggedIn) {
        _listening = false;
      }
    });
  }

  void _startListening() {
    final signalR = _ref.read(signalRProvider);
    _listening = true;

    signalR.on('ReceiveNotification', (args) {
      debugPrint('[RealTimeSync] ReceiveNotification: $args');
      if (_shouldRefreshForNotification(args)) {
        _refreshData();
      }
    });

    signalR.on('SystemNotification', (args) {
      debugPrint('[RealTimeSync] SystemNotification: $args');
      _refreshData();
    });

    signalR.on('SettingsChanged', (args) async {
      debugPrint('[RealTimeSync] SettingsChanged — refreshing pricing + data');
      await AppPricing.loadFromApi(_api);
      _refreshData();
    });
  }

  bool _shouldRefreshForNotification(List<Object?>? args) {
    final type = _extractNotificationType(args);
    if (type == null) {
      return true;
    }

    return _refreshingNotificationTypes.contains(type);
  }

  int? _extractNotificationType(List<Object?>? args) {
    if (args == null || args.isEmpty) {
      return null;
    }

    final raw = args.first;
    if (raw is Map<Object?, Object?>) {
      final json = Map<String, dynamic>.from(raw);
      return _parseNotificationTypeValue(json['type']);
    }

    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return _parseNotificationTypeValue(decoded['type']);
        }
      } catch (error) {
        debugPrint('[RealTimeSync] notification parse fallback: $error');
      }
    }

    return null;
  }

  int? _parseNotificationTypeValue(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }

  Future<void> _refreshData() async {
    final auth = _ref.read(authProvider);
    if (!auth.isLoggedIn) return;

    final authNotifier = _ref.read(authProvider.notifier);

    if (auth.userType == 'Customer') {
      await _refreshSeniorOrders(authNotifier);
    } else if (auth.userType == 'Student') {
      await _refreshStudentJobs(authNotifier);
    }
  }

  Future<void> _refreshSeniorOrders(AuthNotifier authNotifier) async {
    final seniorId = await _tokenStorage.getSeniorId();
    if (seniorId == null) return;

    final result = await _api.getOrdersBySenior(seniorId);
    if (result.success && result.data != null) {
      authNotifier.ordersNotifier.replaceAll(result.data!);
      debugPrint(
        '[RealTimeSync] senior orders refreshed: ${result.data!.length}',
      );
    }
  }

  Future<void> _refreshStudentJobs(AuthNotifier authNotifier) async {
    final userId = await _tokenStorage.getUserId();
    if (userId == null) return;

    final result = await _api.getSessionsByStudent(userId);
    if (result.success && result.data != null) {
      _ref.read(jobsProvider.notifier).replaceAll(result.data!);
      debugPrint(
        '[RealTimeSync] student jobs refreshed: ${result.data!.length}',
      );
    }
  }
}

/// Eager provider - initializes as soon as someone reads it.
final realTimeSyncProvider = Provider<RealTimeSyncService>((ref) {
  return RealTimeSyncService(ref);
});
