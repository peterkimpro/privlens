#if canImport(SwiftUI)
import SwiftUI
import PrivlensCore

public struct FolderManagementView: View {
    @Environment(\.dismiss) private var dismiss

    private let viewModel: LibraryViewModel
    private let existingFolder: Folder?

    @State private var folderName: String
    @State private var selectedIcon: String
    @State private var selectedColor: String
    @State private var showDeleteConfirmation = false

    private static let availableIcons = [
        "folder.fill",
        "doc.fill",
        "heart.fill",
        "creditcard.fill",
        "house.fill",
        "car.fill",
        "cross.case.fill",
        "building.2.fill"
    ]

    private static let availableColors: [(name: String, hex: String)] = [
        ("Blue", "007AFF"),
        ("Red", "FF3B30"),
        ("Green", "34C759"),
        ("Orange", "FF9500"),
        ("Purple", "AF52DE"),
        ("Pink", "FF2D55")
    ]

    public init(viewModel: LibraryViewModel, folder: Folder? = nil) {
        self.viewModel = viewModel
        self.existingFolder = folder
        self._folderName = State(initialValue: folder?.name ?? "")
        self._selectedIcon = State(initialValue: folder?.iconName ?? "folder.fill")
        self._selectedColor = State(initialValue: folder?.colorHex ?? "007AFF")
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Folder Name") {
                    TextField("Name", text: $folderName)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(Self.availableIcons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .frame(width: 48, height: 48)
                                    .background(
                                        selectedIcon == icon
                                            ? Color(hex: selectedColor).opacity(0.2)
                                            : Color(.systemGray6)
                                    )
                                    .foregroundStyle(
                                        selectedIcon == icon
                                            ? Color(hex: selectedColor)
                                            : .secondary
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(
                                                selectedIcon == icon ? Color(hex: selectedColor) : .clear,
                                                lineWidth: 2
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(Self.availableColors, id: \.hex) { color in
                            Button {
                                selectedColor = color.hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: color.hex))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColor == color.hex ? 3 : 0)
                                            .padding(selectedColor == color.hex ? -2 : 0)
                                    )
                                    .overlay(
                                        selectedColor == color.hex
                                            ? Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                            : nil
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }

                if existingFolder != nil {
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete Folder", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(existingFolder == nil ? "New Folder" : "Edit Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            if let existingFolder {
                                await viewModel.updateFolder(
                                    existingFolder,
                                    name: folderName,
                                    icon: selectedIcon,
                                    color: selectedColor
                                )
                            } else {
                                await viewModel.createFolder(
                                    name: folderName,
                                    icon: selectedIcon,
                                    color: selectedColor
                                )
                            }
                            dismiss()
                        }
                    }
                    .disabled(folderName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog(
                "Delete Folder?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let existingFolder {
                        Task {
                            await viewModel.deleteFolder(existingFolder)
                            dismiss()
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Documents in this folder will be moved to Unfiled.")
            }
        }
    }
}

// MARK: - Color Extension for Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        default:
            r = 0; g = 0; b = 0
        }
        self.init(red: r, green: g, blue: b)
    }
}

#else
// Linux stub
#endif
