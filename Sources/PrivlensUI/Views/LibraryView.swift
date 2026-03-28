#if canImport(SwiftUI)
import SwiftUI
import PrivlensCore

public struct LibraryView: View {
    @State private var viewModel = LibraryViewModel()

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.documents.isEmpty && !viewModel.isLoading {
                    emptyStateView
                } else {
                    documentList
                }
            }
            .navigationTitle("Library")
            .searchable(text: $viewModel.searchQuery, prompt: "Search documents")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    sortMenu
                }
            }
            .task {
                await viewModel.loadDocuments()
            }
            .refreshable {
                await viewModel.loadDocuments()
            }
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Documents",
            systemImage: "doc.text.magnifyingglass",
            description: Text("Scan your first document to see it here.")
        )
    }

    private var documentList: some View {
        List {
            ForEach(viewModel.filteredDocuments) { document in
                NavigationLink(destination: DocumentDetailView(document: document)) {
                    documentRow(document)
                }
            }
            .onDelete { indexSet in
                Task {
                    await viewModel.deleteDocuments(at: indexSet)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func documentRow(_ document: Document) -> some View {
        HStack(spacing: 12) {
            Image(systemName: document.documentType.systemIcon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 44, height: 44)
                .background(.tint.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(document.title)
                    .font(.headline)
                    .lineLimit(1)

                HStack {
                    Text(document.documentType.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !document.redFlags.isEmpty {
                        Label("\(document.redFlags.count)", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                Text(document.dateScanned, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var sortMenu: some View {
        Menu {
            Picker("Sort By", selection: $viewModel.sortOrder) {
                Label("Newest First", systemImage: "arrow.down")
                    .tag(LibraryViewModel.SortOrder.newestFirst)
                Label("Oldest First", systemImage: "arrow.up")
                    .tag(LibraryViewModel.SortOrder.oldestFirst)
                Label("By Type", systemImage: "doc.on.doc")
                    .tag(LibraryViewModel.SortOrder.byType)
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down.circle")
        }
    }
}
#endif
