import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/signalr_client.dart';

import 'package:helpi_app/core/network/api_endpoints.dart';
import 'package:helpi_app/core/network/token_storage.dart';
import 'package:helpi_app/core/providers/auth_provider.dart';

/// SignalR klijent za real-time notifikacije s backenda.
///
/// Backend šalje:
///   - ReceiveNotification  (HNotificationDto JSON)
///   - UnreadCountUpdate    (int)
///   - TypingIndicator      (string)
///   - SystemNotification   (HNotificationDto JSON)
class SignalRService {
  SignalRService(this._tokenStorage);

  final TokenStorage _tokenStorage;
  HubConnection? _connection;
  bool _stoppedManually = false;
  int _reconnectAttempt = 0;

  final Map<String, List<void Function(List<Object?>?)>> _handlers = {};

  bool get isConnected =>
      _connection != null && _connection!.state == HubConnectionState.Connected;

  String get _hubUrl => '${ApiEndpoints.baseUrl}/hubs/notifications';

  Future<void> start() async {
    _stoppedManually = false;

    if (_connection == null) {
      _connection = HubConnectionBuilder()
          .withUrl(
            _hubUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: () async {
                return await _tokenStorage.getToken() ?? '';
              },
              transport: HttpTransportType.WebSockets,
            ),
          )
          .withAutomaticReconnect()
          .build();

      _connection!.onclose(({Exception? error}) {
        debugPrint('[SignalR] closed: $error');
        if (!_stoppedManually) {
          _scheduleReconnect();
        }
      });

      _connection!.onreconnected(({String? connectionId}) {
        debugPrint('[SignalR] reconnected: $connectionId');
        _reconnectAttempt = 0;
      });

      // Wire up all registered handlers
      for (final entry in _handlers.entries) {
        _connection!.on(entry.key, (args) {
          for (final listener in entry.value) {
            listener(args);
          }
        });
      }
    }

    if (_connection!.state == HubConnectionState.Disconnected) {
      await _startWithRetry();
    }
  }

  Future<void> stop() async {
    _stoppedManually = true;
    _reconnectAttempt = 0;
    try {
      await _connection?.stop();
    } catch (e) {
      debugPrint('[SignalR] stop error: $e');
    }
    _connection = null;
    _handlers.clear();
  }

  /// Registriraj handler za backend event (npr. "ReceiveNotification").
  void on(String eventName, void Function(List<Object?>?) handler) {
    final isNewEvent = !_handlers.containsKey(eventName);
    _handlers.putIfAbsent(eventName, () => []).add(handler);

    // Za NOVE event-ove na živoj konekciji, registriraj closure
    // koja iterira _handlers listu (isti pattern kao u start()).
    // Postojeći event-ovi su već pokriveni closure-om iz start().
    if (_connection != null && isNewEvent) {
      _connection!.on(eventName, (args) {
        for (final listener in _handlers[eventName]!) {
          listener(args);
        }
      });
    }
  }

  /// Pozovi metodu na hubu (npr. "JoinUserGroup").
  Future<void> invoke(String methodName, {List<Object>? args}) async {
    if (_connection == null ||
        _connection!.state != HubConnectionState.Connected) {
      debugPrint('[SignalR] invoke skipped — not connected');
      return;
    }
    try {
      await _connection!.invoke(methodName, args: args ?? []);
    } catch (e) {
      debugPrint('[SignalR] invoke error [$methodName]: $e');
    }
  }

  Future<void> _startWithRetry() async {
    const maxAttempts = 5;
    while (!_stoppedManually &&
        _connection!.state == HubConnectionState.Disconnected &&
        _reconnectAttempt < maxAttempts) {
      try {
        _reconnectAttempt++;
        debugPrint('[SignalR] connect attempt #$_reconnectAttempt');
        await _connection!.start();
        debugPrint('[SignalR] connected');
        _reconnectAttempt = 0;
        return;
      } catch (e) {
        debugPrint('[SignalR] connect failed: $e');
        final delay = Duration(seconds: _reconnectAttempt * 2);
        await Future.delayed(delay);
      }
    }
  }

  void _scheduleReconnect() {
    if (_stoppedManually) return;
    Future.delayed(Duration(seconds: 3 * (_reconnectAttempt + 1)), () {
      if (_stoppedManually) return;
      _reconnectAttempt++;
      _startWithRetry();
    });
  }
}

/// Singleton SignalR provider - lives while app is active.
final signalRProvider = Provider<SignalRService>((ref) {
  final service = SignalRService(TokenStorage());

  // Auto-connect/disconnect na temelju auth stanja
  ref.listen<AuthState>(authProvider, (prev, next) {
    if (next.isLoggedIn && !next.isSuspended) {
      service.start();
    } else if (prev != null && prev.isLoggedIn && !next.isLoggedIn) {
      service.stop();
    }
  }, fireImmediately: true);

  ref.onDispose(() {
    service.stop();
  });

  return service;
});
