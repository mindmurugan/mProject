import SwiftUI
import SwiftData
import HearthKit

/// Landing spot for everything dropped in from the Drop Zone share extension.
/// Phase 4 wires `CategorizationService` suggestions into the trailing chip;
/// for now this shows the raw capture and lets you triage it manually.
struct InboxView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CapturedItem.createdAt, order: .reverse) private var untriaged: [CapturedItem]

    private var pending: [CapturedItem] { untriaged.filter { !$0.isTriaged } }

    var body: some View {
        NavigationStack {
            ZStack {
                HearthBackground()

                if pending.isEmpty {
                    ContentUnavailableView(
                        "Drop Zone is empty",
                        systemImage: "tray",
                        description: Text("Share a link, photo, or file from Safari or Photos to see it here.")
                    )
                } else {
                    List(pending) { item in
                        CapturedItemRow(item: item)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Inbox")
        }
    }
}

private struct CapturedItemRow: View {
    let item: CapturedItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.sourceTitle ?? item.rawText ?? "Untitled")
                    .lineLimit(2)
                if let suggestion = item.suggestedCategoryName {
                    Label(suggestion, systemImage: "sparkles")
                        .font(.caption)
                        .foregroundStyle(.tint)
                }
            }
        }
        .padding(12)
        .glassSurface(cornerRadius: 16)
    }

    private var iconName: String {
        switch item.contentType {
        case .link: return "link"
        case .image: return "photo"
        case .file: return "doc"
        case .text: return "text.alignleft"
        }
    }
}
