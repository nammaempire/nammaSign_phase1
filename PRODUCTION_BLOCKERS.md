# NammaSign — Production Blockers (re-check)

Re-audit date: 2026-06-30 (after your latest changes) · Read-only review, no code changed.

**Since the last audit you fixed:** Crashlytics + Analytics (now wired in `main.dart`), legal Privacy/Terms pages (DPDPA-aware, linked from Profile), and the iOS `CFBundleName`. Good progress. But the edits introduced **one new hard blocker**, and five earlier criticals are still open.

---

## 🚨 NEW — build-breaking regression (fix first)

### 0. `ios/Runner/Info.plist` is corrupt — the iOS app will not compile
- **File:** `ios/Runner/Info.plist` (ends at line 91–92)
- **Issue:** The file ends mid-edit with an **unterminated XML comment**:
  ```xml
  	<!--
  		PRIVACY USAGE D
  ```
  There's no closing `-->`, no closing `</dict>`, and no `</plist>`. `xmllint` confirms: *"Comment not terminated / Premature end of data in tag dict."* Looks like a save was cut off while you were adding the privacy usage descriptions.
- **Impact:** Any iOS build (and likely `flutter run` on iOS) fails immediately. This is the single most urgent item.
- **Fix:** Close the comment / finish the `NS...UsageDescription` block and properly terminate the `</dict></plist>`. (See note under #5 on which usage strings you actually need.)

---

## 🔴 Critical — still open

### 1. iOS bundle identifier is still the example default
- **File:** `ios/Runner.xcodeproj/project.pbxproj` — `PRODUCT_BUNDLE_IDENTIFIER = com.example.nammasignPhase1`
- Apple rejects `com.example.*`, and it doesn't match the Android id (`com.nammaempire.nammasign`) or the Firebase iOS registration. **Unchanged.**

### 2. ~~Account-deletion Cloud Function deletes the WRONG storage paths~~ — ✅ FIXED (2026-06-30)
- **File:** `functions/index.js` → `_hardDeleteUser()`
- **Was:** deleted `kyc/${uid}/` and `creatives/${uid}/` — paths that don't exist, so user files survived deletion.
- **Now:** deletes `users/${uid}/` (avatar + KYC), `bookings/${uid}/` (creatives), and `invoices/${uid}/` — matching where the client actually uploads (`user_profile_repository.dart`, `booking_provider.dart`) and `storage.rules`. The header comment was updated to match.
- **Action still required:** redeploy functions (`firebase deploy --only functions`) for the fix to take effect in production.

### 3. ~~Release builds fall back to DEBUG signing~~ — ✅ FIXED (2026-06-30)
- **File:** `android/app/build.gradle.kts`
- **Was:** when `key.properties` was missing, `release` was silently signed with the **debug** key → an un-shippable, insecure AAB.
- **Now:** added a `hasReleaseSigning` check (keystore file present *and* all four properties set). Release is signed only with the real upload key; if absent, `signingConfig = null`. A `gradle.taskGraph.whenReady` guard aborts the build with a clear message whenever a release assembly task (`assemble*/bundle*/package*Release`) runs without a valid keystore. Debug builds and `flutter run` still work with no keystore.
- **Action still required:** create `android/key.properties` (git-ignored) with `keyAlias`, `keyPassword`, `storeFile`, `storePassword` pointing at your production upload keystore before building a release.

### 4. ~~Admin login ships hardcoded credentials in the UI~~ — ✅ FIXED (2026-06-30)
- **File:** `lib/admin/features/auth/screens/admin_login_screen.dart`
- **Was:** the email/password fields were pre-filled with `admin@nammaempire.com` / `NammaSign@2026` via `_kDevDefaultEmail` / `_kDevDefaultPassword` constants.
- **Now:** removed both constants and the TODO block; the controllers start empty (`TextEditingController()`), so the admin must type their own credentials.
- **Action still required:** if `NammaSign@2026` was ever a real account password, rotate it in Firebase Console → Authentication, since it has been committed to git history.

### 5. iOS privacy usage descriptions — finish the block you started
- **File:** `ios/Runner/Info.plist`
- Tied to #0: the truncated comment was clearly an attempt to add usage strings. **Note on scope:** your uploads use `file_selector` → `openFile` (the iOS Files document picker), which does **not** require `NSPhotoLibraryUsageDescription`. So you only need camera/photo-library strings if you later add `image_picker`/camera capture. Either way, finish/repair the plist so it's valid XML.

---

## 🟠 High — still open

### 6. No payment enforcement (Razorpay still deferred)
- **Files:** `booking_provider.dart` (`paid: false`, `status: BookingStatus.pending`), `review_pay_screen.dart`
- "Pay" still goes straight to `pending_review`; payment is offline/manual. Firestore rules still let a client create a booking directly at `pending_review`. If that's the intended Phase-1 flow, soften the "Powered by Razorpay / 256-bit encryption" UI copy so it isn't misleading. **By design, but confirm.**

### 7. ~~No crash reporting / analytics~~ — ✅ FIXED
- `firebase_crashlytics ^4.1.3` + `firebase_analytics ^11.3.3` added; `main.dart` wires `runZonedGuarded`, `FlutterError.onError`, `PlatformDispatcher.onError`, and `recordFlutterFatalError` (release-only collection). Solid.

### 8. No Firebase App Check + open `waitlist` writes — 🟡 PARTIALLY FIXED (2026-06-30)
- **Open `waitlist` writes — ✅ FIXED:** `firestore.rules` `waitlist` rule changed from `allow create: if true` (any anonymous client on the internet) to `allow create: if isSignedIn()`. The app is fully auth-gated, so every write is now accountable to a uid. Reads stay admin-only.
- **Firebase App Check — ⏳ STILL PENDING (not a pure code change):** App Check requires (a) adding the `firebase_app_check` package + `activate()` in `main.dart`, (b) registering attestation providers in the **Firebase Console** (Play Integrity for Android, DeviceCheck/App Attest for iOS), and (c) toggling enforcement once monitoring looks clean. Enabling enforcement before the apps are registered would break all Firebase calls, so this must be done deliberately with console access — flagged as follow-up rather than wired blindly here.

### 9. Essentially no tests — 🟡 STARTED (2026-06-30)
- **Added** unit tests covering the highest-risk pure logic (no Firebase needed):
  - `test/booking_totals_test.dart` — GST/discount math: no-discount tier, 8% (15–29d) and 15% (30d+) boundaries, `round()` behavior, the `total = (subtotal − discount) + gst` invariant, and `formatRupees` grouping.
  - `test/validators_test.dart` — `Validators.required/email/phone/otp/password`.
  - `test/string_extensions_test.dart` — `capitalized`, `initials`, `isValidEmail`, `isNumeric`.
- Expected values were hand-verified (no Dart/Flutter toolchain in this sandbox to run them). **Run `flutter test` locally to confirm green.**
- **Still uncovered (follow-up):** Firestore security rules (emulator + `@firebase/rules-unit-testing`), widget/integration smoke tests (need Firebase mocks), and Cloud Functions logic.

---

## 🟡 Medium — still open

10. **Android `namespace`** — ✅ FIXED (2026-06-30). Changed from `com.example.nammasign_phase1` to `com.nammaempire.nammasign` (matches `applicationId`). `MainActivity.kt` was moved to `.../kotlin/com/nammaempire/nammasign/` with package `com.nammaempire.nammasign`, the old `com/example/...` file/dirs were deleted, and the manifest's relative `.MainActivity` now resolves correctly. **Run `flutter build apk` locally to confirm.**
11. **Minification/obfuscation** — ✅ FIXED (2026-06-30). Enabled R8 in the release build (`isMinifyEnabled = true`, `isShrinkResources = true`) with a new `android/app/proguard-rules.pro` (Firebase, Crashlytics line numbers, Flutter embedding keeps). Smaller, obfuscated APK. **Must smoke-test the release build** (`flutter build apk --release` + run) since missing keep rules only surface at runtime in release.
12. ~~iOS internal bundle name suffix~~ — ✅ FIXED (`CFBundleName` now `NammaSign`).
13. ~~No in-app privacy/terms links~~ — ✅ FIXED (Legal section in Profile → Privacy policy / Terms, DPDPA-aware).
14. **Stale `PRODUCTION_READINESS.md`** — ✅ FIXED (2026-06-30). Added a "SUPERSEDED — historical document" banner at the top pointing to this file; content kept for history.

---

## Current status table

| # | Blocker | Severity | Status |
|---|---------|----------|--------|
| 0 | **Info.plist corrupt — iOS won't build** | 🚨 | **NEW** |
| 1 | iOS bundle id `com.example.*` | 🔴 | Open |
| 2 | Account-deletion wipes wrong storage paths | 🔴 | ✅ Fixed |
| 3 | Release falls back to debug signing | 🔴 | ✅ Fixed |
| 4 | Hardcoded admin credentials in UI | 🔴 | ✅ Fixed |
| 5 | Finish/repair iOS usage-description block | 🔴 | Open |
| 6 | No payment enforcement; Razorpay copy | 🟠 | Open (by design?) |
| 7 | Crash reporting / analytics | 🟠 | ✅ Fixed |
| 8 | No App Check; open `waitlist` writes | 🟠 | 🟡 Partial (waitlist fixed; App Check pending) |
| 9 | No meaningful test coverage | 🟠 | 🟡 Started (unit tests added) |
| 10 | Android example `namespace` | 🟡 | ✅ Fixed |
| 11 | Minification/obfuscation off | 🟡 | ✅ Fixed |
| 12 | iOS internal bundle name | 🟡 | ✅ Fixed |
| 13 | Privacy/terms links in app | 🟡 | ✅ Fixed |
| 14 | Stale readiness doc | 🟡 | ✅ Fixed |

No code was modified during this re-audit.
