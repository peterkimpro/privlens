import Foundation

#if canImport(VisionKit)
import VisionKit

/// Protocol for document scanning, enabling testability through mocking.
public protocol DocumentScannerProtocol: Sendable {
    /// Returns whether the device supports document scanning.
    var isSupported: Bool { get }

    /// Returns the scanned image data from the scanner.
    func scanDocument() async throws -> [Data]
}

/// Production implementation wrapping VisionKit's document scanner.
public final class ScannerService: DocumentScannerProtocol {

    public init() {}

    public var isSupported: Bool {
        VNDocumentCameraViewController.self is AnyClass
    }

    /// Triggers the document scanner. In practice this is driven by
    /// the SwiftUI `VNDocumentCameraViewController` representable in the UI layer.
    /// This service method exists to provide a clean async interface for the scan pipeline.
    public func scanDocument() async throws -> [Data] {
        // The actual camera presentation is handled by the UI layer's ScannerView.
        // This method is a convenience entry point for programmatic flows.
        throw ScannerError.requiresUIPresentation
    }
}

public enum ScannerError: Error, LocalizedError, Sendable {
    case requiresUIPresentation
    case scanFailed(String)
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .requiresUIPresentation:
            return "Document scanning requires UI presentation via ScannerView."
        case .scanFailed(let reason):
            return "Document scan failed: \(reason)"
        case .cancelled:
            return "Document scan was cancelled."
        }
    }
}

#else

public protocol DocumentScannerProtocol: Sendable {
    var isSupported: Bool { get }
    func scanDocument() async throws -> [Data]
}

public final class ScannerService: DocumentScannerProtocol {
    public init() {}

    public var isSupported: Bool { false }

    public func scanDocument() async throws -> [Data] {
        throw ScannerError.unavailable
    }
}

public enum ScannerError: Error, LocalizedError, Sendable {
    case requiresUIPresentation
    case scanFailed(String)
    case cancelled
    case unavailable

    public var errorDescription: String? {
        switch self {
        case .requiresUIPresentation:
            return "Document scanning requires UI presentation via ScannerView."
        case .scanFailed(let reason):
            return "Document scan failed: \(reason)"
        case .cancelled:
            return "Document scan was cancelled."
        case .unavailable:
            return "Document scanning is not available on this platform."
        }
    }
}
#endif

/// A mock scanner for testing and previews.
public final class MockScannerService: DocumentScannerProtocol {
    public var isSupported: Bool { true }
    public var mockImageData: [Data]

    public init(mockImageData: [Data] = []) {
        self.mockImageData = mockImageData
    }

    public func scanDocument() async throws -> [Data] {
        return mockImageData
    }
}
