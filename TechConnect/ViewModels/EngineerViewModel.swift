import Foundation
import Combine
import CoreLocation
import MapKit
import FirebaseAuth
import FirebaseFirestore

class EngineerViewModel: ObservableObject {
    @Published var openRequests: [ServiceRequest] = []
    @Published var activeJob: ServiceRequest?
    @Published var isOnline = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var completedJobs: [ServiceRequest] = []

    private let firestoreService = FirestoreService.shared
    private let locationService = LocationService.shared
    private var requestsListener: ListenerRegistration?
    private var activeJobListener: ListenerRegistration?
    private var locationTimer: Timer?
    private var etaTimer: Timer?

    var hasActiveJob: Bool {
        activeJob != nil
    }

    func startListening() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        requestsListener = firestoreService.listenToOpenRequests { [weak self] requests in
            Task { @MainActor in
                guard let self else { return }
                if let location = self.locationService.currentLocation {
                    self.openRequests = requests.filter { request in
                        let requestLocation = CLLocation(latitude: request.latitude, longitude: request.longitude)
                        let userLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
                        let distanceKm = requestLocation.distance(from: userLocation) / 1000
                        return distanceKm <= Constants.maxRequestDistanceKm
                    }
                } else {
                    self.openRequests = requests
                }
            }
        }

        activeJobListener = firestoreService.listenToEngineerActiveJob(engineerId: uid) { [weak self] job in
            Task { @MainActor in
                self?.activeJob = job
                if job != nil {
                    self?.startLocationUpdates()
                } else {
                    self?.stopLocationUpdates()
                    self?.stopETAUpdates()
                }
            }
        }
    }

    func toggleOnline() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isOnline.toggle()
        do {
            try await firestoreService.updateEngineerOnlineStatus(userId: uid, isOnline: isOnline)
        } catch {
            errorMessage = error.localizedDescription
            isOnline.toggle()
        }

        if isOnline {
            locationService.startUpdating()
        } else {
            locationService.stopUpdating()
        }
    }

    func acceptRequest(_ request: ServiceRequest) async -> Bool {
        guard let uid = Auth.auth().currentUser?.uid,
              let requestId = request.id else { return false }

        let userName = try? await firestoreService.getUser(id: uid)?.name ?? "Engineer"

        isLoading = true
        do {
            let success = try await firestoreService.acceptRequest(
                requestId: requestId,
                engineerId: uid,
                engineerName: userName ?? "Engineer"
            )
            if success {
                await calculateAndStoreETA(for: request)
                startETAUpdates(for: request)
            }
            isLoading = false
            return success
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    func updateJobStatus(_ status: ServiceRequest.RequestStatus) async {
        guard let requestId = activeJob?.id else { return }
        do {
            try await firestoreService.updateRequestStatus(requestId: requestId, status: status)
            if status == .completed || status == .cancelled {
                stopETAUpdates()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadCompletedJobs() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            completedJobs = try await firestoreService.getCompletedRequests(userId: uid, role: .engineer)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - ETA

    func calculateAndStoreETA(for request: ServiceRequest) async {
        guard let requestId = request.id,
              let engineerLocation = locationService.currentLocation else { return }

        let engineerPlacemark = MKPlacemark(coordinate: engineerLocation)
        let destinationPlacemark = MKPlacemark(coordinate: CLLocationCoordinate2D(
            latitude: request.latitude,
            longitude: request.longitude
        ))

        let directionsRequest = MKDirections.Request()
        directionsRequest.source = MKMapItem(placemark: engineerPlacemark)
        directionsRequest.destination = MKMapItem(placemark: destinationPlacemark)
        directionsRequest.transportType = .automobile

        do {
            let directions = MKDirections(request: directionsRequest)
            let response = try await directions.calculate()
            if let route = response.routes.first {
                let eta = Date().addingTimeInterval(route.expectedTravelTime)
                try await firestoreService.updateEstimatedArrival(requestId: requestId, date: eta)
            }
        } catch {
            // ETA calculation failed — not fatal, customer just won't see countdown
        }
    }

    private func startETAUpdates(for request: ServiceRequest) {
        etaTimer?.invalidate()
        etaTimer = Timer.scheduledTimer(withTimeInterval: Constants.etaRefreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let job = self.activeJob,
                      job.status == .accepted || job.status == .enRoute else { return }
                await self.calculateAndStoreETA(for: job)
            }
        }
    }

    private func stopETAUpdates() {
        etaTimer?.invalidate()
        etaTimer = nil
    }

    private func startLocationUpdates() {
        locationTimer?.invalidate()
        locationTimer = Timer.scheduledTimer(withTimeInterval: Constants.engineerLocationUpdateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self,
                      let requestId = self.activeJob?.id,
                      let location = self.locationService.currentLocation else { return }
                try? await self.firestoreService.updateEngineerLocation(
                    requestId: requestId,
                    latitude: location.latitude,
                    longitude: location.longitude
                )
            }
        }
    }

    private func stopLocationUpdates() {
        locationTimer?.invalidate()
        locationTimer = nil
    }
}
