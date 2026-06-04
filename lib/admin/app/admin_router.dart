import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../features/areas/screens/areas_list_screen.dart';
import '../features/auth/providers/is_admin_provider.dart';
import '../features/auth/screens/admin_login_screen.dart';
import '../features/auth/screens/not_authorized_screen.dart';
import '../features/bookings/screens/booking_detail_screen.dart';
import '../features/bookings/screens/bookings_queue_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/faqs/screens/admin_faqs_screen.dart';
import '../features/finance/screens/finance_screen.dart';
import '../features/users/screens/user_detail_screen.dart';
import '../features/users/screens/users_list_screen.dart';
import 'admin_routes.dart';

final adminRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AdminRoutes.dashboard,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final admin = ref.read(isAdminProvider);
      final loc = state.matchedLocation;

      if (auth.isLoading || admin.isLoading) return null;

      final signedIn = auth.asData?.value != null;
      final isAdmin = admin.asData?.value ?? false;

      if (!signedIn) {
        return loc == AdminRoutes.login ? null : AdminRoutes.login;
      }
      if (!isAdmin) {
        return loc == AdminRoutes.notAuthorized
            ? null
            : AdminRoutes.notAuthorized;
      }
      if (loc == AdminRoutes.login || loc == AdminRoutes.notAuthorized) {
        return AdminRoutes.dashboard;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AdminRoutes.login,
        builder: (_, __) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: AdminRoutes.notAuthorized,
        builder: (_, __) => const NotAuthorizedScreen(),
      ),
      GoRoute(
        path: AdminRoutes.dashboard,
        builder: (_, __) => const DashboardScreen(),
      ),
      GoRoute(
        path: AdminRoutes.bookings,
        builder: (_, __) => const BookingsQueueScreen(),
      ),
      GoRoute(
        path: AdminRoutes.bookingDetail,
        builder: (_, state) => BookingDetailScreen(
          bookingId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AdminRoutes.users,
        builder: (_, __) => const UsersListScreen(),
      ),
      GoRoute(
        path: AdminRoutes.userDetail,
        builder: (_, state) =>
            UserDetailScreen(uid: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AdminRoutes.areas,
        builder: (_, __) => const AreasListScreen(),
      ),
      GoRoute(
        path: AdminRoutes.finance,
        builder: (_, __) => const FinanceScreen(),
      ),
      GoRoute(
        path: AdminRoutes.faqs,
        builder: (_, __) => const AdminFaqsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );

  ref.listen<AsyncValue<AppUser?>>(authStateProvider, (prev, next) {
    router.refresh();
  });
  ref.listen<AsyncValue<bool>>(isAdminProvider, (prev, next) {
    router.refresh();
  });

  return router;
});
