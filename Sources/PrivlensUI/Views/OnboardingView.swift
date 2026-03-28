#if canImport(SwiftUI)
import SwiftUI
import PrivlensCore

/// Onboarding experience shown on first launch.
/// Highlights key value propositions: scanning, AI analysis, and privacy.
public struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "doc.viewfinder",
            iconColor: .blue,
            title: "Scan Any Document",
            description: "Use your camera to scan documents instantly. Medical bills, leases, insurance policies, contracts -- anything with text.",
            accessibilityLabel: "Scan any document. Use your camera to scan documents instantly."
        ),
        OnboardingPage(
            icon: "cpu",
            iconColor: .purple,
            title: "AI-Powered Analysis",
            description: "Get plain-English summaries, key terms, red flags, and action items. Powered by Apple Intelligence on your device.",
            accessibilityLabel: "AI powered analysis. Get summaries, key terms, red flags, and action items."
        ),
        OnboardingPage(
            icon: "lock.shield.fill",
            iconColor: .green,
            title: "100% Private",
            description: "Your documents never leave your device. Zero cloud. Zero tracking. All analysis happens locally on your iPhone.",
            accessibilityLabel: "100 percent private. Your documents never leave your device."
        ),
    ]

    public init(hasCompletedOnboarding: Binding<Bool>) {
        self._hasCompletedOnboarding = hasCompletedOnboarding
    }

    public var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    pageView(page)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .accessibilityIdentifier(AccessibilityIdentifiers.onboardingView)

            bottomBar
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
    }

    @ViewBuilder
    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: page.icon)
                .font(.system(size: 72))
                .foregroundStyle(page.iconColor)
                .accessibilityHidden(true)

            Text(page.title)
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Text(page.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(page.accessibilityLabel)
    }

    private var bottomBar: some View {
        HStack {
            if currentPage < pages.count - 1 {
                Button("Skip") {
                    completeOnboarding()
                }
                .foregroundStyle(.secondary)
                .accessibilityIdentifier(AccessibilityIdentifiers.onboardingSkipButton)
                .accessibilityLabel("Skip onboarding")

                Spacer()

                Button {
                    withAnimation {
                        currentPage += 1
                    }
                } label: {
                    Text("Next")
                        .fontWeight(.semibold)
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.onboardingContinueButton)
                .accessibilityLabel("Next page")
            } else {
                Button {
                    completeOnboarding()
                } label: {
                    Text("Get Started")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.tint)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .accessibilityIdentifier(AccessibilityIdentifiers.onboardingContinueButton)
                .accessibilityLabel("Get started with Privlens")
            }
        }
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "privlens_onboarding_completed")
    }
}

// MARK: - OnboardingPage

private struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let accessibilityLabel: String
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
#endif
