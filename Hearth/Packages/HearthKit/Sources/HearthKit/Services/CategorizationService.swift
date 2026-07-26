import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Result of asking the on-device model to file a piece of dropped content.
public struct CategorySuggestion: Sendable, Equatable {
    public let categoryName: String
    public let confidence: Double

    public init(categoryName: String, confidence: Double) {
        self.categoryName = categoryName
        self.confidence = confidence
    }
}

public enum CategorizationAvailability: Sendable {
    case available
    case unavailable(reason: String)
}

/// Suggests a `Category` for freshly-captured Drop Zone content using
/// Apple's on-device Foundation Models framework (Apple Intelligence).
/// Everything here runs on-device -- no network call, no data leaving the
/// household's iCloud account.
public protocol CategorizationService: Sendable {
    func availability() -> CategorizationAvailability
    func suggestCategory(forText text: String, existingCategoryNames: [String]) async throws -> CategorySuggestion?
}

#if canImport(FoundationModels)

@available(iOS 26.0, macOS 26.0, *)
@Generable
struct CategorySuggestionPayload {
    @Guide(description: "The single best matching category name from the provided list, or a short new one if nothing fits")
    var categoryName: String

    @Guide(description: "Confidence in this suggestion, from 0.0 to 1.0")
    var confidence: Double
}

@available(iOS 26.0, macOS 26.0, *)
public final class OnDeviceCategorizationService: CategorizationService {
    public init() {}

    public func availability() -> CategorizationAvailability {
        switch SystemLanguageModel.default.availability {
        case .available:
            return .available
        case .unavailable(let reason):
            return .unavailable(reason: String(describing: reason))
        @unknown default:
            return .unavailable(reason: "unknown")
        }
    }

    public func suggestCategory(
        forText text: String,
        existingCategoryNames: [String]
    ) async throws -> CategorySuggestion? {
        guard case .available = availability() else { return nil }
        guard !text.isEmpty else { return nil }

        let session = LanguageModelSession(
            instructions: """
            You are sorting items into a couple's shared household organizer.
            Existing categories: \(existingCategoryNames.joined(separator: ", ")).
            Prefer an existing category when it clearly fits; otherwise propose
            a short, Title Case category name (two or three words max).
            """
        )

        let response = try await session.respond(
            to: "Categorize this item: \(text)",
            generating: CategorySuggestionPayload.self
        )

        return CategorySuggestion(
            categoryName: response.content.categoryName,
            confidence: response.content.confidence
        )
    }
}

#endif

/// Used on devices/OS versions where Apple Intelligence isn't available, and
/// in previews/tests. Triage still works -- you just pick the category by hand.
public struct NoOpCategorizationService: CategorizationService {
    public init() {}

    public func availability() -> CategorizationAvailability {
        .unavailable(reason: "Foundation Models framework not available on this OS/device")
    }

    public func suggestCategory(forText text: String, existingCategoryNames: [String]) async throws -> CategorySuggestion? {
        nil
    }
}
