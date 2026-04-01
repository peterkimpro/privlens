#if canImport(SwiftUI)
import SwiftUI

/// Reusable Privlens logo view for branding throughout the app.
public struct AppLogoView: View {
    let size: CGFloat

    public init(size: CGFloat = 80) {
        self.size = size
    }

    public var body: some View {
        Image("AppLogo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.22))
    }
}
#endif
