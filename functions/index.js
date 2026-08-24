"use strict";

// NammaSign Cloud Functions — booking notifications.
//
//   onBookingStatusChange (Firestore onUpdate) — fires when a booking's
//       paid / status fields change. Sends an FCM push + writes an
//       in-app notification row for the right event (paid, live,
//       rejected, completed).
//   sweepEndedCampaigns (scheduled, hourly) — marks live bookings whose
//       scheduledEndAt is past as completed. That update re-triggers
//       onBookingStatusChange which then sends the "wrapped" push.
//
// NOTE: Razorpay payment functions have been removed for Phase 1. Re-add
// them here when the payment journey ships in a future phase.

const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const crypto = require("crypto");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();
const storage = admin.storage();

const REGION = "asia-south1";

// =============================================================================
// NOTIFICATIONS
// =============================================================================
//
// Architecture:
//   - Every notification is BOTH pushed via FCM AND written to a
//     users/{uid}/notifications/{id} doc so the app can show full history
//     in the in-app bell screen.
//   - Each user can have multiple FCM tokens (multiple devices). Tokens
//     are stored as an array on users/{uid}.fcmTokens. We send to all of
//     them; tokens that come back as invalid are removed.
//   - Two triggers:
//       onBookingStatusChange — Firestore onUpdate, fires for paid flip
//                                + status transitions (live, rejected).
//       sweepEndedCampaigns   — scheduled hourly, finds live bookings
//                                whose scheduledEndAt has passed, marks
//                                them completed + notifies.

/**
 * Builds the title + body for a given event. Centralised so the wording
 * stays consistent between the push and the in-app row.
 */
function buildNotification(type, booking) {
  const where = booking.locationLabel || booking.areaId || "your area";
  const campaign = booking.campaignTitle || "Your campaign";
  switch (type) {
    case "paid":
      return {
        title: "Payment received",
        body: `${campaign} is now under review by our team.`,
      };
    case "live":
      return {
        title: "You're live!",
        body: `${campaign} just went live at ${where}.`,
      };
    case "rejected":
      return {
        title: "Campaign not approved",
        body: `Tap to see why ${campaign} wasn't approved.`,
      };
    case "completed":
      return {
        title: "Campaign wrapped",
        body: `${campaign} finished its run at ${where}.`,
      };
    default:
      return { title: "Booking update", body: campaign };
  }
}

/**
 * Sends an FCM push + writes the notification doc + updates the booking's
 * lastNotificationAt timestamp. Tolerates bad tokens by pruning them.
 */
async function deliverNotification(uid, bookingId, type, booking) {
  const { title, body } = buildNotification(type, booking);

  // 1. Write the in-app row first. This is the source of truth that the
  //    bell screen reads — if FCM fails, we still want history.
  const notifRef = db
    .collection("users")
    .doc(uid)
    .collection("notifications")
    .doc();
  await notifRef.set({
    type: type,
    title: title,
    body: body,
    bookingId: bookingId,
    read: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // 2. Push to every device the user has signed in on.
  const userSnap = await db.collection("users").doc(uid).get();
  if (!userSnap.exists) return;
  const tokens = (userSnap.data().fcmTokens || []).filter(Boolean);
  if (tokens.length === 0) return;

  const message = {
    notification: { title: title, body: body },
    data: {
      type: type,
      bookingId: bookingId,
      notificationId: notifRef.id,
    },
    android: {
      priority: "high",
      notification: {
        channelId: "nammasign_bookings",
        sound: "default",
      },
    },
    apns: {
      payload: {
        aps: { sound: "default", badge: 1 },
      },
    },
    tokens: tokens,
  };

  let response;
  try {
    response = await messaging.sendEachForMulticast(message);
  } catch (err) {
    console.error("FCM send failed", err);
    return;
  }

  // Prune dead tokens so we don't keep retrying them forever.
  const stale = [];
  response.responses.forEach((r, i) => {
    if (r.success) return;
    const code = r.error && r.error.code;
    if (
      code === "messaging/invalid-registration-token" ||
      code === "messaging/registration-token-not-registered"
    ) {
      stale.push(tokens[i]);
    }
  });
  if (stale.length > 0) {
    await db
      .collection("users")
      .doc(uid)
      .update({
        fcmTokens: admin.firestore.FieldValue.arrayRemove(...stale),
      });
  }
}

/**
 * Fires whenever a booking doc is updated. Detects:
 *   - paid flipped false → true              → "paid"
 *   - status moved to live (not from live)   → "live"
 *   - status moved to rejected               → "rejected"
 *
 * Idempotent guard: we look at the before/after delta, not the absolute
 * state, so a no-op write won't re-notify.
 */
exports.onBookingStatusChange = onDocumentUpdated(
  { region: REGION, document: "bookings/{bookingId}" },
  async (event) => {
    const before = event.data.before.data() || {};
    const after = event.data.after.data() || {};
    const uid = after.userId;
    if (!uid) return;

    const bookingId = event.params.bookingId;
    const events = [];

    if (before.paid !== true && after.paid === true) {
      events.push("paid");
    }
    if (before.status !== "live" && after.status === "live") {
      events.push("live");
    }
    if (before.status !== "rejected" && after.status === "rejected") {
      events.push("rejected");
    }
    if (before.status !== "completed" && after.status === "completed") {
      events.push("completed");
    }

    for (const type of events) {
      try {
        await deliverNotification(uid, bookingId, type, after);
      } catch (err) {
        console.error(
          `deliverNotification failed (type=${type}, bookingId=${bookingId})`,
          err
        );
      }
    }
  }
);

/**
 * Runs every hour. Finds live bookings whose scheduledEndAt is in the
 * past, marks them completed (which itself triggers
 * onBookingStatusChange → "completed" notification).
 *
 * Kept separate so the onUpdate trigger stays clean and time-only
 * transitions (no admin action) still get caught.
 */
exports.sweepEndedCampaigns = onSchedule(
  { region: REGION, schedule: "every 1 hours" },
  async () => {
    const now = admin.firestore.Timestamp.now();
    const liveSnap = await db
      .collection("bookings")
      .where("status", "==", "live")
      .where("scheduledEndAt", "<=", now)
      .get();

    if (liveSnap.empty) {
      console.log("sweepEndedCampaigns: nothing to wrap.");
      return;
    }

    const batch = db.batch();
    liveSnap.docs.forEach((doc) => {
      batch.update(doc.ref, {
        status: "completed",
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });
    await batch.commit();
    console.log(
      `sweepEndedCampaigns: marked ${liveSnap.size} booking(s) completed.`
    );
  }
);

// =============================================================================
// ACCOUNT DELETION
// =============================================================================
//
// Two callables exposed:
//   deleteMyAccount  — signed-in user removes their own account.
//   adminDeleteUser  — admin removes any user's account.
//
// Both perform the same hard-delete sequence:
//   1. Cancel any active bookings owned by the user (so admins / boards
//      don't keep referencing a phantom user).
//   2. Delete all docs in users/{uid}/notifications and users/{uid}/kycDocs.
//   3. Delete the user doc itself.
//   4. Delete the user's files in Storage (users/{uid}/* avatar+KYC,
//      bookings/{uid}/* creatives, invoices/{uid}/* invoices).
//   5. Delete the Firebase Auth account.
//   6. Best-effort delete of the user's payments docs.

async function _deleteUserBookings(uid) {
  const snap = await db.collection("bookings").where("userId", "==", uid).get();
  if (snap.empty) return;
  const batch = db.batch();
  snap.docs.forEach((doc) => {
    const data = doc.data() || {};
    // Active bookings get cancelled so any downstream listeners (devices,
    // admin dashboards) see a clean state rather than a stale userId.
    if (
      data.status === "pending_review" ||
      data.status === "pending_payment" ||
      data.status === "draft" ||
      data.status === "live"
    ) {
      batch.update(doc.ref, {
        status: "cancelled",
        cancelReason: "account_deleted",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });
  await batch.commit();
}

async function _deleteSubcollection(parentRef, name) {
  // Firestore has no recursive delete in the Admin SDK without the
  // CLI. Paginate through to be safe with large collections.
  const col = parentRef.collection(name);
  while (true) {
    const page = await col.limit(200).get();
    if (page.empty) return;
    const batch = db.batch();
    page.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    if (page.size < 200) return;
  }
}

async function _deleteStoragePath(prefix) {
  try {
    const bucket = storage.bucket();
    await bucket.deleteFiles({ prefix: prefix });
  } catch (e) {
    console.warn(`Storage delete failed for ${prefix}`, e);
  }
}

async function _hardDeleteUser(uid) {
  // 1. Cancel / mark up the user's bookings.
  await _deleteUserBookings(uid);

  // 2. Wipe subcollections.
  const userRef = db.collection("users").doc(uid);
  await _deleteSubcollection(userRef, "notifications");
  await _deleteSubcollection(userRef, "kycDocs");

  // 3. Delete the user doc.
  await userRef.delete().catch(() => {});

  // 4. Storage files. Paths must match where the client actually uploads:
  //    - users/{uid}/...    avatar + KYC docs  (see user_profile_repository.dart)
  //    - bookings/{uid}/... creatives          (see booking_provider.dart)
  //    - invoices/{uid}/... server-generated invoices (storage.rules)
  await _deleteStoragePath(`users/${uid}/`);
  await _deleteStoragePath(`bookings/${uid}/`);
  await _deleteStoragePath(`invoices/${uid}/`);

  // 5. Firebase Auth user. Wrap so a missing auth user doesn't crash the
  // whole pipeline — sometimes the Firestore doc outlives the auth user.
  try {
    await admin.auth().deleteUser(uid);
  } catch (e) {
    if (e && e.code !== "auth/user-not-found") {
      console.warn(`auth.deleteUser failed for ${uid}`, e);
    }
  }

  // 6. Best-effort payments cleanup (read-only for users, so we tidy here).
  const payments = await db
    .collection("payments")
    .where("userId", "==", uid)
    .get();
  if (!payments.empty) {
    const batch = db.batch();
    payments.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
  }
}

exports.deleteMyAccount = onCall(
  { region: REGION },
  async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    try {
      await _hardDeleteUser(uid);
      return { ok: true };
    } catch (e) {
      console.error(`deleteMyAccount failed for ${uid}`, e);
      throw new HttpsError("internal", "Could not delete account.");
    }
  }
);

exports.adminDeleteUser = onCall(
  { region: REGION },
  async (request) => {
    const callerUid = request.auth && request.auth.uid;
    if (!callerUid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    // Admin gate — caller must be in admins/{uid}.
    const adminDoc = await db.collection("admins").doc(callerUid).get();
    if (!adminDoc.exists) {
      throw new HttpsError("permission-denied", "Admins only.");
    }
    const targetUid = request.data && request.data.uid;
    if (!targetUid || typeof targetUid !== "string") {
      throw new HttpsError("invalid-argument", "Target uid is required.");
    }
    // Don't let an admin delete themselves through this path — they should
    // use their own self-delete + a second admin removes them from /admins.
    if (targetUid === callerUid) {
      throw new HttpsError(
        "failed-precondition",
        "Use deleteMyAccount for self-removal."
      );
    }
    try {
      await _hardDeleteUser(targetUid);
      return { ok: true };
    } catch (e) {
      console.error(`adminDeleteUser failed for ${targetUid}`, e);
      throw new HttpsError("internal", "Could not delete user.");
    }
  }
);

// =============================================================================
// CORPORATE KYC VERIFICATION (GSTIN + PAN)
// =============================================================================
//
// Verifies a corporate account's GSTIN + Company PAN against a third-party KYC
// provider (Surepass / Cashfree / Sandbox.co.in / etc.). Provider-AGNOSTIC and
// INERT until you configure two environment values in /functions (e.g. a
// functions/.env file, then `firebase deploy --only functions`):
//
//   KYC_PROVIDER_URL=https://api.your-provider.com
//   KYC_PROVIDER_KEY=your_api_token
//
// Until those are set it returns {verified:false, reason:'verification_not_configured'}
// and never auto-verifies anyone (safe default). Once set, swap the request /
// response shapes in the marked block to match your provider's GST endpoint.

const KYC_PROVIDER_URL = process.env.KYC_PROVIDER_URL || "";
const KYC_PROVIDER_KEY = process.env.KYC_PROVIDER_KEY || "";

// Normalise a company name for comparison: upper-case, strip punctuation and
// common suffixes (PVT / LTD / LLP …) so "Acme Pvt. Ltd." == "ACME".
function _normaliseCompanyName(s) {
  return String(s || "")
    .toUpperCase()
    .replace(/[^A-Z0-9]+/g, " ")
    .replace(/\b(PVT|PRIVATE|LTD|LIMITED|LLP|AND|CO|COMPANY|THE)\b/g, "")
    .replace(/\s+/g, " ")
    .trim();
}

exports.verifyCorporateKyc = onCall(
  { region: REGION },
  async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const gstin = String((request.data && request.data.gstin) || "")
      .toUpperCase()
      .trim();
    const pan = String((request.data && request.data.pan) || "")
      .toUpperCase()
      .trim();

    // Shape checks (defence in depth — the app validates too).
    const gstinOk =
      /^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$/.test(gstin);
    const panOk = /^[A-Z]{5}[0-9]{4}[A-Z]$/.test(pan);
    if (!gstinOk || !panOk) {
      throw new HttpsError("invalid-argument", "Invalid GSTIN or PAN format.");
    }
    // Characters 3–12 of a GSTIN are the entity's PAN.
    if (gstin.substring(2, 12) !== pan) {
      throw new HttpsError("failed-precondition", "GSTIN does not match PAN.");
    }

    // Not configured → safe no-op (never auto-verifies).
    if (!KYC_PROVIDER_URL || !KYC_PROVIDER_KEY) {
      console.warn("verifyCorporateKyc: provider not configured; skipping.");
      return { verified: false, reason: "verification_not_configured" };
    }

    // ---- Call the provider (adjust to YOUR provider's API) --------------
    let legalName = "";
    let providerStatus = "";
    try {
      const res = await fetch(`${KYC_PROVIDER_URL}/gstin/verify`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${KYC_PROVIDER_KEY}`,
        },
        body: JSON.stringify({ gstin }),
      });
      const json = await res.json();
      // TODO: map these to your provider's actual response shape.
      const data = json.data || json;
      legalName = data.legal_name || data.legalName || data.lgnm || "";
      providerStatus = data.status || data.sts || "";
    } catch (e) {
      console.error("verifyCorporateKyc: provider call failed", e);
      throw new HttpsError("unavailable", "Verification service unavailable.");
    }
    // --------------------------------------------------------------------

    const active = String(providerStatus).toLowerCase().includes("active");

    // Compare the provider's legal name to the company name the user entered
    // (stored at users/{uid}.org.name by saveCorporate).
    const userSnap = await db.collection("users").doc(uid).get();
    const enteredName =
      (userSnap.exists &&
        userSnap.data().org &&
        userSnap.data().org.name) ||
      "";
    const nameMatches =
      _normaliseCompanyName(legalName) !== "" &&
      _normaliseCompanyName(legalName) === _normaliseCompanyName(enteredName);

    const verified = active && nameMatches;

    await db.collection("users").doc(uid).set(
      {
        kycStatus: verified ? "verified" : "pending",
        kycCorporate: {
          gstin: gstin,
          pan: pan,
          legalName: legalName,
          providerStatus: providerStatus,
          nameMatches: nameMatches,
          verifiedAt: verified
            ? admin.firestore.FieldValue.serverTimestamp()
            : null,
        },
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    return {
      verified: verified,
      legalName: legalName,
      nameMatches: nameMatches,
      active: active,
    };
  }
);

// =============================================================================
// RAZORPAY PAYMENTS
// =============================================================================
//
// Flow (payment-first):
//   1. App creates the booking as `pending_payment` (paid:false).
//   2. App calls createRazorpayOrder({bookingId}) — this reads the amount
//      from the booking doc SERVER-SIDE (so the client can't tamper it),
//      creates a Razorpay order, stashes the orderId on the booking, and
//      returns { orderId, amount, currency, keyId } to open Checkout.
//   3. User pays in the Razorpay Checkout sheet (razorpay_flutter).
//   4. App calls verifyRazorpayPayment({...}) — the HMAC signature is
//      verified with the key secret. On success the booking flips to
//      paid:true / pending_review and a payments/{paymentId} doc is
//      written. That paid-flip re-triggers onBookingStatusChange, which
//      sends the "Payment received" push.
//   5. razorpayWebhook is the server-authoritative safety net: if the app
//      is killed before step 4, Razorpay's payment.captured webhook marks
//      the booking paid anyway. Both paths are idempotent.
//
// SETUP (see RAZORPAY_SETUP.md):
//   • functions/.env         → RAZORPAY_KEY_ID=rzp_live_or_test_xxx
//   • firebase secret        → RAZORPAY_KEY_SECRET
//   • firebase secret        → RAZORPAY_WEBHOOK_SECRET (from the webhook you
//                              create in the Razorpay dashboard)

const RAZORPAY_KEY_SECRET = defineSecret("RAZORPAY_KEY_SECRET");
const RAZORPAY_WEBHOOK_SECRET = defineSecret("RAZORPAY_WEBHOOK_SECRET");

// The key *id* is publishable (it ships to the client to open Checkout), so
// it lives in functions/.env rather than in a secret.
function razorpayKeyId() {
  return process.env.RAZORPAY_KEY_ID || "";
}

const RAZORPAY_API = "https://api.razorpay.com/v1";

/**
 * Marks a booking paid + moves it into the admin review queue, and records
 * the payment. Idempotent: a second call for an already-paid booking is a
 * no-op. Shared by verifyRazorpayPayment (client) and the webhook (server).
 */
async function markBookingPaid(bookingId, payment) {
  const ref = db.collection("bookings").doc(bookingId);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) {
      throw new HttpsError("not-found", "Booking not found.");
    }
    const data = snap.data() || {};
    if (data.paid === true) return; // already settled — idempotent

    tx.update(ref, {
      paid: true,
      status: "pending_review",
      "razorpay.orderId": payment.orderId || null,
      "razorpay.paymentId": payment.paymentId || null,
      paymentMethod: payment.method || data.paymentMethod || "UPI",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    if (payment.paymentId) {
      const payRef = db.collection("payments").doc(payment.paymentId);
      tx.set(
        payRef,
        {
          bookingId: bookingId,
          userId: data.userId || null,
          orderId: payment.orderId || null,
          paymentId: payment.paymentId,
          amount: (data.pricing && data.pricing.total) || 0,
          currency: "INR",
          method: payment.method || data.paymentMethod || "UPI",
          source: payment.source || "app",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }
  });
}

/**
 * createRazorpayOrder({ bookingId }) → { orderId, amount, currency, keyId }.
 * The amount is read from the booking document, never trusted from the client.
 */
exports.createRazorpayOrder = onCall(
  { region: REGION, secrets: [RAZORPAY_KEY_SECRET] },
  async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const keyId = razorpayKeyId();
    const keySecret = RAZORPAY_KEY_SECRET.value();
    if (!keyId || !keySecret) {
      throw new HttpsError(
        "failed-precondition",
        "Payments are not configured yet. Please try again later.",
      );
    }

    const bookingId = String((request.data && request.data.bookingId) || "");
    if (!bookingId) {
      throw new HttpsError("invalid-argument", "bookingId is required.");
    }

    const ref = db.collection("bookings").doc(bookingId);
    const snap = await ref.get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "Booking not found.");
    }
    const booking = snap.data() || {};
    if (booking.userId !== uid) {
      throw new HttpsError("permission-denied", "Not your booking.");
    }
    if (booking.paid === true) {
      throw new HttpsError("failed-precondition", "Already paid.");
    }

    // Amount in paise, from the SERVER's copy of the booking total.
    const rupees = (booking.pricing && booking.pricing.total) || 0;
    const amountPaise = Math.round(Number(rupees) * 100);
    if (!Number.isFinite(amountPaise) || amountPaise < 100) {
      throw new HttpsError("failed-precondition", "Invalid booking amount.");
    }

    const auth = Buffer.from(`${keyId}:${keySecret}`).toString("base64");
    let order;
    try {
      const res = await fetch(`${RAZORPAY_API}/orders`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Basic ${auth}`,
        },
        body: JSON.stringify({
          amount: amountPaise,
          currency: "INR",
          receipt: bookingId,
          notes: { bookingId: bookingId, uid: uid },
        }),
      });
      order = await res.json();
      if (!res.ok || !order || !order.id) {
        console.error("Razorpay order create failed", order);
        throw new HttpsError("unavailable", "Could not start payment.");
      }
    } catch (e) {
      if (e instanceof HttpsError) throw e;
      console.error("Razorpay order create error", e);
      throw new HttpsError("unavailable", "Could not start payment.");
    }

    await ref.update({
      "razorpay.orderId": order.id,
      status: "pending_payment",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      orderId: order.id,
      amount: amountPaise,
      currency: "INR",
      keyId: keyId,
    };
  },
);

/**
 * verifyRazorpayPayment({ bookingId, razorpayOrderId, razorpayPaymentId,
 * razorpaySignature }) → { verified: true }. Verifies the Checkout signature
 * (HMAC-SHA256 of "orderId|paymentId" with the key secret) before settling.
 */
exports.verifyRazorpayPayment = onCall(
  { region: REGION, secrets: [RAZORPAY_KEY_SECRET] },
  async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const keySecret = RAZORPAY_KEY_SECRET.value();
    if (!keySecret) {
      throw new HttpsError("failed-precondition", "Payments not configured.");
    }

    const d = request.data || {};
    const bookingId = String(d.bookingId || "");
    const orderId = String(d.razorpayOrderId || "");
    const paymentId = String(d.razorpayPaymentId || "");
    const signature = String(d.razorpaySignature || "");
    if (!bookingId || !orderId || !paymentId || !signature) {
      throw new HttpsError("invalid-argument", "Missing payment fields.");
    }

    // Ownership check before we trust anything else.
    const snap = await db.collection("bookings").doc(bookingId).get();
    if (!snap.exists || (snap.data() || {}).userId !== uid) {
      throw new HttpsError("permission-denied", "Not your booking.");
    }

    const expected = crypto
      .createHmac("sha256", keySecret)
      .update(`${orderId}|${paymentId}`)
      .digest("hex");
    const ok =
      expected.length === signature.length &&
      crypto.timingSafeEqual(
        Buffer.from(expected),
        Buffer.from(signature),
      );
    if (!ok) {
      throw new HttpsError("permission-denied", "Signature mismatch.");
    }

    await markBookingPaid(bookingId, {
      orderId: orderId,
      paymentId: paymentId,
      source: "app",
    });

    return { verified: true };
  },
);

/**
 * Razorpay webhook (server-authoritative). Verifies X-Razorpay-Signature
 * against the webhook secret, then settles the booking on payment.captured.
 * Configure the endpoint + secret in the Razorpay dashboard. Always returns
 * 200 for handled/ignored events so Razorpay doesn't retry needlessly; 4xx
 * only for a bad signature.
 */
exports.razorpayWebhook = onRequest(
  { region: REGION, secrets: [RAZORPAY_WEBHOOK_SECRET] },
  async (req, res) => {
    const secret = RAZORPAY_WEBHOOK_SECRET.value();
    if (!secret) {
      console.error("razorpayWebhook: secret not configured");
      res.status(500).send("not configured");
      return;
    }
    const signature = req.get("X-Razorpay-Signature") || "";
    const raw = req.rawBody; // Buffer — required for a correct HMAC.
    const expected = crypto
      .createHmac("sha256", secret)
      .update(raw)
      .digest("hex");
    const ok =
      expected.length === signature.length &&
      crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(signature));
    if (!ok) {
      console.warn("razorpayWebhook: bad signature");
      res.status(400).send("bad signature");
      return;
    }

    let event;
    try {
      event = JSON.parse(raw.toString("utf8"));
    } catch (e) {
      res.status(400).send("bad body");
      return;
    }

    try {
      if (event.event === "payment.captured" || event.event === "order.paid") {
        const entity =
          (event.payload &&
            event.payload.payment &&
            event.payload.payment.entity) ||
          {};
        const bookingId =
          (entity.notes && entity.notes.bookingId) ||
          (event.payload &&
            event.payload.order &&
            event.payload.order.entity &&
            event.payload.order.entity.receipt) ||
          "";
        if (bookingId) {
          await markBookingPaid(bookingId, {
            orderId: entity.order_id || null,
            paymentId: entity.id || null,
            method: entity.method || null,
            source: "webhook",
          });
        } else {
          console.warn("razorpayWebhook: no bookingId in event");
        }
      }
    } catch (e) {
      console.error("razorpayWebhook: handler error", e);
      // Fall through to 200 so Razorpay doesn't hammer retries; the
      // client-side verify + next webhook delivery still cover us.
    }

    res.status(200).send("ok");
  },
);
