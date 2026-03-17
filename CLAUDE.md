# TechConnect

## What is this?
TechConnect is an on-demand IT support marketplace — like Uber for computer repair. Customers post service requests with an offer price, nearby IT engineers get notified, one accepts, goes to the customer's home, fixes the issue, and gets paid cash.

## Tech Stack
- **SwiftUI** — iOS app (single app, role toggle between Customer & Engineer)
- **Firebase Auth** — phone number OTP login
- **Cloud Firestore** — database + real-time sync (no custom backend)
- **Apple MapKit** — maps (free)
- **Cash payments only** for MVP

## Architecture
- Firebase is the entire backend — no custom server
- Two Firestore collections: `users` and `serviceRequests`
- Real-time listeners for live updates (no push notifications for MVP)
- Firestore transactions for race-condition-safe job acceptance
- Engineer location updates every 10s on the request doc for live tracking

## Project Structure
```
TechConnect/
  TechConnectApp.swift              — Firebase init + auth routing
  Models/
    User.swift                      — User model (Codable)
    ServiceRequest.swift            — Service request model (Codable)
    ServiceCategory.swift           — Enum: 9 categories with icons & suggested prices
  Services/
    AuthService.swift               — Firebase phone auth wrapper
    FirestoreService.swift          — All Firestore CRUD + listeners
    LocationService.swift           — CLLocationManager wrapper
  ViewModels/
    AuthViewModel.swift
    CustomerViewModel.swift
    EngineerViewModel.swift
    ProfileViewModel.swift
  Views/
    Auth/
      LoginView.swift               — Phone OTP login
      ProfileSetupView.swift        — Name, role, engineer fields
    Customer/
      CustomerHomeView.swift        — Map + post button + waiting state
      PostRequestView.swift         — Category/description/price form
      CustomerTrackingView.swift    — Engineer on map + status
    Engineer/
      EngineerHomeView.swift        — Online toggle + request list
      RequestDetailView.swift       — Job details + accept button
      EngineerActiveJobView.swift   — Navigate + status buttons
    Shared/
      RootView.swift                — Auth state routing
      JobHistoryView.swift          — Past jobs list
      MapViewRepresentable.swift    — MKMapView wrapper
  Utilities/
    Constants.swift
  GoogleService-Info.plist          — Firebase config (not committed)
```

## Service Categories
Virus Removal ($80), WiFi Setup ($60), Hardware Repair ($120), Software Install ($50), Data Recovery ($150), Printer Setup ($50), PC Speedup ($70), Smart Home Setup ($100), Other ($75)

## Key Flows
1. **Customer posts request** — picks category, describes problem, sets price, auto-detects location
2. **Engineers see open requests** — real-time Firestore listener, filtered by distance client-side
3. **Engineer accepts** — Firestore transaction (first-to-accept wins)
4. **Live tracking** — engineer location updates every 10s, customer sees on map
5. **Job lifecycle** — open → accepted → en_route → arrived → working → completed
6. **Cash payment** — shown as prompt at completion, no in-app processing

## Build Phases
1. Firebase Auth (phone OTP)
2. Profile + role switching
3. Location + maps
4. Customer posts requests
5. Engineer sees & accepts jobs
6. Live tracking + job lifecycle
7. Polish + edge cases

## Cloud Credits
- Google Cloud: $300 (use for Firebase)
- AWS: $100 (backup)
- DigitalOcean: $200 (backup)

## Not Building for MVP
Push notifications, in-app payments, ratings, chat, admin dashboard, profile photos

## Commands
- Build: Open `TechConnect.xcodeproj` in Xcode, Cmd+R
- Bundle ID: `Stock.TechConnect`
- Deployment target: iOS 26.2
