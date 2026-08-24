# Firestore security-rules tests

These test `../../firestore.rules` against the Firebase **Firestore emulator**
using `@firebase/rules-unit-testing`. They read the real rules file, so they
can never drift from what actually ships.

## What they cover (30 tests)

- **users** — a user can read/update only their own profile; a user **cannot
  self-verify KYC** (`kycStatus: verified` is admin-only); admins can.
- **bookings** — a user can create a booking only for themselves and only at
  an allowed status; a user **cannot mark their own booking `paid` /
  `pending_review`** (that's the payment Cloud Function's job) and cannot flip
  it to `live`; owners can cancel; admins have full lifecycle control; list
  queries must be self-filtered; no client deletes.
- **payments** — a user can read only their own payment; **no client can write
  a payment** (Cloud Functions only).
- **waitlist** — only signed-in users can write; reads are admin-only.
- **admins** — a user can read only their own admin doc; nobody can grant
  themselves admin.

## Prerequisites

- **Node 18+** and **Java 11+** (the Firestore emulator is a Java process).

## Run

```bash
cd test/firestore
npm install        # first time only
npm test           # boots the emulator, runs jest, tears it down
```

`npm test` wraps jest in `firebase emulators:exec`, so you don't need a running
emulator — it starts one, runs the suite, and shuts it down. Expect
`30 passed`. (You'll see one `PERMISSION_DENIED` warning logged mid-run — that's
an expected negative test asserting a write is correctly denied, not a failure.)

## Notes

- The emulator port (8080) comes from the `emulators` block in the repo-root
  `firebase.json`. Change it there and in `rules.test.js` together if 8080 is
  taken.
- `node_modules/` here is a separate JS toolchain from the Flutter app and is
  git-ignored — it does not affect the app build.
