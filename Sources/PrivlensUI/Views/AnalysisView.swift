#if canImport(SwiftUI)
import SwiftUI
import PrivlensCore

public struct AnalysisView: View {
    let document: Document
    let result: AnalysisResult

    @State private var isReanalyzing = false
    @State private var currentResult: AnalysisResult
    @State private var errorInfo: ErrorRecoveryInfo?
    @State private var showError = false

    private let errorRecovery = ErrorRecoveryService()

    public init(document: Document, result: AnalysisResult) {
        self.document = document
        self.result = result
        self._currentResult = State(initialValue: result)
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Privacy Indicator
                privacyIndicator

                // Header
                headerSection

                // Red Flags
                if !currentResult.redFlags.isEmpty {
                    redFlagsSection
                }

                // Summary
                summarySection

                // Key Insights
                if !currentResult.keyInsights.isEmpty {
                    keyInsightsSection
                }

                // Action Items
                if !currentResult.actionItems.isEmpty {
                    actionItemsSection
                }
            }
            .padding()
        }
        .navigationTitle("Analysis")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                ShareLink(
                    item: shareText,
                    subject: Text("Privlens Analysis"),
                    message: Text("Document analysis from Privlens")
                ) {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.analysisShareButton)
                .accessibilityLabel("Share analysis")

                Button {
                    Task { await reanalyze() }
                } label: {
                    if isReanalyzing {
                        ProgressView()
                            .accessibilityLabel("Analysis in progress")
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(isReanalyzing)
                .accessibilityIdentifier(AccessibilityIdentifiers.analysisReanalyzeButton)
                .accessibilityLabel(isReanalyzing ? "Reanalyzing document" : "Reanalyze document")
            }
        }
        .alert("Error", isPresented: $showError, presenting: errorInfo) { info in
            ForEach(info.actions.filter { $0 != .none }, id: \.self) { action in
                Button(action.displayText) {
                    handleRecoveryAction(action)
                }
            }
            Button("OK", role: .cancel) {}
        } message: { info in
            Text(info.message)
        }
    }

    // MARK: - Sections

    private var privacyIndicator: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.shield.fill")
                .font(.caption)
                .foregroundStyle(.green)
            Text("Analyzed on your device")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(AccessibilityLabels.onDeviceProcessing)
    }

    private var headerSection: some View {
        HStack {
            Image(systemName: currentResult.documentType.systemIcon)
                .font(.title)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            VStack(alignment: .leading) {
                Text(currentResult.documentType.displayName)
                    .font(.title2.bold())
                Text(document.dateScanned, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(AccessibilityLabels.documentType(currentResult.documentType.displayName))
    }

    private var redFlagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Red Flags", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.red)
                .accessibilityLabel(AccessibilityLabels.redFlagCount(currentResult.redFlags.count))

            ForEach(currentResult.redFlags, id: \.self) { flag in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                        .font(.subheadline)
                        .accessibilityHidden(true)
                    Text(flag)
                        .font(.subheadline)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityElement(children: .combine)
                .accessibilityLabel(AccessibilityLabels.redFlag(text: flag))
            }
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.analysisRedFlags)
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Summary")
                .font(.headline)

            Text(currentResult.summary)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityIdentifier(AccessibilityIdentifiers.analysisSummary)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(AccessibilityLabels.summarySection(text: currentResult.summary))
    }

    private var keyInsightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Insights")
                .font(.headline)
                .accessibilityLabel(AccessibilityLabels.insightCount(currentResult.keyInsights.count))

            ForEach(currentResult.keyInsights, id: \.self) { insight in
                InsightCard(text: insight, icon: "lightbulb.fill", tint: .yellow)
                    .accessibilityLabel(AccessibilityLabels.insight(text: insight))
            }
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.analysisInsights)
    }

    private var actionItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Action Items")
                .font(.headline)
                .accessibilityLabel(AccessibilityLabels.actionItemCount(currentResult.actionItems.count))

            ForEach(Array(currentResult.actionItems.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(.tint)
                        .clipShape(Circle())
                        .accessibilityHidden(true)

                    Text(item)
                        .font(.subheadline)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityElement(children: .combine)
                .accessibilityLabel(AccessibilityLabels.actionItem(number: index + 1, text: item))
            }
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.analysisActionItems)
    }

    // MARK: - Actions

    private var shareText: String {
        var text = "Privlens Document Analysis\n"
        text += "Type: \(currentResult.documentType.displayName)\n\n"
        text += "Summary:\n\(currentResult.summary)\n\n"

        if !currentResult.redFlags.isEmpty {
            text += "Red Flags:\n"
            for flag in currentResult.redFlags {
                text += "- \(flag)\n"
            }
            text += "\n"
        }

        if !currentResult.keyInsights.isEmpty {
            text += "Key Insights:\n"
            for insight in currentResult.keyInsights {
                text += "- \(insight)\n"
            }
            text += "\n"
        }

        if !currentResult.actionItems.isEmpty {
            text += "Action Items:\n"
            for (index, item) in currentResult.actionItems.enumerated() {
                text += "\(index + 1). \(item)\n"
            }
        }

        text += "\nAnalyzed with Privlens - 100% on-device, 100% private."

        return text
    }

    private func reanalyze() async {
        isReanalyzing = true
        defer { isReanalyzing = false }

        let service = AIAnalysisService()
        do {
            let newResult = try await service.analyzeDocument(
                text: document.rawText,
                type: document.documentType
            )
            currentResult = newResult
        } catch {
            errorInfo = errorRecovery.recoveryInfo(for: error)
            showError = true
        }
    }

    private func handleRecoveryAction(_ action: RecoveryAction) {
        switch action {
        case .retry:
            Task { await reanalyze() }
        default:
            break
        }
    }
}
#endif
