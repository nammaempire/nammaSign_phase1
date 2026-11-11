import '../../features/account_type/domain/account_type.dart';
import '../../features/history/domain/booking.dart';
import '../../features/user/domain/user_profile.dart';

/// UI preview mode — for looking at the screens without a real login.
///
/// OFF by default, so normal and release builds are completely unaffected.
/// Turn it on only from the command line:
///
///   flutter run -d chrome --dart-define=UI_PREVIEW=true
///
/// In preview mode: any phone number + any 6-digit OTP signs you in as a
/// sample corporate user, and Home / History / Notifications show sample
/// data instead of reading Firestore. Nothing is saved, and uploads and
/// payment will not work (there is no real signed-in user).
const bool kUiPreview = bool.fromEnvironment('UI_PREVIEW');

const String kPreviewUserId = 'fake-user-id';

const UserProfile kPreviewProfile = UserProfile(
  uid: kPreviewUserId,
  phone: '+91 98765 43210',
  email: 'marketing@samplecorp.in',
  displayName: 'Sample Corp',
  accountType: AccountType.corporate,
  corporate: CorporateProfile(
    name: 'Sample Corp Pvt Ltd',
    panCin: 'ABCDE1234F',
    gstin: '29ABCDE1234F1Z5',
    officialEmail: 'marketing@samplecorp.in',
    managerName: 'Priya Sharma',
    managerPhone: '+91 98765 43210',
  ),
  kycStatus: 'verified',
);

const List<Booking> kPreviewBookings = [
  Booking(
    id: 'preview-1',
    userId: kPreviewUserId,
    areaId: 'koramangala',
    campaignTitle: 'Diwali Mega Sale',
    location: 'Koramangala',
    boardType: '4 LED Boards',
    durationDays: 15,
    runDateLabel: '15 Nov – 29 Nov',
    amount: 10585,
    paymentMethod: 'UPI',
    paid: true,
    status: BookingStatus.live,
    actualPlays: 4200,
    targetPlays: 9000,
  ),
  Booking(
    id: 'preview-2',
    userId: kPreviewUserId,
    areaId: 'madiwala',
    campaignTitle: 'New Store Launch',
    location: 'Madiwala',
    boardType: '4 LED Boards',
    durationDays: 7,
    runDateLabel: '20 Nov – 26 Nov',
    amount: 3717,
    paymentMethod: 'Card',
    paid: true,
    status: BookingStatus.pending,
  ),
  Booking(
    id: 'preview-3',
    userId: kPreviewUserId,
    areaId: 'electronic_city',
    campaignTitle: 'Hiring Drive — Engineers',
    location: 'Electronic City',
    boardType: '4 LED Boards',
    durationDays: 30,
    runDateLabel: '1 Dec – 30 Dec',
    amount: 16550,
    paymentMethod: 'Net banking',
    paid: true,
    status: BookingStatus.rejected,
    adminNote: 'Text is too small to read from the road. Please enlarge '
        'the headline and resubmit.',
    adminReviewerName: 'Review team',
  ),
  Booking(
    id: 'preview-4',
    userId: kPreviewUserId,
    areaId: 'koramangala',
    campaignTitle: 'Weekend Brunch Offer',
    location: 'Koramangala',
    boardType: '4 LED Boards',
    durationDays: 7,
    runDateLabel: 'Not scheduled yet',
    amount: 5369,
    paymentMethod: 'UPI',
    paid: false,
    status: BookingStatus.pendingPayment,
  ),
];
