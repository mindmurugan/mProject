import Foundation
import SwiftData

enum WineMatchResult {
    /// Exact same bottle, identified by barcode or a near-exact text match.
    case previouslyScanned(Wine)
    /// Not the same wine, but here's how it compares to ones already rated.
    case newWine(nearest: [WineSimilarityService.Neighbor])
}

/// Answers "have I scanned this before, or what's it like compared to wines I've rated" —
/// entirely from the local SwiftData store, no network required.
@MainActor
struct WineMatchingService {

    private let similarity = WineSimilarityService()
    private let textMatchThreshold = 0.94
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func match(identification: WineIdentification, barcode: String?) throws -> WineMatchResult {
        let allWines = try modelContext.fetch(FetchDescriptor<Wine>())

        if let barcode, let exact = allWines.first(where: { $0.barcode == barcode }) {
            return .previouslyScanned(exact)
        }

        let candidateProfile = ProfileText.build(from: identification)
        if let textMatch = allWines.first(where: {
            normalizedSimilarity($0.normalizedProfile, candidateProfile) >= textMatchThreshold
        }) {
            return .previouslyScanned(textMatch)
        }

        // Not seen before — but tell the user how it relates to wines they've already rated.
        let ratedWineIDs = Set(
            (try modelContext.fetch(FetchDescriptor<TastingEvent>()))
                .compactMap { $0.vintage?.wine?.persistentModelID }
        )
        let ratedWines = allWines.filter { ratedWineIDs.contains($0.persistentModelID) }

        guard let vector = similarity.embed(candidateProfile) else {
            return .newWine(nearest: [])
        }
        let placeholder = Wine(name: identification.wineName)
        placeholder.profileEmbedding = vector

        return .newWine(nearest: similarity.nearestNeighbors(to: placeholder, among: ratedWines))
    }

    /// Token-overlap similarity — cheap, dependency-free fuzzy match for near-duplicate
    /// label text (OCR noise, punctuation, vintage suffix differences).
    private func normalizedSimilarity(_ lhs: String, _ rhs: String) -> Double {
        let lhsTokens = Set(lhs.split(separator: " "))
        let rhsTokens = Set(rhs.split(separator: " "))
        guard !lhsTokens.isEmpty, !rhsTokens.isEmpty else { return 0 }
        let intersection = lhsTokens.intersection(rhsTokens).count
        let union = lhsTokens.union(rhsTokens).count
        return Double(intersection) / Double(union)
    }
}

private enum ProfileText {
    static func build(from identification: WineIdentification) -> String {
        var parts = [identification.wineName]
        if let producerName = identification.producerName { parts.append(producerName) }
        parts.append(contentsOf: identification.varietals)
        if let region = identification.region { parts.append(region) }
        parts.append(identification.wineType.rawValue)
        return parts.joined(separator: " ").lowercased()
    }
}
