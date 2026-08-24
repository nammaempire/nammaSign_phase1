# Google Play — Data Safety form answers (Reset95)

Transcribe these into **Play Console → App content → Data safety**. They're
based on what the Reset95 app actually collects (Firebase Auth/Firestore/
Storage/Functions/FCM/Analytics/Crashlytics/App Check, plus Razorpay for
payments). Read the two ⚠️ judgment calls at the bottom before you submit.

---

## Section 1 — Overview questions

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **Yes** |
| Is all of the user data collected by your app encrypted in transit? | **Yes** |
| Do you provide a way for users to request that their data is deleted? | **Yes** — in-app (Profile → Delete account) **and** a web URL (your hosted `account-deletion.html`) |

You will also be asked for a **Privacy policy URL** (App content → set it to your
hosted `privacy-policy.html`).

---

## Section 2 — Data types (what to declare)

For every row: **Collected = Yes**, **Processed ephemerally = No** (we store it),
and **Shared = No** unless stated. “Optional” means only some users provide it.

### Personal info

| Data type | Collected | Shared | Required/Optional | Purposes |
|---|---|---|---|---|
| Name | Yes | No | Required | Account management, App functionality |
| Email address | Yes | No | Required | Account management, App functionality, Customer support |
| Phone number | Yes | No | Required | Account management (OTP sign-in), App functionality |
| Other info (business KYC: company name, PAN, GSTIN) | Yes | No* | Optional (corporate users) | App functionality, Fraud prevention/compliance |

### Financial info

| Data type | Collected | Shared | Required/Optional | Purposes |
|---|---|---|---|---|
| Purchase history (bookings, amounts, transaction IDs) | Yes | No | Required (to book) | App functionality |
| Payment info (card/UPI/bank credentials) | **No** — entered directly into **Razorpay**; the app never receives or stores it | — | — | — |

### Photos and videos

| Data type | Collected | Shared | Required/Optional | Purposes |
|---|---|---|---|---|
| Photos and videos (your ad creatives) | Yes | Yes** | Required (to run an ad) | App functionality |

### Files and docs

| Data type | Collected | Shared | Required/Optional | Purposes |
|---|---|---|---|---|
| Files and docs (uploaded KYC documents: PAN/CIN/GST/address proof) | Yes | No* | Optional (corporate users) | App functionality, Fraud prevention/compliance |

### App activity

| Data type | Collected | Shared | Required/Optional | Purposes |
|---|---|---|---|---|
| App interactions (analytics events, screens viewed) | Yes | No | Optional | Analytics |
| Other user-generated content (campaign title/description) | Yes | No | Required | App functionality |

### App info and performance

| Data type | Collected | Shared | Required/Optional | Purposes |
|---|---|---|---|---|
| Crash logs | Yes | No | Optional | Analytics (stability) |
| Diagnostics (performance/diagnostic data) | Yes | No | Optional | Analytics |

### Device or other identifiers

| Data type | Collected | Shared | Required/Optional | Purposes |
|---|---|---|---|---|
| Device or other IDs (Firebase installation ID / FCM push token / analytics app-instance ID) | Yes | No | Optional | App functionality (push notifications), Analytics |

---

## Section 3 — Security practices (tick these)

- ✅ **Data is encrypted in transit** (all Firebase + Razorpay traffic is HTTPS/TLS).
- ✅ **Users can request that data be deleted** (in-app + web URL).
- ✅ You follow the Play **Families**/target-audience policy if you ever target
  under-18s — Reset95 targets adults (18+), so keep the target audience 18+.

---

## ⚠️ Two judgment calls to confirm before submitting

1. **\* Business KYC / documents — “Shared”.**
   Declared as **not shared** because today the GSTIN/PAN verification provider
   is **not configured** in the app. **If** you later enable a third-party KYC
   verification API (that receives PAN/GSTIN/company data), change those two
   rows to **Shared = Yes** with purpose *Fraud prevention, security & compliance*.

2. **\*\* Photos and videos — “Shared”.**
   Your ad creative is delivered to the **billboard operator** to be displayed.
   If the operator is a **separate company**, that counts as sharing → keep
   **Shared = Yes**. If you own/operate all the boards yourself (no external
   party receives the file), set **Shared = No**. Pick the one that matches your
   real setup.

> These answers must match your app’s real behaviour and your Privacy Policy.
> Google audits for consistency. Update the form whenever you add a data-using
> feature (e.g., turning on the KYC provider).
