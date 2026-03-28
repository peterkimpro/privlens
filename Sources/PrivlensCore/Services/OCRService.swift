import Foundation

#if canImport(Vision)
import Vision
import CoreGraphics

public final class OCRService: Sendable {

    public init() {}

    /// Extracts text from a CGImage using Apple's Vision framework with accurate recognition.
    public func extractText(from image: CGImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }

                let extractedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")

                continuation.resume(returning: extractedText)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.revision = VNRecognizeTextRequestRevision3

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Extracts text from image data (JPEG, PNG, etc.).
    public func extractText(from imageData: Data) async throws -> String {
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
        return try await extractText(from: cgImage)
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

// Stub for non-Apple platforms
public final class OCRService: Sendable {
    public init() {}

    public func extractText(from image: Any) async throws -> String {
        throw OCRError.unavailable
    }

    public func extractText(from imageData: Data) async throws -> String {
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
