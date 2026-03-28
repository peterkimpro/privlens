import Foundation

#if canImport(Vision)
import Vision
import CoreGraphics

/// Protocol for OCR services, enabling testability.
public protocol OCRServiceProtocol: Sendable {
    func extractText(from image: CGImage, recognitionLevel: OCRRecognitionLevel, languageCorrection: Bool) async throws -> OCRResult
}

public final class OCRService: OCRServiceProtocol, Sendable {

    public init() {}

    /// Extracts text from a CGImage with full OCR pipeline control.
    ///
    /// - Parameters:
    ///   - image: The source image to extract text from.
    ///   - recognitionLevel: `.accurate` (default) for best quality, `.fast` for speed.
    ///   - languageCorrection: Whether to apply language correction (default `true`).
    /// - Returns: An `OCRResult` with extracted text, confidence scores, and bounding boxes.
    public func extractText(
        from image: CGImage,
        recognitionLevel: OCRRecognitionLevel = .accurate,
        languageCorrection: Bool = true
    ) async throws -> OCRResult {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: OCRError.recognitionFailed(error.localizedDescription))
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: .empty)
                    return
                }

                let regions: [OCRTextRegion] = observations.compactMap { observation in
                    guard let candidate = observation.topCandidates(1).first else { return nil }
                    return OCRTextRegion(
                        text: candidate.string,
                        confidence: candidate.confidence,
                        boundingBox: observation.boundingBox
                    )
                }

                let fullText = regions.map(\.text).joined(separator: "\n")
                let avgConfidence: Float = regions.isEmpty ? 0 : regions.reduce(0) { $0 + $1.confidence } / Float(regions.count)
                let levelName = recognitionLevel == .accurate ? "accurate" : "fast"

                let result = OCRResult(
                    text: fullText,
                    averageConfidence: avgConfidence,
                    regions: regions,
                    recognitionLevel: levelName,
                    languageCorrectionApplied: languageCorrection
                )
                continuation.resume(returning: result)
            }

            switch recognitionLevel {
            case .accurate:
                request.recognitionLevel = .accurate
            case .fast:
                request.recognitionLevel = .fast
            }
            request.usesLanguageCorrection = languageCorrection
            request.revision = VNRecognizeTextRequestRevision3

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.recognitionFailed(error.localizedDescription))
            }
        }
    }

    /// Convenience: extracts text from raw image data (JPEG or PNG).
    public func extractText(
        from imageData: Data,
        recognitionLevel: OCRRecognitionLevel = .accurate,
        languageCorrection: Bool = true
    ) async throws -> OCRResult {
        guard let dataProvider = CGDataProvider(data: imageData as CFData),
              let cgImage = CGImage(
                  jpegDataProviderSource: dataProvider,
                  decode: nil,
                  shouldInterpolate: true,
                  intent: .defaultIntent
              ) ?? CGImage(
                  pngDataProviderSource: dataProvider,
                  decode: nil,
                  shouldInterpolate: true,
                  intent: .defaultIntent
              )
        else {
            throw OCRError.invalidImageData
        }
        return try await extractText(from: cgImage, recognitionLevel: recognitionLevel, languageCorrection: languageCorrection)
    }

    /// Legacy convenience: returns just the extracted text string.
    public func extractTextString(from image: CGImage) async throws -> String {
        let result = try await extractText(from: image)
        return result.text
    }
}

public enum OCRError: Error, LocalizedError, Sendable {
    case invalidImageData
    case recognitionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "The provided image data could not be decoded."
        case .recognitionFailed(let reason):
            return "Text recognition failed: \(reason)"
        }
    }
}

#else

// MARK: - Linux / non-Apple platform stubs

/// Protocol for OCR services (stub for non-Apple platforms).
public protocol OCRServiceProtocol: Sendable {
    func extractText(from image: Any, recognitionLevel: OCRRecognitionLevel, languageCorrection: Bool) async throws -> OCRResult
}

public final class OCRService: OCRServiceProtocol, Sendable {
    public init() {}

    public func extractText(
        from image: Any,
        recognitionLevel: OCRRecognitionLevel = .accurate,
        languageCorrection: Bool = true
    ) async throws -> OCRResult {
        throw OCRError.unavailable
    }

    public func extractText(
        from imageData: Data,
        recognitionLevel: OCRRecognitionLevel = .accurate,
        languageCorrection: Bool = true
    ) async throws -> OCRResult {
        throw OCRError.unavailable
    }

    public func extractTextString(from image: Any) async throws -> String {
        throw OCRError.unavailable
    }
}

public enum OCRError: Error, LocalizedError, Sendable {
    case invalidImageData
    case recognitionFailed(String)
    case unavailable

    public var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "The provided image data could not be decoded."
        case .recognitionFailed(let reason):
            return "Text recognition failed: \(reason)"
        case .unavailable:
            return "OCR is not available on this platform."
        }
    }
}
#endif

// MARK: - Mock for testing

public final class MockOCRService: @unchecked Sendable {
    public var mockResult: OCRResult
    public var shouldThrow: Error?
    public private(set) var extractCallCount = 0

    public init(mockResult: OCRResult = .empty) {
        self.mockResult = mockResult
    }

    public func extractText(
        recognitionLevel: OCRRecognitionLevel = .accurate,
        languageCorrection: Bool = true
    ) async throws -> OCRResult {
        extractCallCount += 1
        if let error = shouldThrow { throw error }
        return mockResult
    }
}
