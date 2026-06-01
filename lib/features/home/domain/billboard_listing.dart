import 'package:cloud_firestore/cloud_firestore.dart';

/// Availability state shown as a pill in the top-right of a billboard card.
enum AvailabilityStatus {
  available,
  fewLeft,
  fullyBooked,
}

extension AvailabilityStatusX on AvailabilityStatus {
  String get storageValue => name;
  static AvailabilityStatus fromStorage(String? raw) {
    return AvailabilityStatus.values.firstWhere(
      (e) => e.storageValue == raw,
      orElse: () => AvailabilityStatus.available,
    );
  }
}

/// A single AREA listing the customer can book.
///
/// Each area maps to N physical Android signage boards (4 per area in
/// Phase 1). The customer picks the area; the scheduler distributes the
/// approved creative across all boards in that area's rotation.
class BillboardListing {
  const BillboardListing({
    required this.id,
    required this.location,
    required this.boardType,
    required this.displayLabel,
    required this.fullAddress,
    required this.pricePerDay,
    required this.viewsPerDay,
    required this.availability,
    required this.boardCount,
    this.slotsLeft = 0,
  });

  final String id;
  final String location;
  final String boardType;
  final String displayLabel;
  final String fullAddress;
  final int pricePerDay;
  final int viewsPerDay;
  final AvailabilityStatus availability;
  final int boardCount;
  final int slotsLeft;

  /// Builds from a Firestore `areas/{id}` document.
  factory BillboardListing.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    final d = snap.data() ?? const <String, dynamic>{};
    return BillboardListing(
      id: snap.id,
      location: (d['name'] as String?) ?? snap.id,
      boardType:
          '${(d['boardCount'] as num?)?.toInt() ?? 4} LED Boards',
      displayLabel: (d['displayLabel'] as String?) ?? 'YOUR AD',
      fullAddress: (d['description'] as String?) ?? '',
      pricePerDay: (d['pricePerDay'] as num?)?.toInt() ?? 500,
      viewsPerDay: (d['estimatedViewsPerDay'] as num?)?.toInt() ?? 0,
      availability: AvailabilityStatusX.fromStorage(d['availability'] as String?),
      boardCount: (d['boardCount'] as num?)?.toInt() ?? 4,
      slotsLeft: (d['slotsLeft'] as num?)?.toInt() ?? 0,
    );
  }

  /// For the seed script / admin tools.
  Map<String, dynamic> toFirestore() => {
        'name': location,
        'city': 'Bengaluru',
        'description': fullAddress,
        'boardCount': boardCount,
        'pricePerDay': pricePerDay,
        'maxAdsInRotation': 30,
        'estimatedViewsPerDay': viewsPerDay,
        'displayLabel': displayLabel,
        'availability': availability.storageValue,
        'slotsLeft': slotsLeft,
        'status': 'active',
        'updatedAt': FieldValue.serverTimestamp(),
      };
}

/// Fallback sample data — used when the listingsStreamProvider hasn't
/// emitted yet, or in widget tests. Real production data comes from
/// Firestore via [listingsStreamProvider].
const List<BillboardListing> sampleListings = [
  BillboardListing(
    id: 'koramangala',
    location: 'Koramangala',
    boardType: '4 LED Boards',
    displayLabel: 'YOUR AD',
    fullAddress: 'Forum Mall, 100 Feet Road, 5th Block,\n'
        '80 Feet Road  ·  Koramangala, Bengaluru',
    pricePerDay: 650,
    viewsPerDay: 48000,
    availability: AvailabilityStatus.available,
    boardCount: 4,
  ),
  BillboardListing(
    id: 'madiwala',
    location: 'Madiwala',
    boardType: '4 LED Boards',
    displayLabel: 'YOUR AD',
    fullAddress: 'BTM Layout, Madiwala Market,\n'
        'Hosur Road  ·  Madiwala, Bengaluru',
    pricePerDay: 450,
    viewsPerDay: 36000,
    availability: AvailabilityStatus.fewLeft,
    slotsLeft: 4,
    boardCount: 4,
  ),
  BillboardListing(
    id: 'electronic-city',
    location: 'Electronic City',
    boardType: '4 LED Boards',
    displayLabel: 'YOUR AD',
    fullAddress: 'Phase 1 & 2, Hosur Road,\n'
        'Tech Park hubs  ·  Electronic City, Bengaluru',
    pricePerDay: 550,
    viewsPerDay: 42000,
    availability: AvailabilityStatus.available,
    boardCount: 4,
  ),
];
