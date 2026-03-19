import SwiftUI
import UIKit
import MapKit
import CoreLocation

struct EngineerActiveJobView: View {
    @ObservedObject var viewModel: EngineerViewModel
    let request: ServiceRequest

    var body: some View {
        ZStack(alignment: .bottom) {
            MapViewRepresentable(
                centerCoordinate: CLLocationCoordinate2D(latitude: request.latitude, longitude: request.longitude),
                annotations: [.init(coordinate: CLLocationCoordinate2D(latitude: request.latitude, longitude: request.longitude),
                                    title: request.customerName, tint: .systemBlue)],
                showsUserLocation: true
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Job summary
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [Color(hex: "1a73e8"), Color(hex: "6c3ce1")],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 44, height: 44)
                        Image(systemName: request.category.icon)
                            .font(.title3).foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(request.category.rawValue).font(.headline)
                        Text(request.customerName).font(.subheadline).foregroundStyle(.secondary)
                    }
                    Spacer()
                    StatusBadge(status: request.status)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                Text(request.address)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)

                Divider().padding(.top, 12)

                HStack(spacing: 10) {
                    // Navigate button
                    Button { openInMaps() } label: {
                        Label("Navigate", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(Color(.systemGray5))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Next status button
                    nextStatusButton
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: -4)
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }

    @ViewBuilder
    private var nextStatusButton: some View {
        switch request.status {
        case .accepted:
            actionButton("Start Driving", icon: "car.fill", color: Color(hex: "1a73e8"), next: .enRoute)
        case .enRoute:
            actionButton("I've Arrived", icon: "mappin.circle.fill", color: Color(hex: "6c3ce1"), next: .arrived)
        case .arrived:
            actionButton("Start Working", icon: "wrench.fill", color: .indigo, next: .working)
        case .working:
            actionButton("Mark Complete", icon: "checkmark.circle.fill", color: .green, next: .completed)
        default:
            EmptyView()
        }
    }

    private func actionButton(_ title: String, icon: String, color: Color, next: ServiceRequest.RequestStatus) -> some View {
        Button { Task { await viewModel.updateJobStatus(next) } } label: {
            Label(title, systemImage: icon)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(color)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func openInMaps() {
        let coordinate = CLLocationCoordinate2D(latitude: request.latitude, longitude: request.longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = request.customerName
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}

struct StatusBadge: View {
    let status: ServiceRequest.RequestStatus

    var body: some View {
        Text(label)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var label: String {
        switch status {
        case .open: return "OPEN"
        case .accepted: return "ACCEPTED"
        case .enRoute: return "EN ROUTE"
        case .arrived: return "ARRIVED"
        case .working: return "WORKING"
        case .completed: return "DONE"
        case .cancelled: return "CANCELLED"
        }
    }

    private var color: Color {
        switch status {
        case .open: return .orange
        case .accepted: return Color(hex: "1a73e8")
        case .enRoute: return Color(hex: "6c3ce1")
        case .arrived: return .green
        case .working: return .indigo
        case .completed: return .green
        case .cancelled: return .red
        }
    }
}
