#if canImport(SwiftUI) && canImport(StoreKit)
import SwiftUI
import StoreKit
import PrivlensCore

public struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var paywallManager = PaywallManager()
    @State private var isPurchasing = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Trial Banner
                    if paywallManager.isInTrial {
                        trialBanner
                    }

                    // Hero
                    heroSection

                    // Feature Comparison
                    featureComparisonSection

                    // Product Options
                    productOptionsSection

                    // Restore
                    restoreButton

                    // Legal
                    legalSection
                }
                .padding()
            }
            .navigationTitle("Go Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                await paywallManager.loadProducts()
            }
        }
    }

    // MARK: - Trial Banner

    private var trialBanner: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.orange)
                Text("\(paywallManager.trialDaysRemaining) days left of your free trial")
                    .font(.subheadline.bold())
            }

            let totalTrialDays = 7
            let progress = max(0, min(1, 1.0 - Double(paywallManager.trialDaysRemaining) / Double(totalTrialDays)))
            ProgressView(value: progress)
                .tint(.orange)
        }
        .padding()
        .background(.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Sections

    private var heroSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            Text("Unlock Unlimited Analysis")
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Text("Get unlimited AI-powered document analysis, all processed privately on your device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }

    private var featureComparisonSection: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Feature")
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Free")
                    .font(.caption.bold())
                    .frame(width: 60)
                Text("Pro")
                    .font(.caption.bold())
                    .foregroundStyle(.tint)
                    .frame(width: 60)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.tint.opacity(0.1))

            Divider()

            featureRow("Document Scanning", free: true, pro: true)
            featureRow("OCR Text Extraction", free: true, pro: true)
            featureRow("AI Analysis", free: "3/mo", pro: "Unlimited")
            featureRow("Red Flag Detection", free: true, pro: true)
            featureRow("Document Library", free: true, pro: true)
            featureRow("Priority Processing", free: false, pro: true)
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func featureRow(_ name: String, free: Bool, pro: Bool) -> some View {
        featureRow(name, freeText: free ? "checkmark" : "xmark", proText: pro ? "checkmark" : "xmark", isFreeIcon: true, isProIcon: true)
    }

    private func featureRow(_ name: String, free: String, pro: String) -> some View {
        featureRow(name, freeText: free, proText: pro, isFreeIcon: false, isProIcon: false)
    }

    private func featureRow(_ name: String, freeText: String, proText: String, isFreeIcon: Bool, isProIcon: Bool) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(name)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Group {
                    if isFreeIcon {
                        Image(systemName: freeText)
                            .foregroundStyle(freeText == "checkmark" ? .green : .red)
                    } else {
                        Text(freeText)
                            .font(.caption)
                    }
                }
                .frame(width: 60)

                Group {
                    if isProIcon {
                        Image(systemName: proText)
                            .foregroundStyle(proText == "checkmark" ? .green : .red)
                    } else {
                        Text(proText)
                            .font(.caption)
                            .foregroundStyle(.tint)
                            .bold()
                    }
                }
                .frame(width: 60)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)

            Divider()
        }
    }

    private var productOptionsSection: some View {
        VStack(spacing: 12) {
            if paywallManager.products.isEmpty {
                ProgressView("Loading plans...")
            } else {
                ForEach(paywallManager.products, id: \.id) { product in
                    productButton(for: product)
                }
            }

            if let error = paywallManager.purchaseError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private func productButton(for product: Product) -> some View {
        let recommended = isRecommended(product)

        return Button {
            Task {
                isPurchasing = true
                defer { isPurchasing = false }
                try? await paywallManager.purchase(product)
                if paywallManager.isPro {
                    dismiss()
                }
            }
        } label: {
            VStack(spacing: 0) {
                if recommended {
                    Text("RECOMMENDED")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity)
                        .background(.tint)
                }

                HStack {
                    VStack(alignment: .leading) {
                        Text(product.displayName)
                            .font(.headline)
                        Text(product.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(product.displayPrice)
                        .font(.headline)
                }
                .padding()
            }
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.tint, lineWidth: recommended ? 3 : 0)
            )
            .overlay(alignment: .topTrailing) {
                productBadge(for: product)
            }
        }
        .buttonStyle(.plain)
        .disabled(isPurchasing)
    }

    @ViewBuilder
    private func productBadge(for product: Product) -> some View {
        if product.id == PaywallManager.ProductID.annual.rawValue {
            Text("Save 58%")
                .font(.caption2.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.green, in: RoundedRectangle(cornerRadius: 6))
                .offset(x: -8, y: -8)
        } else if product.id == PaywallManager.ProductID.lifetime.rawValue {
            Text("Best Value")
                .font(.caption2.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.orange, in: RoundedRectangle(cornerRadius: 6))
                .offset(x: -8, y: -8)
        }
    }

    private func isRecommended(_ product: Product) -> Bool {
        product.id == PaywallManager.ProductID.annual.rawValue
    }

    private var restoreButton: some View {
        Button("Restore Purchases") {
            Task {
                await paywallManager.restorePurchases()
                if paywallManager.isPro {
                    dismiss()
                }
            }
        }
        .font(.subheadline)
    }

    private var legalSection: some View {
        VStack(spacing: 4) {
            Text("Payment will be charged to your Apple ID account. Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Link("Terms of Use", destination: URL(string: "https://privlens.app/terms")!)
                Link("Privacy Policy", destination: URL(string: "https://privlens.app/privacy")!)
            }
            .font(.caption2)
        }
    }
}
#endif
