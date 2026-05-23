import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../account_type/domain/account_type.dart';
import '../../../home/domain/billboard_listing.dart';
import '../../domain/booking_draft.dart';

/// Holds the in-flight [BookingDraft] across the 3-step booking flow.
class BookingNotifier extends Notifier<BookingDraft> {
  @override
  BookingDraft build() => const BookingDraft();

  void start(BillboardListing listing) {
    // Reset the draft and seed it with the listing the user just tapped.
    state = BookingDraft(
      listing: listing,
      // Sensible default duration for the corporate flow.
      durationDays: 15,
      // Demo fields prefilled (these would come from the user's profile).
      campaignId: 'NE-A7842',
      manager: 'Priya Menon',
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

  void setCreative(PlatformFile file, {required bool isVideo}) {
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
}

final bookingProvider =
    NotifierProvider<BookingNotifier, BookingDraft>(BookingNotifier.new);
