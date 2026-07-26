import Foundation
import CloudKit
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

/// Wraps the one-time flow of turning your local `Household` into a
/// CloudKit-shared record graph, plus accepting the invite on the partner's
/// device. This is the piece that stands in for "two separate iCloud
/// accounts syncing the same data": SwiftData's private-database sync alone
/// only ever reaches devices signed into the *same* iCloud account, so
/// sharing a `CKShare` for the single `Household` root is what bridges your
/// account and Saral's.
///
/// - Note: SwiftData's CloudKit-sharing surface (`ModelContext.share`,
///   share-participant inspection, etc.) has continued to evolve across SDK
///   releases. The method shapes below match the WWDC24 "Sync to iCloud with
///   CloudKit and SwiftData" sharing session; re-check them against the
///   current SDK docs in Xcode before shipping.
@MainActor
public final class CloudSharingCoordinator: NSObject, ObservableObject {
    @Published public private(set) var isSharing = false
    @Published public private(set) var lastError: Error?

    public override init() {}

    /// Creates (or fetches the existing) `CKShare` for the household so it
    /// can be handed to `UICloudSharingController` for the system share sheet.
    public func makeOrFetchShare(
        for household: Household,
        in context: ModelContext
    ) async throws -> CKShare {
        isSharing = true
        defer { isSharing = false }

        do {
            let share = try context.share([household], to: nil)
            share[CKShare.SystemFieldKey.title] = household.name
            share.publicPermission = .none
            try context.save()
            return share
        } catch {
            lastError = error
            throw error
        }
    }

    /// Call from `UIApplicationDelegate.window(_:userDidAcceptCloudKitShareWith:)`
    /// (or the SwiftUI `.onAppear`/scene-delegate equivalent) once the partner
    /// taps the share link they received.
    public func acceptShare(
        with metadata: CKShare.Metadata,
        container: ModelContainer
    ) async throws {
        let ckContainer = CKContainer(identifier: HearthIdentifiers.cloudKitContainer)
        let operation = CKAcceptSharesOperation(shareMetadatas: [metadata])
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation.acceptSharesResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            ckContainer.add(operation)
        }
    }
}

#if canImport(UIKit)
/// SwiftUI-friendly wrapper around `UICloudSharingController`, the stable,
/// documented system UI for presenting/managing a `CKShare` (invite by
/// Messages/Mail/link, see participants, stop sharing).
public struct CloudSharingView: UIViewControllerRepresentable {
    public let share: CKShare
    public let container: CKContainer

    public init(share: CKShare, container: CKContainer) {
        self.share = share
        self.container = container
    }

    public func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.delegate = context.coordinator
        controller.availablePermissions = [.allowReadWrite, .allowPrivate]
        return controller
    }

    public func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}

    public func makeCoordinator() -> Coordinator { Coordinator() }

    public final class Coordinator: NSObject, UICloudSharingControllerDelegate {
        public func itemTitle(for csc: UICloudSharingController) -> String? {
            csc.share?[CKShare.SystemFieldKey.title] as? String
        }

        public func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            assertionFailure("Failed to save CKShare: \(error)")
        }
    }
}
#endif
