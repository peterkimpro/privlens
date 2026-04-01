#if canImport(SwiftUI)
import SwiftUI
import PrivlensCore

public struct SearchView: View {
    @State private var searchQuery = ""
    @State private var allDocuments: [Document] = []
    @State private var folders: [Folder] = []
    @State private var isLoading = false

    public init() {}

    private var filteredDocuments: [Document] {
        guard !searchQuery.isEmpty else { return allDocuments }
        let query = searchQuery.lowercased()
        return allDocuments.filter {
            $0.title.lowercased().contains(query) ||
            $0.rawText.lowercased().contains(query) ||
            $0.documentType.displayName.lowercased().contains(query) ||
            ($0.analysisResult?.lowercased().contains(query) ?? false)
        }
    }

    private var suggestions: [String] {
        guard !searchQuery.isEmpty else { return [] }
        let query = searchQuery.lowercased()
        // Suggest matching document titles
        let titleMatches = allDocuments
            .filter { $0.title.lowercased().contains(query) }
            .map { $0.title }
        // Suggest matching document types
        let typeMatches = Set(allDocuments
            .filter { $0.documentType.displayName.lowercased().contains(query) && $0.documentType != .unknown }
            .map { $0.documentType.displayName })
        return Array(Set(titleMatches + typeMatches)).prefix(5).map { $0 }
    }

    private var recentDocuments: [Document] {
        Array(allDocuments.sorted { $0.dateScanned > $1.dateScanned }.prefix(5))
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if searchQuery.isEmpty {
                        // Default state: show everything
                        browseSection
                    } else {
                        // Searching: show suggestions + results
                        searchResultsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Search")
            .searchable(text: $searchQuery, prompt: "Search documents")
            .accessibilityIdentifier(AccessibilityIdentifiers.searchView)
            .task {
                await loadData()
            }
        }
    }

    // MARK: - Browse (default state)

    private var browseSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Recent scans
            if !recentDocuments.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Recent Scans", systemImage: "clock.fill")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    ForEach(recentDocuments) { document in
                        NavigationLink(destination: DocumentDetailView(document: document)) {
                            documentRow(document)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Folders
            if !folders.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Folders", systemImage: "folder.fill")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(folders) { folder in
                            folderCard(folder)
                        }
                    }
                }
            }

            // All documents
            if !allDocuments.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Label("All Documents (\(allDocuments.count))", systemImage: "doc.on.doc.fill")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    ForEach(allDocuments.sorted { $0.dateScanned > $1.dateScanned }) { document in
                        NavigationLink(destination: DocumentDetailView(document: document)) {
                            documentRow(document)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if allDocuments.isEmpty && !isLoading {
                VStack(spacing: 16) {
                    AppLogoView(size: 64)
                    Text("No Documents Yet")
                        .font(.title3.bold())
                    Text("Scan your first document to see it here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
    }

    // MARK: - Search Results

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Suggestions
            if !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suggestions")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    ForEach(suggestions, id: \.self) { suggestion in
                        Button {
                            searchQuery = suggestion
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(suggestion)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "arrow.up.left")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 4)
            }

            // Results
            if filteredDocuments.isEmpty {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("No documents match \"\(searchQuery)\"")
                )
            } else {
                Text("\(filteredDocuments.count) result\(filteredDocuments.count == 1 ? "" : "s")")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                ForEach(filteredDocuments) { document in
                    NavigationLink(destination: DocumentDetailView(document: document)) {
                        searchResultRow(document)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Row Views

    private func documentRow(_ document: Document) -> some View {
        HStack(spacing: 12) {
            Image(systemName: document.documentType.systemIcon)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 40, height: 40)
                .background(.tint.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(document.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(document.documentType == .unknown ? "Document" : document.documentType.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(document.dateScanned, style: .date)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func searchResultRow(_ document: Document) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: document.documentType.systemIcon)
                    .font(.title3)
                    .foregroundStyle(.tint)
                    .frame(width: 40, height: 40)
                    .background(.tint.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 3) {
                    Text(document.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Text(document.documentType == .unknown ? "Document" : document.documentType.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(document.dateScanned, style: .date)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            // Show matching snippet from content
            if let snippet = findMatchingSnippet(in: document) {
                Text(snippet)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func folderCard(_ folder: Folder) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: folder.iconName)
                .font(.title2)
                .foregroundStyle(Color(hex: folder.colorHex))

            Text(folder.name)
                .font(.subheadline.bold())
                .lineLimit(1)

            Text("\(folder.documentCount) doc\(folder.documentCount == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Data

    private func loadData() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let store = try DocumentStore()
            allDocuments = try store.fetchAll()
            folders = try store.fetchAllFolders()
        } catch {
            allDocuments = []
            folders = []
        }
    }

    private func findMatchingSnippet(in document: Document) -> String? {
        let query = searchQuery.lowercased()
        guard !query.isEmpty else { return nil }
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
