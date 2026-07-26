import Foundation
import SwiftUI
import UIKit
import SwiftData
import Observation

@MainActor
@Observable
final class ScannerViewModel {
    var mode: ScanMode = .drink
    var isProcessing = false
    var errorMessage: String?
    var shopQueue: [ScanOutcome] = []
    var menuCandidates: [WineIdentification] = []
    var activeOutcome: ScanOutcome?

    let enrichmentCoordinator: EnrichmentCoordinator
    private let visionService = VisionScanService()
    private let locationService = LocationTaggingService()

    struct ScanOutcome: Identifiable {
        let id = UUID()
        var identification: WineIdentification
        var barcode: String?
        var location: TaggedLocation?
        var matchResult: WineMatchResult
        var mode: ScanMode
    }

    init(enrichmentCoordinator: EnrichmentCoordinator) {
        self.enrichmentCoordinator = enrichmentCoordinator
        locationService.requestAuthorizationIfNeeded()
    }

    func handleCapturedImage(_ image: UIImage, modelContext: ModelContext) async {
        isProcessing = true
        defer { isProcessing = false }

        do {
            if mode == .menu {
                let lines = try await visionService.scanMenu(from: image)
                menuCandidates = await enrichmentCoordinator.identifyWines(fromMenuLines: lines)
                return
            }

            let label = try await visionService.scanLabel(from: image)
            let identification = await enrichmentCoordinator.identifyWine(
                fromOCRText: label.joinedText,
                barcode: label.barcodes.first
            )
            async let locationTag = locationService.currentTag()

            let matching = WineMatchingService(modelContext: modelContext)
            let matchResult = try matching.match(identification: identification, barcode: label.barcodes.first)

            let outcome = ScanOutcome(
                identification: identification,
                barcode: label.barcodes.first,
                location: await locationTag,
                matchResult: matchResult,
                mode: mode
            )

            if mode == .shop {
                shopQueue.append(outcome)
            }
            activeOutcome = outcome
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Called when the user taps one of the wines parsed out of a scanned menu — runs the
    /// same local dedup/similarity match a bottle scan would.
    func resolveMenuCandidate(_ identification: WineIdentification, modelContext: ModelContext) async -> ScanOutcome? {
        do {
            let matching = WineMatchingService(modelContext: modelContext)
            let matchResult = try matching.match(identification: identification, barcode: nil)
            let location = await locationService.currentTag()
            let outcome = ScanOutcome(
                identification: identification,
                barcode: nil,
                location: location,
                matchResult: matchResult,
                mode: .menu
            )
            activeOutcome = outcome
            return outcome
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
