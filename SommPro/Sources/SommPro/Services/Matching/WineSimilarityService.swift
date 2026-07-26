import Foundation
import NaturalLanguage
import SwiftData

/// On-device semantic similarity between wine profiles, using Apple's `NLEmbedding`
/// sentence embeddings. Free, offline, and the basis for "how close is this to a wine
/// I've already rated" — no network call needed.
struct WineSimilarityService {

    private let embedding = NLEmbedding.sentenceEmbedding(for: .english)

    /// Computes (and caches) the embedding vector for a wine's normalized profile text.
    func embed(_ text: String) -> [Double]? {
        embedding?.vector(for: text)
    }

    func cosineSimilarity(_ lhs: [Double], _ rhs: [Double]) -> Double {
        guard lhs.count == rhs.count, !lhs.isEmpty else { return 0 }
        var dot = 0.0, lhsMagnitude = 0.0, rhsMagnitude = 0.0
        for i in 0..<lhs.count {
            dot += lhs[i] * rhs[i]
            lhsMagnitude += lhs[i] * lhs[i]
            rhsMagnitude += rhs[i] * rhs[i]
        }
        guard lhsMagnitude > 0, rhsMagnitude > 0 else { return 0 }
        return dot / (lhsMagnitude.squareRoot() * rhsMagnitude.squareRoot())
    }

    struct Neighbor {
        var wine: Wine
        var similarity: Double
    }

    /// Ranks `candidates` by similarity to `target`, nearest first. Intended use: find what
    /// among the wines the user has already rated is closest to the one just scanned.
    func nearestNeighbors(to target: Wine, among candidates: [Wine], limit: Int = 3) -> [Neighbor] {
        guard let targetVector = target.profileEmbedding ?? embed(target.normalizedProfile) else {
            return []
        }
        let scored: [Neighbor] = candidates
            .filter { $0.persistentModelID != target.persistentModelID }
            .compactMap { candidate in
                guard let vector = candidate.profileEmbedding ?? embed(candidate.normalizedProfile) else {
                    return nil
                }
                return Neighbor(wine: candidate, similarity: cosineSimilarity(targetVector, vector))
            }
            .sorted { $0.similarity > $1.similarity }
        return Array(scored.prefix(limit))
    }
}
