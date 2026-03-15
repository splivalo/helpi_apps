import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:helpi_app/core/network/token_storage.dart';
import 'package:helpi_app/core/services/app_api_service.dart';
import 'package:helpi_app/features/booking/data/order_model.dart';
import 'package:helpi_app/features/schedule/data/job_model.dart';

/// Učitava podatke s backenda prema ulozi korisnika.
///
/// Za Senior: narudžbe iz `/api/orders/senior/{id}`.
/// Za Student: sesije iz `/api/sessions/student/{id}`.
///
/// Poziva se nakon uspješnog logina.  Ako backend ne odgovori,
/// postojeći mock podaci ostaju kao fallback.
class DataLoader {
  DataLoader._();

  static bool _loaded = false;
  static bool get isLoaded => _loaded;

  static const _timeout = Duration(seconds: 8);

  /// Učitaj podatke za trenutnog korisnika.
  ///
  /// [ordersNotifier] je potreban samo za Senior (Customer) — ako je null,
  /// senior narudžbe se preskaču.
  static Future<bool> loadAll({OrdersNotifier? ordersNotifier}) async {
    try {
      return await _doLoad(ordersNotifier: ordersNotifier).timeout(_timeout);
    } on TimeoutException {
      debugPrint('[DataLoader] loadAll TIMEOUT — using mock data');
      return false;
    } catch (e) {
      debugPrint('[DataLoader] loadAll ERROR: $e — using mock data');
      return false;
    }
  }

  static Future<bool> _doLoad({OrdersNotifier? ordersNotifier}) async {
    final storage = TokenStorage();
    final userId = await storage.getUserId();
    final userType = await storage.getUserType();

    if (userId == null || userType == null) {
      debugPrint('[DataLoader] no userId/userType — skipping');
      return false;
    }

    final api = AppApiService();
    var allOk = true;

    if (userType == 'Customer' && ordersNotifier != null) {
      // Senior: load orders
      final ordersResult = await api.getOrdersBySenior(userId);
      if (ordersResult.success && ordersResult.data != null) {
        ordersNotifier.replaceAll(ordersResult.data!);
        debugPrint(
          '[DataLoader] senior orders loaded: ${ordersResult.data!.length}',
        );
      } else {
        debugPrint(
          '[DataLoader] senior orders failed: ${ordersResult.error}',
        );
        allOk = false;
      }
    } else if (userType == 'Student') {
      // Student: load sessions → MockJobs
      final sessionsResult = await api.getSessionsByStudent(userId);
      if (sessionsResult.success && sessionsResult.data != null) {
        MockJobs.all
          ..clear()
          ..addAll(sessionsResult.data!);
        debugPrint(
          '[DataLoader] student jobs loaded: ${sessionsResult.data!.length}',
        );
      } else {
        debugPrint(
          '[DataLoader] student sessions failed: ${sessionsResult.error}',
        );
        allOk = false;
      }
    }

    _loaded = allOk;
    return allOk;
  }

  /// Reset na logout.
  static void reset() {
    _loaded = false;
  }
}
