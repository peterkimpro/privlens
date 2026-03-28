#if canImport(SwiftUI)
import SwiftUI
import PrivlensCore

public struct DocumentDetailView: View {
    let document: Document
    @State private var selectedTab: DetailTab = .analysis

    private enum DetailTab: String, CaseIterable {
        case analysis = "Analysis"
        case rawText = "Raw Text"
    }

    public init(document: Document) {
        self.document = document
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Tab Picker
            Picker("View", selection: $selectedTab) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            // Content
            switch selectedTab {
            case .analysis:
                analysisTab
            case .rawText:
                rawTextTab
            }
        }
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Analysis Tab

    private var analysisTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Document Info
                HStack {
                    Image(systemName: document.documentType.systemIcon)
                        .foregroundStyle(.tint)
                    Text(document.documentType.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(document.dateScanned, style: .date)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Analysis Result
                if let analysisText = document.analysisResult {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Summary")
                            .font(.headline)
                        Text(analysisText)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Red Flags
                if !document.redFlags.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Red Flags", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .foregroundStyle(.red)

                        ForEach(document.redFlags, id: \.self) { flag in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                                Text(flag)
                                    .font(.subheadline)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }

                // Key Insights
                if !document.keyInsights.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Key Insights")
                            .font(.headline)

                        ForEach(document.keyInsights, id: \.self) { insight in
                            InsightCard(text: insight, icon: "lightbulb.fill", tint: .yellow)
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Raw Text Tab

    private var rawTextTab: some View {
        ScrollView {
            Text(document.rawText)
                .font(.system(.body, design: .monospaced))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
    }
}
#endif
