# NammaSign — Firebase Architecture

Reference for the complete Firebase backend. Covers Firestore data model, indexes, security rules, Storage layout, Cloud Functions API, and FCM topics. Every "Phase 1b" placeholder in the Flutter app maps to something defined here.

---

## 0. Firebase services in use

| Service | Purpose |
|---|---|
| **Firebase Auth** | Phone OTP, Google, Apple sign-in |
| **Cloud Firestore** | Primary database |
| **Firebase Storage** | Creatives (image/video), KYC docs, avatars, invoices |
| **Cloud Functions (TS)** | Razorpay, scheduler, admin actions, aggregations |
| **Cloud Messaging (FCM)** | Push to mobile users + push to player devices |
| **Realtime Database** | Device heartbeats (low-latency, append-only telemetry) |
| **Firebase Hosting** | Admin dashboard (Next.js export) |

Realtime DB is used **only** for device telemetry because it's cheaper and faster for append-only IoT data than Firestore. Everything else lives in Firestore.

---

## 1. Firestore collections

### `users/{uid}`

```ts
{
  uid: string,                  // matches Firebase Auth uid
  phone: string | null,         // E.164 e.g. +919876543210
  email: string | null,
  displayName: string | null,
  photoUrl: string | null,
  accountType: 'corporate' | 'individual' | null,

  // Corporate-only
  org: {
    name: string,
    panCin: string,
    officialEmail: string,
    managerName: string,
    managerPhone: string,
  } | null,

  // Individual-only
  personal: {
    fullName: string,
    dob: Timestamp,
    aadhaarLast4: string,       // never store full Aadhaar number
  } | null,

  kycStatus: 'none' | 'pending' | 'verified' | 'rejected',
  fcmTokens: string[],          // array of registered device push tokens

  createdAt: Timestamp,
  updatedAt: Timestamp,
}
```

### `areas/{areaId}`

Three docs initially: `koramangala`, `madiwala`, `electronic-city`.

```ts
{
  id: string,                   // doc id
  name: string,                 // "Koramangala"
  city: string,                 // "Bengaluru"
  description: string,          // multi-line address summary
  boardCount: number,           // 4
  pricePerDay: number,          // 650
  maxAdsInRotation: number,     // 30
  estimatedViewsPerDay: number, // 48000 aggregate
  status: 'active' | 'maintenance' | 'inactive',
  geo: { lat: number, lng: number },
  createdAt: Timestamp,
}
```

### `devices/{deviceId}`

One doc per physical signage board (12 total in Phase 1).

```ts
{
  id: string,                   // e.g. "koramangala-01"
  areaId: string,               // ref to areas
  label: string,                // "Koramangala Board #1 — Forum Mall"
  serialNumber: string,         // hardware serial
  installLocation: string,      // "Forum Mall, Hosur Road"
  status: 'online' | 'offline' | 'maintenance',
  appVersion: string,           // player APK version
  networkType: '4g' | 'wifi' | 'ethernet' | 'unknown',
  installedAt: Timestamp,
  lastSeenAt: Timestamp,        // updated by heartbeat function
  currentlyPlayingBookingId: string | null,
}
```

### `bookings/{bookingId}`

Single collection covering the entire lifecycle. Status transitions are append-only — never delete bookings.

```ts
{
  id: string,
  userId: string,
  areaId: string,
  accountType: 'corporate' | 'individual',

  status: 'draft'             // user is filling the form
        | 'pending_payment'   // submitted, awaiting Razorpay
        | 'pending_review'    // paid, awaiting admin
        | 'approved'          // admin approved, ready to schedule
        | 'live'              // currently rotating on boards
        | 'completed'         // delivered target plays
        | 'rejected'          // admin rejected
        | 'cancelled',        // user cancelled before payment

  // Campaign details
  campaignTitle: string,
  description: string,
  purpose: string | null,     // individual only

  // Duration & scheduling
  durationDays: number,
  scheduledStartAt: Timestamp,
  scheduledEndAt: Timestamp,
  actualEndAt: Timestamp | null,  // may shift later if replays needed

  // Creative
  creative: {
    url: string,              // gs:// or https:// signed
    type: 'image' | 'video',
    durationSeconds: number,  // for videos
    sizeBytes: number,
    width: number,
    height: number,
  } | null,

  // Pricing snapshot — frozen at booking time
  pricing: {
    dailyRate: number,
    durationDays: number,
    subtotal: number,
    discountPercent: number,
    discount: number,
    gstPercent: number,       // 18
    gst: number,
    total: number,
  },

  // Proof of play
  targetPlays: number,        // computed: assumes 10s ads, 30-ad rotation
  actualPlays: number,        // incremented by deviceReportPlay function

  // Admin
  review: {
    reviewerId: string,
    reviewedAt: Timestamp,
    decision: 'approved' | 'rejected',
    reason: string | null,    // for rejections
    ruleCode: string | null,  // e.g. "NE-CREATIVE-04"
  } | null,

  // Audit timestamps
  createdAt: Timestamp,
  updatedAt: Timestamp,
  submittedAt: Timestamp | null,
  paidAt: Timestamp | null,
  liveAt: Timestamp | null,
  completedAt: Timestamp | null,
}
```

### `payments/{paymentId}`

One doc per payment attempt (so retries create multiple).

```ts
{
  id: string,
  bookingId: string,
  userId: string,
  amount: number,             // in paise (multiply ₹ × 100)
  currency: 'INR',
  method: 'upi' | 'card' | 'netbanking',
  status: 'initiated' | 'success' | 'failed' | 'refunded',
  razorpay: {
    orderId: string,
    paymentId: string | null,
    signature: string | null,
  },
  failure: {
    code: string,             // e.g. "E_INSUFFICIENT_BAL"
    reason: string,
  } | null,
  createdAt: Timestamp,
  capturedAt: Timestamp | null,
  refundedAt: Timestamp | null,
}
```

### `devices/{deviceId}/scheduleItems/{bookingId}`

Subcollection. The scheduler writes one doc per active booking that should rotate on this device.

```ts
{
  bookingId: string,
  creativeUrl: string,
  creativeType: 'image' | 'video',
  durationSeconds: number,
  priority: number,           // 1.0 = normal, lower = down-prioritized
  addedAt: Timestamp,
  expiresAt: Timestamp,       // when to stop playing
}
```

### `users/{uid}/notifications/{notifId}`

```ts
{
  type: 'booking_approved' | 'booking_rejected' | 'payment_success'
      | 'campaign_live' | 'campaign_completed' | 'kyc_verified',
  title: string,
  body: string,
  bookingId: string | null,
  read: boolean,
  createdAt: Timestamp,
}
```

### `users/{uid}/kycDocs/{docId}`

```ts
{
  type: 'pan' | 'cin' | 'aadhaar_front' | 'aadhaar_back' | 'gst' | 'address_proof',
  storageUrl: string,         // gs:// path
  fileName: string,
  sizeBytes: number,
  status: 'pending' | 'verified' | 'rejected',
  rejectionReason: string | null,
  reviewedBy: string | null,
  uploadedAt: Timestamp,
  reviewedAt: Timestamp | null,
}
```

### `waitlist/{auto}`

Premium-tier "Notify me" signups.

```ts
{
  email: string,
  userId: string | null,
  joinedAt: Timestamp,
}
```

### `config/global` (single doc)

Static config readable by all signed-in users.

```ts
{
  appVersionMin: { ios: string, android: string },
  supportEmail: string,
  supportPhone: string,
  termsUrl: string,
  privacyUrl: string,
  defaultMaxAdsPerRotation: 30,
  defaultAdLengthSeconds: 10,
  operatingHours: { start: '09:00', end: '22:00', tz: 'Asia/Kolkata' },
}
```

### `admin/users/{uid}` (single doc indicating admin role)

```ts
{
  uid: string,
  role: 'admin' | 'reviewer',
  addedAt: Timestamp,
  addedBy: string,
}
```

---

## 2. Realtime Database (telemetry only)

```
/heartbeats/{deviceId}: {
  ts: number,                 // server epoch ms
  status: 'playing' | 'idle' | 'error',
  currentlyPlaying: string | null,  // bookingId
  uptime: number,             // seconds since boot
  appVersion: string,
  networkType: string,
  signalStrength: number,     // 0-100 for cellular
}

/plays/{deviceId}/{auto}: {
  bookingId: string,
  startedAt: number,
  endedAt: number,
  durationMs: number,
  completed: boolean,         // false if cut off
}
```

Cloud Function `aggregatePlays` runs every 10 minutes, scans new entries under `/plays/*`, increments `bookings/{id}.actualPlays`, then deletes the processed entries. This keeps the realtime DB lean and the actualPlays counter authoritative in Firestore.

---

## 3. Firestore indexes

Add these to `firestore.indexes.json`:

```json
{
  "indexes": [
    { "collectionGroup": "bookings", "fields": [
      { "fieldPath": "userId", "order": "ASCENDING" },
      { "fieldPath": "createdAt", "order": "DESCENDING" }
    ]},
    { "collectionGroup": "bookings", "fields": [
      { "fieldPath": "status", "order": "ASCENDING" },
      { "fieldPath": "createdAt", "order": "DESCENDING" }
    ]},
    { "collectionGroup": "bookings", "fields": [
      { "fieldPath": "areaId", "order": "ASCENDING" },
      { "fieldPath": "status", "order": "ASCENDING" },
      { "fieldPath": "scheduledStartAt", "order": "ASCENDING" }
    ]},
    { "collectionGroup": "payments", "fields": [
      { "fieldPath": "userId", "order": "ASCENDING" },
      { "fieldPath": "createdAt", "order": "DESCENDING" }
    ]},
    { "collectionGroup": "devices", "fields": [
      { "fieldPath": "areaId", "order": "ASCENDING" },
      { "fieldPath": "status", "order": "ASCENDING" }
    ]},
    { "collectionGroup": "notifications", "fields": [
      { "fieldPath": "read", "order": "ASCENDING" },
      { "fieldPath": "createdAt", "order": "DESCENDING" }
    ]}
  ]
}
```

---

## 4. Firestore security rules

`firestore.rules`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isSignedIn() { return request.auth != null; }
    function isOwner(uid) { return isSignedIn() && request.auth.uid == uid; }
    function isAdmin() {
      return isSignedIn() &&
        exists(/databases/$(database)/documents/admin/users/$(request.auth.uid));
    }

    // Users: own doc R/W only
    match /users/{uid} {
      allow read: if isOwner(uid) || isAdmin();
      allow write: if isOwner(uid);

      match /notifications/{notifId} {
        allow read, update: if isOwner(uid);
        allow create, delete: if isAdmin();
      }
      match /kycDocs/{docId} {
        allow read: if isOwner(uid) || isAdmin();
        allow create: if isOwner(uid);
        allow update: if isAdmin();   // only admin can verify/reject
      }
    }

    // Areas: publicly readable (also for unauthenticated landing pages later)
    match /areas/{areaId} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // Devices: admin-only writes; players auth via service account, not these rules
    match /devices/{deviceId} {
      allow read: if isSignedIn();
      allow write: if isAdmin();
      match /scheduleItems/{itemId} {
        allow read: if isSignedIn();
        allow write: if false;       // only Cloud Functions write here
      }
    }

    // Bookings: user reads/writes drafts; once submitted, only server mutates
    match /bookings/{bookingId} {
      allow read: if isSignedIn() &&
        (resource.data.userId == request.auth.uid || isAdmin());
      allow create: if isSignedIn() &&
        request.resource.data.userId == request.auth.uid &&
        request.resource.data.status == 'draft';
      allow update: if isSignedIn() &&
        resource.data.userId == request.auth.uid &&
        resource.data.status == 'draft' &&
        request.resource.data.status in ['draft', 'pending_payment'];
      // No client deletes
    }

    // Payments: read-own, server-only writes
    match /payments/{paymentId} {
      allow read: if isSignedIn() &&
        (resource.data.userId == request.auth.uid || isAdmin());
      allow write: if false;
    }

    // Waitlist: anyone can join
    match /waitlist/{id} {
      allow create: if true;
      allow read: if isAdmin();
    }

    // Config: world-readable
    match /config/{doc} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // Admin
    match /admin/{path=**} {
      allow read, write: if isAdmin();
    }
  }
}
```

---

## 5. Storage layout + rules

```
/users/{uid}/avatar.jpg
/users/{uid}/kyc/{type}.{ext}
/bookings/{bookingId}/creative.{ext}
/invoices/{bookingId}/invoice.pdf
```

`storage.rules`:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    function isSignedIn() { return request.auth != null; }
    function isOwner(uid) { return isSignedIn() && request.auth.uid == uid; }

    match /users/{uid}/{path=**} {
      allow read: if isOwner(uid);
      allow write: if isOwner(uid) && request.resource.size < 10 * 1024 * 1024;
    }

    // Creatives — uploaded by user, but only Cloud Functions can mark as
    // 'attached to booking'. Public read so player devices can fetch.
    match /bookings/{bookingId}/{path=**} {
      allow read: if true;
      allow write: if isSignedIn() && request.resource.size < 50 * 1024 * 1024;
    }

    // Invoices — server generated, signed URL access only
    match /invoices/{bookingId}/{path=**} {
      allow read: if isSignedIn();
      allow write: if false;
    }
  }
}
```

---

## 6. Cloud Functions API

Project structure (`functions/src/`):

```
functions/src/
  index.ts                — exports
  triggers/
    onUserCreate.ts       — auth.user().onCreate
    onBookingWrite.ts     — firestore trigger
    onPaymentWrite.ts     — firestore trigger
  callable/
    submitBooking.ts
    initRazorpayPayment.ts
    verifyRazorpayPayment.ts
    deviceHeartbeat.ts
    deviceReportPlay.ts
  admin/
    approveBooking.ts
    rejectBooking.ts
    cancelBooking.ts
    verifyKyc.ts
  http/
    razorpayWebhook.ts    — receives webhook events from Razorpay
    deviceRegister.ts     — initial device pairing
  scheduled/
    runScheduler.ts       — every 5 min: rebuild device schedules
    aggregatePlays.ts     — every 10 min: realtime db → firestore counters
    completeBookings.ts   — every hour: mark fully-delivered bookings
    boardHealthCheck.ts   — every 5 min: flag stale devices offline
  utils/
    razorpay.ts
    fcm.ts
    pricing.ts
    pdf.ts
```

### 6.1 Auth trigger

```typescript
// triggers/onUserCreate.ts
export const onUserCreate = functions.auth.user().onCreate(async (user) => {
  await db.collection('users').doc(user.uid).set({
    uid: user.uid,
    phone: user.phoneNumber ?? null,
    email: user.email ?? null,
    displayName: user.displayName ?? null,
    photoUrl: user.photoURL ?? null,
    accountType: null,
    kycStatus: 'none',
    fcmTokens: [],
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
});
```

### 6.2 Submit booking (callable)

```typescript
// callable/submitBooking.ts
export const submitBooking = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');
  const { bookingId } = request.data as { bookingId: string };

  const ref = db.collection('bookings').doc(bookingId);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError('not-found', 'Booking not found');
  const b = snap.data()!;
  if (b.userId !== request.auth.uid) {
    throw new HttpsError('permission-denied', 'Not your booking');
  }
  if (b.status !== 'draft') {
    throw new HttpsError('failed-precondition', 'Booking already submitted');
  }
  // Validate required fields
  if (!b.creative || !b.campaignTitle) {
    throw new HttpsError('failed-precondition', 'Missing creative or title');
  }
  // Validate video duration ≤ 20s
  if (b.creative.type === 'video' && b.creative.durationSeconds > 20) {
    throw new HttpsError('invalid-argument', 'Video must be 20s or less');
  }

  await ref.update({
    status: 'pending_payment',
    submittedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  return { ok: true };
});
```

### 6.3 Init Razorpay payment (callable)

```typescript
// callable/initRazorpayPayment.ts
import Razorpay from 'razorpay';

const rzp = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID!,
  key_secret: process.env.RAZORPAY_KEY_SECRET!,
});

export const initRazorpayPayment = onCall(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in required');
  const { bookingId, method } = request.data;

  const bookingRef = db.collection('bookings').doc(bookingId);
  const booking = (await bookingRef.get()).data();
  if (!booking || booking.userId !== request.auth.uid) {
    throw new HttpsError('permission-denied', 'Invalid booking');
  }
  if (booking.status !== 'pending_payment') {
    throw new HttpsError('failed-precondition', 'Booking not awaiting payment');
  }

  const order = await rzp.orders.create({
    amount: booking.pricing.total * 100,      // paise
    currency: 'INR',
    receipt: bookingId,
    notes: { bookingId, userId: request.auth.uid },
  });

  const paymentRef = db.collection('payments').doc();
  await paymentRef.set({
    id: paymentRef.id,
    bookingId,
    userId: request.auth.uid,
    amount: booking.pricing.total,
    currency: 'INR',
    method,
    status: 'initiated',
    razorpay: { orderId: order.id, paymentId: null, signature: null },
    failure: null,
    createdAt: FieldValue.serverTimestamp(),
    capturedAt: null,
    refundedAt: null,
  });

  return {
    paymentId: paymentRef.id,
    orderId: order.id,
    amount: order.amount,
    currency: order.currency,
    key: process.env.RAZORPAY_KEY_ID,
  };
});
```

### 6.4 Verify Razorpay payment (callable)

```typescript
// callable/verifyRazorpayPayment.ts
import crypto from 'crypto';

export const verifyRazorpayPayment = onCall(async (request) => {
  const { paymentId, razorpayPaymentId, razorpayOrderId, signature } = request.data;

  // Verify signature
  const body = `${razorpayOrderId}|${razorpayPaymentId}`;
  const expected = crypto
    .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET!)
    .update(body)
    .digest('hex');
  if (expected !== signature) {
    throw new HttpsError('invalid-argument', 'Invalid signature');
  }

  const paymentRef = db.collection('payments').doc(paymentId);
  const payment = (await paymentRef.get()).data();
  if (!payment) throw new HttpsError('not-found', 'Payment not found');

  await paymentRef.update({
    status: 'success',
    'razorpay.paymentId': razorpayPaymentId,
    'razorpay.signature': signature,
    capturedAt: FieldValue.serverTimestamp(),
  });

  // Move booking forward
  await db.collection('bookings').doc(payment.bookingId).update({
    status: 'pending_review',
    paidAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  return { ok: true };
});
```

### 6.5 Razorpay webhook (HTTP)

```typescript
// http/razorpayWebhook.ts
export const razorpayWebhook = onRequest(async (req, res) => {
  const signature = req.headers['x-razorpay-signature'] as string;
  const body = JSON.stringify(req.body);
  const expected = crypto
    .createHmac('sha256', process.env.RAZORPAY_WEBHOOK_SECRET!)
    .update(body)
    .digest('hex');
  if (expected !== signature) {
    res.status(400).send('Invalid signature');
    return;
  }

  const event = req.body.event;
  // Handle payment.failed, refund.created, etc.
  // Update payments + bookings accordingly.
  res.status(200).send('ok');
});
```

### 6.6 Admin actions

```typescript
// admin/approveBooking.ts
export const approveBooking = onCall(async (request) => {
  if (!(await isAdmin(request.auth?.uid))) {
    throw new HttpsError('permission-denied', 'Admin only');
  }
  const { bookingId } = request.data;
  const ref = db.collection('bookings').doc(bookingId);
  const b = (await ref.get()).data()!;
  if (b.status !== 'pending_review') {
    throw new HttpsError('failed-precondition', 'Booking not under review');
  }

  // Compute targetPlays
  const adLengthSec = b.creative.durationSeconds || 10;
  const operatingSecPerDay = 13 * 3600;       // 9 AM to 10 PM
  const maxRotation = 30;
  const playsPerDayPerBoard =
    Math.floor(operatingSecPerDay / adLengthSec / maxRotation);
  const targetPlays = playsPerDayPerBoard * 4 * b.durationDays;  // 4 boards

  await ref.update({
    status: 'approved',
    targetPlays,
    actualPlays: 0,
    review: {
      reviewerId: request.auth!.uid,
      reviewedAt: FieldValue.serverTimestamp(),
      decision: 'approved',
      reason: null,
      ruleCode: null,
    },
    updatedAt: FieldValue.serverTimestamp(),
  });

  // Add to user notifications
  await db.collection('users').doc(b.userId)
    .collection('notifications').add({
      type: 'booking_approved',
      title: 'Your campaign is approved',
      body: `Going live within minutes on ${b.areaId} boards.`,
      bookingId,
      read: false,
      createdAt: FieldValue.serverTimestamp(),
    });

  // Send FCM to user device
  await sendPushToUser(b.userId, 'Your campaign is approved', '...');

  // Trigger scheduler immediately
  await runSchedulerForArea(b.areaId);

  return { ok: true };
});

// admin/rejectBooking.ts — similar but writes review.decision='rejected'
//   sets booking.status = 'rejected', sends rejection notification.
```

### 6.7 Scheduler (scheduled function, every 5 min)

```typescript
// scheduled/runScheduler.ts
export const runScheduler = onSchedule('every 5 minutes', async () => {
  // For each area, find approved+live bookings that should be in rotation
  const now = Timestamp.now();
  const areas = await db.collection('areas').get();

  for (const areaDoc of areas.docs) {
    const areaId = areaDoc.id;

    // All bookings that should currently be live in this area
    const liveBookings = await db.collection('bookings')
      .where('areaId', '==', areaId)
      .where('status', 'in', ['approved', 'live'])
      .where('scheduledStartAt', '<=', now)
      .get();

    // Filter those whose actualPlays < targetPlays
    const active = liveBookings.docs.filter(d => {
      const b = d.data();
      return b.actualPlays < b.targetPlays;
    });

    // For each device in this area, rewrite scheduleItems subcollection
    const devices = await db.collection('devices')
      .where('areaId', '==', areaId).where('status', '==', 'online').get();

    for (const dev of devices.docs) {
      const subRef = dev.ref.collection('scheduleItems');
      const batch = db.batch();

      // Clear existing
      const existing = await subRef.get();
      existing.forEach(d => batch.delete(d.ref));

      // Add active bookings (capped at maxAdsInRotation from area config)
      const cap = areaDoc.data().maxAdsInRotation || 30;
      for (const b of active.slice(0, cap)) {
        const bData = b.data();
        batch.set(subRef.doc(b.id), {
          bookingId: b.id,
          creativeUrl: bData.creative.url,
          creativeType: bData.creative.type,
          durationSeconds: bData.creative.durationSeconds || 10,
          priority: 1.0,
          addedAt: FieldValue.serverTimestamp(),
          expiresAt: bData.scheduledEndAt,
        });
      }

      await batch.commit();
    }

    // Promote any newly-active approved → live + send FCM to devices
    for (const b of active) {
      if (b.data().status === 'approved') {
        await b.ref.update({
          status: 'live',
          liveAt: FieldValue.serverTimestamp(),
        });
      }
    }
  }

  // Push to all area devices: "reload schedule now"
  await sendFcmToTopic('schedule_changed', { reason: 'scheduler_tick' });
});
```

### 6.8 Aggregate plays (scheduled, every 10 min)

```typescript
// scheduled/aggregatePlays.ts
export const aggregatePlays = onSchedule('every 10 minutes', async () => {
  const rtdb = admin.database();
  const playsRef = rtdb.ref('plays');
  const snap = await playsRef.get();
  if (!snap.exists()) return;

  const updates: Record<string, number> = {};  // bookingId → playCount
  const toDelete: string[] = [];

  snap.forEach(deviceSnap => {
    deviceSnap.forEach(playSnap => {
      const p = playSnap.val();
      if (p.completed) {
        updates[p.bookingId] = (updates[p.bookingId] || 0) + 1;
      }
      toDelete.push(`plays/${deviceSnap.key}/${playSnap.key}`);
    });
  });

  // Batch-increment bookings
  const batch = db.batch();
  for (const [bookingId, count] of Object.entries(updates)) {
    batch.update(db.collection('bookings').doc(bookingId), {
      actualPlays: FieldValue.increment(count),
    });
  }
  await batch.commit();

  // Clean up
  const rtUpdates: Record<string, null> = {};
  toDelete.forEach(path => { rtUpdates[path] = null; });
  await rtdb.ref().update(rtUpdates);
});
```

### 6.9 Complete bookings (scheduled, every hour)

```typescript
// scheduled/completeBookings.ts
export const completeBookings = onSchedule('every 1 hours', async () => {
  const candidates = await db.collection('bookings')
    .where('status', '==', 'live')
    .get();

  const batch = db.batch();
  for (const doc of candidates.docs) {
    const b = doc.data();
    if (b.actualPlays >= b.targetPlays) {
      batch.update(doc.ref, {
        status: 'completed',
        actualEndAt: FieldValue.serverTimestamp(),
        completedAt: FieldValue.serverTimestamp(),
      });
      // Notify user
      // ...
    }
  }
  await batch.commit();
});
```

### 6.10 Board health check (scheduled, every 5 min)

```typescript
// scheduled/boardHealthCheck.ts
export const boardHealthCheck = onSchedule('every 5 minutes', async () => {
  const cutoff = Timestamp.fromMillis(Date.now() - 90 * 1000);  // 90s stale
  const devices = await db.collection('devices')
    .where('status', '==', 'online')
    .where('lastSeenAt', '<', cutoff)
    .get();
  const batch = db.batch();
  devices.forEach(d => batch.update(d.ref, { status: 'offline' }));
  await batch.commit();
  // Optional: alert admin via email if offline > 5 min
});
```

### 6.11 Device heartbeat (HTTP, called by player)

```typescript
// http/deviceHeartbeat.ts
export const deviceHeartbeat = onRequest(async (req, res) => {
  // Player authenticates via X-Device-Token header (issued at pairing)
  const token = req.headers['x-device-token'];
  const deviceId = await verifyDeviceToken(token);
  if (!deviceId) { res.status(401).send('unauth'); return; }

  const { status, currentlyPlaying } = req.body;

  // Write to Realtime DB for low-latency
  await admin.database().ref(`heartbeats/${deviceId}`).set({
    ts: Date.now(),
    status,
    currentlyPlaying,
  });

  // Update Firestore device doc periodically (every 5th heartbeat)
  await db.collection('devices').doc(deviceId).update({
    lastSeenAt: FieldValue.serverTimestamp(),
    status: 'online',
    currentlyPlayingBookingId: currentlyPlaying ?? null,
  });

  res.status(200).send({ ok: true });
});
```

### 6.12 Device report play (HTTP)

```typescript
// http/deviceReportPlay.ts
export const deviceReportPlay = onRequest(async (req, res) => {
  const deviceId = await verifyDeviceToken(req.headers['x-device-token']);
  if (!deviceId) { res.status(401).send('unauth'); return; }

  const { bookingId, startedAt, endedAt, durationMs, completed } = req.body;
  await admin.database().ref(`plays/${deviceId}`).push({
    bookingId, startedAt, endedAt, durationMs, completed,
  });
  res.status(200).send({ ok: true });
});
```

---

## 7. FCM topics

- `user_{uid}` — per-user notifications (booking status changes)
- `device_{deviceId}` — wake a specific board to reload schedule
- `schedule_changed` — broadcast topic, all online devices reload

Player app subscribes to `device_{deviceId}` and `schedule_changed` on boot. When admin approves a booking, `approveBooking` triggers `runSchedulerForArea`, then publishes to `schedule_changed` — every player within 10 seconds pulls its new schedule.

---

## 8. Environment / secrets

Set via `firebase functions:secrets:set`:

- `RAZORPAY_KEY_ID`
- `RAZORPAY_KEY_SECRET`
- `RAZORPAY_WEBHOOK_SECRET`
- `DEVICE_PAIRING_SECRET` — used to sign device tokens at pairing time

---

## 9. Total endpoints summary

| Type | Count |
|---|---|
| Auth triggers | 1 |
| Callable (user) | 3 |
| Callable (admin) | 4 |
| HTTP (Razorpay, device) | 3 |
| Scheduled | 4 |
| Firestore triggers | 2 |
| **Total Cloud Functions** | **17** |

This replaces the 38-endpoint custom REST API from the original plan. Most operations are direct Firestore reads/writes from the client with security rules enforcing access.
