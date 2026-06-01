/**
 * One-time Firestore seed.
 *
 * Writes the 3 area listings (Koramangala, Madiwala, Electronic City)
 * and 12 device docs (4 per area) so the home screen has live data to
 * display the first time you boot the app against real Firebase.
 *
 * Usage (from the project root):
 *
 *   1. cd scripts
 *   2. npm init -y  (one-time)
 *   3. npm install firebase-admin
 *   4. Download your service-account key from Firebase Console:
 *      Project Settings → Service Accounts → Generate new private key
 *      Save the JSON as scripts/service-account.json (gitignored).
 *   5. node seed-firestore.js
 *
 * Re-running is safe — uses set() with merge, so existing data is updated
 * rather than duplicated.
 */

const admin = require('firebase-admin');
const serviceAccount = require('./service-account.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

// ---------------------------------------------------------------------------
// Areas — 3 area listings, one doc per area
// ---------------------------------------------------------------------------
const areas = [
  {
    id: 'koramangala',
    name: 'Koramangala',
    city: 'Bengaluru',
    description:
      'Forum Mall, 100 Feet Road, 5th Block,\n80 Feet Road  ·  Koramangala, Bengaluru',
    boardCount: 4,
    pricePerDay: 650,
    maxAdsInRotation: 30,
    estimatedViewsPerDay: 48000,
    displayLabel: 'YOUR AD',
    availability: 'available',
    slotsLeft: 0,
    status: 'active',
    geo: { lat: 12.9352, lng: 77.6245 },
  },
  {
    id: 'madiwala',
    name: 'Madiwala',
    city: 'Bengaluru',
    description:
      'BTM Layout, Madiwala Market,\nHosur Road  ·  Madiwala, Bengaluru',
    boardCount: 4,
    pricePerDay: 450,
    maxAdsInRotation: 30,
    estimatedViewsPerDay: 36000,
    displayLabel: 'YOUR AD',
    availability: 'fewLeft',
    slotsLeft: 4,
    status: 'active',
    geo: { lat: 12.9216, lng: 77.6196 },
  },
  {
    id: 'electronic-city',
    name: 'Electronic City',
    city: 'Bengaluru',
    description:
      'Phase 1 & 2, Hosur Road,\nTech Park hubs  ·  Electronic City, Bengaluru',
    boardCount: 4,
    pricePerDay: 550,
    maxAdsInRotation: 30,
    estimatedViewsPerDay: 42000,
    displayLabel: 'YOUR AD',
    availability: 'available',
    slotsLeft: 0,
    status: 'active',
    geo: { lat: 12.8456, lng: 77.6603 },
  },
];

// ---------------------------------------------------------------------------
// Devices — 12 boards, 4 per area
// ---------------------------------------------------------------------------
const devices = areas.flatMap((area) =>
  [1, 2, 3, 4].map((n) => ({
    id: `${area.id}-${String(n).padStart(2, '0')}`,
    areaId: area.id,
    label: `${area.name} Board #${n}`,
    serialNumber: `NSGN-${area.id.toUpperCase().slice(0, 4)}-${String(n).padStart(4, '0')}`,
    installLocation: `${area.name} — site ${n}`,
    status: 'offline', // becomes 'online' once a real device heartbeats
    appVersion: null,
    networkType: 'unknown',
    currentlyPlayingBookingId: null,
  })),
);

// ---------------------------------------------------------------------------
// Run
// ---------------------------------------------------------------------------
async function seed() {
  console.log('Seeding areas…');
  const areasBatch = db.batch();
  for (const area of areas) {
    const ref = db.collection('areas').doc(area.id);
    areasBatch.set(
      ref,
      { ...area, createdAt: FieldValue.serverTimestamp() },
      { merge: true },
    );
  }
  await areasBatch.commit();
  console.log(`  ✓ Wrote ${areas.length} areas`);

  console.log('Seeding devices…');
  const devicesBatch = db.batch();
  for (const dev of devices) {
    const ref = db.collection('devices').doc(dev.id);
    devicesBatch.set(
      ref,
      { ...dev, installedAt: FieldValue.serverTimestamp(), lastSeenAt: null },
      { merge: true },
    );
  }
  await devicesBatch.commit();
  console.log(`  ✓ Wrote ${devices.length} devices`);

  console.log('Done.');
  process.exit(0);
}

seed().catch((e) => {
  console.error('Seed failed:', e);
  process.exit(1);
});
