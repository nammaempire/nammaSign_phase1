import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/analytics/analytics_identity_bootstrap.dart';
import '../core/constants/app_constants.dart';
import '../features/notifications/data/fcm_bootstrap.dart';
import '../shared/providers/theme_mode_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Root widget — sets up MaterialApp.router with our theme + router.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final mode = ref.watch(themeModeProvider);

    // Spawn FCM wiring once. The bootstrap reads the auth state internally
    // so it correctly defers token registration until sign-in completes.
    ref.watch(fcmBootstrapProvider);

    // Wire signed-in identity into Crashlytics + Analytics. Same pattern
    // as FCM — internal listener picks up auth changes.
    ref.watch(analyticsIdentityBootstrapProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: mode,
      routerConfig: router,
    );
  }
}
