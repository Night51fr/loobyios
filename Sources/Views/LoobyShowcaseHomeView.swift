import SwiftUI

public struct LoobyShowcaseHomeView: View {
    @EnvironmentObject var vm: LoobyViewModel
    @State private var selectedPillarIndex: Int = 0
    @State private var animateCards: Bool = false

    private let b2cPillars: [(icon: String, title: String, subtitle: String, detail: String, color: Color)] = [
        (
            "building.2.crop.circle.fill",
            "100 % Commerces Locaux du Grand Est",
            "De l'ancien modèle C2C vers une alliance B2C certifiée",
            "Fini les annonces aléatoires entre particuliers : Looby v2 réunit exclusivement les commerçants indépendants, artisans, producteurs et boutiques de proximité d'Alsace, de Lorraine et de Champagne-Ardenne sur une plateforme unique.",
            LoobyPalette.infinityMint
        ),
        (
            "bag.badge.plus",
            "Click & Collect 30 min & Livraison Unifiée",
            "Commandez en ligne, retirez en boutique ou recevez chez vous",
            "Réservez vos produits auprès des boutiques de Strasbourg, Metz, Nancy, Reims, Mulhouse, Colmar, Épinal ou Troyes. Retirez-les gratuitement en magasin ou profitez d'une expédition groupée suivie.",
            LoobyPalette.infinityCyan
        ),
        (
            "person.badge.shield.checkmark.fill",
            "Garanties Pro & Compte Viple Live ID",
            "Facture officielle, garantie légale 2 ans & 14 jours de rétractation",
            "Chaque vendeur est un professionnel vérifié du Grand Est. Grâce au nouveau Viple Live ID, votre compte, votre abonnement Looby+ et votre cagnotte fonctionnent à la fois sur Looby v2 et sur Livria.",
            LoobyPalette.infinityViolet
        )
    ]

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Cross-App SSO Banner if detected from Livria Store / Livria Social
                if vm.showCrossAppPrompt, let cross = vm.detectedCrossAppAccount {
                    crossAppDetectionCard(cross)
                }

                // 1. Animated Hero Banner + Countdown to 21/11/2026
                heroLaunchBanner

                // 2. Interactive C2C -> B2C Grand Est Transformation Carousel
                transformationB2CSection

                // 3. Interactive Quick Access Grid (Viple Live ID, Livria, Commerces Grand Est, Mes Commandes, CGU)
                ecosystemQuickGrid

                // 4. Preview of Featured Grand Est Local Merchants
                featuredGrandEstMerchantsStrip

                // 5. Official Launch Roadmap to 21/11/2026
                roadmapTimelineCard
            }
            .padding(16)
            .padding(.bottom, 32)
        }
        .background(LoobyPalette.bgPrimary.ignoresSafeArea())
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateCards = true
            }
        }
    }

    // MARK: - Cross-App SSO Prompt

    private func crossAppDetectionCard(_ acc: LoobyCrossAppAccount) -> some View {
        LoobyGlassCard(borderColor: LoobyPalette.infinityCyan.opacity(0.65)) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LoobyPalette.infinityGradient)
                        .frame(width: 46, height: 46)
                    Text(acc.initials)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    LoobyBadgePill(text: "VIPLE LIVE ID DÉTECTÉ", color: LoobyPalette.infinityCyan)
                    Text("Nous avons détecté que vous étiez connecté depuis \(acc.sourceApp)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Souhaitez-vous vous connecter au même compte (\(acc.displayName) • \(acc.email)) sur Looby ?")
                        .font(.system(size: 12))
                        .foregroundStyle(LoobyPalette.textSecondary)
                }
            }

            HStack(spacing: 10) {
                Button {
                    Task { await vm.acceptDetectedCrossAppSession() }
                } label: {
                    Label("Continuer en tant que \(acc.displayName)", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(LoobyPalette.infinityGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    vm.dismissDetectedCrossAppSession()
                } label: {
                    Text("Plus tard")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(LoobyPalette.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(LoobyPalette.bgSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    // MARK: - 1. Hero Launch Banner + Live Countdown to 21/11/2026

    private var heroLaunchBanner: some View {
        VStack(spacing: 16) {
            HStack {
                LoobyBadgePill(text: "NOUVELLE GÉNÉRATION • LOOBY V2", color: LoobyPalette.infinityMint)
                Spacer()
                LoobyBadgePill(text: "LANCEMENT 21/11/2026", color: LoobyPalette.infinityCyan)
            }

            LoobyAnimatedInfinityHero(size: 108)
                .padding(.vertical, 4)

            VStack(spacing: 8) {
                Text("Looby devient la Marketplace des Commerces du Grand Est")
                    .font(.system(size: 23, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Anciennement plateforme entre particuliers, Looby se réinvente en Version 2 sous la forme d'une place de marché B2C fédérant les commerçants locaux, artisans et boutiques indépendantes du Grand Est.")
                    .font(.system(size: 13.5))
                    .foregroundStyle(LoobyPalette.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            // Live Animated Countdown to 21/11/2026
            VStack(spacing: 10) {
                Text("OUVERTURE OFFICIELLE DE LOOBY V2 LE 21 NOVEMBRE 2026")
                    .font(.system(size: 10.5, weight: .black, design: .monospaced))
                    .foregroundStyle(LoobyPalette.infinityCyan)

                HStack(spacing: 10) {
                    countdownUnitBox(value: vm.daysRemaining, label: "JOURS")
                    countdownUnitBox(value: vm.hoursRemaining, label: "HEURES")
                    countdownUnitBox(value: vm.minutesRemaining, label: "MINUTES")
                    countdownUnitBox(value: vm.secondsRemaining, label: "SECONDES")
                }
            }
            .padding(14)
            .background(LoobyPalette.bgPrimary.opacity(0.65))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(LoobyPalette.infinityCyan.opacity(0.35), lineWidth: 1)
            )

            // Interactive Action Row
            HStack(spacing: 10) {
                Button {
                    vm.toggleLaunchAlertSubscription()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: vm.launchAlertSubscribed ? "bell.badge.fill" : "bell.fill")
                        Text(vm.launchAlertSubscribed ? "Pass Prioritaire 21/11 activé" : "M'alerter le 21/11/2026")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        vm.launchAlertSubscribed
                        ? AnyShapeStyle(LoobyPalette.infinityMint.opacity(0.28))
                        : AnyShapeStyle(LoobyPalette.infinityGradient)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 13)
                            .stroke(vm.launchAlertSubscribed ? LoobyPalette.infinityMint : Color.clear, lineWidth: 1)
                    )
                }

                Button {
                    if vm.isAuthenticated {
                        vm.selectedTab = 3
                    } else {
                        vm.showLoginSheet = true
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "person.badge.key.fill")
                        Text(vm.isAuthenticated ? "Mon espace" : "Viple Live ID")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(LoobyPalette.infinityCyan)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(LoobyPalette.bgSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 13)
                            .stroke(LoobyPalette.infinityCyan.opacity(0.45), lineWidth: 1)
                    )
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.14, blue: 0.26),
                    Color(red: 0.06, green: 0.19, blue: 0.28),
                    Color(red: 0.11, green: 0.13, blue: 0.27)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(LoobyPalette.infinityCyan.opacity(0.4), lineWidth: 1.2)
        )
    }

    private func countdownUnitBox(value: Int, label: String) -> some View {
        VStack(spacing: 3) {
            Text(String(format: "%02d", value))
                .font(.system(size: 22, weight: .black, design: .monospaced))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .animation(.snappy, value: value)
            Text(label)
                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                .foregroundStyle(LoobyPalette.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(LoobyPalette.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - 2. Interactive C2C -> B2C Transformation Section

    private var transformationB2CSection: some View {
        LoobyGlassCard(borderColor: LoobyPalette.infinityMint.opacity(0.4)) {
            HStack {
                Label("Pourquoi Looby change tout en Version 2", systemImage: "arrow.triangle.2.circlepath.circle.fill")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                LoobyBadgePill(text: "C2C → B2C", color: LoobyPalette.infinityMint)
            }

            // Interactive Pillar Selector
            HStack(spacing: 8) {
                ForEach(0..<b2cPillars.count, id: \.self) { idx in
                    let active = selectedPillarIndex == idx
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                            selectedPillarIndex = idx
                        }
                    } label: {
                        Text("Pilier \(idx + 1)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(active ? .white : LoobyPalette.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(active ? b2cPillars[idx].color : LoobyPalette.bgSecondary)
                            .clipShape(Capsule())
                    }
                }
            }

            let current = b2cPillars[selectedPillarIndex]
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: current.icon)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(current.color)
                        .frame(width: 44, height: 44)
                        .background(current.color.opacity(0.16))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(current.title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                        Text(current.subtitle)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(current.color)
                    }
                }

                Text(current.detail)
                    .font(.system(size: 13))
                    .foregroundStyle(LoobyPalette.textSecondary)
                    .lineSpacing(2)
            }
            .padding(12)
            .background(LoobyPalette.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    // MARK: - 3. Quick Navigation Cards to App Sections

    private var ecosystemQuickGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Explorer l'univers Looby v2 & Viple")
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                quickNavTile(
                    icon: "person.badge.shield.checkmark.fill",
                    badge: "NOUVEAU",
                    title: "Viple Live ID & Projet Livria",
                    subtitle: "Ce qui change par rapport à l'ancien Viple ID + découverte de Livria",
                    accent: LoobyPalette.infinityViolet
                ) {
                    vm.selectedTab = 1
                }

                quickNavTile(
                    icon: "storefront.fill",
                    badge: "GRAND EST B2C",
                    title: "Commerces Locaux & Simulateur",
                    subtitle: "Annuaire Strasbourg, Metz, Nancy, Reims… & simulateur vendeur pro",
                    accent: LoobyPalette.infinityMint
                ) {
                    vm.selectedTab = 2
                }

                quickNavTile(
                    icon: "shippingbox.fill",
                    badge: "SUIVI UNIFIÉ",
                    title: "Espace Mes Commandes",
                    subtitle: "Consultez vos commandes Livria Store et vos pré-réservations Looby",
                    accent: LoobyPalette.infinityCyan
                ) {
                    vm.selectedTab = 3
                }

                quickNavTile(
                    icon: "doc.text.magnifyingglass",
                    badge: "OFFICIEL",
                    title: "CGU Marketplace Looby B2C",
                    subtitle: "Conditions générales de la nouvelle plateforme B2C du Grand Est",
                    accent: LoobyPalette.goldAmber
                ) {
                    vm.selectedTab = 4
                }
            }
        }
    }

    private func quickNavTile(
        icon: String,
        badge: String,
        title: String,
        subtitle: String,
        accent: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(accent)
                        .frame(width: 38, height: 38)
                        .background(accent.opacity(0.16))
                        .clipShape(RoundedRectangle(cornerRadius: 11))
                    Spacer()
                    LoobyBadgePill(text: badge, color: accent)
                }

                Text(title)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)

                Text(subtitle)
                    .font(.system(size: 11.5))
                    .foregroundStyle(LoobyPalette.textSecondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 148, alignment: .topLeading)
            .background(LoobyPalette.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(accent.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 4. Preview of Grand Est Local Merchants

    private var featuredGrandEstMerchantsStrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Aperçu des Commerces du Grand Est")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Boutiques partenaires en cours d'intégration pour le 21/11/2026")
                        .font(.system(size: 12))
                        .foregroundStyle(LoobyPalette.textSecondary)
                }
                Spacer()
                Button {
                    vm.selectedTab = 2
                } label: {
                    Text("Tout voir →")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundStyle(LoobyPalette.infinityCyan)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(vm.grandEstMerchants.prefix(5)) { shop in
                        let isFav = vm.favoriteMerchantIds.contains(shop.id)
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                LoobyBadgePill(text: "📍 \(shop.city)", color: LoobyPalette.infinityMint)
                                Spacer()
                                Button {
                                    vm.toggleFavoriteMerchant(shop.id)
                                } label: {
                                    Image(systemName: isFav ? "heart.fill" : "heart")
                                        .foregroundStyle(isFav ? LoobyPalette.livriaCoral : LoobyPalette.textSecondary)
                                }
                            }

                            Text(shop.name)
                                .font(.system(size: 14.5, weight: .bold))
                                .foregroundStyle(.white)
                                .lineLimit(1)

                            Text(shop.tagline)
                                .font(.system(size: 12))
                                .foregroundStyle(LoobyPalette.textSecondary)
                                .lineLimit(2)

                            HStack {
                                Label("Click & Collect \(shop.clickAndCollectMinutes) min", systemImage: "clock.fill")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(LoobyPalette.infinityCyan)
                                Spacer()
                                Text("★ \(String(format: "%.1f", shop.rating))")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(LoobyPalette.goldAmber)
                            }
                        }
                        .padding(14)
                        .frame(width: 255)
                        .background(LoobyPalette.cardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(LoobyPalette.border, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    // MARK: - 5. Official Launch Roadmap Card

    private var roadmapTimelineCard: some View {
        LoobyGlassCard(borderColor: LoobyPalette.infinityBlue.opacity(0.4)) {
            Label("Feuille de route vers le lancement du 21/11/2026", systemImage: "calendar.badge.clock")
                .font(.system(size: 15.5, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)

            roadmapStepRow(
                date: "Étape 1 • Déjà disponible",
                title: "Lancement de Livria Store, Livria Social & Viple Live ID",
                desc: "Déploiement du nouveau compte Viple Live ID et ouverture de la librairie culturelle Livria (Neuf, Occasion, Audio, eBooks & Troc).",
                done: true
            )
            roadmapStepRow(
                date: "Étape 2 • Octobre – Novembre 2026",
                title: "Onboarding des Commerçants B2C du Grand Est",
                desc: "Certification SIRET et intégration des catalogues des commerces indépendants d'Alsace, de Lorraine et de Champagne-Ardenne.",
                done: true
            )
            roadmapStepRow(
                date: "Étape 3 • 21 Novembre 2026 (21/11/2026)",
                title: "Ouverture officielle de la Marketplace Looby v2",
                desc: "Ouverture des achats B2C, du Click & Collect 30 min en boutique locale et de la livraison groupée dans tout le Grand Est.",
                done: false
            )
        }
    }

    private func roadmapStepRow(date: String, title: String, desc: String, done: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: done ? "checkmark.circle.fill" : "sparkles")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(done ? LoobyPalette.infinityMint : LoobyPalette.infinityCyan)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(date.uppercased())
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(done ? LoobyPalette.infinityMint : LoobyPalette.infinityCyan)
                Text(title)
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundStyle(.white)
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundStyle(LoobyPalette.textSecondary)
            }
        }
        .padding(10)
        .background(LoobyPalette.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
