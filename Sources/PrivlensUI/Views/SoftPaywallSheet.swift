#if canImport(SwiftUI) && canImport(StoreKit)
import SwiftUI
import PrivlensCore

/// A soft paywall sheet shown when the user has exhausted their free monthly analyses.
/// Triggered by `AnalysisCoordinator` throwing `.analysisLimitReached`.
public struct SoftPaywallSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showFullPaywall = false

    public init() {}

    public var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            // Title
            Text("You've used all 3 free analyses this month")
                .font(.title3.bold())
                .multilineTextAlignment(.center)

            // Subtitle
            Text("Upgrade to Pro for unlimited AI-powered document analysis, all processed privately on your device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // CTA
            Button {
                showFullPaywall = true
            } label: {
                Text("Upgrade to Pro")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundStyle(.white)
                    .background(.tint, in: RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal)

            // Dismiss
            Button("Maybe later") {
                dismiss()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
        .sheet(isPresented: $showFullPaywall) {
            PaywallView()
        }
    }
}
#endif
