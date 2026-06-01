"use strict";

// NammaSign Cloud Functions — Razorpay payments via hosted Payment Links.
//
//   createRazorpayPaymentLink (callable) — server recomputes the amount from
//       the area's price, creates a Razorpay Payment Link, stores its id+url
//       on the booking, and returns the short URL for the app to open.
//   razorpayWebhook (HTTP) — Razorpay calls this when the link is paid. We
//       verify the webhook signature, then mark the booking paid +
//       pending_review and write a payments record.
//
// Secrets (set once, never in the client / repo):
//   firebase functions:secrets:set RAZORPAY_KEY_ID
//   firebase functions:secrets:set RAZORPAY_KEY_SECRET
//   firebase functions:secrets:set RAZORPAY_WEBHOOK_SECRET

const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const Razorpay = require("razorpay");
const crypto = require("crypto");

admin.initializeApp();
const db = admin.firestore();

const RAZORPAY_KEY_ID = defineSecret("RAZORPAY_KEY_ID");
const RAZORPAY_KEY_SECRET = defineSecret("RAZORPAY_KEY_SECRET");
const RAZORPAY_WEBHOOK_SECRET = defineSecret("RAZORPAY_WEBHOOK_SECRET");

const REGION = "asia-south1";

// Mirror of lib/features/booking/domain/booking_totals.dart — the server is
// the source of truth for the charge. Returns the total in rupees.
function computeTotalRupees(dailyRate, durationDays) {
  const subtotal = dailyRate * durationDays;
  let discountPct = 0;
  if (durationDays >= 30) discountPct = 0.15;
  else if (durationDays >= 15) discountPct = 0.08;
  const discount = Math.round(subtotal * discountPct);
  const taxable = subtotal - discount;
  const gst = Math.round(taxable * 0.18);
  return taxable + gst;
}

exports.createRazorpayPaymentLink = onCall(
  { region: REGION, secrets: [RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET] },
  async (request) => {
    const uid = request.auth && request.auth.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const bookingId = request.data && request.data.bookingId;
    if (!bookingId) {
      throw new HttpsError("invalid-argument", "bookingId is required.");
    }

    const bookingRef = db.collection("bookings").doc(bookingId);
    const snap = await bookingRef.get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "Booking not found.");
    }
    const booking = snap.data();
    if (booking.userId !== uid) {
      throw new HttpsError("permission-denied", "Not your booking.");
    }
    if (booking.paid === true) {
      throw new HttpsError("failed-precondition", "Booking already paid.");
    }

    const areaSnap = await db.collection("areas").doc(booking.areaId).get();
    if (!areaSnap.exists) {
      throw new HttpsError("not-found", "Area not found.");
    }
    const dailyRate = Number(areaSnap.data().pricePerDay) || 0;
    const durationDays = Number(booking.durationDays) || 1;
    const totalRupees = computeTotalRupees(dailyRate, durationDays);
    if (totalRupees <= 0) {
      throw new HttpsError("failed-precondition", "Invalid amount.");
    }

    const rzp = new Razorpay({
      key_id: RAZORPAY_KEY_ID.value(),
      key_secret: RAZORPAY_KEY_SECRET.value(),
    });

    let link;
    try {
      link = await rzp.paymentLink.create({
        amount: totalRupees * 100,
        currency: "INR",
        accept_partial: false,
        description: "NammaSign campaign booking",
        customer: {
          name: booking.campaignTitle || "NammaSign customer",
        },
        notify: { sms: false, email: false },
        reminder_enable: false,
        notes: { bookingId: bookingId, uid: uid },
      });
    } catch (err) {
      console.error("Razorpay payment link create failed", err);
      throw new HttpsError("internal", "Could not create payment link.");
    }

    await bookingRef.set(
      {
        razorpayPaymentLinkId: link.id,
        paymentLinkUrl: link.short_url,
        pricing: { total: totalRupees },
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return { url: link.short_url, amount: totalRupees };
  }
);

exports.razorpayWebhook = onRequest(
  { region: REGION, secrets: [RAZORPAY_WEBHOOK_SECRET] },
  async (req, res) => {
    const signature = req.headers["x-razorpay-signature"];
    const expected = crypto
      .createHmac("sha256", RAZORPAY_WEBHOOK_SECRET.value())
      .update(req.rawBody)
      .digest("hex");
    if (!signature || expected !== signature) {
      console.warn("Razorpay webhook signature mismatch");
      res.status(400).send("invalid signature");
      return;
    }

    const event = req.body || {};
    // We only act on a fully-paid payment link.
    if (event.event !== "payment_link.paid") {
      res.status(200).send("ignored");
      return;
    }

    const linkEntity =
      event.payload &&
      event.payload.payment_link &&
      event.payload.payment_link.entity;
    const paymentEntity =
      event.payload &&
      event.payload.payment &&
      event.payload.payment.entity;
    const bookingId =
      linkEntity && linkEntity.notes && linkEntity.notes.bookingId;

    if (!bookingId) {
      console.warn("Webhook missing bookingId in notes");
      res.status(200).send("no booking");
      return;
    }

    const bookingRef = db.collection("bookings").doc(bookingId);
    const snap = await bookingRef.get();
    if (!snap.exists) {
      res.status(200).send("booking gone");
      return;
    }
    const booking = snap.data();

    await bookingRef.set(
      {
        paid: true,
        status: "pending_review",
        razorpayPaymentId: paymentEntity ? paymentEntity.id : null,
        paidAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    const paymentId =
      (paymentEntity && paymentEntity.id) ||
      (linkEntity && linkEntity.id) ||
      bookingId;
    await db.collection("payments").doc(paymentId).set({
      bookingId: bookingId,
      userId: booking.userId || null,
      razorpayPaymentLinkId: linkEntity ? linkEntity.id : null,
      razorpayPaymentId: paymentEntity ? paymentEntity.id : null,
      amount: (booking.pricing && booking.pricing.total) || 0,
      currency: "INR",
      status: "captured",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    res.status(200).send("ok");
  }
);
