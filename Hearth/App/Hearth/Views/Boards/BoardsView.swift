import SwiftUI
import SwiftData
import HearthKit

/// Phase 5 canvas for inspiration boards. This scaffold lists boards in a
/// glass-carded grid; the pin/annotate canvas and Vision extraction UI land
/// alongside `VisionExtractionService` in a later pass.
struct BoardsView: View {
    @Query(sort: \Board.createdAt, order: .reverse) private var boards: [Board]

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 16)]

    var body: some View {
        NavigationStack {
            ZStack {
                HearthBackground()

                if boards.isEmpty {
                    ContentUnavailableView(
                        "No boards yet",
                        systemImage: "square.grid.2x2",
                        description: Text("Create a board to start pinning inspiration photos.")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(boards) { board in
                                VStack(alignment: .leading, spacing: 8) {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(.thinMaterial)
                                        .aspectRatio(1, contentMode: .fit)
                                        .overlay(Image(systemName: "photo.stack").foregroundStyle(.secondary))
                                    Text(board.title).font(.headline)
                                    Text("\(board.items?.count ?? 0) items")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(12)
                                .glassSurface(cornerRadius: 18)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Boards")
        }
    }
}
