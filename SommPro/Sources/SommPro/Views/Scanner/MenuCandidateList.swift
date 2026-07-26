import SwiftUI

/// Every wine the enrichment pipeline was able to pick out of a scanned menu page.
struct MenuCandidateList: View {
    let candidates: [WineIdentification]
    var onSelect: (WineIdentification) -> Void

    var body: some View {
        List(candidates.indices, id: \.self) { index in
            let candidate = candidates[index]
            Button {
                onSelect(candidate)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(candidate.wineName)
                        .font(.headline)
                    HStack(spacing: 6) {
                        if let producer = candidate.producerName {
                            Text(producer)
                        }
                        if let year = candidate.vintageYear {
                            Text(String(year))
                        }
                        Text(candidate.wineType.displayName)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)
        }
        .listStyle(.plain)
        .frame(maxHeight: 320)
    }
}
