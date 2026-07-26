import Foundation

/// Tries Gemini first (richer, grounded, paid), falling back to the on-device Foundation
/// Models framework when offline or when the Gemini call fails — so scanning still works
/// on a plane with no signal, just with a smaller knowledge base.
actor EnrichmentCoordinator {

    private let gemini: GeminiService?
    private let onDevice = OnDeviceIntelligenceService()

    init(gemini: GeminiService?) {
        self.gemini = gemini
    }

    func identifyWine(fromOCRText text: String, barcode: String?) async -> WineIdentification {
        if let gemini, let result = try? await gemini.identifyWine(fromOCRText: text, barcode: barcode) {
            return result
        }
        if let result = try? await onDevice.identifyWine(fromOCRText: text, barcode: barcode) {
            return result
        }
        return .unknown
    }

    func identifyWines(fromMenuLines lines: [String]) async -> [WineIdentification] {
        if let gemini, let results = try? await gemini.identifyWines(fromMenuLines: lines), !results.isEmpty {
            return results
        }
        // Menu segmentation needs multi-line reasoning the on-device model does less
        // reliably; fall back to one identification per non-empty line as a rough baseline.
        var fallbackResults: [WineIdentification] = []
        for line in lines where !line.trimmingCharacters(in: .whitespaces).isEmpty {
            if let result = try? await onDevice.identifyWine(fromOCRText: line, barcode: nil) {
                var withLine = result
                withLine.sourceMenuLine = line
                fallbackResults.append(withLine)
            }
        }
        return fallbackResults
    }

    func educate(producerName: String, region: String?, varietals: [String]) async -> WineEducation {
        if let gemini, let result = try? await gemini.educate(producerName: producerName, region: region, varietals: varietals) {
            return result
        }
        if let result = try? await onDevice.educate(producerName: producerName, region: region, varietals: varietals) {
            return result
        }
        return WineEducation(generatedOffline: true)
    }
}
