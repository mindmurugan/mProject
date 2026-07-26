import XCTest
import SwiftData
@testable import SommPro

@MainActor
final class WineMatchingServiceTests: XCTestCase {

    private func makeInMemoryContext() throws -> ModelContext {
        let schema = Schema([Producer.self, Wine.self, Vintage.self, Bottle.self, TastingEvent.self, ExternalRating.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    func testExactBarcodeMatchIsRecognizedAsPreviouslyScanned() throws {
        let context = try makeInMemoryContext()
        let wine = Wine(name: "Reserve Cabernet Sauvignon", wineType: .red, barcode: "012345678905")
        context.insert(wine)

        let service = WineMatchingService(modelContext: context)
        let identification = WineIdentification(
            producerName: nil,
            wineName: "Something Else Entirely",
            vintageYear: nil,
            varietals: [],
            region: nil,
            country: nil,
            wineType: .red,
            sourceMenuLine: nil,
            confidence: 0.9
        )

        let result = try service.match(identification: identification, barcode: "012345678905")

        guard case .previouslyScanned(let matched) = result else {
            return XCTFail("Expected a barcode match")
        }
        XCTAssertEqual(matched.name, "Reserve Cabernet Sauvignon")
    }

    func testUnseenWineWithNoRatedHistoryReturnsNoNeighbors() throws {
        let context = try makeInMemoryContext()
        let service = WineMatchingService(modelContext: context)
        let identification = WineIdentification(
            producerName: "Brand New Winery",
            wineName: "Debut Pinot Noir",
            vintageYear: 2023,
            varietals: ["Pinot Noir"],
            region: "Willamette Valley",
            country: "USA",
            wineType: .red,
            sourceMenuLine: nil,
            confidence: 0.8
        )

        let result = try service.match(identification: identification, barcode: nil)

        guard case .newWine(let nearest) = result else {
            return XCTFail("Expected a new-wine result")
        }
        XCTAssertTrue(nearest.isEmpty)
    }
}
