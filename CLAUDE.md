# TechConnect

## What is this?
TechConnect is an on-demand IT support marketplace — like Uber for computer repair. Customers post service requests with an offer price, nearby IT engineers get notified in proximity waves, one accepts, goes to the customer's home, fixes the issue, and gets paid cash.

## Current Status (as of 2026-03-19)
- **Two iOS apps** — Customer (`Stock.TechConnect`) + Engineer (`Stock.TechConnect.Engineer`) — both building and running
- **Admin dashboard** — deployed live at https://techconnect-admin.pages.dev (Cloudflare Pages)
- **Firebase Cloud Functions** — wave notification system written, NOT yet deployed (needs `cd functions && npm install && firebase deploy --only functions,firestore:rules,firestore:indexes`)
- **Cloud Tasks queue** — NOT yet created (needs `gcloud tasks queues create wave-notifications --location=us-central1`)
- **Push notifications (APNs)** — code written, NOT active (requires paid Apple Developer account $99/yr)
- **Firebase plan** — Blaze (pay-as-you-go) ✅

## Tech Stack
- **SwiftUI** — two separate iOS app targets in one Xcode project
- **Firebase Auth** — phone number OTP login
- **Cloud Firestore** — database + real-time sync
- **Firebase Cloud Functions v2** — proximity wave push notifications (Node 20, TypeScript)
- **Cloud Tasks** — scheduling notification waves (30s delays)
- **FCM** — push to engineer devices (pending APNs capability)
- **Apple MapKit + MKDirections** — maps + ETA calculation
- **Next.js 15** — admin dashboard
- **Cloudflare Pages** — admin dashboard hosting
- **Recharts** — charts in admin dashboard
- **Cash payments only** for MVP

## Cloud Credits
- Google Cloud: $300 (Firebase/Cloud Tasks)
- DigitalOcean: $200 (backup)
- Cloudflare Pro plan (admin dashboard hosting)

## Repository
- GitHub: https://github.com/17-jd/TechConnect (private)
- Branch strategy: `main` (stable), `customer`, `engineer`, `admin` feature branches

## iOS App Targets

### TechConnect (Customer app)
- Bundle ID: `Stock.TechConnect`
- Entry: `TechConnect/TechConnectApp.swift`
- Root view: `Views/Shared/RootView.swift` → `CustomerRootView`
- Deployment target: iOS 26.2

### TechConnectEngineer (Engineer app)
- Bundle ID: `Stock.TechConnect.Engineer`
- Entry: `TechConnectEngineer/TechConnectEngineerApp.swift`
- Root view: `TechConnectEngineer/EngineerRootView.swift`
- Deployment target: iOS 26.2
- Excluded from engineer target (via PBXFileSystemSynchronizedBuildFileExceptionSet):
  - `TechConnectApp.swift`, `Views/Customer/*`, `ViewModels/CustomerViewModel.swift`,
  - `Views/Shared/RootView.swift`, `Services/NotificationService.swift`

## Project Structure
```
TechConnect/
  TechConnect.xcodeproj/          — Xcode project (two targets)
  TechConnect/                    — Shared + Customer source
    TechConnectApp.swift          — Customer app entry point
    Models/
      User.swift                  — AppUser model (fcmToken, averageRating, reviewCount added)
      ServiceRequest.swift        — ServiceRequest (estimatedArrivalAt, notificationWave, notifiedEngineerIds added)
      ServiceCategory.swift       — 9 categories with icons & suggested prices
      Review.swift                — NEW: review/rating model
    Services/
      AuthService.swift           — Firebase phone auth wrapper
      FirestoreService.swift      — All Firestore CRUD + listeners + FCM token + ETA + review methods
      LocationService.swift       — CLLocationManager wrapper
      NotificationService.swift   — UNUserNotificationCenter (simple, no FirebaseMessaging yet)
    ViewModels/
      AuthViewModel.swift
      CustomerViewModel.swift     — + submitReview(), showReviewSheet, hasReviewedActiveRequest
      EngineerViewModel.swift     — + calculateAndStoreETA(), startETAUpdates(), stopETAUpdates()
      ProfileViewModel.swift
    Views/
      Auth/
        LoginView.swift
        ProfileSetupView.swift
      Customer/
        CustomerHomeView.swift    — + ETA countdown, ReviewSheet modal
        PostRequestView.swift
        CustomerTrackingView.swift — + ETA row
      Engineer/
        EngineerHomeView.swift    — + notification permission request on appear
        RequestDetailView.swift   — + async engineer rating fetch (★ X.X)
        EngineerActiveJobView.swift
      Shared/
        RootView.swift            — Customer-only (excluded from engineer target)
        ProfileView.swift         — NEW: extracted ProfileView + InfoRow (shared with engineer)
        JobHistoryView.swift
        MapViewRepresentable.swift
    Utilities/
      Constants.swift             — + etaRefreshInterval, notificationWave constants
    GoogleService-Info.plist      — Firebase config (NOT committed — in .gitignore)

  TechConnectEngineer/            — Engineer-only files
    TechConnectEngineerApp.swift  — Engineer app entry + AppDelegate for APNs
    EngineerRootView.swift        — Auth routing → engineer tabs
    NotificationService.swift     — FCM token sync (TODO: add FirebaseMessaging SPM when paid dev account ready)
    TechConnectEngineer.entitlements — Empty (APNs capability added later)

  functions/                      — Firebase Cloud Functions
    src/index.ts                  — Wave notification system (onRequestCreated, processWave, onRequestAccepted)
    package.json                  — Node 20, TypeScript
    tsconfig.json

  admin-dashboard/                — Next.js 15 admin dashboard
    app/
      layout.tsx                  — Root layout (edge runtime, force-dynamic)
      page.tsx                    — Overview (live stats + feed)
      users/page.tsx              — Users table
      engineers/page.tsx          — Engineers table
      requests/page.tsx           — All jobs table
      map/page.tsx                — Live map (placeholder)
      analytics/page.tsx          — Recharts charts
      notifications/page.tsx      — Wave log table
      not-found.tsx               — Custom 404 (edge runtime)
    components/
      Sidebar.tsx                 — Navigation
      AuthGuard.tsx               — Firebase email/password login gate
    lib/
      firebase-client.ts          — Client Firebase SDK
    .env.local                    — Firebase config (NOT committed — in .gitignore)
    .env.local.example            — Template
    next.config.mjs               — Next.js config (serverExternalPackages: firebase-admin)
    postcss.config.mjs            — Tailwind v4 PostCSS config
    wrangler.toml                 — Cloudflare Pages config

  firestore.rules                 — Firestore security rules
  firestore.indexes.json          — Composite indexes
  firebase.json                   — Firestore + Functions config
  .gitignore                      — Excludes GoogleService-Info.plist, .env files, node_modules, etc.
```

## Firestore Collections
- `users/{uid}` — AppUser (role, fcmToken, isOnline, location, averageRating, reviewCount)
- `serviceRequests/{id}` — ServiceRequest (status, estimatedArrivalAt, notifiedEngineerIds, notificationWave)
- `reviews/{id}` — Review (requestId, customerId, engineerId, stars, comment, createdAt)

## Job Lifecycle
`open` → `accepted` → `en_route` → `arrived` → `working` → `completed`

## Key Flows
1. **Customer posts request** — picks category, describes problem, sets price, auto-detects location
2. **Wave notifications** — Cloud Function finds online engineers sorted by Haversine distance; Wave 0: closest 1; Wave 1+: next 10 every 30s via Cloud Tasks
3. **Engineer accepts** — Firestore transaction (first-to-accept wins), cancels further waves
4. **ETA** — Engineer device calls MKDirections post-accept, stores `estimatedArrivalAt`, refreshed every 10s; customer sees countdown timer
5. **Live tracking** — engineer location updates every 10s
6. **Review** — customer rates engineer (1-5 stars) on job completion; rolling average stored on user doc
7. **Cash payment** — shown as prompt at completion, no in-app processing

## Admin Dashboard
- URL: https://techconnect-admin.pages.dev
- Login: Firebase email/password (create user in Firebase Console → Authentication → Users)
- Firebase project: `f1f2-1d447`
- Pages: Overview, Users, Engineers, Requests, Map, Analytics, Notifications log
- Real-time via Firestore `onSnapshot` listeners

## Deploy Commands

### Admin Dashboard (Cloudflare Pages)
```bash
cd admin-dashboard
npm run pages:build          # builds with @cloudflare/next-on-pages
npx wrangler pages deploy .vercel/output/static --project-name techconnect-admin --commit-dirty=true
```

### Firebase Functions + Rules + Indexes (NOT YET DONE)
```bash
cd functions
npm install
firebase deploy --only functions,firestore:rules,firestore:indexes
```

### Cloud Tasks Queue (NOT YET DONE — run once)
```bash
gcloud tasks queues create wave-notifications --location=us-central1
```

## TODO (Next Session)
1. **Deploy Firebase Functions** — Firestore rules + indexes deployed ✅, `processWave` HTTP function deployed ✅. Still failing: `onRequestCreated` and `onRequestAccepted` Firestore triggers (Eventarc Service Agent permissions keep timing out). Run `firebase deploy --only functions` to retry — it usually works after a few attempts.
2. **Create Cloud Tasks queue** — run `gcloud tasks queues create wave-notifications --location=us-central1` (gcloud CLI installed at `~/google-cloud-sdk`, source `~/google-cloud-sdk/path.zsh.inc` first if needed)
3. **Test wave notifications end-to-end** — post a request, check Cloud Functions logs
4. **Push notifications (later)** — upgrade to paid Apple Developer account ($99/yr), add FirebaseMessaging SPM product to engineer target, enable APNs capability in Xcode
5. **Admin dashboard map page** — add Google Maps API key, implement live engineer map

## Setup Notes (for new sessions)
- Firebase CLI: installed globally via npm (`firebase login` already done)
- gcloud CLI: installed at `~/google-cloud-sdk` — run `source ~/google-cloud-sdk/path.zsh.inc` to activate in terminal
- Firebase project: `f1f2-1d447` — run `firebase use f1f2-1d447` if not set
- Cloudflare: logged in via wrangler (`npx wrangler whoami` to verify)

## Build Commands
- iOS: Open `TechConnect.xcodeproj` in Xcode, select target (TechConnect or TechConnectEngineer), Cmd+R
- Admin dashboard dev: `cd admin-dashboard && npm run dev`
- Admin dashboard deploy: see Deploy Commands above

## Important Notes
- `GoogleService-Info.plist` is in `.gitignore` — never commit it (contains Firebase secrets)
- `admin-dashboard/.env.local` is in `.gitignore` — never commit it
- Both iOS apps build and run successfully as of 2026-03-19
- Xcode project uses `PBXFileSystemSynchronizedRootGroup` (Xcode 16 format) — whole folders auto-included; `membershipExceptions` used to exclude customer-only files from engineer target
- Build settings: `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_APPROACHABLE_CONCURRENCY = YES`
