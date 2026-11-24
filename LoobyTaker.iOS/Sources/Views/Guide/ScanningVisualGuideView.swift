import SwiftUI

// MARK: - Guide Visuel Illustré « Quoi scanner pour recevoir un colis ? » (`ScanningVisualGuideView.swift` • Swift 6)

public struct ScanningVisualGuideView: View {
    @Environment(\.dismiss) private var dismiss
    public var showsCloseButton: Bool

    public init(showsCloseButton: Bool = false) {
        self.showsCloseButton = showsCloseButton
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                goldenRuleHeroBanner

                illustratedCardboardBoxComparison

                pinVsProHandoverCard

                practicalSituationsSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .loobyTakerScreenBackground()
        .navigationTitle("Guide : Quoi scanner ?")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsCloseButton {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") { dismiss() }
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
            }
        }
    }

    // MARK: - 1. Règle d'Or

    private var goldenRuleHeroBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                Text("LA RÈGLE D'OR LOOBY TAKER")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.90))
            }

            Text("Scannez toujours la 2e étiquette « Viple Delivery » (VD-…), même quand c'est UPS qui vous livre !")
                .font(.system(size: 19, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("Chaque colis expédié vers un Point Relais Looby Taker comporte notre étiquette interne Viple Delivery. Lorsqu'un colis transite par UPS, le carton possède deux étiquettes côte à côte.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.92))
        }
        .padding(18)
        .background(
            LoobyTakerHeroBackground(isProStyle: false)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        )
    }

    // MARK: - 2. Schéma Comparatif Illustré d'un Carton (Étiquette 1 UPS vs 2e Étiquette Viple Delivery)

    private var illustratedCardboardBoxComparison: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "shippingbox.fill")
                    .foregroundStyle(LoobyTakerPalette.amberPrimary)
                Text("Schéma d'un colis livré par UPS")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(LoobyTakerPalette.ink)
            }

            // Illustration du dessus de carton kraft
            VStack(spacing: 14) {
                // Ruban adhésif kraft supérieur
                HStack(spacing: 6) {
                    Rectangle()
                        .fill(Color(red: 0.76, green: 0.58, blue: 0.34).opacity(0.45))
                        .frame(height: 8)
                        .clipShape(Capsule())
                    Text("CARTON COLIS LIVRIA / LOOBY")
                        .font(.system(size: 9.5, weight: .black, design: .rounded))
                        .foregroundStyle(Color(red: 0.45, green: 0.31, blue: 0.14))
                    Rectangle()
                        .fill(Color(red: 0.76, green: 0.58, blue: 0.34).opacity(0.45))
                        .frame(height: 8)
                        .clipShape(Capsule())
                }

                // Étiquette 1 : UPS (Barrée / Acheminement livreur uniquement)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        HStack(spacing: 5) {
                            Image(systemName: "xmark.octagon.fill")
                                .foregroundStyle(LoobyTakerPalette.danger)
                            Text("ÉTIQUETTE 1 — TRANSPORTEUR UPS")
                                .font(.system(size: 10.5, weight: .black, design: .rounded))
                                .foregroundStyle(LoobyTakerPalette.danger)
                        }
                        Spacer()
                        Text("NE PAS SCANNER")
                            .font(.system(size: 9.5, weight: .black, design: .rounded))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(LoobyTakerPalette.danger))
                            .foregroundStyle(.white)
                    }

                    ZStack {
                        HStack(spacing: 3) {
                            ForEach(0..<22, id: \.self) { i in
                                Rectangle()
                                    .fill(Color.primary.opacity(0.32))
                                    .frame(width: (i % 3 == 0) ? 3 : 1.5, height: 28)
                            }
                        }
                        // Barre rouge oblique
                        Rectangle()
                            .fill(LoobyTakerPalette.danger)
                            .frame(width: 170, height: 3)
                            .rotationEffect(.degrees(-8))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)

                    Text("1Z 999 AA1 01 2345 6784")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .strikethrough(true, color: LoobyTakerPalette.danger)
                        .foregroundStyle(LoobyTakerPalette.inkMuted)

                    Text("Acheminement livreur UPS uniquement (sert uniquement au chauffeur UPS pour arriver jusqu'à chez vous).")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(LoobyTakerPalette.danger)
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(LoobyTakerPalette.cardSurface))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(LoobyTakerPalette.danger.opacity(0.55), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                )

                // Flèche visuelle vers la 2e étiquette
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(LoobyTakerPalette.emerald)
                    Text("Scannez plutôt la 2e étiquette juste à côté :")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(LoobyTakerPalette.emerald)
                }

                // 2e Étiquette : Viple Delivery (Mise en valeur !)
                VStack(alignment: .leading, spacing: 9) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(LoobyTakerPalette.emerald)
                            Text("2e ÉTIQUETTE — VIPLE DELIVERY")
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundStyle(LoobyTakerPalette.emerald)
                        }
                        Spacer()
                        Text("À SCANNER !")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 3.5)
                            .background(Capsule().fill(LoobyTakerPalette.emerald))
                            .foregroundStyle(.white)
                    }

                    HStack(spacing: 12) {
                        LoobyTakerBrandMedallion(size: 40, showGlow: false)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 2.5) {
                                ForEach(0..<20, id: \.self) { i in
                                    Rectangle()
                                        .fill(LoobyTakerPalette.ink)
                                        .frame(width: (i % 2 == 0) ? 3 : 1.5, height: 30)
                                }
                            }
                            Text("VD-2026-84920")
                                .font(.system(size: 15, weight: .black, design: .monospaced))
                                .foregroundStyle(LoobyTakerPalette.amberDeep)
                        }
                        Spacer()
                    }

                    Text("Toujours scanner cette 2e étiquette dans Looby Taker, même si c'est UPS qui vous livre ! C'est elle qui notifie instantanément l'acheteur et crédite votre suivi.")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(LoobyTakerPalette.emerald)
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(LoobyTakerPalette.cardSurface))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(LoobyTakerPalette.emerald, lineWidth: 2.4)
                )
                .shadow(color: LoobyTakerPalette.emerald.opacity(0.22), radius: 10, x: 0, y: 4)
            }
            .padding(15)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(red: 0.88, green: 0.76, blue: 0.58).opacity(0.26))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color(red: 0.72, green: 0.55, blue: 0.32).opacity(0.45), lineWidth: 1.2)
            )
        }
        .loobyTakerCard()
    }

    // MARK: - 3. Comparatif Remise Client : Particulier (Code PIN) vs Pro (Sans PIN)

    private var pinVsProHandoverCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Remise au client : Particulier vs Professionnel")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(LoobyTakerPalette.ink)

            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Relais Particulier", systemImage: "house.fill")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(LoobyTakerPalette.amberPrimary)
                    Text("• RDV convenu avec le client\n• Scan du code VD-…\n• Saisie du **Code PIN à 6 chiffres** du client\n• **+1,00 €** crédité immédiatement")
                        .font(.system(size: 11.5))
                        .foregroundStyle(LoobyTakerPalette.inkSecondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 14).fill(LoobyTakerPalette.amberSoft))

                VStack(alignment: .leading, spacing: 6) {
                    Label("Relais Pro", systemImage: "storefront.fill")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(LoobyTakerPalette.proCobalt)
                    Text("• Accueil aux horaires boutique\n• Scan du code VD-…\n• **Validation immédiate sans aucun Code PIN**\n• Zéro file d'attente en caisse")
                        .font(.system(size: 11.5))
                        .foregroundStyle(LoobyTakerPalette.inkSecondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 14).fill(LoobyTakerPalette.proCobaltSoft))
            }
        }
        .loobyTakerCard()
    }

    // MARK: - 4. Fiches Pratiques Terrain

    private var practicalSituationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fiches réflexes en cas d'imprévu")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(LoobyTakerPalette.ink)

            practicalTipRow(
                icon: "wand.and.stars",
                tint: LoobyTakerPalette.amberPrimary,
                title: "Vous avez scanné l'étiquette UPS (1Z…) par erreur ?",
                body: "Pas d'inquiétude ! Looby Taker détecte automatiquement les codes commençant par 1Z, bloque l'erreur et vous propose même de basculer directement sur l'étiquette VD-… correspondante si le colis est déjà annoncé."
            )

            practicalTipRow(
                icon: "doc.text.VIEWFINDER".lowercased(),
                tint: LoobyTakerPalette.proCobalt,
                title: "La 2e étiquette Viple Delivery est froissée ou déchirée ?",
                body: "Saisissez le code écrit en clair sous les barres (ex. VD-2026-84920) dans le champ manuel du scanner. Si elle est totalement absente, ouvrez « Signaler un problème de réception » en indiquant le 1Z… UPS."
            )

            practicalTipRow(
                icon: "exclamationmark.shield.fill",
                tint: LoobyTakerPalette.danger,
                title: "Le carton arrive ouvert ou écrasé ?",
                body: "Émettez une réserve auprès du livreur (ou refusez le colis à la porte) et déclarez immédiatement l'incident via le mode « Signaler anomalie » du scanner."
            )
        }
        .loobyTakerCard()
    }

    private func practicalTipRow(icon: String, tint: Color, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon == "doc.text.viewfinder" ? "doc.viewfinder.fill" : icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(RoundedRectangle(cornerRadius: 10).fill(tint.opacity(0.14)))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13.5, weight: .black, design: .rounded))
                    .foregroundStyle(LoobyTakerPalette.ink)
                Text(body)
                    .font(.system(size: 12))
                    .foregroundStyle(LoobyTakerPalette.inkSecondary)
            }
        }
    }
}
