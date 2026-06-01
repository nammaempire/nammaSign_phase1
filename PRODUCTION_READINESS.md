# NammaSign — Production Readiness Report

Generated: 2026-05-24
Codebase scanned: 85 Dart files, 9 features, 16 screens, ~6,500 LOC

---

## TL;DR

**UI is ~100% built.** Every screen you've designed is in place, navigates correctly, and looks pixel-close to your Figma. **Zero backend exists.** The app runs entirely on an in-memory `FakeAuthRepository` plus two `const` lists of sample data (4 listings, 4 bookings). To ship to the Play Store / App Store you need three things:

1. A real backend (~38 REST endpoints, see §3)
2. Native config + app store assets (icons, splash, signing, permissions — see §4)
3. The 27 "Phase 1b" placeholders wired to live calls (see §2)

Recommended path: **Firebase for auth + storage + push, custom Node/Postgres API for everything else** (see §5).

---

## 1. What's done

### Auth & onboarding
- Splash screen — animated 3-second progress bar, logo lockup, brand footer
- Onboarding — 3-slide carousel with Page indicators, Get started / Skip
- Login — phone input with India flag + +91, helper text, social buttons (Google, Apple), Create account link
- OTP — 6-box input with auto-advance + paste-from-clipboard, 30s resend timer, Edit phone link
- Account-type picker — Corporate / Individual selection (used in signup flow only after rebrand)
- Signup forms — Corporate (org, PAN/CIN, email, manager phone, doc upload) and Individual (name, DOB picker, mobile, Aadhaar, doc upload)

### Home (Local + Premium tabs)
- Custom top bar with brand logo + name + notification bell
- Centered rectangular pill tabs (Local with count, Premium with SOON)
- Search bar (UI only, no search logic)
- 4 sample billboard cards with hero illustration, status pill (Available / X Left / Fully booked), price chip, full address, person + views/day, **Book my slot** CTA
- Premium tab: Coming Soon teaser, dark feature card, dashed Notify-me card

### Booking flow (3 steps + outcomes)
- Step 1: Selected board summary + Corporate/Individual picker
- Step 2A (Corporate): organisation (locked), manager, campaign ID (locked), title, description, 7/15/30 day duration cards, creative preview, image+video upload
- Step 2B (Individual): name, purpose, message, fixed 1-day chip with price, creative preview
- Step 3 (Review & Pay): order summary with live-computed totals (8% discount at ≥15d, 15% at ≥30d, 18% GST), payment method radios (UPI / Card / Net banking)
- Payment success — green confirmation, order reference, Download invoice + Share + Track in History
- Payment failure — pink error with reason, code, slot-reserved info, Try again + Change method

### History + Campaign Status
- History tab with All/Pending/Live/Rejected filter chips, color-coded booking cards, admin-note variant for rejected
- Campaign status — single screen with 3 variants:
  - Under Review: amber clock + 3-step timeline + View campaign details
  - Live on Board: green target + stats row (views / days run / left) + 4-step timeline + View live preview
  - Needs Changes: pink alert + admin feedback card + Edit & resubmit + Contact support

### Profile
- Avatar with verified check + name + account-type/org line
- Grouped settings: Account (Personal info, Payment methods, KYC), Preferences (Notifications, Language), Support (Help, Sign out)

### Design system & infra
- Light theme everywhere except splash (dark purple gradient)
- Reusable: GradientBorderBox (purple gradient on every content card), BrandLogo (lockup + mark variants), OutlinedInput, LabeledFormField, FileUploadSlot, CreativePreview with video_player, BookingTopBar, CampaignStatusHero, TimelineStep
- Riverpod providers with proper Notifier patterns
- Clean feature-first architecture (domain / data / presentation)
- GoRouter with auth-aware redirect, push/pop semantics correct everywhere

---

## 2. What's pending — frontend wiring (the 27 Phase 1b placeholders)

These are spots where the UI fires a snackbar "(Phase 1b)" instead of calling the real backend. Every one of them maps to a backend endpoint:

| Screen | Action | Backend call needed |
|---|---|---|
| Login | Google sign-in | OAuth2 with Google → POST /auth/google |
| Login | Apple sign-in | Sign in with Apple → POST /auth/apple |
| OTP | Send + verify code | POST /auth/send-otp, POST /auth/verify-otp |
| Signup (both) | File pickers | POST /uploads/kyc |
| Home AppBar | Menu drawer | local UI only — build the drawer |
| Home AppBar | Notifications | GET /notifications + drawer screen |
| Home/Local | Search bar | GET /listings?q= |
| Home/Local | List of billboards | GET /listings (replaces sampleListings const) |
| Home/Premium | Notify me | POST /waitlist |
| Booking 2A/2B | Creative upload | POST /uploads/creative (with video validation) |
| Booking 3 | Pay button | POST /payments/init + Razorpay SDK |
| Success | Download invoice | GET /bookings/:id/invoice.pdf |
| Success | Share | platform share intent (no backend) |
| Success | Track in History | already wired to /history tab |
| History | Search history | GET /campaigns?q= |
| History | List bookings | GET /campaigns (replaces sampleBookings const) |
| Campaign | View campaign details | GET /campaigns/:id |
| Campaign | View live preview | GET /campaigns/:id/preview |
| Campaign | Edit & resubmit | PATCH /campaigns/:id/creative |
| Campaign | Contact support | mailto: or open chat SDK |
| Profile | Personal info | screen + GET/PATCH /users/me |
| Profile | Payment methods | screen + GET/POST/DELETE /payment-methods |
| Profile | KYC documents | screen + GET /users/me/kyc |
| Profile | Notification prefs | screen + GET/PATCH /users/me/preferences |
| Profile | Language | locale picker + flutter_localizations |
| Profile | Help & FAQs | static screen or web link |

Plus two hardcoded `const` lists that need to come from the backend:
- `lib/features/home/domain/billboard_listing.dart` → `sampleListings`
- `lib/features/history/domain/booking.dart` → `sampleBookings`

---

## 3. Backend endpoints needed (~38 total)

Grouped by domain. Auth uses bearer tokens; everything else expects `Authorization: Bearer <jwt>`.

### Auth (6)
- `POST /auth/send-otp` — body `{phoneE164}` → `{verificationId, expiresAt}`
- `POST /auth/verify-otp` — body `{verificationId, code}` → `{accessToken, refreshToken, user}`
- `POST /auth/google` — body `{idToken}` → same response
- `POST /auth/apple` — body `{authCode, identityToken}` → same response
- `POST /auth/refresh` — body `{refreshToken}` → `{accessToken}`
- `POST /auth/logout` — invalidate refresh token

### Users / KYC (5)
- `GET /users/me` — profile
- `PATCH /users/me` — name, email, photo
- `GET /users/me/kyc` — KYC document status
- `POST /users/me/kyc` — multipart: pan/cin/aadhaar files
- `POST /uploads/avatar` — multipart photo

### Account setup (3)
- `POST /accounts/corporate` — org name, PAN, CIN, manager, official email, manager phone
- `POST /accounts/individual` — full name, DOB, mobile, Aadhaar
- `GET /accounts/me` — current account snapshot

### Listings (4)
- `GET /listings?city=&type=&minPrice=&maxPrice=&available=&q=&page=&limit=` — paginated
- `GET /listings/:id` — full detail (multiple images, exact location, time-of-day breakdown)
- `GET /listings/categories` — for filter chips later
- `GET /listings/locations` — autocomplete

### Bookings + Campaigns (8)
- `POST /bookings` — create draft `{listingId, accountType, durationDays}`
- `PATCH /bookings/:id` — update title / description / purpose
- `POST /bookings/:id/creative` — multipart image or video (server validates ≤20s, ≤50MB)
- `POST /bookings/:id/calculate` — body `{durationDays}` → `{subtotal, discount, gst, total, breakdown}`
- `POST /bookings/:id/submit` — moves draft → pending admin review
- `GET /campaigns?status=` — list user's campaigns (replaces `sampleBookings`)
- `GET /campaigns/:id` — full status, timeline, feedback
- `GET /campaigns/:id/analytics` — views, performance vs avg, day-by-day chart

### Payments (4)
- `POST /payments/init` — body `{bookingId, method}` → `{razorpayOrderId, amount, currency, key}`
- `POST /payments/verify` — body `{razorpayPaymentId, signature, orderId}` → `{status, receipt}`
- `GET /payments/:id` — status (for polling on failure)
- `GET /bookings/:id/invoice.pdf` — PDF stream

### Notifications + Devices (3)
- `GET /notifications?since=&limit=`
- `POST /notifications/mark-read/:id`
- `POST /devices/register-fcm` — body `{token, platform}`

### Misc / Config (2)
- `GET /config/cities` — for location detection fallback
- `GET /support/faqs` — static FAQ list

### Admin (separate auth, ~5)
- `GET /admin/pending-reviews`
- `POST /admin/campaigns/:id/approve`
- `POST /admin/campaigns/:id/reject` body `{reason, ruleCode}`
- `POST /admin/campaigns/:id/go-live`
- `GET /admin/dashboard/stats`

**Total: ~38 endpoints** (excluding admin: ~33)

---

## 4. Native / app store readiness — currently at scaffold defaults

Both `ios/Runner/Info.plist` and `android/app/src/main/AndroidManifest.xml` are still default Flutter scaffold. You'll need to update:

### iOS (Info.plist)
- `CFBundleDisplayName` → `NammaSign`
- `CFBundleName` → `nammasign`
- Add `NSCameraUsageDescription` if scanning IDs ("To capture KYC documents")
- Add `NSPhotoLibraryUsageDescription` ("To upload your ad creative")
- Add `NSLocationWhenInUseUsageDescription` ("To detect your city for nearby billboards")
- Add `NSContactsUsageDescription` only if you ever import contacts
- Apple Sign-In capability in Xcode
- Push notifications capability + APNs key

### Android (AndroidManifest.xml + build.gradle)
- `android:label` → `NammaSign`
- `android:icon` → custom launcher icon (use `flutter_launcher_icons` package)
- Permissions: `INTERNET`, `ACCESS_NETWORK_STATE` (already implicit), `POST_NOTIFICATIONS` for Android 13+
- Add `READ_MEDIA_IMAGES` + `READ_MEDIA_VIDEO` if not using SAF
- `applicationId` in build.gradle → `com.nammasign.app`
- Google Services JSON for FCM
- Signing config + release keystore

### Assets needed
- App launcher icons (1024×1024 source → all sizes via `flutter_launcher_icons`)
- Native splash screens (use `flutter_native_splash` package — purple bg + logo lockup)
- Play Store assets: 512×512 icon, feature graphic 1024×500, 2–8 phone screenshots
- App Store assets: 1024×1024 icon, 6.7" + 5.5" screenshots, preview videos (optional)

### Build / release
- App signing — generate Android keystore, upload to Play Console
- iOS provisioning profiles + distribution certificate
- Fastlane / Codemagic / GitHub Actions for CI/CD
- Crashlytics or Sentry for crash reporting
- Firebase Analytics or Mixpanel for product analytics

### Legal / store requirements
- Privacy policy URL (mandatory for Play + App Store)
- Terms of service URL
- In-app data deletion flow (Play Store requirement since 2024)
- Age rating questionnaire
- Indian payment compliance: Razorpay handles most, but check RBI tokenisation rules if storing cards

---

## 5. Recommended backend stack

You have three realistic options:

### Option A — Firebase-only (fastest, least flexible)
- Auth: Firebase Phone Auth + Google + Apple
- Database: Cloud Firestore (NoSQL)
- Storage: Firebase Storage
- Push: FCM
- Functions: Cloud Functions for Razorpay webhook + admin logic
- Cost: free tier covers up to ~10k MAU, then scales

**When to pick**: tiny team, no backend engineer, want to ship in 2 weeks.

**Downside**: hard to do complex queries (e.g. "billboards within 5km of user with footfall > 10k and price < 500"), hard to migrate off later, no proper relational data, harder to build admin panel.

### Option B — Custom Node.js + PostgreSQL (recommended)
- API: Node + Fastify or Express (TypeScript)
- DB: PostgreSQL (Supabase or hosted RDS / Cloud SQL)
- Auth: Firebase Auth for phone OTP, OR roll your own with MSG91 / Twilio Verify
- Storage: Firebase Storage or AWS S3 (signed URLs)
- Push: FCM
- Payments: Razorpay (Indian market standard)
- Admin: Refine.dev or Retool for the admin panel
- Hosting: Railway / Render / Fly.io for API, managed Postgres
- Cost: ~$30–80/month at launch, scales with usage

**When to pick**: you have or can hire 1 backend engineer, want full control, plan to grow.

**Why I'd recommend this**: your domain is relational (users → bookings → listings → campaigns → payments), you need geo queries (nearby billboards), complex reporting (admin dashboard), and an admin app. Firestore makes all of these painful.

### Option C — Hybrid (Firebase auth + custom API)
- Firebase Auth for phone/Google/Apple (battle-tested, free)
- Firebase Storage for file uploads (signed URLs)
- Firebase Cloud Messaging for push
- Custom Node + Postgres API for everything else
- Validate Firebase JWT in your API middleware

**When to pick**: you want fast auth + push setup but proper relational data and a real admin panel.

**My recommendation**: **Option C**. You skip writing OTP / SMS / OAuth code (3-4 days of work) but keep proper data modelling for the rest.

---

## 6. Suggested phasing to production

### Phase 1b (2–3 weeks)
1. Wire Firebase Auth (replaces FakeAuthRepository — already isolated, single-line swap)
2. Backend MVP: users, listings, bookings, payments endpoints
3. Razorpay integration
4. Replace `sampleListings` + `sampleBookings` with real API calls
5. File uploads to Firebase Storage with size + video-duration validation

### Phase 1c (1–2 weeks)
6. Push notifications (FCM)
7. Real admin panel (Retool or simple Next.js dashboard)
8. Crashlytics + Analytics
9. Native splash + launcher icons
10. iOS + Android signing, internal test track

### Phase 1d (1 week)
11. Legal pages (privacy / terms / data deletion)
12. App Store + Play Store listings
13. Beta with 20–30 testers via TestFlight + Play Internal Testing
14. Bug fixes from beta feedback

### Phase 2 (post-launch, ongoing)
- Real-time campaign analytics
- Map view for billboards
- In-app chat with admin
- Premium tier launch
- Referral / loyalty
- Multi-city expansion

**Realistic minimum to public launch from today: 4–6 weeks** with 1 mobile + 1 backend engineer working full-time.

---

## 7. Open decisions I need from you

1. **Backend language preference** (Node.js / Python / Go)?
2. **Hosting**: cloud provider preference (AWS / GCP / Vercel-Railway / self-hosted)?
3. **Payment gateway**: Razorpay is the default; do you want to also support PhonePe / Cashfree?
4. **OTP provider**: Firebase Phone Auth (free, but Google logo on the UI) vs MSG91 (paid, India-native, no branding)?
5. **Admin panel build vs buy**: Retool / Refine / Forest Admin vs custom Next.js dashboard?
6. **Analytics**: Firebase Analytics (free) vs Mixpanel / Amplitude (paid, more powerful)?
7. **Single-city launch or multi-city from day 1**? Affects backend complexity (multi-tenancy if multi-city later).
8. **Web admin app needed at launch** or is "approve via Firebase console" acceptable for first 100 bookings?

Send me your picks and I'll lock in the architecture + write the Phase 1b project plan.
