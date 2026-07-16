import SwiftUI

/// The "Dawn Warm" design language: warm cream surfaces, an amber→coral
/// sunrise gradient for primary actions, rounded typography, and soft
/// spring animations. Every color has light/dark variants in Assets.xcassets
/// (cream backgrounds by day, warm charcoal by night).
enum Theme {
    static let background = Color("DawnBackground")
    static let surface = Color("DawnSurface")
    static let amber = Color("DawnAmber")
    /// Darker amber that stays legible as text/icons on light surfaces.
    static let amberDeep = Color("DawnAmberDeep")
    static let coral = Color("DawnCoral")

    static let sunrise = LinearGradient(
        colors: [amber, coral],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

/// Gradient capsule for the one main action on a screen.
struct DawnPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded).weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.sunrise, in: Capsule())
            .shadow(color: Theme.coral.opacity(configuration.isPressed ? 0.15 : 0.35),
                    radius: 12, y: 6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7),
                       value: configuration.isPressed)
    }
}

/// Soft warm capsule for the secondary choice next to a primary action.
struct DawnSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded).weight(.medium))
            .foregroundStyle(Theme.amberDeep)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.amber.opacity(0.16), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7),
                       value: configuration.isPressed)
    }
}

extension View {
    /// Warm rounded surface with a soft layered shadow.
    func dawnCard(cornerRadius: CGFloat = 20) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Theme.surface)
                .shadow(color: .black.opacity(0.07), radius: 14, y: 6)
                .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
        )
    }
}
