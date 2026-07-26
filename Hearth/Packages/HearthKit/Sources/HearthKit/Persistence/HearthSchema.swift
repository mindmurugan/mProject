import Foundation
import SwiftData

/// Central place that lists every `@Model` type and builds the one
/// `ModelContainer` shared by the app, the Drop Zone share extension, and the
/// widget extension.
public enum HearthSchema {
    public static var models: [any PersistentModel.Type] {
        [
            Household.self,
            HouseholdMember.self,
            Category.self,
            TaskItem.self,
            CapturedItem.self,
            Board.self,
            BoardItem.self,
            Trip.self,
            ItinerarySegment.self,
            LocationReminder.self
        ]
    }

    public static var schema: Schema {
        Schema(models)
    }

    /// Builds the shared container.
    ///
    /// - The store file lives inside the App Group container so the share
    ///   extension and widget extension read/write the exact same database
    ///   as the app (App Groups are required for extensions regardless of
    ///   CloudKit).
    /// - `cloudKitDatabase: .automatic` lets SwiftData sync a model both to
    ///   the signed-in iCloud account's private database *and* any shared
    ///   database zones that account has accepted a `CKShare` into -- which
    ///   is what makes the same `Household` graph appear on both partners'
    ///   devices once one of you shares it (see `CloudSharingCoordinator`).
    ///
    /// - Note: The exact `ModelConfiguration` CloudKit sharing API has moved
    ///   between SDK releases; confirm the initializer shape against the
    ///   Xcode version you're building with and adjust if needed.
    public static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        guard
            let appGroupURL = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: HearthIdentifiers.appGroup)
        else {
            fatalError("App Group '\(HearthIdentifiers.appGroup)' is not configured for this target. Add it in Signing & Capabilities.")
        }

        let storeURL = appGroupURL.appendingPathComponent("Hearth.sqlite")

        let configuration = ModelConfiguration(
            schema: schema,
            url: inMemory ? URL(filePath: "/dev/null") : storeURL,
            allowsSave: true,
            cloudKitDatabase: inMemory ? .none : .automatic
        )

        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
