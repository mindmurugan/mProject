import Foundation
import CloudKit
import HearthKit

/// Answers "which `HouseholdMember` is *this* device's owner?" by comparing
/// each member's stored `cloudKitUserRecordName` against the signed-in
/// iCloud account. This is why `HouseholdMember` doesn't store an `isMe`
/// boolean: that flag would sync via CloudKit and read as true on both of
/// your devices for whichever record it was set on.
@MainActor
final class CurrentMemberResolver: ObservableObject {
    @Published private(set) var currentUserRecordName: String?

    func refresh() async {
        let container = CKContainer(identifier: HearthIdentifiers.cloudKitContainer)
        currentUserRecordName = try? await container.userRecordID().recordName
    }

    func currentMember(in members: [HouseholdMember]) -> HouseholdMember? {
        guard let currentUserRecordName else { return nil }
        return members.first { $0.cloudKitUserRecordName == currentUserRecordName }
    }

    func partner(in members: [HouseholdMember]) -> HouseholdMember? {
        guard let currentUserRecordName else { return members.first }
        return members.first { $0.cloudKitUserRecordName != currentUserRecordName }
    }
}
