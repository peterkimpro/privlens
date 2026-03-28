import SwiftUI
import SwiftData
import PrivlensUI
import PrivlensCore

@main
struct PrivlensApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Document.self)
    }
}
