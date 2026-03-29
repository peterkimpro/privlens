#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import UIKit
import PhotosUI
import PrivlensCore

@Observable
@MainActor
public final class ScanViewModel {
    public var isProcessing = false
    public var processingStatus = "Preparing..."
    public var latestResult: AnalysisResult?
    public var latestDocument: Document?
    public var errorMessage: String?
    /// Set to true once a document has been saved — drives post-scan navigation.
    public var didSaveDocument = false

    /// When true, uses AI-powered smart classification; falls back to keyword-based otherwise.
    public var useSmartDetection: Bool = true

    private let ocrService = OCRService()
    private let keywordClassifier = DocumentClassifier()
    private let smartClassifier = SmartClassifier()
    private let aiService = AIAnalysisService()
    private let scannerService = ScannerService()
    private let store: DocumentStore?

    public init(store: DocumentStore? = nil) {
        self.store = store
    }

    /// Whether the device supports VisionKit document scanning.
    public var isScanningSupported: Bool {
        scannerService.isSupported
    }

    /// Process scanned page images through the full pipeline: OCR → classify → AI analyze.
    public func processScannedImages(_ images: [CGImage]) async {
        guard !images.isEmpty else { return }

        isProcessing = true
        processingStatus = "Extracting text..."
        didSaveDocument = false
        defer { isProcessing = false }

        do {
            // Convert scanned pages to JPEG data for persistence
            let pageData = ScannerService.convertToData(images)

            // OCR all pages and combine
            var allText = ""
            for (index, image) in images.enumerated() {
                processingStatus = "Reading page \(index + 1) of \(images.count)..."
                let ocrResult = try await ocrService.extractText(from: image)
                allText += ocrResult.text + "\n\n"
            }

            let trimmedText = allText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedText.isEmpty else {
                errorMessage = ScannerError.noTextFound.localizedDescription
                return
            }

            // Classify (smart AI detection by default, keyword fallback if disabled)
            processingStatus = "Classifying document..."
            let docType: DocumentType
            if useSmartDetection {
                docType = await smartClassifier.classify(text: trimmedText)
            } else {
                docType = keywordClassifier.classify(text: trimmedText)
            }

            // Analyze with AI
            processingStatus = "Analyzing with on-device AI..."
            let result = try await aiService.analyzeDocument(text: trimmedText, type: docType)

            // Generate thumbnail from first page
            var thumbnailData: Data?
            if let firstImage = images.first {
                let thumb = UIImage(cgImage: firstImage)
                let maxDim: CGFloat = 300
                let scale = min(maxDim / thumb.size.width, maxDim / thumb.size.height, 1.0)
                let newSize = CGSize(width: thumb.size.width * scale, height: thumb.size.height * scale)
                let renderer = UIGraphicsImageRenderer(size: newSize)
                let resized = renderer.image { _ in thumb.draw(in: CGRect(origin: .zero, size: newSize)) }
                thumbnailData = resized.jpegData(compressionQuality: 0.6)
            }

            // Create document with page images — derive a short title from the summary
            let autoTitle: String
            if docType != .unknown {
                autoTitle = "\(docType.displayName) - \(Date().formatted(date: .abbreviated, time: .omitted))"
            } else {
                let summaryWords = result.summary.split(separator: " ").prefix(6).joined(separator: " ")
                autoTitle = summaryWords.isEmpty
                    ? "Document - \(Date().formatted(date: .abbreviated, time: .omitted))"
                    : summaryWords
            }
            let document = Document(
                title: autoTitle,
                rawText: trimmedText,
                documentType: docType,
                analysisResult: result.summary,
                redFlags: result.redFlags,
                keyInsights: result.keyInsights,
                thumbnailData: thumbnailData,
                pageImageData: pageData,
                pageCount: images.count
            )

            // Persist to DocumentStore
            processingStatus = "Saving document..."
            if let store {
                try store.save(document)
            }

            latestDocument = document
            latestResult = result
            didSaveDocument = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func processPhotoPickerItem(_ item: Any) async {
        isProcessing = true
        processingStatus = "Importing photo..."
        defer { isProcessing = false }

        guard let pickerItem = item as? PhotosPickerItem else {
            errorMessage = "Unable to read selected photo."
            return
        }

        do {
            guard let data = try await pickerItem.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data),
                  let cgImage = uiImage.cgImage else {
                errorMessage = "Could not load image from photo library."
                return
            }

            await processScannedImages([cgImage])
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Resets state so the user can scan another document.
    public func reset() {
        latestResult = nil
        latestDocument = nil
        didSaveDocument = false
        errorMessage = nil
    }
}

#else

// Stub for non-Apple platforms
import Foundation
#if canImport(PrivlensCore)
import PrivlensCore
#endif

@MainActor
public final class ScanViewModel {
    public var isProcessing = false
    public var processingStatus = "Preparing..."
    public var latestResult: AnalysisResult?
    public var latestDocument: Document?
    public var errorMessage: String?
    public var didSaveDocument = false
    public var useSmartDetection: Bool = true

    public var isScanningSupported: Bool { false }

    public init() {}

    public func reset() {
        latestResult = nil
        latestDocument = nil
        didSaveDocument = false
    }
}
#endif
