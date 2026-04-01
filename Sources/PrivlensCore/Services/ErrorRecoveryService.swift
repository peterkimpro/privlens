import Foundation

// MARK: - RecoveryAction

/// Suggested recovery actions for different error scenarios.
public enum RecoveryAction: String, Sendable, CaseIterable {
    case retry
    case rescan
    case reducePages
    case checkStorage
    case contactSupport
    case none

    /// Human-readable description of the recovery action.
    public var displayText: String {
        switch self {
        case .retry: return "Try Again"
        case .rescan: return "Rescan Document"
        case .reducePages: return "Try with Fewer Pages"
        case .checkStorage: return "Free Up Storage"
        case .contactSupport: return "Contact Support"
        case .none: return ""
        }
    }

    /// System icon name for the action.
    public var systemIcon: String {
        switch self {
        case .retry: return "arrow.clockwise"
        case .rescan: return "doc.viewfinder"
        case .reducePages: return "doc.on.doc"
        case .checkStorage: return "internaldrive"
        case .contactSupport: return "envelope.fill"
        case .none: return ""
        }
    }
}

// MARK: - ErrorRecoveryInfo

/// Structured error information with user-friendly message and recovery options.
public struct ErrorRecoveryInfo: Sendable {
    /// User-friendly error title.
    public let title: String
    /// User-friendly error description.
    public let message: String
    /// Suggested recovery actions.
    public let actions: [RecoveryAction]
    /// Whether the error is likely transient and retrying may help.
    public let isRetryable: Bool

    public init(
        title: String,
        message: String,
        actions: [RecoveryAction],
        isRetryable: Bool
    ) {
        self.title = title
        self.message = message
        self.actions = actions
        self.isRetryable = isRetryable
    }
}

// MARK: - ErrorRecoveryServiceProtocol

/// Protocol for mapping errors to user-friendly recovery information.
public protocol ErrorRecoveryServiceProtocol: Sendable {
    /// Converts any error into a user-friendly error recovery info.
    func recoveryInfo(for error: Error) -> ErrorRecoveryInfo
}

// MARK: - ErrorRecoveryService

/// Maps errors to user-friendly messages and recovery actions.
public final class ErrorRecoveryService: ErrorRecoveryServiceProtocol, Sendable {

    public init() {}

    public func recoveryInfo(for error: Error) -> ErrorRecoveryInfo {
        // Analysis coordinator errors
        if let coordError = error as? AnalysisCoordinatorError {
            return handleCoordinatorError(coordError)
        }

        // AI analysis errors
        if let aiError = error as? AIAnalysisError {
            return handleAIError(aiError)
        }

        // Validation errors
        if let validationError = error as? ValidationError {
            return handleValidationError(validationError)
        }

        // OCR errors
        if let ocrError = error as? OCRError {
            return handleOCRError(ocrError)
        }

        // Scanner errors
        if let scanError = error as? ScannerError {
            return handleScannerError(scanError)
        }

        // Storage errors
        if let storageError = error as? StorageError {
            return handleStorageError(storageError)
        }

        // Comparison errors
        if let comparisonError = error as? DocumentComparisonError {
            return handleComparisonError(comparisonError)
        }

        // PDF export errors
        if let exportError = error as? PDFExportError {
            return handleExportError(exportError)
        }

        // Generic fallback
        return ErrorRecoveryInfo(
            title: "Something Went Wrong",
            message: "An unexpected error occurred. Please try again.",
            actions: [.retry, .contactSupport],
            isRetryable: true
        )
    }

    // MARK: - Error Type Handlers

    private func handleCoordinatorError(_ error: AnalysisCoordinatorError) -> ErrorRecoveryInfo {
        switch error {
        case .emptyDocumentText:
            return ErrorRecoveryInfo(
                title: "No Text Found",
                message: "The document doesn't contain any readable text. Try rescanning with better lighting or a clearer document.",
                actions: [.rescan],
                isRetryable: false
            )
        case .analysisServiceFailed:
            return ErrorRecoveryInfo(
                title: "Analysis Failed",
                message: "The AI analysis engine encountered an error. This is usually temporary — please try again.",
                actions: [.retry],
                isRetryable: true
            )
        }
    }

    private func handleAIError(_ error: AIAnalysisError) -> ErrorRecoveryInfo {
        switch error {
        case .unavailable:
            return ErrorRecoveryInfo(
                title: "AI Not Available",
                message: "On-device AI analysis requires iOS 26+ with Apple Intelligence support (A17 Pro or M1 chip).",
                actions: [.none],
                isRetryable: false
            )
        case .noChunksProvided:
            return ErrorRecoveryInfo(
                title: "No Content to Analyze",
                message: "The document processing produced no content. Try rescanning the document.",
                actions: [.rescan],
                isRetryable: false
            )
        case .chunkAnalysisFailed:
            return ErrorRecoveryInfo(
                title: "Analysis Interrupted",
                message: "Part of the document could not be analyzed. Try again, or try with fewer pages.",
                actions: [.retry, .reducePages],
                isRetryable: true
            )
        }
    }

    private func handleValidationError(_ error: ValidationError) -> ErrorRecoveryInfo {
        switch error {
        case .emptyText, .noReadableContent:
            return ErrorRecoveryInfo(
                title: "No Readable Text",
                message: "No text was detected in this document. Ensure the document has printed text and try scanning again with good lighting.",
                actions: [.rescan],
                isRetryable: false
            )
        case .textTooShort:
            return ErrorRecoveryInfo(
                title: "Not Enough Text",
                message: "The document doesn't contain enough text for meaningful analysis. Try scanning the full document.",
                actions: [.rescan],
                isRetryable: false
            )
        case .textTooLong:
            return ErrorRecoveryInfo(
                title: "Document Too Large",
                message: "This document is very large and may cause performance issues. Consider scanning fewer pages at a time.",
                actions: [.reducePages],
                isRetryable: true
            )
        case .unsupportedCharacterRatio:
            return ErrorRecoveryInfo(
                title: "Poor Scan Quality",
                message: "The text recognition quality is low. Try rescanning with better lighting and a flatter document.",
                actions: [.rescan],
                isRetryable: false
            )
        }
    }

    private func handleOCRError(_ error: OCRError) -> ErrorRecoveryInfo {
        switch error {
        case .invalidImageData:
            return ErrorRecoveryInfo(
                title: "Invalid Image",
                message: "The scanned image could not be processed. Try scanning the document again.",
                actions: [.rescan],
                isRetryable: false
            )
        case .recognitionFailed:
            return ErrorRecoveryInfo(
                title: "Text Recognition Failed",
                message: "Could not extract text from the image. Ensure good lighting and that the document is in focus.",
                actions: [.rescan, .retry],
                isRetryable: true
            )
        #if !canImport(Vision)
        case .unavailable:
            return ErrorRecoveryInfo(
                title: "OCR Not Available",
                message: "Text recognition is not available on this platform.",
                actions: [.none],
                isRetryable: false
            )
        #endif
        }
    }

    private func handleScannerError(_ error: ScannerError) -> ErrorRecoveryInfo {
        switch error {
        case .scanFailed:
            return ErrorRecoveryInfo(
                title: "Scan Failed",
                message: "The document scan failed. Please try again.",
                actions: [.retry],
                isRetryable: true
            )
        case .cancelled:
            return ErrorRecoveryInfo(
                title: "Scan Cancelled",
                message: "The document scan was cancelled.",
                actions: [.none],
                isRetryable: false
            )
        case .noTextFound:
            return ErrorRecoveryInfo(
                title: "No Text Found",
                message: "No text was detected in the scanned document. Try scanning with better lighting.",
                actions: [.rescan],
                isRetryable: false
            )
        #if !canImport(VisionKit) || !os(iOS)
        case .unavailable:
            return ErrorRecoveryInfo(
                title: "Scanner Not Available",
                message: "Document scanning is not available on this platform.",
                actions: [.none],
                isRetryable: false
            )
        #endif
        }
    }

    private func handleComparisonError(_ error: DocumentComparisonError) -> ErrorRecoveryInfo {
        switch error {
        case .emptyDocument(let name):
            return ErrorRecoveryInfo(
                title: "Empty Document",
                message: "'\(name)' has no text content to compare. Please ensure both documents have been scanned with OCR.",
                actions: [.rescan],
                isRetryable: false
            )
        case .sameDocument:
            return ErrorRecoveryInfo(
                title: "Same Document",
                message: "Please select two different documents to compare.",
                actions: [.none],
                isRetryable: false
            )
        case .comparisonFailed:
            return ErrorRecoveryInfo(
                title: "Comparison Failed",
                message: "The document comparison could not be completed. Please try again.",
                actions: [.retry],
                isRetryable: true
            )
        }
    }

    private func handleExportError(_ error: PDFExportError) -> ErrorRecoveryInfo {
        switch error {
        case .noContent:
            return ErrorRecoveryInfo(
                title: "Nothing to Export",
                message: "There is no analysis content to export. Please run an analysis first.",
                actions: [.none],
                isRetryable: false
            )
        case .renderingFailed:
            return ErrorRecoveryInfo(
                title: "Export Failed",
                message: "The PDF could not be generated. Please try again.",
                actions: [.retry],
                isRetryable: true
            )
        }
    }

    private func handleStorageError(_ error: StorageError) -> ErrorRecoveryInfo {
        switch error {
        case .encodingFailed, .decodingFailed:
            return ErrorRecoveryInfo(
                title: "Data Error",
                message: "There was a problem saving or loading the analysis. Try running the analysis again.",
                actions: [.retry],
                isRetryable: true
            )
        case .fileWriteFailed, .fileReadFailed, .deleteFailed:
            return ErrorRecoveryInfo(
                title: "Storage Error",
                message: "There was a problem accessing device storage. Please ensure you have enough free space.",
                actions: [.checkStorage, .retry],
                isRetryable: true
            )
        }
    }
}
