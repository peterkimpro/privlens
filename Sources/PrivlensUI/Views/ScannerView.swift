#if canImport(SwiftUI) && canImport(VisionKit) && canImport(UIKit)
import SwiftUI
import UIKit
import VisionKit
import PrivlensCore
import PhotosUI

public struct ScannerView: View {
    @State private var viewModel: ScanViewModel
    @State private var showScanner = false
    @State private var showPhotoPicker = false

    private let scannerService = ScannerService()

    public init(store: DocumentStore? = nil) {
        _viewModel = State(initialValue: ScanViewModel(store: store))
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if viewModel.isProcessing {
                    processingView
                } else if let result = viewModel.latestResult,
                          let document = viewModel.latestDocument {
                    VStack(spacing: 16) {
                        if viewModel.didSaveDocument {
                            Label("Saved to Library", systemImage: "checkmark.circle.fill")
                                .font(.subheadline.bold())
                                .foregroundStyle(.green)
                        }

                        NavigationLink(
                            destination: DocumentDetailView(document: document)
                        ) {
                            resultPreviewCard(result)
                        }

                        Button {
                            viewModel.reset()
                        } label: {
                            Label("Scan Another", systemImage: "doc.viewfinder")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
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
                        .disabled(!scannerService.isSupported)

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
                DocumentScannerView(
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

            AppLogoView(size: 80)

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
                .disabled(!scannerService.isSupported)

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
                Image(systemName: "doc.text.magnifyingglass")
                    .foregroundStyle(.tint)
                Text(viewModel.latestDocument?.title ?? "Scan Complete")
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

#endif
