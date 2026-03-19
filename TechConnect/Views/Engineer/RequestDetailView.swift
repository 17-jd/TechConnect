import SwiftUI
import UIKit
import MapKit
import CoreLocation

struct RequestDetailView: View {
    @ObservedObject var viewModel: EngineerViewModel
    @Environment(\.dismiss) private var dismiss
    let request: ServiceRequest

    @State private var engineerRating: Double = 0
    @State private var reviewCount: Int = 0
    @State private var ratingLoaded = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    // Map
                    MapViewRepresentable(
                        centerCoordinate: CLLocationCoordinate2D(latitude: request.latitude, longitude: request.longitude),
                        annotations: [.init(coordinate: CLLocationCoordinate2D(latitude: request.latitude, longitude: request.longitude),
                                            title: request.customerName, tint: .systemBlue)],
                        showsUserLocation: true
                    )
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)

                    // Price + category hero
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(LinearGradient(colors: [Color(hex: "1a73e8"), Color(hex: "6c3ce1")],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 60, height: 60)
                            Image(systemName: request.category.icon)
                                .font(.title2)
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(request.category.rawValue).font(.title3.bold())
                            Text("by \(request.customerName)").font(.subheadline).foregroundStyle(.secondary)

                            // Rating row
                            if ratingLoaded && reviewCount > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.caption)
                                        .foregroundStyle(Color(hex: "f4b400"))
                                    Text(String(format: "%.1f", engineerRating))
                                        .font(.caption.bold())
                                    Text("(\(reviewCount) reviews)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } else if ratingLoaded {
                                Text("No reviews yet")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("$\(request.price)").font(.largeTitle.bold())
                                .foregroundStyle(Color(hex: "1a73e8"))
                            Text("cash").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .cardStyle()

                    // Problem
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Problem", systemImage: "text.alignleft").font(.subheadline.bold()).foregroundStyle(.secondary)
                        Text(request.description).font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()

                    // Location
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Location", systemImage: "location.fill").font(.subheadline.bold()).foregroundStyle(.secondary)
                        Text(request.address).font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()

                    // Payment
                    HStack {
                        Label("Cash Payment Only", systemImage: "banknote.fill")
                            .font(.subheadline)
                        Spacer()
                        Text("$\(request.price)").fontWeight(.bold)
                    }
                    .padding(14)
                    .background(Color.green.opacity(0.08))
                    .foregroundStyle(.green)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.green.opacity(0.2), lineWidth: 1))

                    if let error = viewModel.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                            Text(error).font(.caption)
                        }
                        .foregroundStyle(.red)
                    }

                    // Accept button
                    Button {
                        Task {
                            let success = await viewModel.acceptRequest(request)
                            if success { dismiss() }
                        }
                    } label: {
                        ZStack {
                            if viewModel.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Label("Accept Job", systemImage: "checkmark.circle.fill")
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(LinearGradient(colors: [Color.green, Color(hex: "00b894")],
                                                   startPoint: .leading, endPoint: .trailing))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: Color.green.opacity(0.35), radius: 8, x: 0, y: 4)
                    }
                    .disabled(viewModel.isLoading)
                }
                .padding(16)
            }
        }
        .navigationTitle("Job Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let engineerId = request.engineerId {
                if let result = try? await FirestoreService.shared.getEngineerAverageRating(engineerId: engineerId) {
                    engineerRating = result.rating
                    reviewCount = result.count
                }
                ratingLoaded = true
            } else {
                ratingLoaded = true
            }
        }
    }
}
