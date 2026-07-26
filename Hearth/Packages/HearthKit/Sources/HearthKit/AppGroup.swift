import Foundation

/// Identifiers shared by the main app, the Drop Zone share extension, and the
/// widget extension. All three targets need the same App Group container so
/// they can open the same SwiftData store, and the same CloudKit container so
/// they resolve to the same shared `Household` record zone.
///
/// Replace these once you've created the real identifiers in your Apple
/// Developer account (Certificates, Identifiers & Profiles -> Identifiers),
/// then mirror them in `project.yml`'s entitlements for every target.
public enum HearthIdentifiers {
    public static let appGroup = "group.com.yourteam.hearth"
    public static let cloudKitContainer = "iCloud.com.yourteam.hearth"
}
