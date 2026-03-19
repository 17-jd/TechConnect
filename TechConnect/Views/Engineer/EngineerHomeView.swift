import SwiftUI

struct EngineerHomeView: View {
    @StateObject private var viewModel = EngineerViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    // Online toggle banner
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(viewModel.isOnline ? Color.green.opacity(0.15) : Color(.systemGray5))
                                .frame(width: 46, height: 46)
                            Image(systemName: viewModel.isOnline ? "wifi" : "wifi.slash")
                                .font(.title3)
                                .foregroundStyle(viewModel.isOnline ? .green : .secondary)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(viewModel.isOnline ? "You're Online" : "You're Offline")
                                .font(.headline)
                            Text(viewModel.isOnline ? "Receiving job requests" : "Go online to see jobs")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { viewModel.isOnline },
                            set: { _ in Task { await viewModel.toggleOnline() } }
                        ))
                        .labelsHidden()
                        .tint(.green)
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)

                    if let activeJob = viewModel.activeJob {
                        EngineerActiveJobView(viewModel: viewModel, request: activeJob)
                    } else if viewModel.isOnline {
                        if viewModel.openRequests.isEmpty {
                            VStack(spacing: 16) {
                                Spacer()
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .font(.system(size: 52))
                                    .foregroundStyle(Color(hex: "1a73e8").opacity(0.5))
                                Text("Listening for requests...")
                                    .font(.headline)
                                Text("New jobs nearby will appear here in real time")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                Spacer()
                            }
                            .padding(32)
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(viewModel.openRequests) { request in
                                        NavigationLink {
                                            RequestDetailView(viewModel: viewModel, request: request)
                                        } label: {
                                            RequestCard(request: request)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(16)
                            }
                        }
                    } else {
                        VStack(spacing: 16) {
                            Spacer()
                            Image(systemName: "power.circle")
                                .font(.system(size: 52))
                                .foregroundStyle(Color(.systemGray3))
                            Text("You're Offline")
                                .font(.headline)
                            Text("Toggle online above to start\nreceiving job requests")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                        .padding(32)
                    }
                }
            }
            .navigationTitle("Jobs")
            .onAppear {
                LocationService.shared.requestPermission()
                NotificationService.shared.requestPermissionAndRegister()
                viewModel.startListening()
            }
        }
    }
}

struct RequestCard: View {
    let request: ServiceRequest

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(colors: [Color(hex: "1a73e8"), Color(hex: "6c3ce1")],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 52, height: 52)
                Image(systemName: request.category.icon)
                    .font(.title3)
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(request.category.rawValue).font(.headline)
                Text(request.description).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                HStack(spacing: 4) {
                    Image(systemName: "location.fill").font(.caption2).foregroundStyle(.secondary)
                    Text(request.address).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(request.price)")
                    .font(.title3.bold())
                    .foregroundStyle(Color(hex: "1a73e8"))
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}
