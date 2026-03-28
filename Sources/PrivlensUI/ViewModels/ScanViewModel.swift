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

    public init() {}

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
                errorMessage = "No text found in the scanned document."
                return
            }

            // Classify
            processingStatus = "Classifying document..."
            let docType = classifier.classify(text: trimmedText)

            // Analyze with AI
            processingStatus = "Analyzing with on-device AI..."
            let result = try await aiService.analyzeDocument(text: trimmedText, type: docType)

            // Create document
            let document = Document(
                title: "\(docType.displayName) - \(Date().formatted(date: .abbreviated, time: .omitted))",
                rawText: trimmedText,
                documentType: docType,
                analysisResult: result.summary,
                redFlags: result.redFlags,
                keyInsights: result.keyInsights
            )

            latestDocument = document
            latestResult = result
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func processPhotoPickerItem(_ item: Any) async {
        // PhotosPickerItem handling will be implemented with PhotosUI integration
        isProcessing = true
        processingStatus = "Importing photo..."
        defer { isProcessing = false }

        errorMessage = "Photo import will be available when running on device."
    }
}

#else

// Stub for non-Apple platforms
import Foundation

@MainActor
public final class ScanViewModel {
    public var isProcessing = false
    public var processingStatus = "Preparing..."
    public var latestResult: AnalysisResult?
    public var latestDocument: Document?
    public var errorMessage: String?

    public init() {}
}
#endif
