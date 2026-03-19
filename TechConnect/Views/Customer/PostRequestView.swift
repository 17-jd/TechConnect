import SwiftUI

struct PostRequestView: View {
    @ObservedObject var viewModel: CustomerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: ServiceCategory = .other
    @State private var description = ""
    @State private var price = 75

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {

                        // Category grid
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What do you need help with?")
                                .font(.subheadline.bold())
                                .foregroundStyle(.secondary)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(ServiceCategory.allCases) { category in
                                    CategoryTile(category: category, isSelected: selectedCategory == category) {
                                        selectedCategory = category
                                        price = category.suggestedPrice
                                    }
                                }
                            }
                        }
                        .cardStyle()

                        // Description
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Describe the problem")
                                .font(.subheadline.bold())
                                .foregroundStyle(.secondary)
                            TextEditor(text: $description)
                                .frame(minHeight: 90)
                                .padding(10)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    Group {
                                        if description.isEmpty {
                                            Text("e.g. My laptop won't start, screen is black...")
                                                .foregroundStyle(.secondary.opacity(0.6))
                                                .padding(16)
                                                .allowsHitTesting(false)
                                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                        }
                                    }
                                )
                        }
                        .cardStyle()

                        // Price
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Offer")
                                .font(.subheadline.bold())
                                .foregroundStyle(.secondary)
                            HStack {
                                Text("$").font(.title.bold()).foregroundStyle(Color(hex: "1a73e8"))
                                TextField("Price", value: $price, format: .number)
                                    .keyboardType(.numberPad)
                                    .font(.title.bold())
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("Suggested").font(.caption2).foregroundStyle(.secondary)
                                    Text("$\(selectedCategory.suggestedPrice)").font(.caption.bold()).foregroundStyle(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            Text("Engineers see your offer and decide whether to accept.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .cardStyle()

                        if let error = viewModel.errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                Text(error).font(.caption)
                            }
                            .foregroundStyle(.red)
                        }

                        // Post button
                        Button {
                            Task {
                                let success = await viewModel.postRequest(
                                    category: selectedCategory,
                                    description: description,
                                    price: price
                                )
                                if success { dismiss() }
                            }
                        } label: {
                            ZStack {
                                if viewModel.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Label("Post Request", systemImage: "paperplane.fill")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(description.isEmpty
                                ? AnyShapeStyle(Color(.systemGray4))
                                : AnyShapeStyle(LinearGradient(colors: [Color(hex: "1a73e8"), Color(hex: "6c3ce1")],
                                                 startPoint: .leading, endPoint: .trailing)))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(description.isEmpty || viewModel.isLoading)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("New Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct CategoryTile: View {
    let category: ServiceCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color(hex: "1a73e8") : Color(.systemGray5))
                        .frame(width: 42, height: 42)
                    Image(systemName: category.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(isSelected ? .white : .secondary)
                }
                Text(category.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isSelected ? Color(hex: "1a73e8") : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Color(hex: "1a73e8").opacity(0.08) : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color(hex: "1a73e8") : .clear, lineWidth: 1.5))
        }
    }
}
