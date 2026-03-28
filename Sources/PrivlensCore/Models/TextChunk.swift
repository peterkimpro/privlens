import Foundation

// MARK: - ChunkMetadata

/// Metadata describing the position and context of a text chunk within a source document.
public struct ChunkMetadata: Codable, Sendable, Equatable {
    /// Zero-based index of this chunk in the sequence.
    public let chunkIndex: Int
    /// Character offset where this chunk starts in the original text.
    public let startOffset: Int
    /// Character offset where this chunk ends in the original text (exclusive).
    public let endOffset: Int
    /// Index of the source page this chunk originated from, if known.
    public let sourcePageIndex: Int?
    /// Number of overlapping characters shared with the previous chunk.
    public let overlapWithPrevious: Int

    public init(
        chunkIndex: Int,
        startOffset: Int,
        endOffset: Int,
        sourcePageIndex: Int? = nil,
        overlapWithPrevious: Int = 0
    ) {
        self.chunkIndex = chunkIndex
        self.startOffset = startOffset
        self.endOffset = endOffset
        self.sourcePageIndex = sourcePageIndex
        self.overlapWithPrevious = overlapWithPrevious
    }
}

// MARK: - TextChunk

/// A chunk of text extracted from a larger document, suitable for AI processing.
public struct TextChunk: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    /// The chunk's text content.
    public let text: String
    /// Positional metadata for this chunk.
    public let metadata: ChunkMetadata

    public init(
        id: UUID = UUID(),
        text: String,
        metadata: ChunkMetadata
    ) {
        self.id = id
        self.text = text
        self.metadata = metadata
    }
}
