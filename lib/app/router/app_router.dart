import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/logger.dart';
import '../../features/auth/domain/entities/app_user.dart';
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
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/home/presentation/providers/listings_provider.dart';
import '../../features/signup/presentation/screens/corporate_signup_screen.dart';
import '../../features/signup/presentation/screens/individual_signup_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/main_shell.dart';
import '../../features/help/presentation/screens/help_screen.dart';
import '../../features/legal/presentation/screens/legal_page_screen.dart';
import '../../features/notifications/data/fcm_bootstrap.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/screens/personal_info_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/user/presentation/providers/user_profile_provider.dart';
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

      // TEMP diagnostic — remove once splash navigation is confirmed.
      appLogger.d(
        'REDIRECT loc=$loc authLoading=${auth.isLoading} '
        'authErr=${auth.hasError} signedIn=${auth.asData?.value != null} '
        'prefsReady=$prefsReady splashDone=$splashDone',
      );

      // Still resolving auth/prefs OR the 3-second splash animation isn't
      // finished yet — hold on the splash screen.
      if (auth.isLoading || !prefsReady || !splashDone) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final seenOnboarding = ref.read(onboardingSeenProvider);
      final signedIn = auth.asData?.value != null;
      final atAuthRoute =
          loc == AppRoutes.login || loc == AppRoutes.otp;
      final atSetupRoute =
          loc == AppRoutes.accountType || loc.startsWith('/signup');
      final atOnboardingRoute = loc == AppRoutes.onboarding;

      // ---- Not signed in ----
      if (!signedIn) {
        // First-launch users see onboarding before login.
        if (!seenOnboarding && !atOnboardingRoute) {
          return AppRoutes.onboarding;
        }
        if (seenOnboarding && !atAuthRoute && !atOnboardingRoute) {
          return AppRoutes.login;
        }
        return null;
      }

      // ---- Signed in ----
      // Wait for the user's Firestore profile to load before deciding
      // whether they're returning or need first-time setup.
      final profileAsync = ref.read(userProfileProvider);
      if (profileAsync.isLoading) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }
      final profile = profileAsync.asData?.value;
      final isSetupComplete = profile?.isSetupComplete ?? false;

      // First-time user — force them through the setup flow until they
      // complete the corporate/individual form. Once isSetupComplete
      // flips true, the next redirect carries them on to /home.
      if (!isSetupComplete) {
        if (atSetupRoute) return null; // already in setup
        return '${AppRoutes.accountType}'
            '?${AppRoutes.accountTypeModeParam}='
            '${AppRoutes.accountTypeModeSignup}';
      }

      // Returning user with profile complete — bounce them off any
      // pre-auth or setup screen → /home.
      if (atAuthRoute ||
          atOnboardingRoute ||
          atSetupRoute ||
          loc == AppRoutes.splash) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.accountType,
        builder: (_, _) => const AccountTypeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (_, _) => const OtpScreen(),
      ),
      GoRoute(
        path: AppRoutes.signupCorporate,
        builder: (_, _) => const CorporateSignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.signupIndividual,
        builder: (_, _) => const IndividualSignupScreen(),
      ),

      // Booking flow (only reachable when signed in)
      GoRoute(
        path: AppRoutes.bookingSelectType,
        builder: (_, state) => _BookingListingResolver(
          listingId: state.uri.queryParameters['listingId'],
        ),
      ),
      GoRoute(
        path: AppRoutes.bookingCorporate,
        builder: (_, _) => const CorporateCampaignScreen(),
      ),
      GoRoute(
        path: AppRoutes.bookingIndividual,
        builder: (_, _) => const IndividualCampaignScreen(),
      ),
      GoRoute(
        path: AppRoutes.bookingReview,
        builder: (_, _) => const ReviewPayScreen(),
      ),
      GoRoute(
        path: AppRoutes.bookingSuccess,
        builder: (_, _) => const PaymentSuccessScreen(),
      ),
      GoRoute(
        path: AppRoutes.bookingFailure,
        builder: (_, _) => const PaymentFailureScreen(),
      ),
      GoRoute(
        path: AppRoutes.campaignStatus,
        builder: (_, state) {
          final id = state.pathParameters['bookingId']!;
          return CampaignStatusScreen(bookingId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.personalInfo,
        builder: (_, _) => const PersonalInfoScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.help,
        builder: (_, _) => const HelpScreen(),
      ),
      GoRoute(
        path: AppRoutes.legal,
        builder: (_, state) => LegalPageScreen(
          pageId: state.pathParameters['pageId']!,
        ),
      ),

      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (_, _) => const HomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.history,
              builder: (_, _) => const HistoryScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (_, _) => const ProfileScreen(),
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

  // Refresh whenever the Firebase auth state changes. Listening to the
  // StreamProvider (not the underlying stream) guarantees the provider
  // value is already updated by the time we re-evaluate the redirect —
  // refreshListenable on the raw stream can fire in a different order.
  ref.listen<AsyncValue<AppUser?>>(authStateProvider, (prev, next) {
    router.refresh();
  });

  // Refresh when the Firestore profile updates — fires when (a) the
  // profile loads after sign-in and (b) the user completes signup so
  // isSetupComplete flips and the redirect carries them to /home.
  ref.listen(userProfileProvider, (prev, next) {
    router.refresh();
  });

  // Deep-link a notification tap to its booking's status page. We wait
  // until the user is on a non-auth route to avoid yanking them out of
  // login halfway through.
  ref.listen<String?>(pendingNotificationBookingIdProvider, (prev, next) {
    if (next == null || next.isEmpty) return;
    final signedIn = ref.read(authStateProvider).asData?.value != null;
    if (!signedIn) return;
    router.push(AppRoutes.campaignStatusFor(next));
    // Clear so the same tap isn't replayed if profile/user changes
    // trigger another refresh.
    ref.read(pendingNotificationBookingIdProvider.notifier).state = null;
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

/// Resolves the listing id from the booking deep-link against the live
/// Firestore listings. On a missing / unknown id it shows a clear
/// "board unavailable" screen instead of silently booking a random board.
class _BookingListingResolver extends ConsumerWidget {
  const _BookingListingResolver({required this.listingId});

  final String? listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = listingId;
    if (id == null || id.isEmpty) {
      return const _BookingListingUnavailable();
    }
    final async = ref.watch(listingByIdProvider(id));
    return async.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const _BookingListingUnavailable(),
      data: (listing) => listing == null
          ? const _BookingListingUnavailable()
          : BookingAccountTypeScreen(listing: listing),
    );
  }
}

class _BookingListingUnavailable extends StatelessWidget {
  const _BookingListingUnavailable();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_off_outlined,
                  size: 48,
                  color: Color(0xFF6E6E7C),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Board unavailable',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A22),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "This board isn't available right now. It may have been "
                  'removed or is no longer active.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Color(0xFF6E6E7C),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: const Text('Back to boards'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
