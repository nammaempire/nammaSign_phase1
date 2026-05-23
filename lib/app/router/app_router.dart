import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/providers/splash_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/account_type/presentation/screens/account_type_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/booking/presentation/screens/booking_account_type_screen.dart';
import '../../features/booking/presentation/screens/corporate_campaign_screen.dart';
import '../../features/booking/presentation/screens/individual_campaign_screen.dart';
import '../../features/booking/presentation/screens/payment_failure_screen.dart';
import '../../features/booking/presentation/screens/payment_success_screen.dart';
import '../../features/booking/presentation/screens/review_pay_screen.dart';
import '../../features/campaign/presentation/screens/campaign_status_screen.dart';
import '../../features/history/domain/booking.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/home/domain/billboard_listing.dart';
import '../../features/signup/presentation/screens/corporate_signup_screen.dart';
import '../../features/signup/presentation/screens/individual_signup_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/main_shell.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../shared/providers/app_prefs_provider.dart';
import 'app_routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: _StreamListenable(
      ref.read(authRepositoryProvider).authStateChanges(),
    ),
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final prefsReady = ref.read(prefsReadyProvider);
      final splashDone = ref.read(splashCompleteProvider);
      final loc = state.matchedLocation;

      // Still resolving auth/prefs OR the 3-second splash animation isn't
      // finished yet — hold on the splash screen.
      if (auth.isLoading || !prefsReady || !splashDone) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final seenOnboarding = ref.read(onboardingSeenProvider);
      final signedIn = auth.asData?.value != null;
      final atAuthRoute = loc == AppRoutes.login ||
          loc == AppRoutes.otp ||
          loc.startsWith('/signup');
      final atOnboarding = loc == AppRoutes.onboarding ||
          loc == AppRoutes.accountType;

      // Not signed in
      if (!signedIn) {
        if (!seenOnboarding && !atOnboarding) return AppRoutes.onboarding;
        if (seenOnboarding && !atAuthRoute && !atOnboarding) {
          return AppRoutes.login;
        }
        return null;
      }

      // Signed in but on auth/onboarding/splash — go home.
      if (atAuthRoute || atOnboarding || loc == AppRoutes.splash) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.accountType,
        builder: (_, __) => const AccountTypeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (_, __) => const OtpScreen(),
      ),
      GoRoute(
        path: AppRoutes.signupCorporate,
        builder: (_, __) => const CorporateSignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.signupIndividual,
        builder: (_, __) => const IndividualSignupScreen(),
      ),

      // Booking flow (only reachable when signed in)
      GoRoute(
        path: AppRoutes.bookingSelectType,
        builder: (_, state) {
          final id = state.uri.queryParameters['listingId'];
          final listing = sampleListings.firstWhere(
            (l) => l.id == id,
            orElse: () => sampleListings.first,
          );
          return BookingAccountTypeScreen(listing: listing);
        },
      ),
      GoRoute(
        path: AppRoutes.bookingCorporate,
        builder: (_, __) => const CorporateCampaignScreen(),
      ),
      GoRoute(
        path: AppRoutes.bookingIndividual,
        builder: (_, __) => const IndividualCampaignScreen(),
      ),
      GoRoute(
        path: AppRoutes.bookingReview,
        builder: (_, __) => const ReviewPayScreen(),
      ),
      GoRoute(
        path: AppRoutes.bookingSuccess,
        builder: (_, __) => const PaymentSuccessScreen(),
      ),
      GoRoute(
        path: AppRoutes.bookingFailure,
        builder: (_, __) => const PaymentFailureScreen(),
      ),
      GoRoute(
        path: AppRoutes.campaignStatus,
        builder: (_, state) {
          final id = state.pathParameters['bookingId'];
          final booking = sampleBookings.firstWhere(
            (b) => b.id == id,
            orElse: () => sampleBookings.first,
          );
          return CampaignStatusScreen(booking: booking);
        },
      ),

      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (_, __) => const HomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.history,
              builder: (_, __) => const HistoryScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (_, __) => const ProfileScreen(),
            ),
          ]),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );

  // Trigger a redirect re-evaluation once SharedPreferences finishes loading,
  // so the user moves off the splash screen as soon as we know the
  // onboarding-complete flag.
  ref.listen<bool>(prefsReadyProvider, (prev, next) {
    if (next) router.refresh();
  });

  // Also refresh when the splash animation completes — that's the signal
  // for the router to redirect away from /splash.
  ref.listen<bool>(splashCompleteProvider, (prev, next) {
    if (next) router.refresh();
  });

  // Refresh when the user finishes onboarding (account-type Continue),
  // so the redirect correctly stops gating on /onboarding.
  ref.listen<bool>(onboardingSeenProvider, (prev, next) {
    if (next) router.refresh();
  });

  return router;
});

/// Bridges a [Stream] to GoRouter's [Listenable] for redirect refresh.
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
