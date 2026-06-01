import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/firebase_providers.dart';
import '../../data/repositories/listings_repository.dart';
import '../../domain/billboard_listing.dart';

/// Firestore-backed implementation of the listings repo. Override in
/// tests for a fake or in-memory list.
final listingsRepositoryProvider = Provider<ListingsRepository>((ref) {
  return FirestoreListingsRepository(
    firestore: ref.watch(firestoreProvider),
  );
});

/// Live stream of all active area listings, ordered by price ascending.
/// Drives the Local tab on the home screen.
final listingsStreamProvider = StreamProvider<List<BillboardListing>>((ref) {
  return ref.watch(listingsRepositoryProvider).watchAll();
});

/// One-off fetch by id — used by the booking flow when the user taps
/// "Book my slot" so step 1 can summarise the picked area.
final listingByIdProvider =
    FutureProvider.family<BillboardListing?, String>((ref, id) {
  return ref.watch(listingsRepositoryProvider).getById(id);
});
