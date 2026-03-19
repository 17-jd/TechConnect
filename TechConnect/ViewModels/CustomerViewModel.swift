import Foundation
import Combine
import CoreLocation
import FirebaseAuth
import FirebaseFirestore

class CustomerViewModel: ObservableObject {
    @Published var activeRequest: ServiceRequest?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showPostRequest = false
    @Published var completedJobs: [ServiceRequest] = []
    @Published var showReviewSheet = false
    @Published var hasReviewedActiveRequest = false

    private let firestoreService = FirestoreService.shared
    private let locationService = LocationService.shared
    private var activeListener: ListenerRegistration?

    var hasActiveRequest: Bool {
        activeRequest != nil
    }

    func startListening() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        activeListener = firestoreService.listenToCustomerActiveRequest(customerId: uid) { [weak self] request in
            Task { @MainActor in
                guard let self else { return }
                let previous = self.activeRequest
                self.activeRequest = request

                // Show review sheet when job transitions to completed
                if let request, request.status == .completed,
                   previous?.status != .completed {
                    await self.checkIfAlreadyReviewed(requestId: request.id ?? "")
                    if !self.hasReviewedActiveRequest {
                        self.showReviewSheet = true
                    }
                }
            }
        }
    }

    func postRequest(category: ServiceCategory, description: String, price: Int) async -> Bool {
        guard let uid = Auth.auth().currentUser?.uid,
              let location = locationService.currentLocation else {
            errorMessage = "Unable to get your location. Please enable location services."
            return false
        }

        isLoading = true
        errorMessage = nil

        // Reverse geocode for address
        let geocoder = CLGeocoder()
        var address = "Current Location"
        if let placemarks = try? await geocoder.reverseGeocodeLocation(
            CLLocation(latitude: location.latitude, longitude: location.longitude)
        ), let placemark = placemarks.first {
            address = [placemark.name, placemark.locality, placemark.administrativeArea]
                .compactMap { $0 }
                .joined(separator: ", ")
        }

        let userName = try? await firestoreService.getUser(id: uid)?.name ?? "Customer"

        let request = ServiceRequest(
            customerId: uid,
            customerName: userName ?? "Customer",
            category: category,
            description: description,
            price: price,
            status: .open,
            latitude: location.latitude,
            longitude: location.longitude,
            address: address
        )

        do {
            _ = try firestoreService.createServiceRequest(request)
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }

    func cancelRequest() async {
        guard let requestId = activeRequest?.id else { return }
        do {
            try await firestoreService.cancelRequest(requestId: requestId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadCompletedJobs() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            completedJobs = try await firestoreService.getCompletedRequests(userId: uid, role: .customer)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Reviews

    func submitReview(stars: Int, comment: String) async {
        guard let uid = Auth.auth().currentUser?.uid,
              let request = activeRequest,
              let requestId = request.id,
              let engineerId = request.engineerId else { return }

        let review = Review(
            requestId: requestId,
            customerId: uid,
            engineerId: engineerId,
            stars: stars,
            comment: comment
        )

        do {
            try await firestoreService.submitReview(review)
            hasReviewedActiveRequest = true
            showReviewSheet = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func checkIfAlreadyReviewed(requestId: String) async {
        do {
            let review = try await firestoreService.getReview(requestId: requestId)
            hasReviewedActiveRequest = review != nil
        } catch {
            hasReviewedActiveRequest = false
        }
    }
}
