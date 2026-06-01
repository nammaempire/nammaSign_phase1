import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin/app/admin_app.dart';
import 'core/utils/logger.dart';
import 'firebase_options.dart';

/// Separate entry point for the NammaSign **admin web portal**.
///
/// Run dev:    flutter run -t lib/main_admin.dart -d chrome
/// Build prod: flutter build web -t lib/main_admin.dart
///
/// Same Firebase project as the mobile app; admin privileges are gated by
/// a Firestore doc at `admin/users/{uid}`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    appLogger.e(
      'FlutterError: ${details.exceptionAsString()}',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, st) {
    appLogger.e('Firebase init failed (admin)', error: e, stackTrace: st);
  }

  runApp(const ProviderScope(child: AdminApp()));
}
