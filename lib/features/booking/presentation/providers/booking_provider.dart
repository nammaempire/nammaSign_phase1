import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/picked_file.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../../account_type/domain/account_type.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../history/domain/booking.dart';
import '../../../history/presentation/providers/bookings_provider.dart';
import '../../../home/domain/billboard_listing.dart';
import '../../domain/booking_draft.dart';
import '../../domain/booking_totals.dart';

/// Holds the in-flight [BookingDraft] across the 3-step booking flow.
///
/// Drafts live in memory only. On `submit()` the draft is uploaded
/// (creative → Firebase Storage) and persisted to Firestore as a real
/// booking with status `pending_review`. Real Razorpay payment lands
/// in Phase 1c — for now "Pay" goes straight to pending_review and the
/// admin reviews + approves manually.
class BookingNotifier extends Notifier<BookingDraft> {
  @override
  BookingDraft build() => const BookingDraft();

  void start(BillboardListing listing) {
    state = BookingDraft(
      listing: listing,
      durationDays: 15,
      // Auto-generated reference for this draft. Manager / org are seeded
      // from the user's profile on the campaign screen.
      campaignId: 'NE-${DateTime.now().millisecondsSinceEpoch % 100000}',
    );
  }

  void setType(AccountType type) {
    state = state.copyWith(bookingType: type);
  }

  void setCampaignTitle(String v) =>
      state = state.copyWith(campaignTitle: v);
  void setDescription(String v) => state = state.copyWith(description: v);
  void setManager(String v) => state = state.copyWith(manager: v);
  void setDuration(int days) => state = state.copyWith(durationDays: days);
  void setPurpose(String v) => state = state.copyWith(purpose: v);

  void setCreative(PickedFile file, {required bool isVideo}) {
    state = state.copyWith(creativeFile: file, creativeIsVideo: isVideo);
  }

  void clearCreative() {
    state = BookingDraft(
      listing: state.listing,
      bookingType: state.bookingType,
      campaignTitle: state.campaignTitle,
      description: state.description,
      manager: state.manager,
      campaignId: state.campaignId,
      durationDays: state.durationDays,
      purpose: state.purpose,
    );
  }

  void reset() => state = const BookingDraft();

  /// Persists the draft to Firestore + uploads the creative to Storage.
  /// Returns the new bookingId. Throws on any failure.
  ///
  /// Phase 1b note: skips Razorpay. Booking lands as `pending_review`
  /// so admin can approve manually. Razorpay integration in Phase 1c.
  Future<String> submit({String paymentMethod = 'UPI'}) async {
    final draft = state;
    final listing = draft.listing;
    final user = ref.read(currentUserProvider);
    if (listing == null) {
      throw StateError('No listing selected');
    }
    if (user == null) {
      throw StateError('Not signed in');
    }

    final totals = BookingTotals.compute(
      dailyRate: listing.pricePerDay,
      durationDays: draft.durationDays ?? 1,
    );
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final endDate = tomorrow.add(
      Duration(days: draft.durationDays ?? 1),
    );

    // Upload creative to Storage if present.
    String? creativeUrl;
    if (draft.creativeFile != null) {
      final storage = ref.read(firebaseStorageProvider);
      final ext = draft.creativeIsVideo ? 'mp4' : 'jpg';
      final ref0 = storage
          .ref()
          .child('bookings')
          .child(user.id)
          .child(
              '${DateTime.now().millisecondsSinceEpoch}.$ext');
      final task = await ref0.putFile(File(draft.creativeFile!.path));
      creativeUrl = await task.ref.getDownloadURL();
    }

    final title = (draft.campaignTitle?.isNotEmpty ?? false)
        ? draft.campaignTitle!
        : (draft.purpose ?? 'Untitled campaign');

    final booking = Booking(
      id: '',
      userId: user.id,
      areaId: listing.id,
      campaignTitle: title,
      location: listing.location,
      boardType: listing.boardType,
      durationDays: draft.durationDays ?? 1,
      runDateLabel: '',
      amount: totals.total,
      paymentMethod: paymentMethod,
      paid: false,
      // Payment is handled offline for now — booking goes straight to the
      // admin review queue. (In-app payment deferred.)
      status: BookingStatus.pending,
      description: draft.description ?? draft.purpose,
      creativeUrl: creativeUrl,
      creativeIsVideo: draft.creativeIsVideo,
      createdAt: now,
      scheduledStartAt: tomorrow,
      scheduledEndAt: endDate,
    );

    final id =
        await ref.read(bookingsRepositoryProvider).create(booking);
    return id;
  }
}

final bookingProvider =
    NotifierProvider<BookingNotifier, BookingDraft>(BookingNotifier.new);
