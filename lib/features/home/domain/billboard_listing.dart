/// Availability state shown as a pill in the top-right of a billboard card.
enum AvailabilityStatus {
  available,
  fewLeft,
  fullyBooked,
}

/// A single billboard / digital board listing surfaced on the Local home tab.
///
/// Phase 1a: built from in-memory sample data.
/// Phase 1b: hydrated from Firestore `items` collection.
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
    this.slotsLeft = 0,
  });

  final String id;
  final String location; // e.g. "100 Feet Road"
  final String boardType; // e.g. "LED Hoarding"
  final String displayLabel; // e.g. "YOUR AD" / "FORUM MALL"
  /// Multi-line street address. Use `\n` to force a line break for nicer
  /// formatting; otherwise the card wraps to max 2 lines naturally.
  final String fullAddress;
  final int pricePerDay;
  final int viewsPerDay;
  final AvailabilityStatus availability;
  final int slotsLeft; // only meaningful when availability == fewLeft
}

/// Hardcoded sample data for the UI-only phase. Replace with a Firestore
/// stream in Phase 1b.
const List<BillboardListing> sampleListings = [
  BillboardListing(
    id: '1',
    location: '100 Feet Road',
    boardType: 'LED Hoarding',
    displayLabel: 'YOUR AD',
    fullAddress: 'Opp. Forum Mall, 100 Feet Road,\n'
        'Koramangala, Bengaluru 560095',
    pricePerDay: 450,
    viewsPerDay: 12000,
    availability: AvailabilityStatus.available,
  ),
  BillboardListing(
    id: '2',
    location: 'Forum Mall',
    boardType: 'Atrium Screen',
    displayLabel: 'FORUM MALL',
    fullAddress: 'Forum Mall, Hosur Road,\n'
        'Koramangala, Bengaluru 560029',
    pricePerDay: 780,
    viewsPerDay: 18500,
    availability: AvailabilityStatus.fewLeft,
    slotsLeft: 2,
  ),
  BillboardListing(
    id: '3',
    location: 'MG Road',
    boardType: 'Digital Tower',
    displayLabel: 'YOUR AD',
    fullAddress: 'Near Trinity Metro Station,\n'
        'MG Road, Bengaluru 560001',
    pricePerDay: 620,
    viewsPerDay: 22000,
    availability: AvailabilityStatus.available,
  ),
  BillboardListing(
    id: '4',
    location: 'Koramangala',
    boardType: 'Bus Stop LED',
    displayLabel: 'YOUR AD',
    fullAddress: '80 Feet Road, 5th Block,\n'
        'Koramangala, Bengaluru 560034',
    pricePerDay: 320,
    viewsPerDay: 8500,
    availability: AvailabilityStatus.fullyBooked,
  ),
];
