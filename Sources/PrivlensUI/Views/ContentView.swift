#if canImport(SwiftUI)
import SwiftUI
import PrivlensCore

public struct ContentView: View {
    private let store: DocumentStore?
    @State private var hasCompletedOnboarding: Bool

    public init() {
        self.store = try? DocumentStore()
        let completed = UserDefaults.standard.bool(forKey: "privlens_onboarding_completed")
        self._hasCompletedOnboarding = State(initialValue: completed)
    }

    public var body: some View {
        if hasCompletedOnboarding {
            mainTabView
        } else {
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
        }
    }

    private var mainTabView: some View {
        TabView {
            Tab("Scan", systemImage: "doc.viewfinder") {
                ScannerView(store: store)
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.scanTab)

            Tab("Documents", systemImage: "folder.fill") {
                LibraryView()
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.documentsTab)

            Tab("Settings", systemImage: "gearshape.fill") {
                SettingsView()
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.settingsTab)
        }
    }
}

#Preview {
    ContentView()
}
#endif
