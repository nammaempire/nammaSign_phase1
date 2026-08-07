import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/theme/admin_theme.dart';
import 'admin_router.dart';

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(adminRouterProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Reset95 Admin',
      theme: buildAdminTheme(),
      routerConfig: router,
    );
  }
}
