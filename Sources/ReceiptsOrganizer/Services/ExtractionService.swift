import Foundation
import FoundationModels

// MARK: - Structured output schema for Apple Intelligence

@Generable
struct ExtractedReceiptData {
    @Guide(description: "The full product or item name as printed on the receipt or warranty card.")
    var productName: String

    @Guide(description: "The store, brand, or vendor name where the item was purchased.")
    var vendorName: String

    @Guide(description: "Purchase date in ISO-8601 format (YYYY-MM-DD). Leave empty string if not found.")
    var purchaseDateISO: String

    @Guide(description: "Purchase price as a decimal number string, e.g. '299.99'. Leave empty if not found.")
    var purchasePriceString: String

    @Guide(description: "Three-letter ISO 4217 currency code, e.g. 'USD'. Default to 'USD' if unclear.")
    var currencyCode: String

    @Guide(description: "Warranty expiration date in ISO-8601 format (YYYY-MM-DD). Leave empty if no warranty found.")
    var warrantyExpirationDateISO: String

    @Guide(description: "Warranty duration in months as an integer string, e.g. '24'. Leave empty if not stated.")
    var warrantyDurationMonthsString: String

    @Guide(description: "Summary of warranty terms and conditions in plain English, max 200 words.")
    var warrantyTermsSummary: String

    @Guide(description: "Name of the warranty provider or manufacturer if stated.")
    var warrantyProviderName: String

    @Guide(description: "Product category. Must be exactly one of: electronics, appliances, furniture, clothing, automotive, health, tools, other.")
    var category: String
}

// MARK: - Service

@MainActor
final class ExtractionService: ObservableObject {

    enum ExtractionError: LocalizedError {
        case modelUnavailable(String)
        case extractionFailed(Error)
        case noTextProvided

        var errorDescription: String? {
            switch self {
            case .modelUnavailable(let reason):
                return "Apple Intelligence is not available: \(reason)"
            case .extractionFailed(let underlying):
                return "Extraction failed: \(underlying.localizedDescription)"
            case .noTextProvided:
                return "No text was found in the document."
            }
        }
    }

    @Published var isExtracting: Bool = false
    @Published var lastError: ExtractionError?

    func checkAvailability() -> ExtractionError? {
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            return nil
        case .unavailable(let reason):
            return .modelUnavailable(reason.localizedDescription)
        }
    }

    func extract(from ocrText: String) async throws -> ExtractedReceiptData {
        guard !ocrText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ExtractionError.noTextProvided
        }

        if let unavailable = checkAvailability() {
            throw unavailable
        }

        isExtracting = true
        defer { isExtracting = false }

        // Fresh session per document — no shared conversation history needed
        let session = LanguageModelSession {
            """
            You are a receipt and warranty data extraction assistant.
            Extract structured information from the provided OCR text of a receipt or warranty document.
            Be precise: only extract information that is explicitly present in the text.
            For dates, always output ISO-8601 format (YYYY-MM-DD).
            For missing fields, output an empty string.
            Do not infer or hallucinate values that are not present in the text.
            """
        }

        let prompt = """
        Extract all relevant receipt and warranty information from the following scanned document text:

        ---
        \(ocrText)
        ---
        """

        do {
            let response = try await session.respond(
                to: prompt,
                generating: ExtractedReceiptData.self
            )
            return response.content
        } catch {
            lastError = .extractionFailed(error)
            throw ExtractionError.extractionFailed(error)
        }
    }
}

// MARK: - Mapping to SwiftData models

extension ExtractionService {

    private static let isoDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    func apply(_ extracted: ExtractedReceiptData, to receipt: Receipt) {
        receipt.productName = extracted.productName.isEmpty ? "Unknown Product" : extracted.productName
        receipt.vendorName = extracted.vendorName.isEmpty ? "Unknown Vendor" : extracted.vendorName
        receipt.currencyCode = extracted.currencyCode.isEmpty ? "USD" : extracted.currencyCode
        receipt.updatedAt = Date()

        if let date = Self.isoDateFormatter.date(from: extracted.purchaseDateISO) {
            receipt.purchaseDate = date
        }
        if let priceValue = Double(extracted.purchasePriceString) {
            receipt.purchasePrice = Decimal(priceValue)
        }
        if let cat = ReceiptCategory(rawValue: extracted.category.lowercased()) {
            receipt.category = cat
        }

        let warranty = receipt.warrantyInfo ?? {
            let w = WarrantyInfo()
            receipt.warrantyInfo = w
            return w
        }()

        warranty.warrantyTerms = extracted.warrantyTermsSummary.isEmpty ? nil : extracted.warrantyTermsSummary
        warranty.providerName = extracted.warrantyProviderName.isEmpty ? nil : extracted.warrantyProviderName

        if let months = Int(extracted.warrantyDurationMonthsString) {
            warranty.durationMonths = months
        }
        if let expiry = Self.isoDateFormatter.date(from: extracted.warrantyExpirationDateISO) {
            warranty.expirationDate = expiry
        } else if let purchase = receipt.purchaseDate, let months = warranty.durationMonths {
            // Derive expiry from purchase date + duration when no explicit expiry was stated
            warranty.expirationDate = Calendar.current.date(
                byAdding: .month, value: months, to: purchase
            )
        }
    }
}
