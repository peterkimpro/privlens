#if canImport(SwiftUI)
import SwiftUI
import PrivlensCore
#if canImport(StoreKit)
import StoreKit
#endif

public struct SettingsView: View {
    @State private var readinessReport: ReadinessReport?
    @State private var tipThankYou = false

    private let readinessChecker = AppReadinessChecker()

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                // Tip Jar
                Section {
                    tipJarRow(label: "Small Tip", emoji: "☕", price: "$1.99")
                    tipJarRow(label: "Nice Tip", emoji: "🍕", price: "$4.99")
                    tipJarRow(label: "Generous Tip", emoji: "🎉", price: "$9.99")
                } header: {
                    Text("Support Privlens")
                } footer: {
                    Text("Privlens is free with no limits. Tips help support development and keep the app ad-free.")
                }

                // Privacy
                Section {
                    Label("All processing is on-device", systemImage: "lock.shield.fill")
                        .accessibilityLabel("All processing happens on your device")
                    Label("No data sent to any server", systemImage: "wifi.slash")
                        .accessibilityLabel("No data is ever sent to any server")
                    Label("No analytics or tracking", systemImage: "eye.slash.fill")
                        .accessibilityLabel("No analytics or tracking of any kind")
                } header: {
                    Text("Privacy")
                } footer: {
                    Text("Privlens never sends your documents off your device. All AI analysis happens locally using Apple Foundation Models.")
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.settingsPrivacy)

                // Device Readiness
                if let report = readinessReport {
                    Section {
                        ForEach(report.checks) { check in
                            HStack {
                                Image(systemName: check.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(check.passed ? .green : .red)
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading) {
                                    Text(check.name)
                                        .font(.subheadline.weight(.medium))
                                    Text(check.detail)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(check.name): \(check.passed ? "Ready" : "Not ready"). \(check.detail)")
                        }
                    } header: {
                        Text("Device Readiness")
                    }
                }

                // About
                Section {
                    HStack(spacing: 12) {
                        AppLogoView(size: 50)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Privlens")
                                .font(.headline)
                            Text("Private Document AI")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("v1.1.0")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)

                    Link(destination: URL(string: "https://peterkimpro.github.io/privlens/policies/support.html")!) {
                        Label("Help & Support", systemImage: "questionmark.circle")
                    }
                    .accessibilityLabel("Help and Support. Opens in browser.")

                    Link(destination: URL(string: "https://peterkimpro.github.io/privlens/policies/privacy.html")!) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }
                    .accessibilityLabel("Privacy Policy. Opens in browser.")

                    Link(destination: URL(string: "https://peterkimpro.github.io/privlens/policies/terms.html")!) {
                        Label("Terms of Use", systemImage: "doc.text")
                    }
                    .accessibilityLabel("Terms of Use. Opens in browser.")
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                readinessReport = readinessChecker.checkReadiness()
            }
            .alert("Thank You!", isPresented: $tipThankYou) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your support means a lot and helps keep Privlens free and ad-free.")
            }
        }
    }

    private func tipJarRow(label: String, emoji: String, price: String) -> some View {
        Button {
            // StoreKit purchase would go here with real product IDs
            tipThankYou = true
        } label: {
            HStack {
                Text(emoji)
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text(label)
                        .font(.subheadline.bold())
                    Text(price)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "heart.fill")
                    .foregroundStyle(.pink)
            }
        }
        .tint(.primary)
    }
}

#Preview {
    SettingsView()
}
#endif
