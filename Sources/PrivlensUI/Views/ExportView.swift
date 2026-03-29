#if canImport(SwiftUI)
import SwiftUI
import PrivlensCore
#if canImport(UIKit)
import UIKit
#endif

/// Provides PDF export and sharing functionality for analysis results.
public struct ExportView: View {
    let document: Document
    let result: AnalysisResult

    @State private var isExporting = false
    @State private var exportError: String?
    @State private var showExportError = false
    @State private var pdfURL: URL?
    @State private var showShareSheet = false

    private let exportService = PDFExportService()
    private let errorRecovery = ErrorRecoveryService()

    public init(document: Document, result: AnalysisResult) {
        self.document = document
        self.result = result
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Export Options
            VStack(spacing: 12) {
                Text("Export Analysis")
                    .font(.headline)

                // PDF Export
                Button {
                    exportPDF()
                } label: {
                    HStack {
                        Image(systemName: "doc.richtext")
                            .font(.title2)
                            .foregroundStyle(.red)
                            .frame(width: 44)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Export as PDF")
                                .font(.headline)
                            Text("Generate a formatted PDF report")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if isExporting {
                            ProgressView()
                        } else {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(isExporting)
                .accessibilityIdentifier(AccessibilityIdentifiers.exportPDFButton)
                .accessibilityLabel(AccessibilityLabels.exportPDF)

                // Text Share
                ShareLink(
                    item: exportService.generateTextReport(document: document, result: result),
                    subject: Text("Privlens Analysis"),
                    message: Text("Document analysis from Privlens")
                ) {
                    HStack {
                        Image(systemName: "text.alignleft")
                            .font(.title2)
                            .foregroundStyle(.blue)
                            .frame(width: 44)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Share as Text")
                                .font(.headline)
                            Text("Share a plain-text analysis report")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(AccessibilityIdentifiers.exportShareButton)
                .accessibilityLabel(AccessibilityLabels.exportText)
            }

            // Preview
            VStack(alignment: .leading, spacing: 8) {
                Text("Preview")
                    .font(.headline)

                Text(exportService.generateTextReport(document: document, result: result))
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .lineLimit(20)
            }
        }
        .alert("Export Error", isPresented: $showExportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportError ?? "An unknown error occurred.")
        }
        #if canImport(UIKit)
        .sheet(isPresented: $showShareSheet) {
            if let url = pdfURL {
                ActivityViewController(activityItems: [url])
            }
        }
        #endif
    }

    // MARK: - Actions

    private func exportPDF() {
        isExporting = true
        defer { isExporting = false }

        do {
            let pdfData = try exportService.exportAnalysis(document: document, result: result)

            // Write to temp directory
            let fileName = sanitizeFileName(document.title) + "_analysis.pdf"
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
            try pdfData.write(to: tempURL, options: .atomic)

            pdfURL = tempURL
            showShareSheet = true
        } catch {
            let info = errorRecovery.recoveryInfo(for: error)
            exportError = info.message
            showExportError = true
        }
    }

    private func sanitizeFileName(_ name: String) -> String {
        let invalidChars = CharacterSet(charactersIn: "/\\:*?\"<>|")
        return name.components(separatedBy: invalidChars).joined(separator: "_")
            .trimmingCharacters(in: .whitespaces)
            .prefix(50)
            .description
    }
}

// MARK: - UIActivityViewController Wrapper

#if canImport(UIKit)
struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

#endif
