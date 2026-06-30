import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/utils/logger.dart';
import 'firebase_options.dart';

/// Top-level background message handler. Runs in its own isolate when the
/// app is fully killed and a push arrives — so it MUST be a top-level
/// function and MUST initialize Firebase on its own.
///
/// We don't render anything here; the Cloud Function already wrote the
/// in-app notification row, so when the user opens the app they'll see
/// it in the bell. This handler just exists so Android shows the system
/// banner reliably.
@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Already initialized — fine.
  }
}

Future<void> main() async {
  // runZonedGuarded catches any *async* error that escapes the regular
  // Flutter framework + platform handlers — without it, a `Future` that
  // throws inside a callback would never reach Crashlytics.
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Lock to portrait — change here if landscape support is needed.
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Initialize Firebase BEFORE the error handlers — Crashlytics needs
    // the core SDK running to send anything.
    //
    // If init fails (bad config, no network at cold start), do NOT boot
    // the normal app — every Auth/Firestore call would throw and the
    // user would see a cascade of raw errors. Show a dedicated failure
    // screen instead.
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e, st) {
      appLogger.e('Firebase init failed', error: e, stackTrace: st);
      runApp(const _FirebaseInitErrorApp());
      return;
    }

    // ---- Crashlytics wiring ----
    //
    // Only enable Crashlytics in release builds. In debug we want errors
    // to land in the console with a full stack so we can fix them fast,
    // not get swallowed and shipped to the dashboard.
    final crashlytics = FirebaseCrashlytics.instance;
    await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

    // 1. Flutter framework errors (build failures, layout issues, etc.)
    FlutterError.onError = (details) {
      appLogger.e(
        'FlutterError: ${details.exceptionAsString()}',
        error: details.exception,
        stackTrace: details.stack,
      );
      crashlytics.recordFlutterFatalError(details);
    };

    // 2. Platform-channel / engine errors. These are async errors that
    //    bubble out of the Dart isolate — without this hook they'd just
    //    crash the app silently in production.
    PlatformDispatcher.instance.onError = (error, stack) {
      appLogger.e('PlatformDispatcher error', error: error, stackTrace: stack);
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };

    // 3. Errors in other isolates (rare but possible — e.g. an isolate
    //    spawned by a plugin). Forwards them to the main isolate so
    //    Crashlytics can capture them.
    Isolate.current.addErrorListener(RawReceivePort((pair) async {
      final List<dynamic> errorAndStacktrace = pair as List<dynamic>;
      await crashlytics.recordError(
        errorAndStacktrace.first,
        errorAndStacktrace.last as StackTrace?,
        fatal: true,
      );
    }).sendPort);

    // Register the FCM background handler BEFORE the app starts so a push
    // arriving in the kill-state isolate can wake the handler up.
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    runApp(const ProviderScope(child: App()));
  }, (error, stack) {
    // Anything that escapes the zone (typically: async errors from code
    // that doesn't have its own try/catch). Treat as non-fatal because
    // the app is still alive at this point.
    appLogger.e('Uncaught zone error', error: error, stackTrace: stack);
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: false);
  });
}

/// Minimal standalone app shown when Firebase fails to initialize. Kept
/// dependency-free (no providers/router) so it can render even when the
/// rest of the app's wiring is unavailable.
class _FirebaseInitErrorApp extends StatelessWidget {
  const _FirebaseInitErrorApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFFF4F1FA),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off_rounded, size: 56),
                SizedBox(height: 20),
                Text(
                  "Couldn't connect",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A22),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'NammaSign could not reach its servers. Check your internet '
                  'connection and reopen the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Color(0xFF6E6E7C),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
