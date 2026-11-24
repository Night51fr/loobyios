import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Système de Design Adaptatif Clair & Sombre « Looby Taker » (Palette Or / Ambre / Corail Infini • Swift 6)

public enum LoobyTakerAppearanceMode: String, CaseIterable, Identifiable, Sendable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    public var id: String { rawValue }

    public var labelFr: String {
        switch self {
        case .system: return "Automatique"
        case .light: return "Mode Clair"
        case .dark: return "Mode Sombre"
        }
    }

    public var iconName: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.stars.fill"
        }
    }

    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

public enum LoobyTakerPalette {
    private static func dynamicColor(
        light: (CGFloat, CGFloat, CGFloat, CGFloat),
        dark: (CGFloat, CGFloat, CGFloat, CGFloat)
    ) -> Color {
        #if canImport(UIKit)
        return Color(
            UIColor { traits in
                let tuple = traits.userInterfaceStyle == .dark ? dark : light
                return UIColor(red: tuple.0, green: tuple.1, blue: tuple.2, alpha: tuple.3)
            }
        )
        #else
        return Color(red: light.0, green: light.1, blue: light.2, opacity: light.3)
        #endif
    }

    // Signatures chromatiques inspirées du logo infini doré-corail LoobyTakerLogo
    public static let amberPrimary = dynamicColor(
        light: (0.91, 0.56, 0.08, 1.0),
        dark: (0.98, 0.71, 0.22, 1.0)
    )

    public static let amberDeep = dynamicColor(
        light: (0.72, 0.39, 0.04, 1.0),
        dark: (0.96, 0.78, 0.36, 1.0)
    )

    public static let goldBright = Color(red: 0.96, green: 0.73, blue: 0.18)
    public static let coralGlow = Color(red: 0.94, green: 0.43, blue: 0.36)
    public static let roseWarm = Color(red: 0.93, green: 0.34, blue: 0.47)

    public static let amberSoft = dynamicColor(
        light: (0.99, 0.94, 0.83, 1.0),
        dark: (0.28, 0.20, 0.08, 0.75)
    )

    public static let coralSoft = dynamicColor(
        light: (1.00, 0.91, 0.89, 1.0),
        dark: (0.30, 0.14, 0.14, 0.75)
    )

    // Couleurs fonctionnelles (Succès, Pro, Alerte, Danger)
    public static let emerald = dynamicColor(
        light: (0.06, 0.64, 0.45, 1.0),
        dark: (0.18, 0.82, 0.60, 1.0)
    )

    public static let emeraldSoft = dynamicColor(
        light: (0.87, 0.97, 0.93, 1.0),
        dark: (0.07, 0.24, 0.18, 0.80)
    )

    public static let proCobalt = dynamicColor(
        light: (0.15, 0.42, 0.88, 1.0),
        dark: (0.36, 0.64, 0.99, 1.0)
    )

    public static let proCobaltSoft = dynamicColor(
        light: (0.89, 0.94, 1.00, 1.0),
        dark: (0.10, 0.18, 0.34, 0.80)
    )

    public static let upsBrown = dynamicColor(
        light: (0.42, 0.26, 0.11, 1.0),
        dark: (0.85, 0.65, 0.42, 1.0)
    )

    public static let danger = dynamicColor(
        light: (0.86, 0.18, 0.22, 1.0),
        dark: (0.98, 0.38, 0.40, 1.0)
    )

    // Surfaces & Typographie Clair / Sombre
    public static let background = dynamicColor(
        light: (0.98, 0.97, 0.95, 1.0),
        dark: (0.06, 0.07, 0.09, 1.0)
    )

    public static let backgroundElevated = dynamicColor(
        light: (0.95, 0.93, 0.89, 1.0),
        dark: (0.11, 0.12, 0.16, 1.0)
    )

    public static let cardSurface = dynamicColor(
        light: (1.00, 1.00, 1.00, 1.0),
        dark: (0.11, 0.12, 0.15, 1.0)
    )

    public static let cardSubtle = dynamicColor(
        light: (0.97, 0.96, 0.93, 1.0),
        dark: (0.15, 0.16, 0.20, 1.0)
    )

    public static let ink = dynamicColor(
        light: (0.10, 0.11, 0.15, 1.0),
        dark: (0.96, 0.96, 0.98, 1.0)
    )

    public static let inkSecondary = dynamicColor(
        light: (0.36, 0.38, 0.44, 1.0),
        dark: (0.72, 0.74, 0.80, 1.0)
    )

    public static let inkMuted = dynamicColor(
        light: (0.52, 0.54, 0.60, 1.0),
        dark: (0.55, 0.58, 0.65, 1.0)
    )

    public static let border = dynamicColor(
        light: (0.89, 0.86, 0.81, 1.0),
        dark: (0.22, 0.24, 0.29, 1.0)
    )

    public static var signatureGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.95, green: 0.68, blue: 0.14),
                Color(red: 0.93, green: 0.50, blue: 0.22),
                Color(red: 0.92, green: 0.38, blue: 0.40)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    public static var goldCoralHorizontal: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.93, green: 0.61, blue: 0.10),
                Color(red: 0.93, green: 0.42, blue: 0.34)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Arrière-Plan Hero « Looby Taker » (Ambre / Or / Corail Profond)

public struct LoobyTakerHeroBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    public var isProStyle: Bool

    public init(isProStyle: Bool = false) {
        self.isProStyle = isProStyle
    }

    public var body: some View {
        ZStack {
            if isProStyle {
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [
                            Color(red: 0.08, green: 0.14, blue: 0.28),
                            Color(red: 0.15, green: 0.24, blue: 0.46),
                            Color(red: 0.36, green: 0.24, blue: 0.14)
                        ]
                        : [
                            Color(red: 0.11, green: 0.26, blue: 0.56),
                            Color(red: 0.18, green: 0.38, blue: 0.74),
                            Color(red: 0.84, green: 0.52, blue: 0.14)
                        ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: colorScheme == .dark
                        ? [
                            Color(red: 0.24, green: 0.14, blue: 0.05),
                            Color(red: 0.42, green: 0.21, blue: 0.09),
                            Color(red: 0.46, green: 0.17, blue: 0.20)
                        ]
                        : [
                            Color(red: 0.84, green: 0.47, blue: 0.06),
                            Color(red: 0.92, green: 0.56, blue: 0.14),
                            Color(red: 0.89, green: 0.35, blue: 0.33)
                        ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            // Halo lumineux infini subtil
            Circle()
                .fill(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.16))
                .frame(width: 220, height: 220)
                .blur(radius: 36)
                .offset(x: 110, y: -60)

            Circle()
                .fill(LoobyTakerPalette.goldBright.opacity(colorScheme == .dark ? 0.14 : 0.24))
                .frame(width: 180, height: 180)
                .blur(radius: 30)
                .offset(x: -115, y: 70)
        }
    }
}

// MARK: - Dessin Vectoriel Lumineux de l'Infini « Looby Taker » + Médaillon Logo

public struct LoobyTakerInfinityShape: Shape {
    public init() {}

    public func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let cx = rect.midX
        let cy = rect.midY
        let rx = w * 0.44
        let ry = h * 0.38

        var path = Path()
        let steps = 120
        for i in 0...steps {
            let t = (Double(i) / Double(steps)) * (2.0 * Double.pi)
            // Courbe de Lemniscate de Bernoulli lissée
            let denom = 1.0 + sin(t) * sin(t)
            let x = cx + rx * CGFloat(cos(t) / denom)
            let y = cy + ry * CGFloat((sin(t) * cos(t)) / denom) * 1.35
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}

public struct LoobyTakerBrandMedallion: View {
    public var size: CGFloat
    public var showGlow: Bool

    public init(size: CGFloat = 64, showGlow: Bool = true) {
        self.size = size
        self.showGlow = showGlow
    }

    public var body: some View {
        ZStack {
            if showGlow {
                RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                LoobyTakerPalette.goldBright.opacity(0.50),
                                LoobyTakerPalette.coralGlow.opacity(0.45)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size * 1.12, height: size * 1.12)
                    .blur(radius: size * 0.16)
            }

            #if canImport(UIKit)
            if let img = UIImage(named: "LoobyTakerLogo") {
                Image(uiImage: img)
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: size * 0.23, style: .continuous))
                    .shadow(color: Color.black.opacity(0.16), radius: 8, x: 0, y: 4)
            } else {
                vectorFallback
            }
            #else
            vectorFallback
            #endif
        }
    }

    private var vectorFallback: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.23, style: .continuous)
                .fill(Color.white)
                .frame(width: size, height: size)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.23, style: .continuous)
                        .stroke(LoobyTakerPalette.border, lineWidth: 1)
                )

            LoobyTakerInfinityShape()
                .stroke(
                    LoobyTakerPalette.signatureGradient,
                    style: StrokeStyle(lineWidth: max(3, size * 0.11), lineCap: .round, lineJoin: .round)
                )
                .frame(width: size * 0.78, height: size * 0.56)
                .shadow(color: LoobyTakerPalette.coralGlow.opacity(0.45), radius: 4, x: 0, y: 2)
        }
    }
}

// MARK: - Modificateurs de Cartes & Retours Haptiques

public struct LoobyTakerCardModifier: ViewModifier {
    public var padding: CGFloat

    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(LoobyTakerPalette.cardSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(LoobyTakerPalette.border, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

extension View {
    public func loobyTakerCard(padding: CGFloat = 16) -> some View {
        modifier(LoobyTakerCardModifier(padding: padding))
    }

    public func loobyTakerScreenBackground() -> some View {
        background(LoobyTakerPalette.background.ignoresSafeArea())
    }
}

@MainActor
public enum LoobyTakerHaptics {
    public static func impact(_ style: Int = 1) {
        #if canImport(UIKit)
        let uiStyle: UIImpactFeedbackGenerator.FeedbackStyle
        switch style {
        case 0: uiStyle = .light
        case 2: uiStyle = .heavy
        default: uiStyle = .medium
        }
        let generator = UIImpactFeedbackGenerator(style: uiStyle)
        generator.prepare()
        generator.impactOccurred()
        #endif
    }

    public static func success() {
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
        #endif
    }

    public static func warning() {
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.warning)
        #endif
    }

    public static func error() {
        #if canImport(UIKit)
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
        #endif
    }
}
