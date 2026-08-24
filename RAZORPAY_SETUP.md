# Reset95 — Razorpay In-App Payment Setup

This is the one-time setup to make the **Pay** button charge real money.
The app code is already done — you only need to plug in your Razorpay
account keys, deploy the Cloud Functions, and add a webhook.

## How the payment flow works

1. User taps **Pay ₹X** on the Review screen.
2. The app creates the booking as `pending_payment` and calls the
   `createRazorpayOrder` Cloud Function. The **amount is taken from the
   booking on the server** — the app can't change what's charged.
3. The Razorpay Checkout sheet opens (UPI / cards / netbanking).
4. After payment, the app calls `verifyRazorpayPayment`. The function
   verifies Razorpay's signature and flips the booking to
   **paid → pending_review**. The user lands on the success screen and the
   "Payment received" push fires.
5. A **webhook** (`razorpayWebhook`) is the safety net: if the app is
   closed before step 4, Razorpay tells your server directly and the
   booking is still marked paid. Both paths are idempotent (no double
   charge, no double booking).

A payment that's cancelled or fails leaves the booking as **AWAITING
PAYMENT** in History so it can be retried.

---

## Step 1 — Create a Razorpay account

1. Sign up at https://dashboard.razorpay.com
2. You can start in **Test Mode** immediately (no KYC needed) to try the
   whole flow with fake money.
3. To accept **real** money, complete **KYC / business verification**
   (PAN, GST, bank account). This is Razorpay's process and can take a
   few days.

## Step 2 — Get your API keys

In the Razorpay Dashboard → **Settings → API Keys → Generate Key**.
You get two values:

- **Key ID** — looks like `rzp_test_xxxxxxxx` (test) or `rzp_live_xxxxxxxx`
  (live). This is *publishable* — it ships inside the app.
- **Key Secret** — shown **once**. Copy it now. This is secret — it lives
  only on the server.

## Step 3 — Configure the Cloud Functions

From the project's `functions/` folder:

**3a. The publishable Key ID** goes in `functions/.env` (create the file):

```
RAZORPAY_KEY_ID=rzp_test_xxxxxxxx
```

**3b. The Key Secret** goes in a Firebase secret (never in a file):

```
firebase functions:secrets:set RAZORPAY_KEY_SECRET
# paste the key secret when prompted
```

**3c. The webhook secret** — pick any strong random string now (you'll
paste the *same* string into the Razorpay dashboard in Step 5):

```
firebase functions:secrets:set RAZORPAY_WEBHOOK_SECRET
# paste your chosen webhook secret when prompted
```

## Step 4 — Deploy the functions

```
firebase deploy --only functions
```

After it finishes, note the URL printed for **razorpayWebhook**. It looks
like:

```
https://asia-south1-<YOUR_PROJECT_ID>.cloudfunctions.net/razorpayWebhook
```

(You can always get it again with `firebase functions:list`.)

## Step 5 — Add the webhook in Razorpay

Razorpay Dashboard → **Settings → Webhooks → Add New Webhook**:

- **Webhook URL**: the `razorpayWebhook` URL from Step 4.
- **Secret**: the *same* string you set as `RAZORPAY_WEBHOOK_SECRET`.
- **Active events**: tick **`payment.captured`** (and optionally
  **`order.paid`**).
- Save.

## Step 6 — Build the app

```
flutter pub get
flutter run          # or: flutter build apk --release
```

`flutter pub get` pulls the new `razorpay_flutter` package. That's the
only app-side thing you need to do.

---

## Testing in Test Mode

With `rzp_test_...` keys, use Razorpay's test instruments — no real money
moves:

- **UPI success**: enter `success@razorpay` as the UPI ID.
- **UPI failure**: enter `failure@razorpay`.
- **Test card**: `4111 1111 1111 1111`, any future expiry, any CVV, any
  name. Use OTP `1111` if asked.

Do a full run: Pay → success screen → check the booking shows **PENDING**
(in review) and **paid** in Firestore. Then check the admin queue sees it.

## Going live

1. Finish Razorpay KYC.
2. Replace `RAZORPAY_KEY_ID` in `functions/.env` with your `rzp_live_...`
   Key ID and re-run `firebase functions:secrets:set RAZORPAY_KEY_SECRET`
   with the **live** secret.
3. `firebase deploy --only functions`.
4. Add a **live-mode** webhook in the Razorpay dashboard (test and live
   webhooks are separate) pointing at the same URL, same secret.
5. Rebuild the app. (The live Key ID is fetched from the server, so no
   app code change is needed to switch test → live.)

---

## Notes / gotchas

- **iOS**: `razorpay_flutter` needs CocoaPods (the Razorpay iOS SDK) — run
  `pod install` in `ios/` before an iOS build. **Android is unaffected**,
  so your current Android track is fine.
- **R8 is currently off.** When you turn it back on later, the Razorpay
  keep-rules are already in `android/app/proguard-rules.pro`, so Checkout
  won't be stripped.
- **Nothing charges until keys are set.** If the functions are deployed
  without keys, `createRazorpayOrder` returns a "not configured" error and
  the app shows a friendly "payment not available" message — it won't
  crash.
- **Amount is server-side** (from `pricing.total`, which already includes
  18% GST), so the charge always matches the order summary.
