import SwiftData
import Foundation

@Model
final class DocumentAttachment {
    var id: UUID
    var createdAt: Date
    var attachmentType: AttachmentType
    var fileName: String
    var pageNumber: Int

    // Stored outside the SQLite store to keep the DB lean.
    // SwiftData only loads this data when the property is accessed.
    @Attribute(.externalStorage)
    var imageData: Data?

    var receipt: Receipt?

    init(attachmentType: AttachmentType, fileName: String, pageNumber: Int = 0) {
        self.id = UUID()
        self.createdAt = Date()
        self.attachmentType = attachmentType
        self.fileName = fileName
        self.pageNumber = pageNumber
    }
}

enum AttachmentType: String, Codable {
    case scannedDocument
    case photoLibraryImage
    case cameraPhoto

    var displayName: String {
        switch self {
        case .scannedDocument: return "Scanned Document"
        case .photoLibraryImage: return "Photo Library"
        case .cameraPhoto: return "Camera Photo"
        }
    }
}
