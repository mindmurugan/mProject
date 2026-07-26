import Foundation

/// Fetches public ratings for a wine from Vivino / CellarTracker / James Suckling search
/// results.
///
/// Important caveats, by design:
/// - None of these sites offer a free public API. This works by requesting their public
///   search page and looking for embedded schema.org `AggregateRating` structured data.
///   That is inherently fragile: it can break the moment a site changes its markup, and it
///   sits in a legal gray area against most sites' terms of service. Treat every result as
///   best-effort.
/// - Every lookup ALWAYS produces a usable `ExternalRating`, even on total failure — with
///   `score == nil` and `url` pointing at the site's own search page, so the UI can always
///   offer a "view on Vivino" style fallback link instead of a blank state.
/// - This deliberately does not attempt to defeat bot detection, CAPTCHAs, or rate limiting.
///   If a site blocks the request, we fall back to the deep link, we don't try harder.
actor ExternalRatingService {

    private let session: URLSession
    private let requestTimeout: TimeInterval = 8

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Looks up all three sources concurrently and returns whatever came back, live or not.
    func fetchRatings(for wine: Wine) async -> [ExternalRating] {
        await withTaskGroup(of: ExternalRating?.self) { group in
            for source in [RatingSource.vivino, .cellarTracker, .jamesSuckling] {
                group.addTask {
                    await self.fetchRating(for: wine, source: source)
                }
            }
            var results: [ExternalRating] = []
            for await result in group {
                if let result { results.append(result) }
            }
            return results
        }
    }

    private func fetchRating(for wine: Wine, source: RatingSource) async -> ExternalRating? {
        guard let url = wine.searchURL(for: source) else { return nil }
        let fallback = ExternalRating(source: source, url: url, wasFetchedLive: false)

        guard let html = try? await fetchHTML(url) else { return fallback }
        guard let parsed = Self.extractAggregateRating(fromHTML: html) else { return fallback }

        return ExternalRating(
            source: source,
            score: parsed.ratingValue,
            scaleMax: parsed.bestRating ?? Self.defaultScale(for: source),
            reviewCount: parsed.reviewCount,
            url: url,
            wasFetchedLive: true
        )
    }

    private func fetchHTML(_ url: URL) async throws -> String {
        var request = URLRequest(url: url, timeoutInterval: requestTimeout)
        request.setValue(
            "Mozilla/5.0 (compatible; SommPro/1.0; +personal wine journal app)",
            forHTTPHeaderField: "User-Agent"
        )
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        guard let html = String(data: data, encoding: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }
        return html
    }

    private static func defaultScale(for source: RatingSource) -> Double {
        switch source {
        case .vivino, .cellarTracker: 5.0
        case .jamesSuckling: 100.0
        case .other: 100.0
        }
    }

    struct ParsedAggregateRating {
        var ratingValue: Double?
        var bestRating: Double?
        var reviewCount: Int?
    }

    /// Scans `<script type="application/ld+json">` blocks for a schema.org `aggregateRating`
    /// object, generically — no site-specific HTML parsing, since that's the part most
    /// likely to rot.
    static func extractAggregateRating(fromHTML html: String) -> ParsedAggregateRating? {
        let scriptBlocks = matches(
            in: html,
            pattern: #"<script[^>]*type=["']application/ld\+json["'][^>]*>(.*?)</script>"#
        )

        for block in scriptBlocks {
            guard let data = block.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) else { continue }
            if let rating = findAggregateRating(in: json) {
                return rating
            }
        }
        return nil
    }

    private static func findAggregateRating(in json: Any) -> ParsedAggregateRating? {
        if let dict = json as? [String: Any] {
            if let ratingDict = dict["aggregateRating"] as? [String: Any] {
                return ParsedAggregateRating(
                    ratingValue: number(ratingDict["ratingValue"]),
                    bestRating: number(ratingDict["bestRating"]),
                    reviewCount: number(ratingDict["reviewCount"] ?? ratingDict["ratingCount"]).map(Int.init)
                )
            }
            for value in dict.values {
                if let found = findAggregateRating(in: value) { return found }
            }
        } else if let array = json as? [Any] {
            for element in array {
                if let found = findAggregateRating(in: element) { return found }
            }
        }
        return nil
    }

    private static func number(_ value: Any?) -> Double? {
        if let double = value as? Double { return double }
        if let int = value as? Int { return Double(int) }
        if let string = value as? String { return Double(string) }
        return nil
    }

    private static func matches(in text: String, pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators, .caseInsensitive]) else {
            return []
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            guard let groupRange = Range(match.range(at: 1), in: text) else { return nil }
            return String(text[groupRange])
        }
    }
}
