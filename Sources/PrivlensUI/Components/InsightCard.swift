#if canImport(SwiftUI)
import SwiftUI

public struct InsightCard: View {
    let text: String
    let icon: String
    let tint: Color

    public init(text: String, icon: String, tint: Color) {
        self.text = text
        self.icon = icon
        self.tint = tint
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .font(.subheadline)

            Text(text)
                .font(.subheadline)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    VStack {
        InsightCard(text: "Your deductible is $5,000 — higher than average.", icon: "lightbulb.fill", tint: .yellow)
        InsightCard(text: "Late payment penalty: $150 per month", icon: "exclamationmark.circle.fill", tint: .red)
    }
    .padding()
}
#endif
