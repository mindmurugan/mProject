import Foundation
import FoundationModels

/// Offline, on-device fallback for wine identification and education text, using Apple's
/// on-device Foundation Models framework (Apple Intelligence, iOS/iPadOS 26+). No network,
/// no per-call cost, fully private — but the model has no live internet access and a fixed
/// training cutoff, so it can't look up a wine it's never heard of or recent vintage news.
/// `GeminiService` is preferred when online; this is what keeps the app useful offline.
///
/// Note: the Foundation Models framework shipped in iOS/iPadOS 26, after this code's
/// training data — verify `SystemLanguageModel`/`LanguageModelSession`/`@Generable`/`@Guide`
/// against the installed Xcode 26 SDK docs before relying on this file to compile as-is.
actor OnDeviceIntelligenceService {

    struct UnavailableError: Error {}

    private func makeSession(instructions: String) throws -> LanguageModelSession {
        let model = SystemLanguageModel.default
        guard case .available = model.availability else {
            throw UnavailableError()
        }
        return LanguageModelSession(model: model, instructions: instructions)
    }

    func identifyWine(fromOCRText text: String, barcode: String?) async throws -> WineIdentification {
        let session = try makeSession(instructions: """
            You read wine labels and extract structured details from noisy OCR text. Omit \
            fields you're not confident about instead of guessing.
            """)
        let prompt = "OCR text from a wine label:\n\(text)\n\(barcode.map { "Barcode: \($0)" } ?? "")"
        let response = try await session.respond(to: prompt, generating: GeneratedIdentification.self)
        return response.content.asWineIdentification()
    }

    func educate(producerName: String, region: String?, varietals: [String]) async throws -> WineEducation {
        let session = try makeSession(instructions: """
            You write short, honest educational summaries about wine producers and regions \
            from what you already know. If you're not confident about a detail, leave it out \
            rather than inventing it.
            """)
        let prompt = """
        Producer: \(producerName)
        Region: \(region ?? "unknown")
        Grapes: \(varietals.isEmpty ? "unknown" : varietals.joined(separator: ", "))
        """
        let response = try await session.respond(to: prompt, generating: GeneratedEducation.self)
        var education = response.content.asWineEducation()
        education.generatedOffline = true
        return education
    }
}

@Generable
private struct GeneratedIdentification {
    @Guide(description: "Winery or producer name, if legible")
    var producerName: String?
    @Guide(description: "The wine's own name, e.g. 'Bin 389', or the varietal if unnamed")
    var wineName: String
    @Guide(description: "Vintage year, e.g. 2019")
    var vintageYear: Int?
    @Guide(description: "Grape varietals, e.g. Cabernet Sauvignon")
    var varietals: [String]
    var region: String?
    var country: String?
    @Guide(description: "One of: red, white, rose, sparkling, dessert, fortified, orange, unknown")
    var wineType: String
    @Guide(description: "Confidence from 0 to 1")
    var confidence: Double

    func asWineIdentification() -> WineIdentification {
        WineIdentification(
            producerName: producerName,
            wineName: wineName,
            vintageYear: vintageYear,
            varietals: varietals,
            region: region,
            country: country,
            wineType: WineType(rawValue: wineType) ?? .unknown,
            sourceMenuLine: nil,
            confidence: confidence
        )
    }
}

@Generable
private struct GeneratedEducation {
    var producerStory: String?
    var regionNotes: String?
    var grapeNotes: String?
    var foodPairingSuggestion: String?

    func asWineEducation() -> WineEducation {
        WineEducation(
            producerStory: producerStory,
            regionNotes: regionNotes,
            grapeNotes: grapeNotes,
            foodPairingSuggestion: foodPairingSuggestion,
            generatedOffline: true
        )
    }
}
