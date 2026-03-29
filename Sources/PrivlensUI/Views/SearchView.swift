#if canImport(SwiftUI)
import SwiftUI
import PrivlensCore

public struct SearchView: View {
    @State private var searchQuery = ""
    @State private var results: [Document] = []
    @State private var isSearching = false
    @State private var hasSearched = false

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                if !hasSearched {
                    searchPromptView
                } else if results.isEmpty {
                    noResultsView
                } else {
                    resultsList
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchQuery, prompt: "Search all documents")
            .onSubmit(of: .search) {
                Task { await performSearch() }
            }
            .onChange(of: searchQuery) { _, newValue in
                if newValue.isEmpty {
                    results = []
                    hasSearched = false
                }
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.searchView)
        }
    }

    // MARK: - Subviews

    private var searchPromptView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Search Documents")
                .font(.title2.bold())

            Text("Search across all your document titles, content, and analysis results.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
        .accessibilityLabel(AccessibilityLabels.searchDocuments)
    }

    private var noResultsView: some View {
        ContentUnavailableView(
            "No Results",
            systemImage: "magnifyingglass",
            description: Text("No documents match \"\(searchQuery)\". Try a different search term.")
        )
    }

    private var resultsList: some View {
        List {
            Section {
                Text(AccessibilityLabels.searchResultCount(results.count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
            }

            ForEach(results) { document in
                NavigationLink(destination: DocumentDetailView(document: document)) {
                    searchResultRow(document)
                }
            }
        }
        .listStyle(.insetGrouped)
        .accessibilityIdentifier(AccessibilityIdentifiers.searchResults)
    }

    private func searchResultRow(_ document: Document) -> some View {
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

                // Show matching snippet
                if let snippet = findMatchingSnippet(in: document) {
                    Text(snippet)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                HStack {
                    Text(document.documentType.displayName)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Text(document.dateScanned, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Actions

    private func performSearch() async {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        isSearching = true
        defer {
            isSearching = false
            hasSearched = true
        }

        do {
            let store = try DocumentStore()
            results = try store.fullTextSearch(query: searchQuery)
        } catch {
            results = []
        }
    }

    private func findMatchingSnippet(in document: Document) -> String? {
        let query = searchQuery.lowercased()
        let sources = [document.rawText, document.analysisResult ?? ""]

        for source in sources {
            let lower = source.lowercased()
            if let range = lower.range(of: query) {
                let startIndex = source.index(range.lowerBound, offsetBy: -40, limitedBy: source.startIndex) ?? source.startIndex
                let endIndex = source.index(range.upperBound, offsetBy: 40, limitedBy: source.endIndex) ?? source.endIndex
                let snippet = String(source[startIndex..<endIndex])
                    .replacingOccurrences(of: "\n", with: " ")
                    .trimmingCharacters(in: .whitespaces)
                return "...\(snippet)..."
            }
        }

        return nil
    }
}
#endif
