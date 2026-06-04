/**
 * One-time FAQ seed.
 *
 * Writes ~15 starter Q&A items into `helpFaqs/{id}` across 5 categories so
 * the user-facing Help screen and the admin FAQs CMS aren't empty on first
 * open. Re-running is safe — `set()` with the same id overwrites cleanly.
 *
 * Usage (from the project root):
 *
 *   1. cd scripts
 *   2. (one-time) npm install firebase-admin
 *   3. Service account JSON at scripts/service-account.json (gitignored).
 *   4. node seed-faqs.js
 *
 * To edit answers later, do it from the admin portal — no need to re-run.
 */

const admin = require('firebase-admin');
const serviceAccount = require('./service-account.json');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

const faqs = [
  // ---------- BOOKING ----------
  {
    id: 'booking-how-to-book',
    category: 'booking',
    question: 'How do I book a billboard?',
    answer:
      "Open the Home tab, pick an area in Bengaluru, tap Book, choose how many days you'd like to run, upload your ad creative, and submit. Our team will review your campaign within 24 hours.",
    order: 10,
    published: true,
  },
  {
    id: 'booking-approval-time',
    category: 'booking',
    question: 'How long does admin approval take?',
    answer:
      "Most campaigns are reviewed within 1–4 hours during business hours. Worst case it takes 24 hours. You'll get a notification the moment your campaign is approved or rejected.",
    order: 20,
    published: true,
  },
  {
    id: 'booking-cancel',
    category: 'booking',
    question: 'Can I cancel my booking?',
    answer:
      "Yes — you can cancel any booking that's still waiting for admin review. Once it goes Live, cancellation is not possible because the ad is already scheduled to play on the boards.",
    order: 30,
    published: true,
  },
  {
    id: 'booking-why-kyc',
    category: 'booking',
    question: 'Why do I need to upload Aadhaar / PAN?',
    answer:
      'KYC is required by Indian advertising regulations to verify who is behind each campaign. Your documents are stored securely and only reviewed by NammaSign admins — never shared.',
    order: 40,
    published: true,
  },
  {
    id: 'booking-kyc-formats',
    category: 'booking',
    question: 'What KYC file formats are accepted?',
    answer:
      'PDF, JPG, PNG, HEIC (iPhone photos), or WEBP — up to 5 MB per file. A clear photo from your phone camera works fine; make sure all four corners of the document are visible.',
    order: 45,
    published: true,
  },

  // ---------- PRICING ----------
  {
    id: 'pricing-how-calculated',
    category: 'pricing',
    question: 'How is the price calculated?',
    answer:
      "Each area has a fixed daily rate (shown on its card). Total = daily rate × number of days + 18% GST. Longer runs get an automatic discount — 8% off for 15+ days, 15% off for 30+ days.",
    order: 10,
    published: true,
  },
  {
    id: 'pricing-gst',
    category: 'pricing',
    question: "What's the 18% GST charge?",
    answer:
      "GST (Goods and Services Tax) is the statutory Indian tax charged on every advertising service. NammaSign collects it on behalf of the government — it's already included in the total shown on the review screen.",
    order: 20,
    published: true,
  },
  {
    id: 'pricing-when-charged',
    category: 'pricing',
    question: 'When am I charged?',
    answer:
      "Payment is collected upfront at booking, before your ad goes into review. If your campaign is rejected, you'll receive a full refund within 5–7 business days.",
    order: 30,
    published: true,
  },

  // ---------- CREATIVES ----------
  {
    id: 'creatives-formats',
    category: 'creatives',
    question: 'What file formats and sizes work?',
    answer:
      'Images: JPG, PNG or WEBP up to 10 MB. Videos: MP4 (H.264) up to 50 MB, 10–30 seconds long. Use 1920×1080 (16:9) so your ad fills the LED boards crisply.',
    order: 10,
    published: true,
  },
  {
    id: 'creatives-content-rules',
    category: 'creatives',
    question: "What content isn't allowed?",
    answer:
      'No alcohol, tobacco, political campaigning, gambling, adult content, or anything misleading or hateful. We also reject creatives that infringe on someone else\'s trademark or copyright.',
    order: 20,
    published: true,
  },
  {
    id: 'creatives-change-after-submit',
    category: 'creatives',
    question: 'Can I change my creative after submitting?',
    answer:
      "You can replace the creative while your booking is still in 'Under Review'. Once it's approved and live, the creative is locked in for the rest of the campaign.",
    order: 30,
    published: true,
  },

  // ---------- GOING LIVE ----------
  {
    id: 'live-when-starts',
    category: 'going_live',
    question: 'When does my ad start playing?',
    answer:
      "As soon as it's approved by admin, your ad enters the playback schedule on the boards in your chosen area. Most ads start showing within an hour of approval.",
    order: 10,
    published: true,
  },
  {
    id: 'live-plays-per-day',
    category: 'going_live',
    question: 'How many times will my ad play per day?',
    answer:
      "Each board cycles through approved ads continuously from morning to night. With typical traffic, every ad gets shown 100–200 times a day per board. Reach depends on the area's foot traffic.",
    order: 20,
    published: true,
  },
  {
    id: 'live-where-shown',
    category: 'going_live',
    question: 'Where are the boards located exactly?',
    answer:
      "Tap any area card on the Home tab to see its full address and a description of the foot traffic. Each area has 4 LED boards placed at high-visibility spots.",
    order: 30,
    published: true,
  },

  // ---------- ACCOUNT ----------
  {
    id: 'account-edit-profile',
    category: 'account',
    question: 'How do I update my details?',
    answer:
      "Open the Profile tab → Personal info to update your name, contact details and address. Changes save automatically.",
    order: 10,
    published: true,
  },
  {
    id: 'account-history',
    category: 'account',
    question: 'Where do I see my past bookings?',
    answer:
      "Open the History tab from the bottom navigation. It lists every booking you've made — pending, live, completed, and cancelled — with filters and search.",
    order: 20,
    published: true,
  },
  {
    id: 'account-sign-out',
    category: 'account',
    question: 'How do I sign out?',
    answer:
      "Profile tab → scroll to the bottom → tap 'Sign out'. You can sign back in any time using the same phone number — your campaigns and history are saved against your account.",
    order: 30,
    published: true,
  },
];

async function main() {
  console.log(`Seeding ${faqs.length} FAQs into helpFaqs/...`);
  const batch = db.batch();
  for (const f of faqs) {
    const ref = db.collection('helpFaqs').doc(f.id);
    batch.set(ref, {
      category: f.category,
      question: f.question,
      answer: f.answer,
      order: f.order,
      published: f.published,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  console.log(`Done — ${faqs.length} FAQs written.`);
  process.exit(0);
}

main().catch((err) => {
  console.error('Seed failed:', err);
  process.exit(1);
});
