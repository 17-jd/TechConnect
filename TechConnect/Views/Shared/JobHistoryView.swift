import SwiftUI
import FirebaseAuth

struct JobHistoryView: View {
    let role: AppUser.UserRole
    @State private var jobs: [ServiceRequest] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                if isLoading {
                    ProgressView("Loading history...")
                } else if jobs.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.badge.xmark")
                            .font(.system(size: 52))
                            .foregroundStyle(Color(.systemGray3))
                        Text("No History Yet")
                            .font(.headline)
                        Text("Your completed jobs will appear here")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(jobs) { job in
                                HistoryCard(job: job, role: role)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("History")
            .task { await loadJobs() }
        }
    }

    private func loadJobs() async {
        guard let uid = Auth.auth().currentUser?.uid else { isLoading = false; return }
        do {
            jobs = try await FirestoreService.shared.getCompletedRequests(userId: uid, role: role)
        } catch {
            print("Error: \(error)")
        }
        isLoading = false
    }
}

struct HistoryCard: View {
    let job: ServiceRequest
    let role: AppUser.UserRole

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(colors: [Color(hex: "1a73e8"), Color(hex: "6c3ce1")],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 50, height: 50)
                Image(systemName: job.category.icon)
                    .font(.title3).foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(job.category.rawValue).font(.headline)
                Text(role == .customer ? (job.engineerName ?? "Unknown") : job.customerName)
                    .font(.caption).foregroundStyle(.secondary)
                if let date = job.completedAt {
                    Text(date, style: .date).font(.caption2).foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(job.price)").font(.title3.bold()).foregroundStyle(Color(hex: "1a73e8"))
                Text("Completed").font(.caption2).foregroundStyle(.green)
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}
