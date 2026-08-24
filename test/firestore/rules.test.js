/**
 * Firestore security-rules tests for Reset95.
 *
 * Runs against the Firestore emulator with @firebase/rules-unit-testing.
 * Covers the security-critical invariants:
 *   - a user can only read/write their OWN data
 *   - a user cannot self-verify KYC or self-approve / mark a booking paid
 *   - payments are write-locked to Cloud Functions only
 *   - admin gets the elevated access the app relies on
 *
 * Run:  npm test   (see package.json — wraps this in `firebase emulators:exec`)
 */

const fs = require("fs");
const path = require("path");
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require("@firebase/rules-unit-testing");
const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  collection,
  getDocs,
  query,
  where,
} = require("firebase/firestore");

const PROJECT_ID = "reset95-rules-test";
const ALICE = "alice_uid";
const BOB = "bob_uid";
const ADMIN = "admin_uid";

let testEnv;

/** A booking document owned by `uid`, at the given status. */
function bookingDoc(uid, status, extra = {}) {
  return {
    userId: uid,
    areaId: "area1",
    campaignTitle: "Test campaign",
    status,
    paid: false,
    pricing: { total: 5000 },
    createdAt: new Date(),
    ...extra,
  };
}

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync(
        path.join(__dirname, "..", "..", "firestore.rules"),
        "utf8",
      ),
      host: "127.0.0.1",
      port: 8080,
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  // Seed baseline data with rules DISABLED (admin-context seeding).
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    // Admin roster entry — presence grants admin.
    await setDoc(doc(db, "admins", ADMIN), { role: "admin" });
    // A booking owned by Alice, awaiting payment.
    await setDoc(doc(db, "bookings", "bk_alice"), bookingDoc(ALICE, "pending_payment"));
    // A booking owned by Alice, in admin review.
    await setDoc(doc(db, "bookings", "bk_alice_review"), bookingDoc(ALICE, "pending_review"));
    // A payment doc owned by Alice.
    await setDoc(doc(db, "payments", "pay_alice"), {
      userId: ALICE,
      bookingId: "bk_alice",
      amount: 5000,
    });
    // Alice's user profile.
    await setDoc(doc(db, "users", ALICE), { name: "Alice", kycStatus: "none" });
  });
});

// Firestore handle for a given identity.
function db(uid) {
  return uid
    ? testEnv.authenticatedContext(uid).firestore()
    : testEnv.unauthenticatedContext().firestore();
}

describe("users", () => {
  test("owner can read their own profile", async () => {
    await assertSucceeds(getDoc(doc(db(ALICE), "users", ALICE)));
  });

  test("a different signed-in user cannot read someone else's profile", async () => {
    await assertFails(getDoc(doc(db(BOB), "users", ALICE)));
  });

  test("admin can read any profile", async () => {
    await assertSucceeds(getDoc(doc(db(ADMIN), "users", ALICE)));
  });

  test("owner can update their own profile (kycStatus stays pending)", async () => {
    await assertSucceeds(
      updateDoc(doc(db(ALICE), "users", ALICE), { name: "Alice A.", kycStatus: "pending" }),
    );
  });

  test("owner CANNOT self-verify KYC", async () => {
    await assertFails(
      updateDoc(doc(db(ALICE), "users", ALICE), { kycStatus: "verified" }),
    );
  });

  test("admin CAN verify a user's KYC", async () => {
    await assertSucceeds(
      updateDoc(doc(db(ADMIN), "users", ALICE), { kycStatus: "verified" }),
    );
  });

  test("a user cannot write another user's profile", async () => {
    await assertFails(setDoc(doc(db(BOB), "users", ALICE), { name: "hacked" }));
  });
});

describe("bookings", () => {
  test("owner can read their own booking", async () => {
    await assertSucceeds(getDoc(doc(db(ALICE), "bookings", "bk_alice")));
  });

  test("a different user cannot read someone else's booking", async () => {
    await assertFails(getDoc(doc(db(BOB), "bookings", "bk_alice")));
  });

  test("user can create a booking for themselves as pending_payment", async () => {
    await assertSucceeds(
      setDoc(doc(db(ALICE), "bookings", "bk_new"), bookingDoc(ALICE, "pending_payment")),
    );
  });

  test("user CANNOT create a booking for someone else", async () => {
    await assertFails(
      setDoc(doc(db(BOB), "bookings", "bk_spoof"), bookingDoc(ALICE, "pending_payment")),
    );
  });

  test("user CANNOT create a booking directly as live", async () => {
    await assertFails(
      setDoc(doc(db(ALICE), "bookings", "bk_live"), bookingDoc(ALICE, "live")),
    );
  });

  test("owner can cancel their pending_payment booking", async () => {
    await assertSucceeds(
      updateDoc(doc(db(ALICE), "bookings", "bk_alice"), { status: "cancelled" }),
    );
  });

  test("owner CANNOT mark their own booking paid + pending_review", async () => {
    // This is the Cloud Function's job — a client must never self-settle.
    await assertFails(
      updateDoc(doc(db(ALICE), "bookings", "bk_alice"), {
        paid: true,
        status: "pending_review",
      }),
    );
  });

  test("owner CANNOT flip their booking to live", async () => {
    await assertFails(
      updateDoc(doc(db(ALICE), "bookings", "bk_alice"), { status: "live" }),
    );
  });

  test("owner can cancel a booking that is in admin review", async () => {
    await assertSucceeds(
      updateDoc(doc(db(ALICE), "bookings", "bk_alice_review"), { status: "cancelled" }),
    );
  });

  test("a different user cannot update someone else's booking", async () => {
    await assertFails(
      updateDoc(doc(db(BOB), "bookings", "bk_alice"), { status: "cancelled" }),
    );
  });

  test("admin can move a booking to live", async () => {
    await assertSucceeds(
      updateDoc(doc(db(ADMIN), "bookings", "bk_alice"), { status: "live" }),
    );
  });

  test("no client deletes", async () => {
    await assertFails(deleteDoc(doc(db(ALICE), "bookings", "bk_alice")));
  });

  test("owner-filtered list query succeeds", async () => {
    const q = query(collection(db(ALICE), "bookings"), where("userId", "==", ALICE));
    await assertSucceeds(getDocs(q));
  });

  test("unfiltered list query is denied for a normal user", async () => {
    await assertFails(getDocs(collection(db(ALICE), "bookings")));
  });
});

describe("payments", () => {
  test("owner can read their own payment", async () => {
    await assertSucceeds(getDoc(doc(db(ALICE), "payments", "pay_alice")));
  });

  test("a different user cannot read someone else's payment", async () => {
    await assertFails(getDoc(doc(db(BOB), "payments", "pay_alice")));
  });

  test("NO client can write a payment (functions only)", async () => {
    await assertFails(
      setDoc(doc(db(ALICE), "payments", "pay_hack"), {
        userId: ALICE,
        amount: 1,
      }),
    );
  });
});

describe("waitlist", () => {
  test("a signed-in user can join the waitlist", async () => {
    await assertSucceeds(
      setDoc(doc(db(ALICE), "waitlist", "w1"), { areaId: "area9", uid: ALICE }),
    );
  });

  test("a signed-out visitor cannot write to the waitlist", async () => {
    await assertFails(
      setDoc(doc(db(null), "waitlist", "w2"), { areaId: "area9" }),
    );
  });

  test("a normal user cannot read the waitlist", async () => {
    await assertFails(getDoc(doc(db(ALICE), "waitlist", "w1")));
  });
});

describe("admins", () => {
  test("a user can read their OWN admin doc (to check admin status)", async () => {
    await assertSucceeds(getDoc(doc(db(ALICE), "admins", ALICE)));
  });

  test("a non-admin cannot read someone else's admin doc", async () => {
    await assertFails(getDoc(doc(db(ALICE), "admins", ADMIN)));
  });

  test("a non-admin cannot grant themselves admin", async () => {
    await assertFails(setDoc(doc(db(ALICE), "admins", ALICE), { role: "admin" }));
  });
});
