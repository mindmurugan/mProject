import Foundation
import UniformTypeIdentifiers
import SwiftData
import HearthKit

/// Turns whatever Safari/Photos/Files handed the share sheet into a
/// `CapturedItem` and saves it straight into the shared App Group store --
/// no need to open the app. `HearthApp` picks it up on next launch/refresh
/// because it points at the same SwiftData store via the App Group.
enum ShareExtensionProcessor {
    static func process(_ extensionItems: [NSExtensionItem]) async {
        guard let container = try? HearthSchema.makeContainer() else { return }
        let context = ModelContext(container)

        let descriptor = FetchDescriptor<Household>()
        let household = (try? context.fetch(descriptor))?.first

        for item in extensionItems {
            for provider in item.attachments ?? [] {
                if let captured = await capturedItem(from: provider) {
                    captured.household = household
                    context.insert(captured)
                }
            }
        }

        try? context.save()
    }

    private static func capturedItem(from provider: NSItemProvider) async -> CapturedItem? {
        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            if let url = try? await provider.loadItem(forTypeIdentifier: UTType.url.identifier) as? URL {
                return CapturedItem(contentType: .link, rawText: url.absoluteString, sourceTitle: url.host)
            }
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            if let data = try? await loadData(from: provider, typeIdentifier: UTType.image.identifier) {
                return CapturedItem(contentType: .image, imageData: data)
            }
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            if let text = try? await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) as? String {
                return CapturedItem(contentType: .text, rawText: text)
            }
        }

        if provider.hasItemConformingToTypeIdentifier(UTType.data.identifier) {
            if let data = try? await loadData(from: provider, typeIdentifier: UTType.data.identifier) {
                return CapturedItem(contentType: .file, rawText: nil, imageData: data)
            }
        }

        return nil
    }

    private static func loadData(from provider: NSItemProvider, typeIdentifier: String) async throws -> Data? {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: data)
                }
            }
        }
    }
}
