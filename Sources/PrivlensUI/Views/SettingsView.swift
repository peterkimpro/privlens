#if canImport(SwiftUI)
import SwiftUI
import PrivlensCore
#if canImport(StoreKit)
import StoreKit
#endif

public struct SettingsView: View {
    @State private var showPaywall = false
    @State private var paywallManager = PaywallManager()
    @State private var readinessReport: ReadinessReport?

    private let readinessChecker = AppReadinessChecker()

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
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.1.0")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Version 1.0.0")

                    Link(destination: URL(string: "https://privlens.app/support")!) {
                        Label("Help & Support", systemImage: "questionmark.circle")
                    }
                    .accessibilityLabel("Help and Support. Opens in browser.")

                    Link(destination: URL(string: "https://privlens.app/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }
                    .accessibilityLabel("Privacy Policy. Opens in browser.")

                    Link(destination: URL(string: "https://privlens.app/terms")!) {
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
            #if canImport(StoreKit)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            #endif
        }
    }

    private var proStatusRow: some View {
        Button {
            if !paywallManager.hasPurchase {
                showPaywall = true
            }
        } label: {
            HStack {
                Image(systemName: proStatusIcon)
                    .foregroundStyle(proStatusIconColor)
                    .accessibilityHidden(true)
                VStack(alignment: .leading) {
                    Text(proStatusTitle)
                        .font(.headline)
                    Text(proStatusSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if !paywallManager.hasPurchase {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
            }
        }
        .tint(.primary)
        .accessibilityIdentifier(AccessibilityIdentifiers.settingsProStatus)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(proAccessibilityLabel)
        .accessibilityHint(paywallManager.hasPurchase ? "" : "Double tap to view upgrade options")
    }

    private var proStatusIcon: String {
        if paywallManager.hasPurchase {
            return "checkmark.seal.fill"
        } else if paywallManager.isInTrial {
            return "clock.fill"
        } else {
            return "sparkles"
        }
    }

    private var proStatusIconColor: Color {
        if paywallManager.hasPurchase {
            return .green
        } else if paywallManager.isInTrial {
            return .orange
        } else {
            return .accentColor
        }
    }

    private var proStatusTitle: String {
        if paywallManager.isProPlus {
            return "Pro+"
        } else if paywallManager.hasPurchase {
            return "Pro"
        } else if paywallManager.isInTrial {
            return "Pro Trial — \(paywallManager.trialDaysRemaining) days remaining"
        } else {
            return "Free — \(paywallManager.freeAnalysesUsed)/\(PaywallManager.freeAnalysesPerMonth) analyses used"
        }
    }

    private var proStatusSubtitle: String {
        if paywallManager.isProPlus {
            return "Unlimited analyses + document comparison"
        } else if paywallManager.hasPurchase {
            return "Unlimited analyses enabled"
        } else if paywallManager.isInTrial {
            return "Enjoy full Pro features during your trial"
        } else {
            return "Upgrade for unlimited analyses"
        }
    }

    private var proAccessibilityLabel: String {
        if paywallManager.hasPurchase {
            return "Pro subscription active. Unlimited analyses enabled."
        } else if paywallManager.isInTrial {
            return AccessibilityLabels.trialStatus(daysRemaining: paywallManager.trialDaysRemaining)
        } else {
            return AccessibilityLabels.freeAnalysesRemaining(paywallManager.remainingFreeAnalyses)
        }
    }
}

#Preview {
    SettingsView()
}
#endif
