#if canImport(SwiftUI)
import SwiftUI
import PrivlensCore

public struct ContentView: View {

    public init() {}

    public var body: some View {
        TabView {
            Tab("Scan", systemImage: "doc.viewfinder") {
                ScannerView()
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
