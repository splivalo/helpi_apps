import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:helpi_app/app/app.dart';

// TODO(firebase): Add firebase_messaging + flutter_local_notifications.
// Initialize Firebase here, register FCM token, set up
// onMessage / onMessageOpenedApp / getInitialMessage listeners.
// Review notification (type: reviewRequest) should navigate user
// directly to OrderDetailScreen (senior) or JobDetailScreen (student)
// where the coral "Rate" button is already ready — NO separate modal.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  runApp(const ProviderScope(child: HelpiApp()));
}
