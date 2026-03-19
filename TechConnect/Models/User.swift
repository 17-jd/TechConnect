import Foundation
import FirebaseFirestore

struct AppUser: Codable, Identifiable, Sendable {
    @DocumentID var id: String?
    var name: String
    var phone: String
    var role: UserRole
    var isOnline: Bool
    var latitude: Double?
    var longitude: Double?
    var specialties: [String]
    var experience: String
    var createdAt: Date
    var fcmToken: String?
    var averageRating: Double?
    var reviewCount: Int

    enum UserRole: String, Codable, CaseIterable {
        case customer
        case engineer
    }

    init(
        id: String? = nil,
        name: String = "",
        phone: String = "",
        role: UserRole = .customer,
        isOnline: Bool = false,
        latitude: Double? = nil,
        longitude: Double? = nil,
        specialties: [String] = [],
        experience: String = "",
        createdAt: Date = Date(),
        fcmToken: String? = nil,
        averageRating: Double? = nil,
        reviewCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.phone = phone
        self.role = role
        self.isOnline = isOnline
        self.latitude = latitude
        self.longitude = longitude
        self.specialties = specialties
        self.experience = experience
        self.createdAt = createdAt
        self.fcmToken = fcmToken
        self.averageRating = averageRating
        self.reviewCount = reviewCount
    }
}
