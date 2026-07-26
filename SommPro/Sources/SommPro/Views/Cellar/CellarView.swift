import SwiftUI
import SwiftData

struct CellarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Bottle.purchaseDate, order: .reverse) private var bottles: [Bottle]

    private var activeBottles: [Bottle] { bottles.filter { !$0.isConsumed } }

    var body: some View {
        NavigationStack {
            List {
                if activeBottles.isEmpty {
                    ContentUnavailableView(
                        "Your cellar is empty",
                        systemImage: "square.stack.3d.up.slash",
                        description: Text("Bottles you add to the cellar while scanning in Shop mode show up here.")
                    )
                } else {
                    ForEach(activeBottles) { bottle in
                        CellarRowView(bottle: bottle)
                            .swipeActions {
                                Button("Mark Drunk") {
                                    markDrunk(bottle)
                                }
                                .tint(.purple)
                            }
                    }
                }
            }
            .navigationTitle("Cellar")
        }
    }

    private func markDrunk(_ bottle: Bottle) {
        bottle.isConsumed = true
        if bottle.quantity > 1 {
            bottle.quantity -= 1
            bottle.isConsumed = false
        }
        let event = TastingEvent(
            vintage: bottle.vintage,
            mode: .drink,
            location: bottle.purchaseLocation,
            bottle: bottle
        )
        modelContext.insert(event)
        try? modelContext.save()
    }
}
