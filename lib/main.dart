import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/utils/logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait — change here if landscape support is needed.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Phase 1a: UI-only. No Firebase init here.
  // When re-enabling in Phase 1b, restore:
  //   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Catch any uncaught framework errors and route to our logger.
  FlutterError.onError = (details) {
    appLogger.e(
      'FlutterError: ${details.exceptionAsString()}',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  runApp(const ProviderScope(child: App()));
}
