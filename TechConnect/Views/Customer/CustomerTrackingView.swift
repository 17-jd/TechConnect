import SwiftUI
import UIKit
import MapKit
import CoreLocation

struct CustomerTrackingView: View {
    let request: ServiceRequest

    var body: some View {
        VStack(spacing: 0) {
            MapViewRepresentable(
                centerCoordinate: engineerCoordinate ?? customerCoordinate,
                annotations: annotations,
                showsUserLocation: true
            )
            .frame(maxHeight: .infinity)

            // Info panel
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(request.category.rawValue)
                            .font(.headline)
                        if let name = request.engineerName {
                            Text(name)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    StatusBadge(status: request.status)
                }

                Text("$\(request.price) • Cash Payment")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // ETA row
                if let eta = request.estimatedArrivalAt,
                   request.status == .accepted || request.status == .enRoute {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .foregroundStyle(Color(hex: "1a73e8"))
                            .font(.subheadline)
                        Text("Arrives in")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(eta, style: .timer)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color(hex: "1a73e8"))
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "1a73e8").opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                if request.status == .completed {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.green)
                        Text("Job Complete!")
                            .font(.headline)
                        Text("Please pay $\(request.price) in cash to your engineer.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
            .padding()
            .background(.regularMaterial)
        }
    }

    private var customerCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: request.latitude, longitude: request.longitude)
    }

    private var engineerCoordinate: CLLocationCoordinate2D? {
        guard let lat = request.engineerLatitude, let lng = request.engineerLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    private var annotations: [MapViewRepresentable.MapAnnotationItem] {
        var items: [MapViewRepresentable.MapAnnotationItem] = [
            .init(coordinate: customerCoordinate, title: "You", tint: .systemBlue)
        ]
        if let eng = engineerCoordinate {
            items.append(.init(coordinate: eng, title: request.engineerName ?? "Engineer", tint: .systemGreen))
        }
        return items
    }
}
