import Foundation
import FirebaseFirestore

struct ServiceRequest: Codable, Identifiable, Sendable {
    @DocumentID var id: String?
    var customerId: String
    var customerName: String
    var category: ServiceCategory
    var description: String
    var price: Int
    var status: RequestStatus
    var latitude: Double
    var longitude: Double
    var address: String
    var engineerId: String?
    var engineerName: String?
    var engineerLatitude: Double?
    var engineerLongitude: Double?
    var createdAt: Date
    var acceptedAt: Date?
    var completedAt: Date?
    var estimatedArrivalAt: Date?
    var notificationWave: Int
    var notifiedEngineerIds: [String]

    enum RequestStatus: String, Codable {
        case open
        case accepted
        case enRoute = "en_route"
        case arrived
        case working
        case completed
        case cancelled
    }

    init(
        id: String? = nil,
        customerId: String = "",
        customerName: String = "",
        category: ServiceCategory = .other,
        description: String = "",
        price: Int = 0,
        status: RequestStatus = .open,
        latitude: Double = 0,
        longitude: Double = 0,
        address: String = "",
        engineerId: String? = nil,
        engineerName: String? = nil,
        engineerLatitude: Double? = nil,
        engineerLongitude: Double? = nil,
        createdAt: Date = Date(),
        acceptedAt: Date? = nil,
        completedAt: Date? = nil,
        estimatedArrivalAt: Date? = nil,
        notificationWave: Int = 0,
        notifiedEngineerIds: [String] = []
    ) {
        self.id = id
        self.customerId = customerId
        self.customerName = customerName
        self.category = category
        self.description = description
        self.price = price
        self.status = status
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.engineerId = engineerId
        self.engineerName = engineerName
        self.engineerLatitude = engineerLatitude
        self.engineerLongitude = engineerLongitude
        self.createdAt = createdAt
        self.acceptedAt = acceptedAt
        self.completedAt = completedAt
        self.estimatedArrivalAt = estimatedArrivalAt
        self.notificationWave = notificationWave
        self.notifiedEngineerIds = notifiedEngineerIds
    }
}
