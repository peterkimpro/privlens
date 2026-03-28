#if canImport(SwiftUI)
import SwiftUI
import PrivlensCore
#if canImport(StoreKit)
import StoreKit
#endif

public struct SettingsView: View {
    @State private var showPaywall = false
    @State private var paywallManager = PaywallManager()

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
                }
            }
        }
        .tint(.primary)
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
            return .tint
        }
    }

    private var proStatusTitle: String {
        if paywallManager.hasPurchase {
            return "Pro"
        } else if paywallManager.isInTrial {
            return "Pro Trial — \(paywallManager.trialDaysRemaining) days remaining"
        } else {
            return "Free — \(paywallManager.freeAnalysesUsed)/\(PaywallManager.freeAnalysesPerMonth) analyses used"
        }
    }

    private var proStatusSubtitle: String {
        if paywallManager.hasPurchase {
            return "Unlimited analyses enabled"
        } else if paywallManager.isInTrial {
            return "Enjoy full Pro features during your trial"
        } else {
            return "Upgrade for unlimited analyses"
        }
    }
}

#Preview {
    SettingsView()
}
#endif
