#if canImport(SwiftUI) && canImport(VisionKit) && canImport(UIKit)
import SwiftUI
import UIKit
import VisionKit
import PrivlensCore

public struct ScannerView: View {
    @State private var viewModel = ScanViewModel()
    @State private var showScanner = false
    @State private var showPhotoPicker = false

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if viewModel.isProcessing {
                    processingView
                } else if let result = viewModel.latestResult {
                    NavigationLink(
                        destination: AnalysisView(
                            document: viewModel.latestDocument!,
                            result: result
                        )
                    ) {
                        resultPreviewCard(result)
                    }
                } else {
                    scanPromptView
                }
            }
            .padding()
            .navigationTitle("Scan")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showScanner = true
                        } label: {
                            Label("Scan Document", systemImage: "doc.viewfinder")
                        }

                        Button {
                            showPhotoPicker = true
                        } label: {
                            Label("Import from Photos", systemImage: "photo.on.rectangle")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showScanner) {
                DocumentCameraRepresentable(
                    onScan: { images in
                        showScanner = false
                        Task {
                            await viewModel.processScannedImages(images)
                        }
                    },
                    onCancel: {
                        showScanner = false
                    }
                )
                .ignoresSafeArea()
            }
            .photosPicker(
                isPresented: $showPhotoPicker,
                selection: Binding(
                    get: { nil },
                    set: { item in
                        if let item {
                            Task {
                                await viewModel.processPhotoPickerItem(item)
                            }
                        }
                    }
                ),
                matching: .images
            )
            .alert(
                "Error",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - Subviews

    private var scanPromptView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "doc.viewfinder")
                .font(.system(size: 72))
                .foregroundStyle(.tint)

            Text("Scan a Document")
                .font(.title2.bold())

            Text("Point your camera at a document to scan it, or import from your photo library.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 16) {
                Button {
                    showScanner = true
                } label: {
                    Label("Scan", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    showPhotoPicker = true
                } label: {
                    Label("Import", systemImage: "photo")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.top)

            Spacer()
        }
    }

    private var processingView: some View {
        VStack(spacing: 16) {
            Spacer()

            ProgressView()
                .controlSize(.large)

            Text(viewModel.processingStatus)
                .font(.headline)

            Text("This happens entirely on your device.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }

    private func resultPreviewCard(_ result: AnalysisResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: result.documentType.systemIcon)
                    .foregroundStyle(.tint)
                Text(result.documentType.displayName)
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }

            Text(result.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            if !result.redFlags.isEmpty {
                RedFlagBanner(count: result.redFlags.count)
            }

            Text("Tap to view full analysis")
                .font(.caption)
                .foregroundStyle(.tint)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - VNDocumentCameraViewController Representable

struct DocumentCameraRepresentable: UIViewControllerRepresentable {
    let onScan: ([CGImage]) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan, onCancel: onCancel)
    }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onScan: ([CGImage]) -> Void
        let onCancel: () -> Void

        init(onScan: @escaping ([CGImage]) -> Void, onCancel: @escaping () -> Void) {
            self.onScan = onScan
            self.onCancel = onCancel
        }

        func documentCameraViewController(
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

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onCancel()
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            onCancel()
        }
    }
}

// MARK: - PhotosPicker extension

import PhotosUI

private extension ScannerView {
    // The photosPicker modifier is used directly in the body.
}

#endif
