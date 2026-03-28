import Foundation

// MARK: - AttributionServiceProtocol

/// Protocol for services that find source attributions linking insights to original document text.
public protocol AttributionServiceProtocol: Sendable {
    /// Finds source text spans in the given chunks that correspond to the insight.
    func findAttributions(for insight: Insight, in chunks: [TextChunk]) -> [SourceAttribution]
}

// MARK: - AttributionService

/// Default implementation that uses fuzzy keyword matching to locate insight text in document chunks.
public final class AttributionService: AttributionServiceProtocol, Sendable {

    /// Minimum keyword length to consider for matching.
    private let minimumKeywordLength: Int

    public init(minimumKeywordLength: Int = 4) {
        self.minimumKeywordLength = minimumKeywordLength
    }

    public func findAttributions(for insight: Insight, in chunks: [TextChunk]) -> [SourceAttribution] {
        let keywords = extractKeywords(from: insight)
        guard !keywords.isEmpty else { return [] }

        var attributions: [SourceAttribution] = []

        for chunk in chunks {
            let chunkTextLower = chunk.text.lowercased()

            for keyword in keywords {
                let keywordLower = keyword.lowercased()
                var searchStart = chunkTextLower.startIndex

                while searchStart < chunkTextLower.endIndex,
                      let range = chunkTextLower.range(of: keywordLower, range: searchStart..<chunkTextLower.endIndex) {

                    let startOffset = chunkTextLower.distance(from: chunkTextLower.startIndex, to: range.lowerBound)
                    let endOffset = chunkTextLower.distance(from: chunkTextLower.startIndex, to: range.upperBound)

                    // Extract the original-cased matched text from the chunk.
                    let matchedText = String(chunk.text[range])

                    let attribution = SourceAttribution(
                        chunkIndex: chunk.metadata.chunkIndex,
                        startOffset: startOffset,
                        endOffset: endOffset,
                        matchedText: matchedText,
                        pageIndex: chunk.metadata.sourcePageIndex
                    )

                    // Avoid duplicate attributions for the same span in the same chunk.
                    if !attributions.contains(attribution) {
                        attributions.append(attribution)
                    }

                    searchStart = range.upperBound
                }
            }
        }

        return attributions
    }

    // MARK: - Private Helpers

    /// Extracts meaningful keywords from an insight's title and description.
    private func extractKeywords(from insight: Insight) -> [String] {
        let combinedText = "\(insight.title) \(insight.description)"

        let stopWords: Set<String> = [
            "the", "a", "an", "is", "are", "was", "were", "be", "been", "being",
            "have", "has", "had", "do", "does", "did", "will", "would", "could",
            "should", "may", "might", "shall", "can", "need", "dare", "ought",
            "used", "to", "of", "in", "for", "on", "with", "at", "by", "from",
            "as", "into", "through", "during", "before", "after", "above", "below",
            "between", "out", "off", "over", "under", "again", "further", "then",
            "once", "that", "this", "these", "those", "and", "but", "or", "nor",
            "not", "so", "very", "just", "about", "also", "than", "too", "each",
            "which", "who", "whom", "what", "here", "there", "when", "where",
            "why", "how", "all", "both", "few", "more", "most", "other", "some",
            "such", "only", "own", "same", "its", "it", "they", "them", "their",
            "you", "your", "we", "our", "he", "she", "his", "her",
        ]

        let words = combinedText.components(separatedBy: .alphanumerics.inverted)
            .filter { $0.count >= minimumKeywordLength }
            .filter { !stopWords.contains($0.lowercased()) }

        // Deduplicate while preserving order.
        var seen = Set<String>()
        var unique: [String] = []
        for word in words {
            let lower = word.lowercased()
            if seen.insert(lower).inserted {
                unique.append(word)
            }
        }

        return unique
    }
}
