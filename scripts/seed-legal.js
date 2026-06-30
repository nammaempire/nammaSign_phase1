/**
 * Seeds the three legal pages — Privacy Policy, Terms of Service, and
 * Content Guidelines — into Firestore at `legalPages/{id}`.
 *
 * IMPORTANT: This copy is a starting draft based on India's DPDPA 2023
 * and on Google Play / Apple App Store policy requirements. Before
 * going live you MUST:
 *
 *   1. Have an Indian advertising lawyer review the wording.
 *   2. Confirm the Grievance Officer name + email.
 *   3. Confirm the data retention period (30 days post-deletion).
 *   4. Add your registered business address.
 *
 * After legal review, either re-run this script with edits, or use the
 * admin portal → Legal pages → Edit to update each page individually.
 *
 * Usage:
 *   1. cd scripts
 *   2. (one-time) npm install firebase-admin
 *   3. Service account JSON at scripts/service-account.json (gitignored).
 *   4. node seed-legal.js
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

// ---------------------------------------------------------------------------
// PRIVACY POLICY
// ---------------------------------------------------------------------------
const PRIVACY = `NammaSign is owned and operated by Namma Empire, a sole proprietorship based in Bengaluru, India. This Privacy Policy explains how we collect, use, share, and protect your personal information when you use the NammaSign mobile app or our admin web portal.

By using NammaSign, you agree to this policy. If you do not agree, please do not use the app.

1. WHO WE ARE

Namma Empire ("we", "us", "our") operates the NammaSign marketplace for renting digital out-of-home (DOOH) billboards in Bengaluru. Contact us at nammaempire@gmail.com.

2. WHAT WE COLLECT

We collect only what we need to run the marketplace, comply with Indian advertising regulations, and keep you informed.

Account & identity
• Your mobile phone number (used as your sign-in identifier)
• Your name and date of birth
• Email address (optional, used for invoices)
• Account type (Corporate or Individual)
• For Corporate accounts: company name, PAN or CIN number, manager name and contact, official email
• For Individual accounts: the last four digits of your Aadhaar number (never the full 12 digits)

KYC documents
• Photos or PDFs of identity proof you upload — PAN, CIN, Aadhaar, address proof, GST certificate
• These are stored in encrypted Firebase Storage and reviewed only by NammaSign admin staff

Campaign content
• Ad creatives (images or videos) you upload for booking
• Campaign title, description, and duration
• Selected billboard area

Device & technical data
• Firebase Cloud Messaging tokens (so we can send you push notifications)
• Approximate device type for support purposes
• App version

Communication
• Notification preferences
• Any messages you send us via email or in-app support

3. WHY WE COLLECT EACH ITEM

KYC and identity data
We collect these because Indian advertising regulations require verification of who is behind each campaign. We also need them to issue tax invoices.

Campaign content
We need your creative to display on the LED boards. Without it, we cannot fulfill your booking.

Device tokens
So we can notify you when your campaign is approved, goes live, or wraps up.

Communication
To respond to your queries and improve the service.

4. HOW LONG WE KEEP YOUR DATA

While your account is active, we keep your data for as long as you have an account.

If you delete your account using the in-app "Delete Account" option, we permanently remove your profile, KYC documents, notifications, and FCM tokens within 30 days. Active campaigns are cancelled immediately. Past invoice records may be retained for up to seven years to comply with Indian tax law.

5. WHO WE SHARE YOUR DATA WITH

We do not sell your data. We only share when one of the following is true:

• You explicitly direct us to (e.g. sharing the invoice PDF)
• Required by an Indian law enforcement order, court order, or government request
• Required by the Income Tax Department or GST authority for compliance
• With our hosting and infrastructure provider (Google Firebase), which stores the data on your behalf

We do not currently use third-party advertising networks or analytics services that would let other companies identify you.

6. YOUR RIGHTS UNDER THE DPDPA 2023

Under India's Digital Personal Data Protection Act 2023, you have the right to:

• Access — request a copy of your data by emailing nammaempire@gmail.com
• Correction — edit your name, contact details, and KYC docs directly in the Profile tab
• Erasure — use the "Delete Account" option in the Profile tab to permanently remove your account
• Grievance — contact our Grievance Officer (see Section 12)
• Nomination — nominate a person to exercise these rights on your behalf in case of incapacity

7. CHILDREN

NammaSign is not intended for users under 18 years of age. We enforce this through a date-of-birth check at signup. If you believe a minor has signed up, please email us so we can remove the account.

8. SECURITY

Your data is stored in Firebase, which provides encryption at rest and in transit (TLS 1.2 or higher). Access to the admin portal is restricted to NammaSign admin staff and protected by Firebase Authentication.

We never store your full Aadhaar number — only the last four digits, masked everywhere it appears. KYC documents are scoped per user so no other customer can read them.

9. PAYMENTS

We do not collect any payment data within the NammaSign app today. After your campaign is approved, our team will contact you to arrange payment via bank transfer, UPI, or another offline method. We do not store any card details.

10. CHANGES TO THIS POLICY

When this policy materially changes, we will notify you in-app and bump the version number you see at the top of this page. Continued use of NammaSign after a change means you accept the new policy.

11. COOKIES (admin web only)

Our admin web portal at namma-empire.web.app uses only essential cookies required by Firebase Authentication. We do not use tracking cookies or third-party analytics on the web portal.

12. GRIEVANCE OFFICER

If you have a complaint about how we handle your personal data, contact:

Grievance Officer
Namma Empire
Bengaluru, India
Email: nammaempire@gmail.com

We will respond to your grievance within 30 days as required by the DPDPA.

13. EFFECTIVE DATE

This policy is effective from the version date shown at the top of this page.`;

// ---------------------------------------------------------------------------
// TERMS OF SERVICE
// ---------------------------------------------------------------------------
const TERMS = `Welcome to NammaSign. These Terms of Service ("Terms") govern your use of the NammaSign mobile app and admin web portal. By creating an account or making a booking, you agree to these Terms.

If you do not agree, please do not use the service.

1. ABOUT US

NammaSign is operated by Namma Empire, a sole proprietorship based in Bengaluru, India. We help advertisers rent LED billboard space across Bengaluru on a per-day basis.

2. ELIGIBILITY

You must be at least 18 years old to use NammaSign. By signing up you confirm that you are 18 or older, you have the legal capacity to enter into contracts, and the information you provide is accurate.

For Corporate accounts, you also confirm that you are authorised to bind the company you represent.

3. YOUR ACCOUNT

You are responsible for keeping your sign-in credentials and OTP confidential. Any activity under your account is treated as your activity. If your phone is lost or stolen, sign out of NammaSign on all devices and contact us immediately.

4. KYC AND DOCUMENT VERIFICATION

We need to verify your identity before approving any campaign. By signing up you agree to:

• Upload truthful and current KYC documents (PAN / CIN for Corporate; Aadhaar last-4 and supporting documents for Individual)
• Permit our admin team to review these documents
• Allow us to reject any campaign tied to incomplete or suspect KYC

5. BOOKING PROCESS

Bookings are made in three steps in the app. Once you submit, the booking is reviewed by our admin team. We may:

• Approve and schedule the campaign for the requested period
• Reject the campaign with a written reason
• Ask you for additional information

A booking is not confirmed until our team has approved it AND payment is received. Until then your booking sits in "Under review" status.

6. CONTENT RULES

You may only upload creatives that you have the legal right to use. By uploading you confirm that you own or have licensed all rights to the creative.

The full content rules are in our Content Guidelines page. Reading those is part of agreeing to these Terms.

7. PRICING AND PAYMENT

Each area has a daily rate shown on its card. Total price = daily rate × number of days + 18% GST as required by Indian tax law. Discounts of 8% for 15+ day campaigns and 15% for 30+ day campaigns are applied automatically.

Payment is collected offline after admin approval. Our team will reach out by email or WhatsApp to coordinate. Once payment is received, your campaign goes Live.

8. CANCELLATION AND REFUNDS

You can cancel any booking that is still in "Under review" status. Once a booking is Live (your ad is playing on the boards), it cannot be cancelled and no refund is owed.

If we reject your campaign before payment, no payment is collected. If we have to suspend a Live campaign for force majeure (board outage, court order, technical failure), we will issue a pro-rata refund or extend the run on the next available days.

9. INTELLECTUAL PROPERTY

NammaSign, the name "Namma Empire", and the app's design are our property. The creative you upload remains your property — you grant us a non-exclusive licence to display it on the boards for the duration of your campaign.

10. PROHIBITED USE

You agree not to use NammaSign to:

• Submit fake or impersonated identity documents
• Upload content that violates our Content Guidelines
• Attempt to reverse-engineer, copy, or scrape the app
• Resell or sub-licence campaign space to a third party without our written consent

We can suspend or terminate accounts that violate these terms.

11. LIMITATION OF LIABILITY

We work hard to keep the boards up, but cannot guarantee 100% uptime due to power outages, weather, vandalism, or factors beyond our control. To the maximum extent permitted by law, our liability for any campaign is capped at the booking amount you paid for that campaign.

We are not liable for indirect, incidental, or consequential damages including loss of business or reputation.

12. INDEMNITY

You agree to indemnify and hold harmless Namma Empire and its staff from any claim arising out of:

• Content you uploaded that violated our Content Guidelines, third-party rights, or Indian law
• False or misleading KYC documents you submitted
• Misuse of your account by someone you let access it

13. CHANGES TO THESE TERMS

We may update these Terms from time to time. Material changes will be flagged in-app with the version number. Continued use after a change means you accept the new Terms.

14. GOVERNING LAW AND JURISDICTION

These Terms are governed by the laws of India. Any disputes will be resolved in the courts at Bengaluru, Karnataka.

15. CONTACT

For any question about these Terms, write to us at nammaempire@gmail.com.`;

// ---------------------------------------------------------------------------
// CONTENT GUIDELINES
// ---------------------------------------------------------------------------
const CONTENT = `NammaSign boards display ads in public spaces where children, families, and people from every walk of life walk by. These guidelines exist to keep that space safe and welcoming. Ads that violate them will be rejected, even if the booking is paid for.

1. WHAT'S ALLOWED

Promotion of legal goods, services, and events. Personal moments — birthdays, anniversaries, engagement announcements, congratulations to a friend or family member. Brand campaigns and local business promotions.

2. WHAT'S NOT ALLOWED

Alcohol, tobacco, and gambling. Including indirect references (e.g. a "pub launch party" that promotes a specific bar).

Adult or sexually explicit content. Including suggestive imagery, even if technically clothed.

Political campaigning, including support or opposition to a political party, candidate, or election issue.

Religious propaganda that targets a particular community or attempts to convert.

Content that demeans, insults, or threatens any person, community, religion, or ethnicity.

Content that misrepresents facts (false claims about products, fake testimonials, doctored evidence).

Hate speech, calls to violence, or content that glorifies criminal activity.

Pirated or copyrighted material you do not have a licence to use. This includes movie posters you found online, cartoon characters, brand logos that aren't yours, song lyrics, and stock photos that require a paid licence.

Content that breaks Indian law in any way (drugs, weapons, illegal services, etc.).

3. TECHNICAL SPECS

Images
• Formats: JPG, JPEG, PNG, WEBP
• Maximum file size: 10 MB
• Recommended resolution: 1920 × 1080 (16:9 aspect ratio)
• Colour: sRGB recommended

Videos
• Format: MP4 only, H.264 codec
• Maximum file size: 50 MB
• Length: 10 to 30 seconds
• Recommended resolution: 1920 × 1080 at 30 fps

Files that don't meet these specs may be rejected automatically by the LED board firmware.

4. KYC DOCUMENTS

For ID uploads (PAN, Aadhaar, CIN, etc.):

• Formats: PDF, JPG, PNG, HEIC (iPhone), WEBP
• Maximum file size: 5 MB
• Ensure all four corners of the document are visible
• No glare, no shadows, all text clearly readable

5. WHAT HAPPENS IF YOU SUBMIT NON-COMPLIANT CONTENT

We review every booking before approval. If your creative violates these guidelines, we reject the booking and tell you why. Many fixes are minor — swap an image, re-cut a video.

If you make repeated submissions that violate the guidelines, we may suspend your account.

6. WHAT IF YOU'RE NOT SURE?

Email us at nammaempire@gmail.com with a draft of your creative before booking. We're happy to give feedback so you don't pay for a campaign that gets rejected.

7. QUESTIONS

Email nammaempire@gmail.com.`;

const pages = [
  { id: 'privacy', title: 'Privacy Policy', body: PRIVACY, version: 1 },
  { id: 'terms', title: 'Terms of Service', body: TERMS, version: 1 },
  { id: 'content-guidelines', title: 'Content Guidelines', body: CONTENT, version: 1 },
];

async function main() {
  console.log(`Seeding ${pages.length} legal pages into legalPages/...`);
  const batch = db.batch();
  for (const p of pages) {
    const ref = db.collection('legalPages').doc(p.id);
    batch.set(ref, {
      title: p.title,
      body: p.body,
      version: p.version,
      published: true,
      effectiveFrom: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  console.log('Done.');
  console.log('');
  console.log('Reminder: this copy is a starting draft. Have an Indian');
  console.log('advertising lawyer review before relying on it for compliance.');
  process.exit(0);
}

main().catch((err) => {
  console.error('Seed failed:', err);
  process.exit(1);
});
