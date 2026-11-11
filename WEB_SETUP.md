# Reset95 — customer web app

The customer app (same screens as Android) now also builds for the browser.
Mobile code paths are unchanged: every web difference sits behind `kIsWeb`.

## Build

```
flutter build web --release -o build/web_app
```

`-o build/web_app` keeps it separate from the admin build, which uses
`build/web` (`flutter build web -t lib/main_admin.dart`).

Run locally: `flutter run -d chrome`

## What is different on web

| Area | Mobile | Web |
|---|---|---|
| OTP login | `verifyPhoneNumber` | `signInWithPhoneNumber` (invisible reCAPTCHA) |
| Google login | google_sign_in plugin | Firebase popup |
| Uploads (KYC, creatives) | `putFile` from disk | `putData` from browser bytes |
| Creative preview | file on disk | browser blob URL |
| Payment | razorpay_flutter sheet | Razorpay `checkout.js` (same Cloud Functions) |
| Invoice | share sheet with PDF | browser download |
| Push notifications | FCM | off (in-app bell still works) |
| App Check / Crashlytics | on | off |
| Layout | bottom tabs, single column | 900px+ wide: top navigation bar, card grids, centred page content; narrower: same as mobile |

## One-time setup before going live

1. **Hosting site.** Firebase Console → Hosting → add a second site (e.g.
   `reset95-app`), then deploy `build/web_app` to it. `firebase.json`
   currently has one hosting entry (`build/web`) and was left untouched.
2. **Authorized domain.** Firebase Console → Authentication → Settings →
   Authorized domains: add your custom domain (the `*.web.app` one is added
   automatically). OTP and Google login fail on unlisted domains.
3. **Storage CORS.** Uploaded creatives are shown from Firebase Storage; the
   bucket needs a CORS rule for the site's origin or images won't render.
4. **Razorpay.** Same keys/secrets as mobile (`RAZORPAY_SETUP.md`). Add the
   website URL in the Razorpay dashboard.
5. **Later:** App Check for web (reCAPTCHA site key), web push.

## UI preview (no login needed)

To look at every screen without a real login:

```
flutter run -d chrome --dart-define=UI_PREVIEW=true
```

Any phone number + any 6-digit OTP signs in as a sample corporate user, and
Home / History show sample data. Uploads and payment don't work in this
mode. It is off unless that flag is passed, so normal and release builds are
unaffected.
