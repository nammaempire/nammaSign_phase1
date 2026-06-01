import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/firebase_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/bookings_repository.dart';
import '../../domain/booking.dart';

final bookingsRepositoryProvider = Provider<BookingsRepository>((ref) {
  return FirestoreBookingsRepository(
    firestore: ref.watch(firestoreProvider),
  );
});

/// Live stream of bookings owned by the currently signed-in user.
/// Empty stream while signed out.
final userBookingsStreamProvider = StreamProvider<List<Booking>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return ref.watch(bookingsRepositoryProvider).watchForUser(user.id);
});

/// Live stream of a single booking by id — used by CampaignStatusScreen
/// so the user sees status updates the instant admin approves/rejects.
final bookingByIdProvider =
    StreamProvider.family<Booking?, String>((ref, id) {
  return ref.watch(bookingsRepositoryProvider).watchOne(id);
});
