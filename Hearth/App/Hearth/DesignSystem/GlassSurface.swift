import SwiftUI

/// The one visual primitive most of Hearth's UI is built from: a translucent,
/// rounded surface over the system material stack. Keeping it in a single
/// modifier means the whole app's "glassmorphism" look lives in one place
/// instead of being re-implemented per screen.
struct GlassSurface: ViewModifier {
    var cornerRadius: CGFloat = 20
    var strokeOpacity: Double = 0.15

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(strokeOpacity), lineWidth: 1)
            )
    }
}

extension View {
    func glassSurface(cornerRadius: CGFloat = 20, strokeOpacity: Double = 0.15) -> some View {
        modifier(GlassSurface(cornerRadius: cornerRadius, strokeOpacity: strokeOpacity))
    }
}

/// Full-bleed backdrop used behind every tab: a soft gradient wash so the
/// glass surfaces on top of it have something translucent to actually show.
struct HearthBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.accentColor.opacity(0.18),
                Color(.systemBackground)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
