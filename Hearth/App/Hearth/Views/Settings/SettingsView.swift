import SwiftUI
import SwiftData
import CloudKit
import HearthKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var sharingCoordinator: CloudSharingCoordinator
    @Query private var households: [Household]

    @State private var activeShare: CKShare?
    @State private var isPresentingShareSheet = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                HearthBackground()

                Form {
                    Section("Household") {
                        if let household = households.first {
                            LabeledContent("Name", value: household.name)
                            LabeledContent("Members", value: "\(household.members?.count ?? 0)")
                        } else {
                            Button("Create Household") { createHousehold() }
                        }
                    }

                    Section {
                        Button {
                            Task { await shareHousehold() }
                        } label: {
                            Label("Share with Saral", systemImage: "person.2.badge.gearshape")
                        }
                        .disabled(households.isEmpty || sharingCoordinator.isSharing)
                    } footer: {
                        Text("Sends a CloudKit invite so this entire Hearth household -- tasks, boards, trips, everything -- syncs to her device even though you use separate iCloud accounts.")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .alert("Couldn't share", isPresented: .constant(errorMessage != nil), actions: {
                Button("OK") { errorMessage = nil }
            }, message: {
                Text(errorMessage ?? "")
            })
            #if canImport(UIKit)
            .sheet(isPresented: $isPresentingShareSheet) {
                if let activeShare {
                    CloudSharingView(share: activeShare, container: CKContainer(identifier: HearthIdentifiers.cloudKitContainer))
                }
            }
            #endif
        }
    }

    private func createHousehold() {
        let household = Household()
        modelContext.insert(household)
    }

    private func shareHousehold() async {
        guard let household = households.first else { return }
        do {
            activeShare = try await sharingCoordinator.makeOrFetchShare(for: household, in: modelContext)
            isPresentingShareSheet = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
