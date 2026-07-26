import Foundation

struct GeminiConfiguration {
    /// Read from secure storage (Keychain) at app startup — never hardcode a key here.
    var apiKey: String
    var model: String = "gemini-2.5-flash"
    /// Google Search grounding is a paid, per-request feature. The user has opted into
    /// Gemini's paid tier specifically so scans can be enriched with live web facts
    /// (producer history, current vintage notes) rather than only the model's training data.
    var useSearchGrounding: Bool = true
}

/// Two jobs, both via the Gemini API:
/// 1. Turn raw OCR text (a label, or a block of menu text) into structured `WineIdentification`.
/// 2. Write grounded educational background (`WineEducation`) about a producer/region.
///
/// Requires network + a paid Gemini API key. `OnDeviceIntelligenceService` is the offline
/// fallback used when this fails or the device has no connectivity.
actor GeminiService {

    private let configuration: GeminiConfiguration
    private let session: URLSession

    init(configuration: GeminiConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    func identifyWine(fromOCRText text: String, barcode: String?) async throws -> WineIdentification {
        let prompt = """
        You are a sommelier assistant reading a wine label that was OCR-scanned, which may \
        contain noisy or misspelled text. Identify the wine.

        OCR text:
        \(text)

        \(barcode.map { "Barcode (UPC/EAN): \($0)" } ?? "")

        Return your best single identification. If unsure of a field, omit it rather than \
        guessing. Set confidence between 0 and 1 honestly.
        """
        let data = try await generateJSON(prompt: prompt, schema: Self.identificationSchema, grounded: true)
        return try JSONDecoder().decode(WineIdentification.self, from: data)
    }

    /// Menus list several wines per page; ask for every candidate line at once instead of
    /// one request per wine to keep paid API usage down.
    func identifyWines(fromMenuLines lines: [String]) async throws -> [WineIdentification] {
        let prompt = """
        This is OCR text from a restaurant wine list, one line per array entry. Group lines \
        that belong to the same wine (e.g. name on one line, vintage/price on the next), and \
        return one identification per distinct wine offered. Ignore section headers like \
        "By The Glass" or "Reds".

        Lines:
        \(lines.enumerated().map { "\($0.offset): \($0.element)" }.joined(separator: "\n"))
        """
        let data = try await generateJSON(
            prompt: prompt,
            schema: ["type": "array", "items": Self.identificationSchema],
            grounded: false
        )
        return try JSONDecoder().decode([WineIdentification].self, from: data)
    }

    func educate(producerName: String, region: String?, varietals: [String]) async throws -> WineEducation {
        let prompt = """
        Write a short, factual education briefing for someone learning about this wine, \
        using publicly available information. Keep each field to 2-3 sentences, friendly but \
        precise, and avoid inventing facts you're not confident about.

        Producer: \(producerName)
        Region: \(region ?? "unknown")
        Grape(s): \(varietals.isEmpty ? "unknown" : varietals.joined(separator: ", "))
        """
        let data = try await generateJSON(prompt: prompt, schema: Self.educationSchema, grounded: true)
        var education = try JSONDecoder().decode(WineEducation.self, from: data)
        education.generatedOffline = false
        return education
    }

    // MARK: - Request plumbing

    private func generateJSON(prompt: String, schema: [String: Any], grounded: Bool) async throws -> Data {
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(configuration.model):generateContent")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(configuration.apiKey, forHTTPHeaderField: "x-goog-api-key")

        var body: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]],
            "generationConfig": [
                "responseMimeType": "application/json",
                "responseSchema": schema
            ]
        ]
        if grounded && configuration.useSearchGrounding {
            body["tools"] = [["google_search": [String: Any]()]]
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw GeminiError.requestFailed
        }

        let envelope = try JSONDecoder().decode(GenerateContentResponse.self, from: data)
        guard let text = envelope.candidates?.first?.content?.parts?.first?.text,
              let jsonData = text.data(using: .utf8) else {
            throw GeminiError.emptyResponse
        }
        return jsonData
    }

    private static let identificationSchema: [String: Any] = [
        "type": "object",
        "properties": [
            "producerName": ["type": "string"],
            "wineName": ["type": "string"],
            "vintageYear": ["type": "integer"],
            "varietals": ["type": "array", "items": ["type": "string"]],
            "region": ["type": "string"],
            "country": ["type": "string"],
            "wineType": ["type": "string", "enum": WineType.allCases.map(\.rawValue)],
            "sourceMenuLine": ["type": "string"],
            "confidence": ["type": "number"]
        ],
        "required": ["wineName", "varietals", "wineType", "confidence"]
    ]

    private static let educationSchema: [String: Any] = [
        "type": "object",
        "properties": [
            "producerStory": ["type": "string"],
            "regionNotes": ["type": "string"],
            "grapeNotes": ["type": "string"],
            "foodPairingSuggestion": ["type": "string"],
            "generatedOffline": ["type": "boolean"]
        ],
        "required": ["generatedOffline"]
    ]
}

private struct GenerateContentResponse: Decodable {
    struct Candidate: Decodable {
        struct Content: Decodable {
            struct Part: Decodable { var text: String? }
            var parts: [Part]?
        }
        var content: Content?
    }
    var candidates: [Candidate]?
}

enum GeminiError: Error {
    case requestFailed
    case emptyResponse
}
