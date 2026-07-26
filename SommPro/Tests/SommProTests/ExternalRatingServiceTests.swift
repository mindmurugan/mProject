import XCTest
@testable import SommPro

final class ExternalRatingServiceTests: XCTestCase {

    func testExtractsAggregateRatingFromJSONLD() {
        let html = """
        <html><head>
        <script type="application/ld+json">
        {
          "@context": "https://schema.org",
          "@type": "Product",
          "name": "Example Cabernet 2019",
          "aggregateRating": {
            "@type": "AggregateRating",
            "ratingValue": "4.3",
            "bestRating": "5",
            "reviewCount": "128"
          }
        }
        </script>
        </head><body></body></html>
        """

        let result = ExternalRatingService.extractAggregateRating(fromHTML: html)

        XCTAssertEqual(result?.ratingValue, 4.3)
        XCTAssertEqual(result?.bestRating, 5)
        XCTAssertEqual(result?.reviewCount, 128)
    }

    func testReturnsNilWhenNoStructuredDataPresent() {
        let html = "<html><body><p>No structured data here</p></body></html>"
        XCTAssertNil(ExternalRatingService.extractAggregateRating(fromHTML: html))
    }

    func testReturnsNilOnMalformedJSON() {
        let html = """
        <script type="application/ld+json">{ not valid json </script>
        """
        XCTAssertNil(ExternalRatingService.extractAggregateRating(fromHTML: html))
    }

    func testFindsAggregateRatingNestedInGraphArray() {
        let html = """
        <script type="application/ld+json">
        {
          "@graph": [
            { "@type": "WebPage" },
            { "@type": "Product", "aggregateRating": { "ratingValue": 92, "bestRating": 100 } }
          ]
        }
        </script>
        """

        let result = ExternalRatingService.extractAggregateRating(fromHTML: html)

        XCTAssertEqual(result?.ratingValue, 92)
        XCTAssertEqual(result?.bestRating, 100)
    }
}
