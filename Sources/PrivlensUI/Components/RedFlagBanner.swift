#if canImport(SwiftUI)
import SwiftUI

public struct RedFlagBanner: View {
    let count: Int

    public init(count: Int) {
        self.count = count
    }

    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "eye.fill")
                .foregroundStyle(.white)
                .font(.caption)

            Text("\(count) thing\(count == 1 ? "" : "s") to know")
                .font(.caption.bold())
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.blue)
        .clipShape(Capsule())
    }
}

#Preview {
    VStack {
        RedFlagBanner(count: 1)
        RedFlagBanner(count: 3)
    }
}
#endif
