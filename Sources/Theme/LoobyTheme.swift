import SwiftUI

public enum LoobyPalette {
    // Inspired by the attached Looby Infinity AppIcon (Mint Green -> Cyan -> Electric Blue -> Soft Violet on crisp dark/light surfaces)
    public static let bgPrimary = Color(red: 0.04, green: 0.07, blue: 0.12)
    public static let bgSecondary = Color(red: 0.08, green: 0.12, blue: 0.20)
    public static let cardBg = Color(red: 0.10, green: 0.15, blue: 0.25)
    public static let cardElevated = Color(red: 0.13, green: 0.20, blue: 0.32)
    public static let border = Color.white.opacity(0.12)

    public static let textPrimary = Color.white
    public static let textSecondary = Color(red: 0.74, green: 0.81, blue: 0.91)
    public static let textMuted = Color(red: 0.50, green: 0.58, blue: 0.71)

    // Exact colors from the Looby Infinity Logo
    public static let infinityMint = Color(red: 0.29, green: 0.87, blue: 0.50)
    public static let infinityCyan = Color(red: 0.15, green: 0.80, blue: 0.92)
    public static let infinityBlue = Color(red: 0.25, green: 0.55, blue: 0.98)
    public static let infinityViolet = Color(red: 0.62, green: 0.45, blue: 0.97)
    public static let livriaCoral = Color(red: 0.96, green: 0.43, blue: 0.48)
    public static let goldAmber = Color(red: 0.98, green: 0.73, blue: 0.18)

    public static let infinityGradient = LinearGradient(
        colors: [infinityMint, infinityCyan, infinityBlue, infinityViolet],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let grandEstGradient = LinearGradient(
        colors: [Color(red: 0.06, green: 0.50, blue: 0.43), infinityCyan, infinityBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let livriaBridgeGradient = LinearGradient(
        colors: [infinityViolet, Color(red: 0.88, green: 0.32, blue: 0.55), livriaCoral],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Animated Looby Infinity Vector Emblem + Asset View

public struct LoobyAnimatedInfinityHero: View {
    var size: CGFloat = 110
    @State private var phase: CGFloat = 0
    @State private var pulse: Bool = false

    public init(size: CGFloat = 110) {
        self.size = size
    }

    public var body: some View {
        ZStack {
            // Outer animated aura
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            LoobyPalette.infinityMint.opacity(0.32),
                            LoobyPalette.infinityCyan.opacity(0.18),
                            LoobyPalette.infinityViolet.opacity(0.02)
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: size * 0.85
                    )
                )
                .frame(width: size * 1.55, height: size * 1.55)
                .scaleEffect(pulse ? 1.08 : 0.93)

            // Rounded white icon container matching the official AppIcon
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(Color.white)
                .frame(width: size, height: size)
                .shadow(color: LoobyPalette.infinityCyan.opacity(0.45), radius: 18, y: 8)
                .overlay(
                    Image("LoobyLogo")
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                        .stroke(
                            AngularGradient(
                                colors: [
                                    LoobyPalette.infinityMint,
                                    LoobyPalette.infinityCyan,
                                    LoobyPalette.infinityBlue,
                                    LoobyPalette.infinityViolet,
                                    LoobyPalette.infinityMint
                                ],
                                center: .center,
                                angle: .degrees(phase)
                            ),
                            lineWidth: 3
                        )
                )
                .rotation3DEffect(
                    .degrees(pulse ? 4 : -4),
                    axis: (x: 0.2, y: 1.0, z: 0.0)
                )
        }
        .onAppear {
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                phase = 360
            }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

// MARK: - Reusable Glass Card & Pill Components

public struct LoobyGlassCard<Content: View>: View {
    var borderColor: Color = LoobyPalette.border
    @ViewBuilder var content: () -> Content

    public init(borderColor: Color = LoobyPalette.border, @ViewBuilder content: @escaping () -> Content) {
        self.borderColor = borderColor
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LoobyPalette.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
    }
}

public struct LoobyBadgePill: View {
    let text: String
    let color: Color

    public init(text: String, color: Color) {
        self.text = text
        self.color = color
    }

    public var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.16))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(color.opacity(0.35), lineWidth: 1)
            )
    }
}
