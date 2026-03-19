import Foundation

enum ServiceCategory: String, Codable, CaseIterable, Identifiable {
    case virusRemoval = "Virus Removal"
    case wifiSetup = "WiFi Setup"
    case hardwareRepair = "Hardware Repair"
    case softwareInstall = "Software Install"
    case dataRecovery = "Data Recovery"
    case printerSetup = "Printer Setup"
    case pcSpeedup = "PC Speedup"
    case smartHomeSetup = "Smart Home Setup"
    case other = "Other"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .virusRemoval: return "ladybug"
        case .wifiSetup: return "wifi"
        case .hardwareRepair: return "wrench.and.screwdriver"
        case .softwareInstall: return "arrow.down.app"
        case .dataRecovery: return "externaldrive.badge.plus"
        case .printerSetup: return "printer"
        case .pcSpeedup: return "gauge.with.dots.needle.33percent"
        case .smartHomeSetup: return "homekit"
        case .other: return "ellipsis.circle"
        }
    }

    var suggestedPrice: Int {
        switch self {
        case .virusRemoval: return 80
        case .wifiSetup: return 60
        case .hardwareRepair: return 120
        case .softwareInstall: return 50
        case .dataRecovery: return 150
        case .printerSetup: return 50
        case .pcSpeedup: return 70
        case .smartHomeSetup: return 100
        case .other: return 75
        }
    }

    var color: String {
        switch self {
        case .virusRemoval: return "red"
        case .wifiSetup: return "blue"
        case .hardwareRepair: return "orange"
        case .softwareInstall: return "green"
        case .dataRecovery: return "purple"
        case .printerSetup: return "gray"
        case .pcSpeedup: return "yellow"
        case .smartHomeSetup: return "cyan"
        case .other: return "indigo"
        }
    }
}
