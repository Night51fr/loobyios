import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - LaunchScreen Motion Design « Cenelis Apps » -> « Looby Taker » (120 Hz Canvas • Swift 6)

private struct OrbitalEcosystemItem: Identifiable, Sendable {
    let id: String
    let name: String
    let symbol: String
    let gradient: [Color]
    let glow: Color
    let isTargetLoobyTaker: Bool
}

public struct LoobyTakerLaunchAnimationView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public let onCompleted: () -> Void

    @State private var startDate: Date = Date()
    @State private var didAppear: Bool = false

    private let tSpinEnd: Double = 1.65
    private let tLockEnd: Double = 2.30
    private let tFinish: Double = 2.95

    private let orbitalItems: [OrbitalEcosystemItem] = [
        OrbitalEcosystemItem(
            id: "looby-taker",
            name: "Looby Taker",
            symbol: "infinity",
            gradient: [Color(red: 0.96, green: 0.72, blue: 0.16), Color(red: 0.94, green: 0.42, blue: 0.36)],
            glow: Color(red: 0.96, green: 0.68, blue: 0.18),
            isTargetLoobyTaker: true
        ),
        OrbitalEcosystemItem(
            id: "viple-mail",
            name: "Viple Mail",
            symbol: "envelope.open.fill",
            gradient: [Color(red: 0.04, green: 0.30, blue: 0.80), Color(red: 0.12, green: 0.72, blue: 0.98)],
            glow: Color(red: 0.14, green: 0.68, blue: 1.00),
            isTargetLoobyTaker: false
        ),
        OrbitalEcosystemItem(
            id: "livria-store",
            name: "Livria Store",
            symbol: "book.closed.fill",
            gradient: [Color(red: 0.52, green: 0.24, blue: 0.96), Color(red: 0.95, green: 0.36, blue: 0.68)],
            glow: Color(red: 0.68, green: 0.34, blue: 0.98),
            isTargetLoobyTaker: false
        ),
        OrbitalEcosystemItem(
            id: "viple-delivery",
            name: "Viple Delivery",
            symbol: "truck.box.fill",
            gradient: [Color(red: 0.08, green: 0.64, blue: 0.46), Color(red: 0.22, green: 0.86, blue: 0.66)],
            glow: Color(red: 0.16, green: 0.84, blue: 0.62),
            isTargetLoobyTaker: false
        ),
        OrbitalEcosystemItem(
            id: "livria-social",
            name: "Livria Social",
            symbol: "bubble.left.and.bubble.right.fill",
            gradient: [Color(red: 0.64, green: 0.26, blue: 0.96), Color(red: 0.96, green: 0.34, blue: 0.62)],
            glow: Color(red: 0.95, green: 0.33, blue: 0.68),
            isTargetLoobyTaker: false
        ),
        OrbitalEcosystemItem(
            id: "cenelis-academy",
            name: "Cenelis Academy",
            symbol: "graduationcap.fill",
            gradient: [Color(red: 0.06, green: 0.38, blue: 0.28), Color(red: 0.88, green: 0.56, blue: 0.14)],
            glow: Color(red: 0.96, green: 0.72, blue: 0.22),
            isTargetLoobyTaker: false
        ),
        OrbitalEcosystemItem(
            id: "looby",
            name: "Looby",
            symbol: "storefront.fill",
            gradient: [Color(red: 0.14, green: 0.78, blue: 0.56), Color(red: 0.22, green: 0.58, blue: 0.96)],
            glow: Color(red: 0.22, green: 0.88, blue: 0.66),
            isTargetLoobyTaker: false
        )
    ]

    public init(onCompleted: @escaping () -> Void) {
        self.onCompleted = onCompleted
    }

    public var body: some View {
        GeometryReader { geo in
            let minDim = min(geo.size.width, geo.size.height)
            let orbitRadius = min(max(minDim * 0.34, 112), 152)

            TimelineView(.animation(minimumInterval: 1.0 / 120.0, paused: false)) { timeline in
                let rawElapsed = didAppear ? max(0, timeline.date.timeIntervalSince(startDate)) : 0
                let t = reduceMotion ? min(rawElapsed * 1.5, tFinish) : min(rawElapsed, tFinish)

                let introP = Self.easeOutBack(Self.clamp01(t / 0.52))
                let spinP = Self.easeInOutCubic(Self.clamp01(t / tSpinEnd))
                let lockP = Self.easeInOutCubic(Self.clamp01((t - tSpinEnd) / (tLockEnd - tSpinEnd)))
                let zoomP = Self.easeInCubic(Self.clamp01((t - tLockEnd) / (tFinish - tLockEnd)))

                ZStack {
                    // 1. Fond Cosmique Cenelis × Or Looby Taker
                    cosmicBackdrop(elapsed: t, lockP: lockP)
                        .ignoresSafeArea()

                    VStack(spacing: 0) {
                        Spacer(minLength: max(24, geo.size.height * 0.07))

                        // En-tête « Cenelis Apps » -> « Looby Taker »
                        headerBlock(elapsed: t, introP: introP, lockP: lockP, zoomP: zoomP)

                        Spacer(minLength: 10)

                        // Scène Orbitale 3D + Zoom Dynamique sur l'icône infini dorée Looby Taker
                        orbitalStage(
                            elapsed: t,
                            orbitRadius: orbitRadius,
                            introP: introP,
                            spinP: spinP,
                            lockP: lockP,
                            zoomP: zoomP
                        )
                        .frame(width: orbitRadius * 2.5, height: orbitRadius * 2.2)

                        Spacer(minLength: 10)

                        // Légende dynamique en bas d'écran
                        footerStatusBlock(elapsed: t, introP: introP, lockP: lockP, zoomP: zoomP)

                        Spacer(minLength: max(28, geo.size.height * 0.07))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Voile doré lumineux final au sommet du zoom
                    if zoomP > 0.05 {
                        LinearGradient(
                            colors: [
                                Color(red: 0.96, green: 0.72, blue: 0.18),
                                Color(red: 0.94, green: 0.45, blue: 0.34)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .ignoresSafeArea()
                        .opacity(Self.smoothstep(0.25, 0.98, zoomP))
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onCompleted()
        }
        .onAppear {
            startDate = Date()
            didAppear = true
        }
        .task {
            let speedDiv: Double = reduceMotion ? 1.5 : 1.0
            try? await Task.sleep(nanoseconds: UInt64((0.15 / speedDiv) * 1_000_000_000))
            if Task.isCancelled { return }
            LoobyTakerHaptics.impact(0)

            try? await Task.sleep(nanoseconds: UInt64(((tSpinEnd - 0.15) / speedDiv) * 1_000_000_000))
            if Task.isCancelled { return }
            LoobyTakerHaptics.impact(1)

            try? await Task.sleep(nanoseconds: UInt64(((tFinish - tSpinEnd) / speedDiv) * 1_000_000_000))
            if Task.isCancelled { return }
            LoobyTakerHaptics.impact(2)
            onCompleted()
        }
    }

    // MARK: - Composants Visuels

    private func cosmicBackdrop(elapsed: Double, lockP: Double) -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.04, blue: 0.09),
                    Color(red: 0.07, green: 0.06, blue: 0.14),
                    Color(red: 0.13, green: 0.08, blue: 0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Canvas { ctx, size in
                let w = size.width
                let h = size.height
                let center = CGPoint(x: w * 0.5, y: h * 0.5)
                let goldRadius = w * (0.45 + 0.32 * CGFloat(lockP))

                ctx.fill(
                    Path(ellipseIn: CGRect(x: center.x - goldRadius, y: center.y - goldRadius, width: goldRadius * 2, height: goldRadius * 2)),
                    with: .radialGradient(
                        Gradient(colors: [
                            Color(red: 0.96, green: 0.68, blue: 0.16).opacity(0.18 + 0.28 * lockP),
                            Color(red: 0.94, green: 0.40, blue: 0.36).opacity(0.10 + 0.16 * lockP),
                            Color.clear
                        ]),
                        center: center,
                        startRadius: 8,
                        endRadius: goldRadius
                    )
                )

                for i in 0..<22 {
                    let seed = Double(i) * 1.618
                    let nx = abs((sin(seed * 12.98) * 43758.5).truncatingRemainder(dividingBy: 1.0))
                    let ny = abs((cos(seed * 78.23) * 29432.1).truncatingRemainder(dividingBy: 1.0))
                    let dy = (ny - elapsed * 0.03).truncatingRemainder(dividingBy: 1.0)
                    let py = CGFloat(dy < 0 ? dy + 1.0 : dy) * h
                    let px = CGFloat(nx) * w
                    let dot = CGFloat(1.8 + Double(i % 3) * 0.8)
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: px, y: py, width: dot, height: dot)),
                        with: .color(Color(red: 0.98, green: 0.84, blue: 0.52).opacity(0.42))
                    )
                }
            }
        }
    }

    private func headerBlock(elapsed: Double, introP: Double, lockP: Double, zoomP: Double) -> some View {
        let fadeOut = 1.0 - Self.clamp01(zoomP * 2.2)
        return VStack(spacing: 10) {
            HStack(spacing: 7) {
                Circle()
                    .fill(LoobyTakerPalette.goldBright)
                    .frame(width: 7, height: 7)
                    .shadow(color: LoobyTakerPalette.goldBright, radius: 5)
                Text("GROUPE CENELIS  ×  ÉCOSYSTÈME VIPLE")
                    .font(.system(size: 10.5, weight: .black, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(Color.white.opacity(0.92))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.09))
                    .overlay(Capsule().stroke(LoobyTakerPalette.goldBright.opacity(0.42), lineWidth: 1))
            )

            HStack(spacing: 8) {
                Text(lockP > 0.38 ? "Looby" : "Cenelis")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(lockP > 0.38 ? "Taker" : "Apps")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(LoobyTakerPalette.signatureGradient)
            }
            .animation(.easeInOut(duration: 0.28), value: lockP > 0.38)

            Text(
                lockP > 0.38
                    ? "Points Relais Particuliers (1 €/colis) & Commerces Pro"
                    : "Toutes vos applications unifiées par Viple Live ID"
            )
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(Color.white.opacity(0.76))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 28)
        }
        .opacity(min(1, max(0, introP)) * fadeOut)
        .scaleEffect(0.92 + 0.08 * CGFloat(min(1, introP)))
    }

    private func orbitalStage(
        elapsed: Double,
        orbitRadius: CGFloat,
        introP: Double,
        spinP: Double,
        lockP: Double,
        zoomP: Double
    ) -> some View {
        let tiltRatio: CGFloat = 0.56
        let count = orbitalItems.count
        let endBaseAngle = Double.pi / 2.0 // index 0 (Looby Taker) at front zenith +π/2
        let startBaseAngle = endBaseAngle - (2.0 * Double.pi * (reduceMotion ? 0.35 : 1.25))
        let currentBaseAngle = startBaseAngle + (endBaseAngle - startBaseAngle) * spinP

        return ZStack {
            // Anneaux orbitaux lumineux
            Canvas { ctx, size in
                let cx = size.width * 0.5
                let cy = size.height * 0.5
                let rx = orbitRadius * CGFloat(min(1, max(0, introP)))
                let ry = rx * tiltRatio
                let fade = max(0, 1.0 - lockP * 1.1)
                guard rx > 6, fade > 0.01 else { return }

                let mainRing = Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
                ctx.stroke(mainRing, with: .color(Color.white.opacity(0.18 * fade)), style: StrokeStyle(lineWidth: 1.3))

                let outerRing = Path(ellipseIn: CGRect(x: cx - rx * 1.18, y: cy - ry * 1.18, width: rx * 2.36, height: ry * 2.36))
                ctx.stroke(
                    outerRing,
                    with: .color(LoobyTakerPalette.goldBright.opacity(0.32 * fade)),
                    style: StrokeStyle(lineWidth: 1.1, dash: [5, 7], dashPhase: CGFloat(-elapsed * 30))
                )
            }

            // Dessin vectoriel infini lumineux derrière l'icône Looby Taker lors du verrouillage central
            if lockP > 0.04 {
                let trimEnd = CGFloat(min(1.0, lockP * 1.25))
                LoobyTakerInfinityShape()
                    .trim(from: 0, to: trimEnd)
                    .stroke(
                        LoobyTakerPalette.signatureGradient,
                        style: StrokeStyle(lineWidth: 6.5, lineCap: .round, lineJoin: .round)
                    )
                    .frame(width: 210, height: 120)
                    .blur(radius: 1.2)
                    .opacity((1.0 - zoomP * 0.85) * lockP)
                    .scaleEffect(0.85 + 0.35 * CGFloat(lockP) + 2.8 * CGFloat(zoomP))
            }

            // Icônes en orbite
            ForEach(Array(orbitalItems.enumerated()), id: \.element.id) { idx, item in
                let theta = currentBaseAngle + (2.0 * Double.pi * Double(idx)) / Double(count)
                let cosT = CGFloat(cos(theta))
                let sinT = CGFloat(sin(theta))
                let depth01 = (sinT + 1.0) * 0.5
                let activeR = orbitRadius * CGFloat(min(1.08, max(0, introP)))
                let ox = cosT * activeR
                let oy = sinT * activeR * tiltRatio

                if item.isTargetLoobyTaker {
                    let px = ox * (1.0 - CGFloat(lockP))
                    let py = oy * (1.0 - CGFloat(lockP))
                    let baseScale = 0.78 + 0.42 * depth01
                    let centerScale = baseScale + (1.52 - baseScale) * CGFloat(lockP)
                    let diveScale = centerScale * (1.0 + 11.5 * CGFloat(pow(zoomP, 2.5)))

                    LoobyTakerBrandMedallion(size: 68, showGlow: true)
                        .scaleEffect(max(0.01, diveScale))
                        .offset(x: px, y: py)
                        .opacity(1.0 - Self.smoothstep(0.72, 0.99, zoomP))
                        .zIndex(lockP > 0.05 ? 50 : Double(sinT * 10 + 1))
                } else {
                    let shrink = 1.0 - CGFloat(Self.smoothstep(0.0, 0.75, lockP))
                    let px = ox * (0.45 + 0.55 * shrink)
                    let py = oy * (0.45 + 0.55 * shrink)
                    let tileScale = (0.72 + 0.34 * depth01) * (0.45 + 0.55 * shrink)

                    ZStack {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: item.gradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                            .overlay(
                                RoundedRectangle(cornerRadius: 13, style: .continuous)
                                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
                            )
                            .shadow(color: item.glow.opacity(0.4), radius: 8, x: 0, y: 4)

                        Image(systemName: item.symbol)
                            .font(.system(size: 21, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .scaleEffect(max(0.01, tileScale))
                    .offset(x: px, y: py)
                    .opacity(Double(shrink) * Double(0.65 + 0.35 * depth01))
                    .zIndex(Double(sinT * 10))
                }
            }
        }
    }

    private func footerStatusBlock(elapsed: Double, introP: Double, lockP: Double, zoomP: Double) -> some View {
        let fadeOut = 1.0 - Self.clamp01(zoomP * 2.4)
        return VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: lockP > 0.25 ? "barcode.viewfinder" : "sparkles")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(LoobyTakerPalette.goldBright)
                Text(
                    lockP > 0.25
                        ? "Ouverture de Looby Taker • Réseau Viple Delivery & UPS"
                        : "Synchronisation SSO Viple Live ID…"
                )
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.10))
                    .overlay(Capsule().stroke(LoobyTakerPalette.goldBright.opacity(0.45), lineWidth: 1))
            )

            Text("Touchez l'écran pour passer l'introduction")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.48))
        }
        .opacity(min(1, max(0, introP)) * fadeOut)
    }

    // MARK: - Courbes d'interpolation

    private static func clamp01(_ x: Double) -> Double { min(1.0, max(0.0, x)) }

    private static func smoothstep(_ e0: Double, _ e1: Double, _ x: Double) -> Double {
        guard e1 > e0 else { return x >= e1 ? 1.0 : 0.0 }
        let t = clamp01((x - e0) / (e1 - e0))
        return t * t * (3.0 - 2.0 * t)
    }

    private static func easeInCubic(_ t: Double) -> Double {
        let c = clamp01(t)
        return c * c * c
    }

    private static func easeInOutCubic(_ t: Double) -> Double {
        let c = clamp01(t)
        return c < 0.5 ? 4 * c * c * c : 1 - pow(-2 * c + 2, 3) / 2
    }

    private static func easeOutBack(_ t: Double) -> Double {
        let c = clamp01(t)
        let c1 = 1.40
        let c3 = c1 + 1.0
        return 1.0 + c3 * pow(c - 1.0, 3) + c1 * pow(c - 1.0, 2)
    }
}
