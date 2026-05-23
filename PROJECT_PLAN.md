# Namma Sign — 4-Day Build Plan

**Stack:** Flutter (Dart) + Firebase
**Scope (Phase 1):** UI / Frontend with Firebase backing (Auth + Firestore + Storage)
**Builder:** Claude does the heavy lifting; you review, run, and decide
**Deadline:** 4 days from today (target finish: 2026-05-27)

---

## Important caveat about the Figma file

Your Figma seat is "View" on the starter team plan, which means the Figma MCP integration cannot read the file. I can only see the public thumbnail.

What I can tell from the thumbnail:
- About 10–12 mobile screens
- Dark theme, orange/yellow accent colors
- Card-based lists, item detail screens, bottom tab navigation
- Looks like a marketplace / services / signboard-type app (consistent with "Namma Sign")

**To unblock pixel-perfect work, do ONE of these:**
1. Upgrade your seat to Editor/Dev (best — unlocks full MCP design context, codegen, colors, spacing, assets)
2. Export the frames as PNGs (Figma → select frames → Export) and drop them in this folder
3. Send a short description: what does the app do, who uses it, and what are the 3–5 most important screens?

Even option 3 is enough for me to keep moving. Without any of these, I'll build to "looks-like-the-thumbnail" fidelity which will need rework.

---

## The 4-day plan

### Day 1 — Foundation (no design fidelity needed yet)

**Morning**
- Create Flutter project structure (`flutter create namma_sign`)
- Set up folder architecture: `lib/{core, features, shared, data}`
- Install core packages: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `go_router`, `flutter_riverpod` (or `provider`), `cached_network_image`, `google_fonts`, `flutter_svg`
- Create Firebase project on console, enable Auth (Phone + Google), Firestore, Storage
- Wire `flutterfire configure` for both Android and iOS
- Build the design system primitives: color tokens (dark + orange), text styles, spacing scale, button/card/input widgets

**Afternoon**
- Build navigation skeleton: `go_router` with bottom tab shell
- Build auth flow scaffolding: Splash → Onboarding → Login → OTP → Home
- Mock data layer so screens can be built before backend is wired

**End of Day 1 deliverable:** App launches, you can navigate between empty tabs, theme matches the dark/orange vibe.

### Day 2 — Core screens (highest design fidelity day)

**Morning**
- Home screen: search bar, category chips, featured cards, list of items
- List/Category screen: filterable list with cards
- Item detail screen: hero image, info, action buttons

**Afternoon**
- Profile / Account screen
- Settings, notifications, edit profile sub-screens
- Empty states, loading skeletons, error states for all of the above

**End of Day 2 deliverable:** All "happy path" screens visible and navigable with mock data, matching Figma layouts.

### Day 3 — Firebase wiring + secondary flows

**Morning**
- Wire auth: phone OTP via Firebase Auth, store user doc in Firestore
- Firestore data model: `users`, `categories`, `items`, `favorites`, plus collections specific to your domain (need to confirm)
- Replace mock data calls with `StreamProvider`s reading Firestore
- Image uploads via Firebase Storage where needed

**Afternoon**
- Secondary screens from Figma: forms, create/edit flows, confirmation modals
- Push notifications hookup (FCM) if in scope
- Firestore security rules (basic: authenticated reads, owner-only writes)

**End of Day 3 deliverable:** Real data flowing end-to-end; you can sign up, browse, create/edit, and log out.

### Day 4 — Polish, build, ship

**Morning**
- Pixel-tune spacing/colors against Figma
- Animations and micro-interactions (page transitions, button press, loading shimmer)
- Form validation, error messages, retry flows
- Pull-to-refresh, infinite scroll where lists are long
- Accessibility pass: tap targets, contrast, text scaling

**Afternoon**
- Smoke test on a real Android device + iOS simulator
- App icon + splash screen (`flutter_launcher_icons`, `flutter_native_splash`)
- Generate signed Android APK / AAB
- (Optional) TestFlight build for iOS if you have an Apple Dev account
- Write a short README with run instructions for your team

**End of Day 4 deliverable:** Installable APK, working signed build, ready for internal testing.

---

## Realistic risks and how we mitigate

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Figma access stays blocked | High | You upgrade your seat OR export PNGs OR describe the domain — pick one today |
| Scope creep mid-build | High | Lock the screen list at end of Day 1; new screens go to Phase 2 |
| iOS-only blockers (certs, provisioning) | Medium | Defer iOS signing to Phase 2; ship Android first |
| Firebase pricing surprises | Low | Phase 1 stays in the Spark free tier — confirm by Day 3 |
| Complex flows hiding in Figma (chat, payments, maps) | Medium | Need your input — anything like that bumps timeline by 1-2 days each |

---

## What I need from you right now (in order)

1. **Pick one Figma access option** (upgrade / export PNGs / describe domain)
2. **Confirm the app's purpose** in one sentence — e.g. "Marketplace for sign-board makers to list services and accept bookings"
3. **Tell me anything outside basic CRUD**: chat? payments? maps? video? AR? push notifications?
4. **Pick a target platform priority**: Android-first, iOS-first, or both equally

Once I have these, I start Day 1 immediately and check in at the end of each day with a working build.
