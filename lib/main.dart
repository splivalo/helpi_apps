import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:helpi_app/app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Status bar stil — tamni ikoni na svijetloj pozadini.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const HelpiApp());
}
