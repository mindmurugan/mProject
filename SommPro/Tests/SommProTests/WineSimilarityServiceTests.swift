import XCTest
@testable import SommPro

final class WineSimilarityServiceTests: XCTestCase {

    func testCosineSimilarityOfIdenticalVectorsIsOne() {
        let service = WineSimilarityService()
        let vector = [0.1, 0.2, 0.3, 0.4]
        XCTAssertEqual(service.cosineSimilarity(vector, vector), 1.0, accuracy: 0.0001)
    }

    func testCosineSimilarityOfOrthogonalVectorsIsZero() {
        let service = WineSimilarityService()
        XCTAssertEqual(service.cosineSimilarity([1, 0], [0, 1]), 0.0, accuracy: 0.0001)
    }

    func testCosineSimilarityHandlesMismatchedLengthsGracefully() {
        let service = WineSimilarityService()
        XCTAssertEqual(service.cosineSimilarity([1, 0], [1, 0, 0]), 0.0)
    }

    func testCosineSimilarityHandlesZeroVectorGracefully() {
        let service = WineSimilarityService()
        XCTAssertEqual(service.cosineSimilarity([0, 0], [1, 1]), 0.0)
    }
}
