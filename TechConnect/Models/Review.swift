import Foundation
import FirebaseFirestore

struct Review: Codable, Identifiable, Sendable {
    @DocumentID var id: String?
    var requestId: String
    var customerId: String
    var engineerId: String
    var stars: Int          // 1-5
    var comment: String
    var createdAt: Date

    init(
        id: String? = nil,
        requestId: String = "",
        customerId: String = "",
        engineerId: String = "",
        stars: Int = 5,
        comment: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.requestId = requestId
        self.customerId = customerId
        self.engineerId = engineerId
        self.stars = stars
        self.comment = comment
        self.createdAt = createdAt
    }
}
