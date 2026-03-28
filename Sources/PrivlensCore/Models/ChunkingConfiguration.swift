import Foundation

// MARK: - ChunkingConfiguration

/// Centralized configuration for text chunking and AI context window limits.
///
/// All values have sensible defaults matching the current on-device Apple Foundation
/// Models constraints (~4K token context). When TurboQuant integration lands
/// (24K+ token context), update `defaultTurboQuant` or create a new preset and
/// inject it at the call site — no other code changes required.
public struct ChunkingConfiguration: Sendable, Equatable {

    // MARK: - Properties

    /// Target chunk size in characters. Each chunk will contain roughly this many
    /// characters (splitting at sentence boundaries).
    public let maxChunkSize: Int

    /// Number of overlapping characters between consecutive chunks. Overlap
    /// preserves context across chunk boundaries so insights that span two
    /// chunks are not lost.
    public let chunkOverlap: Int

    /// Maximum number of tokens the model's context window can accept.
    /// Used to validate that prompt + chunk fit within the model's limits.
    /// For the current on-device model this is ~4 096 tokens.
    public let maxContextTokens: Int

    /// Approximate characters-per-token ratio used when converting between
    /// character counts and token estimates. English text averages ~4 chars
    /// per token; adjust for other languages or tokenizers.
    public let charsPerToken: Double

    // MARK: - Initializer

    public init(
        maxChunkSize: Int = 4000,
        chunkOverlap: Int = 200,
        maxContextTokens: Int = 4096,
        charsPerToken: Double = 4.0
    ) {
        precondition(maxChunkSize > 0, "maxChunkSize must be positive")
        precondition(chunkOverlap >= 0, "chunkOverlap must be non-negative")
        precondition(chunkOverlap < maxChunkSize, "chunkOverlap must be less than maxChunkSize")
        precondition(maxContextTokens > 0, "maxContextTokens must be positive")
        precondition(charsPerToken > 0, "charsPerToken must be positive")

        self.maxChunkSize = maxChunkSize
        self.chunkOverlap = chunkOverlap
        self.maxContextTokens = maxContextTokens
        self.charsPerToken = charsPerToken
    }

    // MARK: - Presets

    /// Default configuration for the current on-device Apple Foundation Models
    /// (~4K token context window).
    public static let `default` = ChunkingConfiguration()

    /// Preset for TurboQuant integration (24K+ token context window).
    /// TODO: Finalize these values once TurboQuant model specs are confirmed.
    public static let turboQuant = ChunkingConfiguration(
        maxChunkSize: 20000,
        chunkOverlap: 500,
        maxContextTokens: 24576,
        charsPerToken: 4.0
    )

    // MARK: - Derived helpers

    /// Estimated maximum chunk size in tokens.
    public var estimatedMaxChunkTokens: Int {
        Int(Double(maxChunkSize) / charsPerToken)
    }
}
