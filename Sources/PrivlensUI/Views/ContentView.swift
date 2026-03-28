#if canImport(SwiftUI)
import SwiftUI
import PrivlensCore

public struct ContentView: View {
    private let store: DocumentStore?

    public init() {
        self.store = try? DocumentStore()
    }

    public var body: some View {
        TabView {
            Tab("Scan", systemImage: "doc.viewfinder") {
                ScannerView(store: store)
            }

            Tab("Documents", systemImage: "folder.fill") {
                LibraryView()
            }

            Tab("Settings", systemImage: "gearshape.fill") {
                SettingsView()
            }
        }
    }
}

#Preview {
    ContentView()
}
#endif
