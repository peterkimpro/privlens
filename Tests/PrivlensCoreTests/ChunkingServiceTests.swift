import Foundation
import Testing
@testable import PrivlensCore

@Suite("ChunkingService Tests")
struct ChunkingServiceTests {

    let service = ChunkingService()

    // MARK: - Empty text

    @Test("Empty text returns no chunks")
    func emptyText() {
        let chunks = service.chunkText("", configuration: .default)
        #expect(chunks.isEmpty)
    }

    // MARK: - Text shorter than chunk size

    @Test("Text shorter than chunk size returns single chunk")
    func shortText() {
        let text = "This is a short sentence."
        let chunks = service.chunkText(text, configuration: .default)
        #expect(chunks.count == 1)
        #expect(chunks[0].text == text)
        #expect(chunks[0].metadata.chunkIndex == 0)
        #expect(chunks[0].metadata.startOffset == 0)
        #expect(chunks[0].metadata.endOffset == text.count)
        #expect(chunks[0].metadata.overlapWithPrevious == 0)
    }

    // MARK: - Normal chunking with overlap

    @Test("Long text is split into multiple chunks with overlap")
    func normalChunking() {
        // Build text with many sentences, each ~50 chars, to exceed chunk size.
        let sentence = "This is a sentence that is roughly fifty chars. "
        let repeatCount = 100
        let text = String(repeating: sentence, count: repeatCount)

        let chunks = service.chunkText(text, configuration: ChunkingConfiguration(maxChunkSize: 500, chunkOverlap: 100, maxContextTokens: 4096))

        #expect(chunks.count > 1)

        // All text should be covered: first chunk starts at 0, last chunk ends at text length.
        #expect(chunks.first!.metadata.startOffset == 0)
        #expect(chunks.last!.metadata.endOffset == text.count)

        // Verify chunk indices are sequential.
        for (i, chunk) in chunks.enumerated() {
            #expect(chunk.metadata.chunkIndex == i)
        }

        // First chunk has no overlap; subsequent chunks should have some.
        #expect(chunks[0].metadata.overlapWithPrevious == 0)
        for chunk in chunks.dropFirst() {
            #expect(chunk.metadata.overlapWithPrevious > 0)
        }
    }

    // MARK: - Sentence boundary respect

    @Test("Chunks respect sentence boundaries")
    func sentenceBoundaryRespect() {
        let text = "First sentence. Second sentence. Third sentence. Fourth sentence."
        // Chunk size large enough for ~2 sentences but not all 4.
        let chunks = service.chunkText(text, configuration: ChunkingConfiguration(maxChunkSize: 35, chunkOverlap: 10, maxContextTokens: 4096))

        for chunk in chunks {
            // Each chunk should end at a sentence boundary (period + space or end of text).
            let trimmed = chunk.text.trimmingCharacters(in: .whitespaces)
            let lastChar = trimmed.last
            #expect(lastChar == "." || lastChar == "!" || lastChar == "?",
                    "Chunk text should end at a sentence boundary, got: \(chunk.text)")
        }
    }

    // MARK: - Very long sentence (exceeds chunk size)

    @Test("A single sentence longer than chunk size is not split mid-sentence")
    func veryLongSentence() {
        let longSentence = String(repeating: "a", count: 5000) + "."
        let chunks = service.chunkText(longSentence, configuration: .default)
        // The sentence is too long to split at a sentence boundary, so it
        // should be returned as a single chunk.
        #expect(chunks.count == 1)
        #expect(chunks[0].text == longSentence)
    }

    // MARK: - Source page index

    @Test("Source page index is recorded in chunk metadata")
    func sourcePageIndex() {
        let text = "A sentence on page two."
        let chunks = service.chunkText(text, configuration: .default, sourcePageIndex: 2)
        #expect(chunks.count == 1)
        #expect(chunks[0].metadata.sourcePageIndex == 2)
    }

    // MARK: - Sendable conformance

    @Test("TextChunk and ChunkMetadata are Sendable")
    func sendableConformance() {
        let metadata = ChunkMetadata(
            chunkIndex: 0,
            startOffset: 0,
            endOffset: 5,
            sourcePageIndex: nil,
            overlapWithPrevious: 0
        )
        let chunk = TextChunk(text: "Hello", metadata: metadata)

        // Verify Sendable by sending across a concurrency boundary.
        let _: any Sendable = chunk
        let _: any Sendable = metadata
    }

    // MARK: - Protocol-based testability

    @Test("ChunkingService conforms to ChunkingServiceProtocol")
    func protocolConformance() {
        let _: any ChunkingServiceProtocol = service
    }
}
