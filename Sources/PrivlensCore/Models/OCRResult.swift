import Foundation

// MARK: - OCRRecognitionLevel

/// Controls the trade-off between speed and accuracy for text recognition.
public enum OCRRecognitionLevel: Sendable {
    /// Prioritizes accuracy — slower but more precise. Best for documents.
    case accurate
    /// Prioritizes speed — faster but may miss details. Best for real-time previews.
    case fast
}

// MARK: - OCRTextRegion

/// A region of recognized text with its bounding box and confidence score.
public struct OCRTextRegion: Codable, Sendable, Identifiable {
    public let id: UUID
    /// The recognized text string.
    public let text: String
    /// Confidence score from 0.0 to 1.0.
    public let confidence: Float
    /// Normalized bounding box (origin bottom-left, values 0–1).
    public let boundingBox: CGRect

    public init(
        id: UUID = UUID(),
        text: String,
        confidence: Float,
        boundingBox: CGRect
    ) {
        self.id = id
        self.text = text
        self.confidence = confidence
        self.boundingBox = boundingBox
    }
}

// MARK: - OCRResult

/// Complete result of an OCR extraction pass.
public struct OCRResult: Codable, Sendable {
    /// Full extracted text (all regions joined by newlines).
    public let text: String
    /// Average confidence across all recognized regions.
    public let averageConfidence: Float
    /// Individual text regions with bounding boxes and per-region confidence.
    public let regions: [OCRTextRegion]
    /// Recognition level used for this extraction.
    public let recognitionLevel: String
    /// Whether language correction was applied.
    public let languageCorrectionApplied: Bool

    public init(
        text: String,
        averageConfidence: Float,
        regions: [OCRTextRegion],
        recognitionLevel: String,
        languageCorrectionApplied: Bool
    ) {
        self.text = text
        self.averageConfidence = averageConfidence
        self.regions = regions
        self.recognitionLevel = recognitionLevel
        self.languageCorrectionApplied = languageCorrectionApplied
    }

    /// An empty result with no recognized text.
    public static let empty = OCRResult(
        text: "",
        averageConfidence: 0,
        regions: [],
        recognitionLevel: "accurate",
        languageCorrectionApplied: false
    )
}
