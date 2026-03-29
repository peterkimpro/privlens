import SwiftUI
import SwiftData
import PrivlensUI
import PrivlensCore

@main
struct PrivlensApp: App {
    let store = DocumentStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(store.modelContainer)
    }
}
