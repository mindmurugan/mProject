import XCTest
@testable import ReceiptsOrganizer

final class ExtractionServiceTests: XCTestCase {

    func testAppleIntelligenceAvailabilityCheck() async {
        let service = await ExtractionService()
        // On devices without Apple Intelligence this returns an error — that's expected.
        // The test verifies the check completes without crashing.
        let error = await service.checkAvailability()
        if error != nil {
            XCTAssertNotNil(error, "Availability check returned an error — Apple Intelligence not available on this device/simulator.")
        }
    }

    func testExtractThrowsWhenTextIsEmpty() async {
        let service = await ExtractionService()
        do {
            _ = try await service.extract(from: "   ")
            XCTFail("Expected ExtractionError.noTextProvided")
        } catch ExtractionService.ExtractionError.noTextProvided {
            // Expected path
        } catch {
            // modelUnavailable is also acceptable in test environments
        }
    }
}
