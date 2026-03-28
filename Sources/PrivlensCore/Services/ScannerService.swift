import Foundation

#if canImport(VisionKit) && os(iOS)
import VisionKit
import UIKit

/// Protocol for document scanning, enabling testability through mocking.
public protocol DocumentScannerProtocol: Sendable {
    /// Returns whether the device supports document scanning.
    var isSupported: Bool { get }
}

/// Production implementation wrapping VisionKit's document scanner.
public final class ScannerService: DocumentScannerProtocol {

    public init() {}

    public var isSupported: Bool {
        VNDocumentCameraViewController.isSupported
    }

    /// Convert a UIImage to JPEG data for storage.
    public static func jpegData(from image: UIImage, quality: CGFloat = 0.85) -> Data? {
        image.jpegData(compressionQuality: quality)
    }

    /// Convert scanned CGImages to JPEG Data arrays for persistence.
    public static func convertToData(_ images: [CGImage], quality: CGFloat = 0.85) -> [Data] {
        images.compactMap { cgImage in
            let uiImage = UIImage(cgImage: cgImage)
            return uiImage.jpegData(compressionQuality: quality)
        }
    }
}

public enum ScannerError: Error, LocalizedError, Sendable {
    case scanFailed(String)
    case cancelled
    case noTextFound

    public var errorDescription: String? {
        switch self {
        case .scanFailed(let reason):
            return "Document scan failed: \(reason)"
        case .cancelled:
            return "Document scan was cancelled."
        case .noTextFound:
            return "No text found in the scanned document."
        }
    }
}

#else

public protocol DocumentScannerProtocol: Sendable {
    var isSupported: Bool { get }
}

public final class ScannerService: DocumentScannerProtocol {
    public init() {}

    public var isSupported: Bool { false }
}

public enum ScannerError: Error, LocalizedError, Sendable {
    case scanFailed(String)
    case cancelled
    case noTextFound
    case unavailable

    public var errorDescription: String? {
        switch self {
        case .scanFailed(let reason):
            return "Document scan failed: \(reason)"
        case .cancelled:
            return "Document scan was cancelled."
        case .noTextFound:
            return "No text found in the scanned document."
        case .unavailable:
            return "Document scanning is not available on this platform."
        }
    }
}
#endif

/// A mock scanner for testing and previews.
public final class MockScannerService: DocumentScannerProtocol, @unchecked Sendable {
    public var isSupported: Bool { true }

    public init() {}
}
