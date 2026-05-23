import 'package:file_picker/file_picker.dart';

import '../../account_type/domain/account_type.dart';
import '../../home/domain/billboard_listing.dart';

/// In-flight booking that the user is assembling across the 3 wizard steps.
///
/// Held in a Riverpod StateNotifier so values survive forward/back navigation
/// inside the booking flow. Cleared when the booking is submitted or the
/// user backs out of the flow entirely.
class BookingDraft {
  const BookingDraft({
    this.listing,
    this.bookingType,
    this.campaignTitle,
    this.description,
    this.manager,
    this.campaignId,
    this.durationDays,
    this.purpose,
    this.creativeFile,
    this.creativeIsVideo = false,
  });

  final BillboardListing? listing;
  final AccountType? bookingType;

  // Corporate fields
  final String? campaignTitle;
  final String? description;
  final String? manager;
  final String? campaignId;
  final int? durationDays;

  // Individual fields
  final String? purpose;

  // Creative (image or video)
  final PlatformFile? creativeFile;
  final bool creativeIsVideo;

  BookingDraft copyWith({
    BillboardListing? listing,
    AccountType? bookingType,
    String? campaignTitle,
    String? description,
    String? manager,
    String? campaignId,
    int? durationDays,
    String? purpose,
    PlatformFile? creativeFile,
    bool? creativeIsVideo,
  }) {
    return BookingDraft(
      listing: listing ?? this.listing,
      bookingType: bookingType ?? this.bookingType,
      campaignTitle: campaignTitle ?? this.campaignTitle,
      description: description ?? this.description,
      manager: manager ?? this.manager,
      campaignId: campaignId ?? this.campaignId,
      durationDays: durationDays ?? this.durationDays,
      purpose: purpose ?? this.purpose,
      creativeFile: creativeFile ?? this.creativeFile,
      creativeIsVideo: creativeIsVideo ?? this.creativeIsVideo,
    );
  }
}
