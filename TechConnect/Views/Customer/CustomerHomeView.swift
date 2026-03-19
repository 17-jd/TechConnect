import SwiftUI
import UIKit
import MapKit
import CoreLocation

struct CustomerHomeView: View {
    @StateObject private var viewModel = CustomerViewModel()
    @StateObject private var locationService = LocationService.shared

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                MapViewRepresentable(
                    centerCoordinate: locationService.currentLocation,
                    annotations: mapAnnotations,
                    showsUserLocation: true
                )
                .ignoresSafeArea()

                if let request = viewModel.activeRequest {
                    ActiveRequestCard(request: request) {
                        Task { await viewModel.cancelRequest() }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    Button {
                        viewModel.showPostRequest = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill").font(.title3)
                            Text("Post Service Request").fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(LinearGradient(colors: [Color(hex: "1a73e8"), Color(hex: "6c3ce1")],
                                                   startPoint: .leading, endPoint: .trailing))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color(hex: "1a73e8").opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4), value: viewModel.activeRequest?.id)
            .navigationTitle("TechConnect")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $viewModel.showPostRequest) {
                PostRequestView(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showReviewSheet) {
                if let request = viewModel.activeRequest {
                    ReviewSheet(engineerName: request.engineerName ?? "your engineer") { stars, comment in
                        Task { await viewModel.submitReview(stars: stars, comment: comment) }
                    }
                }
            }
            .onAppear {
                locationService.requestPermission()
                viewModel.startListening()
            }
        }
    }

    private var mapAnnotations: [MapViewRepresentable.MapAnnotationItem] {
        guard let request = viewModel.activeRequest,
              let lat = request.engineerLatitude,
              let lng = request.engineerLongitude else { return [] }
        return [.init(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                      title: request.engineerName ?? "Engineer", tint: .systemGreen)]
    }
}

struct ActiveRequestCard: View {
    let request: ServiceRequest
    let onCancel: () -> Void

    private let steps: [ServiceRequest.RequestStatus] = [.open, .accepted, .enRoute, .arrived, .working, .completed]

    var body: some View {
        VStack(spacing: 0) {
            // Top row
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(LinearGradient(colors: [Color(hex: "1a73e8"), Color(hex: "6c3ce1")],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 46, height: 46)
                    Image(systemName: request.category.icon)
                        .font(.title3)
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(request.category.rawValue).font(.headline)
                    Text(statusText).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text("$\(request.price)")
                    .font(.title3.bold())
                    .foregroundStyle(Color(hex: "1a73e8"))
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            // Progress bar
            HStack(spacing: 3) {
                ForEach(steps, id: \.self) { step in
                    Capsule()
                        .fill(isComplete(step) ? Color(hex: "1a73e8") : Color(.systemGray5))
                        .frame(height: 4)
                        .animation(.easeInOut(duration: 0.3), value: request.status)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // ETA row
            if let eta = request.estimatedArrivalAt,
               request.status == .accepted || request.status == .enRoute {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                        .foregroundStyle(Color(hex: "1a73e8"))
                    Text("Arrives in")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(eta, style: .timer)
                        .font(.caption.bold())
                        .foregroundStyle(Color(hex: "1a73e8"))
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }

            Divider().padding(.top, 12)

            // Engineer info / cancel
            HStack {
                if let name = request.engineerName {
                    HStack(spacing: 6) {
                        Image(systemName: "person.fill").font(.caption).foregroundStyle(Color(hex: "6c3ce1"))
                        Text(name).font(.subheadline.bold())
                    }
                } else {
                    HStack(spacing: 6) {
                        ProgressView().scaleEffect(0.7)
                        Text("Finding an engineer...").font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if request.status == .open {
                    Button("Cancel") { onCancel() }
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 6)
    }

    private var statusText: String {
        switch request.status {
        case .open: return "Waiting for an engineer..."
        case .accepted: return "Engineer accepted!"
        case .enRoute: return "Engineer is on the way"
        case .arrived: return "Engineer has arrived"
        case .working: return "Work in progress"
        case .completed: return "Job completed!"
        case .cancelled: return "Cancelled"
        }
    }

    private func isComplete(_ step: ServiceRequest.RequestStatus) -> Bool {
        guard let ci = steps.firstIndex(of: request.status),
              let si = steps.firstIndex(of: step) else { return false }
        return si <= ci
    }
}

struct ReviewSheet: View {
    let engineerName: String
    let onSubmit: (Int, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var stars = 5
    @State private var comment = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color(hex: "f4b400"))
                    Text("Rate \(engineerName)")
                        .font(.title2.bold())
                    Text("How was your experience?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)

                // Star picker
                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { i in
                        Button {
                            stars = i
                        } label: {
                            Image(systemName: i <= stars ? "star.fill" : "star")
                                .font(.system(size: 36))
                                .foregroundStyle(i <= stars ? Color(hex: "f4b400") : Color(.systemGray4))
                                .scaleEffect(i == stars ? 1.15 : 1.0)
                                .animation(.spring(response: 0.2), value: stars)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Comment (optional)")
                        .font(.subheadline.bold())
                        .foregroundStyle(.secondary)
                    TextEditor(text: $comment)
                        .frame(height: 100)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 16)

                Spacer()

                Button {
                    onSubmit(stars, comment)
                    dismiss()
                } label: {
                    Text("Submit Review")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(LinearGradient(colors: [Color(hex: "1a73e8"), Color(hex: "6c3ce1")],
                                                   startPoint: .leading, endPoint: .trailing))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .navigationTitle("Leave a Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") { dismiss() }
                }
            }
        }
    }
}
