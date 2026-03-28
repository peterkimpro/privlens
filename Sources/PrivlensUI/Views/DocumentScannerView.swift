#if canImport(SwiftUI) && canImport(VisionKit) && canImport(UIKit)
import SwiftUI
import UIKit
import VisionKit

/// A SwiftUI wrapper around VNDocumentCameraViewController.
///
/// Presents the system document scanner camera. Returns captured page images
/// via the `onScan` callback, or signals cancellation/failure via `onCancel`.
///
/// Usage:
/// ```swift
/// .sheet(isPresented: $showScanner) {
///     DocumentScannerView(
///         onScan: { images in handleImages(images) },
///         onCancel: { showScanner = false }
///     )
/// }
/// ```
public struct DocumentScannerView: UIViewControllerRepresentable {
    public let onScan: ([CGImage]) -> Void
    public let onCancel: () -> Void

    public init(onScan: @escaping ([CGImage]) -> Void, onCancel: @escaping () -> Void) {
        self.onScan = onScan
        self.onCancel = onCancel
    }

    public func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    public func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan, onCancel: onCancel)
    }

    public final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onScan: ([CGImage]) -> Void
        let onCancel: () -> Void

        init(onScan: @escaping ([CGImage]) -> Void, onCancel: @escaping () -> Void) {
            self.onScan = onScan
            self.onCancel = onCancel
        }

        public func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            var images: [CGImage] = []
            for index in 0..<scan.pageCount {
                let uiImage = scan.imageOfPage(at: index)
                if let cgImage = uiImage.cgImage {
                    images.append(cgImage)
                }
            }
            onScan(images)
        }

        public func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onCancel()
        }

        public func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            onCancel()
        }
    }
}
#endif
