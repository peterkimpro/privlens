#if canImport(SwiftUI)
import SwiftUI
import PrivlensCore

public struct SettingsView: View {
    @State private var showPaywall = false

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                // Pro Status
                Section {
                    proStatusRow
                } header: {
                    Text("Subscription")
                }

                // Privacy
                Section {
                    Label("All processing is on-device", systemImage: "lock.shield.fill")
                    Label("No data sent to any server", systemImage: "wifi.slash")
                    Label("No analytics or tracking", systemImage: "eye.slash.fill")
                } header: {
                    Text("Privacy")
                } footer: {
                    Text("Privlens never sends your documents off your device. All AI analysis happens locally using Apple Foundation Models.")
                }

                // About
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://privlens.app/support")!) {
                        Label("Help & Support", systemImage: "questionmark.circle")
                    }

                    Link(destination: URL(string: "https://privlens.app/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }

                    Link(destination: URL(string: "https://privlens.app/terms")!) {
                        Label("Terms of Use", systemImage: "doc.text")
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    private var proStatusRow: some View {
        Button {
            showPaywall = true
        } label: {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.tint)
                VStack(alignment: .leading) {
                    Text("Privlens Pro")
                        .font(.headline)
                    Text("Unlock unlimited analyses")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
        }
        .tint(.primary)
    }
}

#Preview {
    SettingsView()
}
#endif
