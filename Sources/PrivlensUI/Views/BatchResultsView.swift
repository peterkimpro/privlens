#if canImport(SwiftUI)
import SwiftUI
import PrivlensCore

public struct BatchResultsView: View {
    @Environment(\.dismiss) private var dismiss

    public let batchJob: BatchJob

    public init(batchJob: BatchJob) {
        self.batchJob = batchJob
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Overall Status
                    overallStatusSection

                    // Cross-Document Insights
                    if !batchJob.crossDocumentInsights.isEmpty {
                        crossDocumentSection
                    }

                    // Per-Document Results
                    perDocumentSection

                    // Combined Red Flags
                    if !batchJob.allRedFlags.isEmpty {
                        redFlagsSection
                    }

                    // Combined Action Items
                    if !batchJob.allActionItems.isEmpty {
                        actionItemsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Batch Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Overall Status

    private var overallStatusSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                statusCounter(count: batchJob.successCount, label: "Completed", color: .green)
                statusCounter(count: batchJob.failedCount, label: "Failed", color: .red)
                statusCounter(
                    count: batchJob.entries.filter { $0.status == .skipped }.count,
                    label: "Skipped",
                    color: .orange
                )
            }

            ProgressView(value: batchJob.progress)
                .progressViewStyle(.linear)
                .tint(batchJob.status == .completed ? .green : .blue)
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func statusCounter(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Cross-Document Insights

    private var crossDocumentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Cross-Document Insights", systemImage: "link")
                .font(.headline)

            ForEach(batchJob.crossDocumentInsights) { insight in
                crossDocumentCard(insight)
            }
        }
    }

    private func crossDocumentCard(_ insight: CrossDocumentInsight) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconForPatternType(insight.patternType))
                    .foregroundStyle(.tint)
                Text(insight.description)
                    .font(.subheadline)
            }

            HStack(spacing: 4) {
                ForEach(insight.relatedDocumentTitles, id: \.self) { title in
                    Text(title)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.tint.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func iconForPatternType(_ type: CrossDocumentPatternType) -> String {
        switch type {
        case .sharedAddress: return "mappin.circle.fill"
        case .sharedEntity: return "person.2.fill"
        case .sharedFinancialAmount: return "dollarsign.circle.fill"
        case .sharedDate: return "calendar.circle.fill"
        case .relatedTerms: return "text.magnifyingglass"
        case .other: return "link.circle.fill"
        }
    }

    // MARK: - Per-Document Results

    private var perDocumentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Document Results")
                .font(.headline)

            ForEach(batchJob.entries) { entry in
                documentResultCard(entry)
            }
        }
    }

    private func documentResultCard(_ entry: BatchDocumentEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                statusIcon(entry.status)
                Text(entry.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Spacer()
                Text(entry.status.rawValue.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let result = entry.result {
                Text(result.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            if let error = entry.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func statusIcon(_ status: BatchDocumentStatus) -> some View {
        Group {
            switch status {
            case .pending:
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)
            case .analyzing:
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundStyle(.blue)
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case .failed:
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
            case .skipped:
                Image(systemName: "lock.fill")
                    .foregroundStyle(.orange)
            }
        }
    }

    // MARK: - Red Flags

    private var redFlagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Watch Out For", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)

            ForEach(Array(batchJob.allRedFlags.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.caption)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.documentTitle)
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                        Text(item.redFlag)
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(.red.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Action Items

    private var actionItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("All Action Items", systemImage: "checklist")
                .font(.headline)

            ForEach(Array(batchJob.allActionItems.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(index + 1).")
                        .font(.caption.bold())
                        .foregroundStyle(.tint)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.documentTitle)
                            .font(.caption2.bold())
                            .foregroundStyle(.secondary)
                        Text(item.actionItem)
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#endif
