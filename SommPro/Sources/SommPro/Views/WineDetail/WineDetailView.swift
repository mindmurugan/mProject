import SwiftUI

struct WineDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: WineDetailViewModel

    init(outcome: ScannerViewModel.ScanOutcome, enrichmentCoordinator: EnrichmentCoordinator) {
        _viewModel = State(initialValue: WineDetailViewModel(outcome: outcome, enrichmentCoordinator: enrichmentCoordinator))
    }

    var body: some View {
        Form {
            headerSection
            matchSection
            ratingsSection
            educationSection
            tastingSection
            cellarSection

            Section {
                Button("Save") { viewModel.save(modelContext: modelContext) }
                    .disabled(!viewModel.logTasting && !viewModel.addToCellar)
            }
        }
        .navigationTitle(viewModel.outcome.identification.wineName)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadDetails() }
        .alert("Saved to SommPro", isPresented: $viewModel.saveConfirmed) {
            Button("Done") { dismiss() }
        }
    }

    private var headerSection: some View {
        Section {
            if let producer = viewModel.outcome.identification.producerName {
                LabeledContent("Producer", value: producer)
            }
            if let year = viewModel.outcome.identification.vintageYear {
                LabeledContent("Vintage", value: String(year))
            }
            if !viewModel.outcome.identification.varietals.isEmpty {
                LabeledContent("Grapes", value: viewModel.outcome.identification.varietals.joined(separator: ", "))
            }
            if let region = viewModel.outcome.identification.region {
                LabeledContent("Region", value: region)
            }
            LabeledContent("Type", value: viewModel.outcome.identification.wineType.displayName)
            if let location = viewModel.outcome.location {
                LabeledContent("Scanned at", value: location.displayName)
            }
            if viewModel.outcome.identification.confidence < 0.5 {
                Label("Low-confidence read — double check the details above", systemImage: "exclamationmark.triangle")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }
        }
    }

    @ViewBuilder
    private var matchSection: some View {
        if let existing = viewModel.previouslyScannedWine {
            Section("You've scanned this before") {
                Text("This matches \(existing.name)\(existing.producer.map { " by \($0.name)" } ?? "") already in your collection.")
                    .font(.subheadline)
            }
        } else if !viewModel.similarWines.isEmpty {
            Section("Closest to wines you've rated") {
                ForEach(viewModel.similarWines, id: \.wine.persistentModelID) { neighbor in
                    HStack {
                        Text(neighbor.wine.name)
                        Spacer()
                        Text("\(Int(neighbor.similarity * 100))% similar")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }
            }
        }
    }

    private var ratingsSection: some View {
        Section("Public ratings") {
            if viewModel.isLoadingRatings {
                ProgressView()
            } else {
                ForEach(viewModel.externalRatings, id: \.sourceRaw) { rating in
                    RatingRow(rating: rating)
                }
            }
        }
    }

    private var educationSection: some View {
        Section("Learn about this wine") {
            if viewModel.isLoadingEducation {
                ProgressView()
            } else if let education = viewModel.education {
                if let story = education.producerStory {
                    Text(story)
                }
                if let region = education.regionNotes {
                    Text(region).foregroundStyle(.secondary)
                }
                if let grapes = education.grapeNotes {
                    Text(grapes).foregroundStyle(.secondary)
                }
                if let pairing = education.foodPairingSuggestion {
                    Label(pairing, systemImage: "fork.knife")
                }
                if education.generatedOffline {
                    Text("Generated on-device (offline) — connect for a richer, web-grounded summary.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var tastingSection: some View {
        Section {
            Toggle("Log a tasting", isOn: $viewModel.logTasting)
            if viewModel.logTasting {
                VStack(alignment: .leading) {
                    Text("Your rating: \(viewModel.personalRating, specifier: "%.1f")")
                    Slider(value: $viewModel.personalRating, in: 0...5, step: 0.5)
                }
                TextField("Tasting notes", text: $viewModel.notes, axis: .vertical)
                TextField("Tags (comma separated)", text: $viewModel.tagsText)
            }
        } header: {
            Text("Your rating")
        } footer: {
            Text("Location is tagged automatically from where you scanned.")
        }
    }

    private var cellarSection: some View {
        Section("Cellar") {
            Toggle("Add to cellar", isOn: $viewModel.addToCellar)
            if viewModel.addToCellar {
                Stepper("Quantity: \(viewModel.quantity)", value: $viewModel.quantity, in: 1...48)
                TextField("Price paid", text: $viewModel.purchasePrice)
                    .keyboardType(.decimalPad)
                TextField("Cellar location (e.g. Rack B, Shelf 2)", text: $viewModel.cellarSlot)
            }
        }
    }
}

private struct RatingRow: View {
    let rating: ExternalRating

    var body: some View {
        HStack {
            Text(rating.source.displayName)
            Spacer()
            if let score = rating.score, let scale = rating.scaleMax {
                Text("\(score, specifier: "%.1f") / \(Int(scale))")
                    .foregroundStyle(.secondary)
            } else {
                Text("View on site")
                    .foregroundStyle(.secondary)
            }
            if let url = rating.url {
                Link(destination: url) {
                    Image(systemName: "arrow.up.right.square")
                }
            }
        }
        .font(.subheadline)
    }
}
