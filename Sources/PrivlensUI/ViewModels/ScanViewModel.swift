#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import UIKit
import PrivlensCore

@Observable
@MainActor
public final class ScanViewModel {
    public var isProcessing = false
    public var processingStatus = "Preparing..."
    public var latestResult: AnalysisResult?
    public var latestDocument: Document?
    public var errorMessage: String?

    private let ocrService = OCRService()
    private let classifier = DocumentClassifier()
    private let aiService = AIAnalysisService()
    private let scannerService = ScannerService()

    public init() {}

    /// Whether the device supports VisionKit document scanning.
    public var isScanningSupported: Bool {
        scannerService.isSupported
    }

    /// Process scanned page images through the full pipeline: OCR → classify → AI analyze.
    public func processScannedImages(_ images: [CGImage]) async {
        guard !images.isEmpty else { return }

        isProcessing = true
        processingStatus = "Extracting text..."
        defer { isProcessing = false }

        do {
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

            // Classify
            processingStatus = "Classifying document..."
            let docType = classifier.classify(text: trimmedText)

            // Analyze with AI
            processingStatus = "Analyzing with on-device AI..."
            let result = try await aiService.analyzeDocument(text: trimmedText, type: docType)

            // Convert scanned pages to JPEG data for storage
            let pageData = ScannerService.convertToData(images)

            // Create document with scanned page data
            let document = Document(
                title: "\(docType.displayName) - \(Date().formatted(date: .abbreviated, time: .omitted))",
                rawText: trimmedText,
                documentType: docType,
                analysisResult: result.summary,
                redFlags: result.redFlags,
                keyInsights: result.keyInsights,
                pageImageData: pageData,
                pageCount: images.count
            )

            latestDocument = document
            latestResult = result
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func processPhotoPickerItem(_ item: Any) async {
        isProcessing = true
        processingStatus = "Importing photo..."
        defer { isProcessing = false }

        errorMessage = "Photo import will be available when running on device."
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

    public var isScanningSupported: Bool { false }

    public init() {}
}
#endif
