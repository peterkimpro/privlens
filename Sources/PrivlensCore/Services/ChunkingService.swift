import Foundation

// MARK: - ChunkingServiceProtocol

/// Protocol for text chunking services, enabling testability.
public protocol ChunkingServiceProtocol: Sendable {
    /// Splits text into overlapping chunks that respect sentence boundaries.
    ///
    /// - Parameters:
    ///   - text: The full text to chunk.
    ///   - configuration: Chunking parameters (chunk size, overlap, etc.).
    ///   - sourcePageIndex: Optional page index to record in chunk metadata.
    /// - Returns: An array of `TextChunk` values covering the entire input text.
    func chunkText(
        _ text: String,
        configuration: ChunkingConfiguration,
        sourcePageIndex: Int?
    ) -> [TextChunk]
}

// MARK: - ChunkingService

public final class ChunkingService: ChunkingServiceProtocol, Sendable {

    public init() {}

    public func chunkText(
        _ text: String,
        configuration: ChunkingConfiguration = .default,
        sourcePageIndex: Int? = nil
    ) -> [TextChunk] {
        let chunkSize = configuration.maxChunkSize
        let overlap = configuration.chunkOverlap

        guard !text.isEmpty else { return [] }

        // If the entire text fits in one chunk, return it directly.
        if text.count <= chunkSize {
            let metadata = ChunkMetadata(
                chunkIndex: 0,
                startOffset: 0,
                endOffset: text.count,
                sourcePageIndex: sourcePageIndex,
                overlapWithPrevious: 0
            )
            return [TextChunk(text: text, metadata: metadata)]
        }

        let sentences = splitIntoSentences(text)
        var chunks: [TextChunk] = []
        var sentenceIndex = 0

        while sentenceIndex < sentences.count {
            var chunkText = ""
            var chunkStartOffset: Int?
            var chunkEndOffset = 0
            let startSentenceIndex = sentenceIndex

            // Accumulate sentences until we reach the chunk size target.
            while sentenceIndex < sentences.count {
                let sentence = sentences[sentenceIndex]
                if chunkStartOffset == nil {
                    chunkStartOffset = sentence.startOffset
                }

                let candidateLength = chunkText.count + sentence.text.count
                // If adding this sentence would exceed the chunk size and we already
                // have some content, stop here — unless this is the very first sentence
                // in the chunk (handles sentences longer than chunkSize).
                if candidateLength > chunkSize && !chunkText.isEmpty {
                    break
                }

                chunkText += sentence.text
                chunkEndOffset = sentence.endOffset
                sentenceIndex += 1
            }

            // Calculate overlap with previous chunk.
            let overlapAmount: Int
            if chunks.isEmpty {
                overlapAmount = 0
            } else {
                overlapAmount = chunkStartOffset.map { start in
                    let previousEnd = chunks.last!.metadata.endOffset
                    return max(0, previousEnd - start)
                } ?? 0
            }

            let metadata = ChunkMetadata(
                chunkIndex: chunks.count,
                startOffset: chunkStartOffset ?? 0,
                endOffset: chunkEndOffset,
                sourcePageIndex: sourcePageIndex,
                overlapWithPrevious: overlapAmount
            )
            chunks.append(TextChunk(text: chunkText, metadata: metadata))

            // If we've consumed all sentences, we're done.
            if sentenceIndex >= sentences.count {
                break
            }

            // Back up to create overlap: rewind sentences until we've accumulated
            // roughly `overlap` characters of overlap.
            var overlapChars = 0
            var rewindIndex = sentenceIndex - 1
            while rewindIndex >= startSentenceIndex && overlapChars < overlap {
                overlapChars += sentences[rewindIndex].text.count
                rewindIndex -= 1
            }
            // Start the next chunk from the sentence after the rewind point.
            sentenceIndex = rewindIndex + 1

            // Safety: make sure we always advance to avoid infinite loops.
            if sentenceIndex <= startSentenceIndex {
                sentenceIndex = startSentenceIndex + 1
            }
        }

        return chunks
    }

    // MARK: - Private helpers

    /// A sentence extracted from the source text, with its character offsets.
    private struct SentenceSpan {
        let text: String
        let startOffset: Int
        let endOffset: Int
    }

    /// Splits text into sentences by looking for sentence-ending punctuation
    /// followed by whitespace or end-of-string.
    private func splitIntoSentences(_ text: String) -> [SentenceSpan] {
        var sentences: [SentenceSpan] = []
        var currentStart = text.startIndex
        var index = text.startIndex

        while index < text.endIndex {
            let char = text[index]
            let nextIndex = text.index(after: index)

            let isSentenceEnd = (char == "." || char == "!" || char == "?")
            let atEnd = nextIndex == text.endIndex
            let followedByWhitespace = !atEnd && (text[nextIndex].isWhitespace || text[nextIndex].isNewline)

            if isSentenceEnd && (atEnd || followedByWhitespace) {
                // Include trailing whitespace in this sentence so chunks
                // don't start with stray spaces.
                var sentenceEnd = nextIndex
                while sentenceEnd < text.endIndex && text[sentenceEnd].isWhitespace {
                    sentenceEnd = text.index(after: sentenceEnd)
                }

                let sentenceText = String(text[currentStart..<sentenceEnd])
                let startOffset = text.distance(from: text.startIndex, to: currentStart)
                let endOffset = text.distance(from: text.startIndex, to: sentenceEnd)
                sentences.append(SentenceSpan(text: sentenceText, startOffset: startOffset, endOffset: endOffset))
                currentStart = sentenceEnd
                index = sentenceEnd
            } else {
                index = nextIndex
            }
        }

        // If there's remaining text after the last sentence boundary, add it as a final sentence.
        if currentStart < text.endIndex {
            let remaining = String(text[currentStart..<text.endIndex])
            let startOffset = text.distance(from: text.startIndex, to: currentStart)
            let endOffset = text.count
            sentences.append(SentenceSpan(text: remaining, startOffset: startOffset, endOffset: endOffset))
        }

        return sentences
    }
}
