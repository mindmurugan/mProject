import SwiftUI

/// The running list of bottles scanned while walking a shop aisle in `.shop` mode.
struct ShopQueueList: View {
    let outcomes: [ScannerViewModel.ScanOutcome]
    var onSelect: (ScannerViewModel.ScanOutcome) -> Void

    var body: some View {
        List(outcomes) { outcome in
            Button {
                onSelect(outcome)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(outcome.identification.wineName)
                        .font(.headline)
                    if let producer = outcome.identification.producerName {
                        Text(producer)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    if case .previouslyScanned = outcome.matchResult {
                        Label("Scanned before", systemImage: "arrow.triangle.2.circlepath")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
            .foregroundStyle(.primary)
        }
        .listStyle(.plain)
        .frame(maxHeight: 260)
    }
}
