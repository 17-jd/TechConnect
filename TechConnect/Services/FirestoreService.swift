import Foundation
import FirebaseFirestore

nonisolated class FirestoreService: Sendable {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()

    private init() {}

    // MARK: - User Operations

    func createUser(_ user: AppUser) throws {
        guard let uid = user.id else { return }
        try db.collection("users").document(uid).setData(from: user)
    }

    func getUser(id: String) async throws -> AppUser? {
        let doc = try await db.collection("users").document(id).getDocument()
        return try doc.data(as: AppUser.self)
    }

    func updateUser(_ user: AppUser) throws {
        guard let uid = user.id else { return }
        try db.collection("users").document(uid).setData(from: user, merge: true)
    }

    func updateEngineerOnlineStatus(userId: String, isOnline: Bool) async throws {
        try await db.collection("users").document(userId).updateData([
            "isOnline": isOnline
        ])
    }

    func updateFCMToken(userId: String, token: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "fcmToken": token
        ])
    }

    func listenToUser(id: String, completion: @escaping @Sendable (AppUser?) -> Void) -> ListenerRegistration {
        db.collection("users").document(id).addSnapshotListener { snapshot, error in
            guard let snapshot, error == nil else {
                completion(nil)
                return
            }
            let user = try? snapshot.data(as: AppUser.self)
            completion(user)
        }
    }

    // MARK: - Service Request Operations

    func createServiceRequest(_ request: ServiceRequest) throws -> String {
        let ref = try db.collection("serviceRequests").addDocument(from: request)
        return ref.documentID
    }

    func listenToOpenRequests(completion: @escaping @Sendable ([ServiceRequest]) -> Void) -> ListenerRegistration {
        db.collection("serviceRequests")
            .whereField("status", isEqualTo: ServiceRequest.RequestStatus.open.rawValue)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let snapshot, error == nil else {
                    completion([])
                    return
                }
                let requests = snapshot.documents.compactMap { doc in
                    try? doc.data(as: ServiceRequest.self)
                }
                completion(requests)
            }
    }

    func listenToRequest(id: String, completion: @escaping @Sendable (ServiceRequest?) -> Void) -> ListenerRegistration {
        db.collection("serviceRequests").document(id).addSnapshotListener { snapshot, error in
            guard let snapshot, error == nil else {
                completion(nil)
                return
            }
            let request = try? snapshot.data(as: ServiceRequest.self)
            completion(request)
        }
    }

    func listenToCustomerActiveRequest(customerId: String, completion: @escaping @Sendable (ServiceRequest?) -> Void) -> ListenerRegistration {
        db.collection("serviceRequests")
            .whereField("customerId", isEqualTo: customerId)
            .whereField("status", in: [
                ServiceRequest.RequestStatus.open.rawValue,
                ServiceRequest.RequestStatus.accepted.rawValue,
                ServiceRequest.RequestStatus.enRoute.rawValue,
                ServiceRequest.RequestStatus.arrived.rawValue,
                ServiceRequest.RequestStatus.working.rawValue
            ])
            .addSnapshotListener { snapshot, error in
                guard let snapshot, error == nil else {
                    completion(nil)
                    return
                }
                let request = snapshot.documents.first.flatMap { doc in
                    try? doc.data(as: ServiceRequest.self)
                }
                completion(request)
            }
    }

    func listenToEngineerActiveJob(engineerId: String, completion: @escaping @Sendable (ServiceRequest?) -> Void) -> ListenerRegistration {
        db.collection("serviceRequests")
            .whereField("engineerId", isEqualTo: engineerId)
            .whereField("status", in: [
                ServiceRequest.RequestStatus.accepted.rawValue,
                ServiceRequest.RequestStatus.enRoute.rawValue,
                ServiceRequest.RequestStatus.arrived.rawValue,
                ServiceRequest.RequestStatus.working.rawValue
            ])
            .addSnapshotListener { snapshot, error in
                guard let snapshot, error == nil else {
                    completion(nil)
                    return
                }
                let request = snapshot.documents.first.flatMap { doc in
                    try? doc.data(as: ServiceRequest.self)
                }
                completion(request)
            }
    }

    func acceptRequest(requestId: String, engineerId: String, engineerName: String) async throws -> Bool {
        let ref = db.collection("serviceRequests").document(requestId)
        let success = try await db.runTransaction { transaction, errorPointer in
            let doc: DocumentSnapshot
            do {
                doc = try transaction.getDocument(ref)
            } catch {
                errorPointer?.pointee = error as NSError
                return false
            }
            guard let status = doc.data()?["status"] as? String,
                  status == ServiceRequest.RequestStatus.open.rawValue else {
                return false
            }
            transaction.updateData([
                "status": ServiceRequest.RequestStatus.accepted.rawValue,
                "engineerId": engineerId,
                "engineerName": engineerName,
                "acceptedAt": FieldValue.serverTimestamp()
            ], forDocument: ref)
            return true
        }
        return success as? Bool ?? false
    }

    func updateRequestStatus(requestId: String, status: ServiceRequest.RequestStatus) async throws {
        var data: [String: Any] = ["status": status.rawValue]
        if status == .completed {
            data["completedAt"] = FieldValue.serverTimestamp()
        }
        try await db.collection("serviceRequests").document(requestId).updateData(data)
    }

    func updateEngineerLocation(requestId: String, latitude: Double, longitude: Double) async throws {
        try await db.collection("serviceRequests").document(requestId).updateData([
            "engineerLatitude": latitude,
            "engineerLongitude": longitude
        ])
    }

    func updateEstimatedArrival(requestId: String, date: Date) async throws {
        try await db.collection("serviceRequests").document(requestId).updateData([
            "estimatedArrivalAt": Timestamp(date: date)
        ])
    }

    func cancelRequest(requestId: String) async throws {
        try await db.collection("serviceRequests").document(requestId).updateData([
            "status": ServiceRequest.RequestStatus.cancelled.rawValue
        ])
    }

    func getCompletedRequests(userId: String, role: AppUser.UserRole) async throws -> [ServiceRequest] {
        let field = role == .customer ? "customerId" : "engineerId"
        let snapshot = try await db.collection("serviceRequests")
            .whereField(field, isEqualTo: userId)
            .whereField("status", isEqualTo: ServiceRequest.RequestStatus.completed.rawValue)
            .order(by: "completedAt", descending: true)
            .getDocuments()
        return snapshot.documents.compactMap { doc in
            try? doc.data(as: ServiceRequest.self)
        }
    }

    // MARK: - Review Operations

    func submitReview(_ review: Review) async throws {
        guard let engineerId = review.engineerId.isEmpty ? nil : review.engineerId else { return }
        let engineerRef = db.collection("users").document(engineerId)
        let reviewRef = db.collection("reviews").document()

        try await db.runTransaction { transaction, errorPointer in
            let engineerDoc: DocumentSnapshot
            do {
                engineerDoc = try transaction.getDocument(engineerRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }

            let currentCount = engineerDoc.data()?["reviewCount"] as? Int ?? 0
            let currentAvg = engineerDoc.data()?["averageRating"] as? Double ?? 0.0
            let newCount = currentCount + 1
            let newAvg = ((currentAvg * Double(currentCount)) + Double(review.stars)) / Double(newCount)

            transaction.updateData([
                "averageRating": newAvg,
                "reviewCount": newCount
            ], forDocument: engineerRef)

            do {
                try transaction.setData(from: review, forDocument: reviewRef)
            } catch {
                errorPointer?.pointee = error as NSError
            }
            return nil
        }
    }

    func getReview(requestId: String) async throws -> Review? {
        let snapshot = try await db.collection("reviews")
            .whereField("requestId", isEqualTo: requestId)
            .limit(to: 1)
            .getDocuments()
        return snapshot.documents.first.flatMap { try? $0.data(as: Review.self) }
    }

    func getEngineerAverageRating(engineerId: String) async throws -> (rating: Double, count: Int)? {
        guard let user = try await getUser(id: engineerId) else { return nil }
        return (user.averageRating ?? 0, user.reviewCount)
    }
}
