#if canImport(SwiftUI)
import SwiftUI
import PrivlensCore

public struct MoveToFolderView: View {
    @Environment(\.dismiss) private var dismiss

    private let viewModel: LibraryViewModel
    private let document: Document

    public init(viewModel: LibraryViewModel, document: Document) {
        self.viewModel = viewModel
        self.document = document
    }

    public var body: some View {
        NavigationStack {
            List {
                Button {
                    Task {
                        await viewModel.moveDocument(document, to: nil)
                        dismiss()
                    }
                } label: {
                    HStack {
                        Image(systemName: "tray")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .frame(width: 32)

                        Text("No Folder")
                            .foregroundStyle(.primary)

                        Spacer()

                        if document.folder == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                }

                ForEach(viewModel.folders) { folder in
                    Button {
                        Task {
                            await viewModel.moveDocument(document, to: folder)
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Image(systemName: folder.iconName)
                                .font(.title3)
                                .foregroundStyle(Color(hex: folder.colorHex))
                                .frame(width: 32)

                            Text(folder.name)
                                .foregroundStyle(.primary)

                            Spacer()

                            if document.folder?.id == folder.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Move to Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#else
// Linux stub
#endif
