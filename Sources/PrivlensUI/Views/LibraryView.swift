#if canImport(SwiftUI)
import SwiftUI
import PrivlensCore

public struct LibraryView: View {
    @State private var viewModel = LibraryViewModel()
    @State private var showingNewFolder = false
    @State private var editingFolder: Folder? = nil
    @State private var movingDocument: Document? = nil

    public init() {}

    public var body: some View {
        NavigationStack {
            Group {
                if viewModel.documents.isEmpty && !viewModel.isLoading {
                    emptyStateView
                } else {
                    VStack(spacing: 0) {
                        folderChips
                        documentList
                    }
                }
            }
            .navigationTitle("Library")
            .searchable(text: $viewModel.searchQuery, prompt: "Search documents")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    sortMenu
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        showingNewFolder = true
                    } label: {
                        Label("New Folder", systemImage: "folder.badge.plus")
                    }
                }
            }
            .task {
                await viewModel.loadDocuments()
            }
            .refreshable {
                await viewModel.loadDocuments()
            }
            .sheet(isPresented: $showingNewFolder) {
                FolderManagementView(viewModel: viewModel)
            }
            .sheet(item: $editingFolder) { folder in
                FolderManagementView(viewModel: viewModel, folder: folder)
            }
            .sheet(item: $movingDocument) { document in
                MoveToFolderView(viewModel: viewModel, document: document)
            }
        }
    }

    // MARK: - Folder Chips

    private var folderChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // All chip
                folderChip(
                    label: "All",
                    icon: "tray.2.fill",
                    color: .accentColor,
                    count: viewModel.documents.count,
                    isSelected: viewModel.selectedFolder == nil && !viewModel.showUnfiledOnly
                ) {
                    viewModel.selectAll()
                }

                // Unfiled chip
                folderChip(
                    label: "Unfiled",
                    icon: "tray",
                    color: .secondary,
                    count: viewModel.documents.filter { $0.folder == nil }.count,
                    isSelected: viewModel.showUnfiledOnly
                ) {
                    viewModel.selectUnfiled()
                }

                // Folder chips
                ForEach(viewModel.folders) { folder in
                    folderChip(
                        label: folder.name,
                        icon: folder.iconName,
                        color: Color(hex: folder.colorHex),
                        count: folder.documentCount,
                        isSelected: viewModel.selectedFolder?.id == folder.id
                    ) {
                        viewModel.selectFolder(folder)
                    }
                    .contextMenu {
                        Button {
                            editingFolder = folder
                        } label: {
                            Label("Edit Folder", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteFolder(folder)
                            }
                        } label: {
                            Label("Delete Folder", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func folderChip(
        label: String,
        icon: String,
        color: Color,
        count: Int,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)

                Text(label)
                    .font(.subheadline)
                    .lineLimit(1)

                Text("\(count)")
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        isSelected
                            ? Color.white.opacity(0.3)
                            : Color(.systemGray5)
                    )
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color : Color(.systemGray6))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
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
                .contextMenu {
                    Button {
                        movingDocument = document
                    } label: {
                        Label("Move to Folder", systemImage: "folder")
                    }
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

                    if let folder = document.folder {
                        Label(folder.name, systemImage: folder.iconName)
                            .font(.caption)
                            .foregroundStyle(Color(hex: folder.colorHex))
                    }

                    if !document.redFlags.isEmpty {
                        Label("\(document.redFlags.count)", systemImage: "eye.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
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
