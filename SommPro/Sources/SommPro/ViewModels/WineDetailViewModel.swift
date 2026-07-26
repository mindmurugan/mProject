import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class WineDetailViewModel {
    let outcome: ScannerViewModel.ScanOutcome
    let enrichmentCoordinator: EnrichmentCoordinator

    var externalRatings: [ExternalRating] = []
    var education: WineEducation?
    var isLoadingRatings = true
    var isLoadingEducation = true

    var similarWines: [WineSimilarityService.Neighbor] {
        if case .newWine(let nearest) = outcome.matchResult { return nearest }
        return []
    }

    var previouslyScannedWine: Wine? {
        if case .previouslyScanned(let wine) = outcome.matchResult { return wine }
        return nil
    }

    var personalRating: Double = 3.5
    var notes = ""
    var tagsText = ""
    var logTasting: Bool
    var addToCellar: Bool
    var purchasePrice = ""
    var cellarSlot = ""
    var quantity = 1
    var saveConfirmed = false

    private let ratingService = ExternalRatingService()

    init(outcome: ScannerViewModel.ScanOutcome, enrichmentCoordinator: EnrichmentCoordinator) {
        self.outcome = outcome
        self.enrichmentCoordinator = enrichmentCoordinator
        self.logTasting = outcome.mode != .shop
        self.addToCellar = outcome.mode == .shop
    }

    func loadDetails() async {
        let transientWine = Self.transientWine(from: outcome.identification)
        async let ratings = ratingService.fetchRatings(for: transientWine)
        async let ed = enrichmentCoordinator.educate(
            producerName: outcome.identification.producerName ?? outcome.identification.wineName,
            region: outcome.identification.region,
            varietals: outcome.identification.varietals
        )
        externalRatings = await ratings
        isLoadingRatings = false
        education = await ed
        isLoadingEducation = false
    }

    static func transientWine(from identification: WineIdentification) -> Wine {
        let producer = identification.producerName.map { Producer(name: $0) }
        return Wine(
            name: identification.wineName,
            producer: producer,
            varietals: identification.varietals,
            wineType: identification.wineType,
            region: identification.region,
            country: identification.country
        )
    }

    /// Persists the scan: finds-or-creates the Producer/Wine/Vintage graph (reusing the
    /// matched wine when this was a re-scan), then optionally records a cellar bottle and/or
    /// a tasting event depending on what the user filled in.
    func save(modelContext: ModelContext) {
        let wine = resolveWine(modelContext: modelContext)
        let vintage = resolveVintage(for: wine, modelContext: modelContext)

        for rating in externalRatings {
            rating.vintage = vintage
            modelContext.insert(rating)
        }

        var bottle: Bottle?
        if addToCellar {
            let newBottle = Bottle(
                vintage: vintage,
                quantity: quantity,
                purchasePrice: Double(purchasePrice),
                purchaseLocation: outcome.location,
                cellarSlot: cellarSlot.isEmpty ? nil : cellarSlot,
                acquiredViaMode: outcome.mode
            )
            modelContext.insert(newBottle)
            bottle = newBottle
        }

        if logTasting {
            let tags = tagsText
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            let event = TastingEvent(
                vintage: vintage,
                mode: outcome.mode,
                personalRating: personalRating,
                notes: notes.isEmpty ? nil : notes,
                tags: tags,
                location: outcome.location,
                bottle: bottle
            )
            modelContext.insert(event)
        }

        try? modelContext.save()
        saveConfirmed = true
    }

    private func resolveWine(modelContext: ModelContext) -> Wine {
        if case .previouslyScanned(let existing) = outcome.matchResult {
            return existing
        }
        let producer = outcome.identification.producerName.map(Producer.init(name:))
        if let producer { modelContext.insert(producer) }
        let wine = Wine(
            name: outcome.identification.wineName,
            producer: producer,
            varietals: outcome.identification.varietals,
            wineType: outcome.identification.wineType,
            region: outcome.identification.region,
            country: outcome.identification.country,
            barcode: outcome.barcode
        )
        wine.profileEmbedding = WineSimilarityService().embed(wine.normalizedProfile)
        modelContext.insert(wine)
        return wine
    }

    private func resolveVintage(for wine: Wine, modelContext: ModelContext) -> Vintage {
        let year = outcome.identification.vintageYear ?? 0
        if let existing = wine.vintages.first(where: { $0.year == year }) {
            return existing
        }
        let vintage = Vintage(year: year, wine: wine)
        modelContext.insert(vintage)
        return vintage
    }
}
