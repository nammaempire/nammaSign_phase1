import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/analytics/analytics_service.dart';
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
    state = state.copyWith(
      creativeFile: file,
      creativeIsVideo: isVideo,
      creativeImages: const <PickedFile>[],
    );
  }

  /// Up to 5 photos for the creative. The first is kept as the primary
  /// creative (preview + what the board plays).
  void setCreativeImages(List<PickedFile> files) {
    final capped = files.take(5).toList();
    if (capped.isEmpty) {
      clearCreative();
      return;
    }
    state = state.copyWith(
      creativeImages: capped,
      creativeFile: capped.first,
      creativeIsVideo: false,
    );
  }

  void removeCreativeImageAt(int index) {
    final list = [...state.creativeImages];
    if (index < 0 || index >= list.length) return;
    list.removeAt(index);
    if (list.isEmpty) {
      clearCreative();
    } else {
      state = state.copyWith(
        creativeImages: list,
        creativeFile: list.first,
        creativeIsVideo: false,
      );
    }
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

    // Upload creative(s) to Storage. A video is one file; photos can be up
    // to 5 — all uploaded, first kept as the primary creative the board plays.
    final storage = ref.read(firebaseStorageProvider);
    Future<String> uploadOne(PickedFile f, String ext, int i) async {
      final ref0 = storage
          .ref()
          .child('bookings')
          .child(user.id)
          .child('${DateTime.now().millisecondsSinceEpoch}_$i.$ext');
      final task = await ref0.putFile(File(f.path));
      return task.ref.getDownloadURL();
    }

    String? creativeUrl;
    final creativeUrls = <String>[];
    if (draft.creativeIsVideo && draft.creativeFile != null) {
      creativeUrl = await uploadOne(draft.creativeFile!, 'mp4', 0);
      creativeUrls.add(creativeUrl);
    } else if (draft.creativeImages.isNotEmpty) {
      for (var i = 0; i < draft.creativeImages.length; i++) {
        creativeUrls.add(await uploadOne(draft.creativeImages[i], 'jpg', i));
      }
      creativeUrl = creativeUrls.first;
    } else if (draft.creativeFile != null) {
      creativeUrl = await uploadOne(draft.creativeFile!, 'jpg', 0);
      creativeUrls.add(creativeUrl);
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
      creativeUrls: creativeUrls,
      creativeIsVideo: draft.creativeIsVideo,
      createdAt: now,
      scheduledStartAt: tomorrow,
      scheduledEndAt: endDate,
    );

    final id =
        await ref.read(bookingsRepositoryProvider).create(booking);

    // Funnel — fires once the booking is actually persisted in Firestore.
    // We log the booking total as the analytics "value" so revenue
    // reporting in Firebase / Google Analytics works automatically.
    await ref.read(analyticsServiceProvider).bookingSubmitted(
          areaId: listing.id,
          durationDays: draft.durationDays ?? 1,
          amountRupees: totals.total,
          accountType: draft.bookingType?.name ?? 'unknown',
        );

    return id;
  }
}

final bookingProvider =
    NotifierProvider<BookingNotifier, BookingDraft>(BookingNotifier.new);
