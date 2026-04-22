import SwiftUI
import SwiftData

@MainActor
@Observable
final class AddEditReceiptViewModel {

    enum ProcessingStage: String {
        case idle = ""
        case ocr = "Reading document text..."
        case extracting = "Extracting details with Apple Intelligence..."
        case saving = "Saving..."
    }

    private let ocrService = OCRService()
    private let extractionService = ExtractionService()
    private let notificationService = NotificationService()
    private let modelContext: ModelContext

    var receipt: Receipt
    var isProcessing: Bool = false
    var processingStage: ProcessingStage = .idle
    var errorMessage: String?
    var showScanner: Bool = false
    var showPhotoPicker: Bool = false

    init(receipt: Receipt? = nil, modelContext: ModelContext) {
        self.modelContext = modelContext
        self.receipt = receipt ?? Receipt()
    }

    // MARK: - Full pipeline: Scan → OCR → AI extraction → persist → notify

    func processScannedPages(_ pages: [UIImage]) async {
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false; processingStage = .idle }

        do {
            processingStage = .ocr
            let ocrText = try await ocrService.recognizeText(inPages: pages)
            receipt.rawOCRText = ocrText

            for (index, image) in pages.enumerated() {
                if let data = image.jpegData(compressionQuality: 0.8) {
                    let attachment = DocumentAttachment(
                        attachmentType: .scannedDocument,
                        fileName: "scan_\(receipt.id.uuidString)_page\(index).jpg",
                        pageNumber: index
                    )
                    attachment.imageData = data
                    receipt.attachments.append(attachment)
                    modelContext.insert(attachment)
                }
            }

            processingStage = .extracting
            do {
                let extracted = try await extractionService.extract(from: ocrText)
                extractionService.apply(extracted, to: receipt)
            } catch let extractionError as ExtractionService.ExtractionError {
                // AI unavailable or failed — keep OCR text, let user fill manually
                errorMessage = extractionError.localizedDescription
            }

            try persistAndNotify()
        } catch {
            errorMessage = error.localizedDescription
            // Still attempt to save whatever we have
            try? persistAndNotify()
        }
    }

    func processPickedImage(_ image: UIImage) async {
        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false; processingStage = .idle }

        if let data = image.jpegData(compressionQuality: 0.8) {
            let attachment = DocumentAttachment(
                attachmentType: .photoLibraryImage,
                fileName: "photo_\(receipt.id.uuidString).jpg"
            )
            attachment.imageData = data
            receipt.attachments.append(attachment)
            modelContext.insert(attachment)
        }

        do {
            processingStage = .ocr
            let ocrText = try await ocrService.recognizeText(in: image)
            receipt.rawOCRText = ocrText

            processingStage = .extracting
            do {
                let extracted = try await extractionService.extract(from: ocrText)
                extractionService.apply(extracted, to: receipt)
            } catch let extractionError as ExtractionService.ExtractionError {
                errorMessage = extractionError.localizedDescription
            }

            try persistAndNotify()
        } catch {
            errorMessage = error.localizedDescription
            try? persistAndNotify()
        }
    }

    func saveManually() throws {
        try persistAndNotify()
    }

    // MARK: - Private

    private func persistAndNotify() throws {
        receipt.updatedAt = Date()
        processingStage = .saving

        if receipt.modelContext == nil {
            modelContext.insert(receipt)
        }
        try modelContext.save()

        Task {
            if receipt.warrantyInfo?.expirationDate != nil {
                await notificationService.scheduleWarrantyNotifications(
                    for: receipt,
                    context: modelContext
                )
            }
        }
    }
}
