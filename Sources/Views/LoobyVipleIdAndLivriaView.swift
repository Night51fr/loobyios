import SwiftUI

public struct LoobyVipleIdAndLivriaView: View {
    @EnvironmentObject var vm: LoobyViewModel
    @State private var comparisonMode: String = "both" // "both", "legacy", "new"
    @State private var pulseOrbit: Bool = false

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 1. Viple Live ID vs Ancien Viple ID Hero
                vipleLiveIdHeroCard

                // 2. Interactive Filter & Side-by-Side Comparison Cards
                vipleIdComparatorSection

                // 3. Presentation of the NEW Project: LIVRIA (Did not exist at the time of Looby v1)
                livriaDiscoverySection

                // 4. Live Interactive Books Feed from Livria Store
                livriaLiveCatalogPreview
            }
            .padding(16)
            .padding(.bottom, 32)
        }
        .background(LoobyPalette.bgPrimary.ignoresSafeArea())
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                pulseOrbit = true
            }
        }
    }

    // MARK: - 1. Viple Live ID Hero Card

    private var vipleLiveIdHeroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                LoobyBadgePill(text: "IDENTITÉ UNIFIÉE 2026", color: LoobyPalette.infinityCyan)
                Spacer()
                LoobyBadgePill(text: "VIPLE LIVE ID", color: LoobyPalette.infinityViolet)
            }

            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(LoobyPalette.infinityGradient, lineWidth: 3)
                        .frame(width: 68, height: 68)
                        .scaleEffect(pulseOrbit ? 1.08 : 0.94)
                    Image(systemName: "person.badge.key.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Qu'est-ce que Viple Live ID ?")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Et tout ce que cela change par rapport à l'ancien Viple ID connu à l'époque de Looby v1.")
                        .font(.system(size: 13))
                        .foregroundStyle(LoobyPalette.textSecondary)
                }
            }

            Text("À l'époque de la première version de Looby, chaque service utilisait un ancien « Viple ID » classique qui nécessitait de se reconnecter séparément et ne synchronisait ni les avantages, ni les applications mobiles. En 2026, **Viple Live ID** devient votre passeport numérique unique à travers tout l'écosystème Viple.")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.92))
                .lineSpacing(2)

            HStack(spacing: 10) {
                Button {
                    if vm.isAuthenticated {
                        vm.selectedTab = 3
                    } else {
                        vm.showLoginSheet = true
                    }
                } label: {
                    Label(
                        vm.isAuthenticated ? "Connecté : \(vm.currentUser.displayName)" : "Se connecter avec Viple Live ID",
                        systemImage: vm.isAuthenticated ? "checkmark.seal.fill" : "person.crop.circle.badge.checkmark"
                    )
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(LoobyPalette.infinityGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(18)
        .background(LoobyPalette.cardBg)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(LoobyPalette.infinityViolet.opacity(0.45), lineWidth: 1)
        )
    }

    // MARK: - 2. Interactive Comparator: Ancien Viple ID vs Nouveau Viple Live ID

    private var vipleIdComparatorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Comparatif : Ancien Viple ID vs Viple Live ID")
                    .font(.system(size: 16.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
            }

            Picker("Mode de comparaison", selection: $comparisonMode) {
                Text("Avant / Après").tag("both")
                Text("Ancien Viple ID").tag("legacy")
                Text("Nouveau Viple Live ID").tag("new")
            }
            .pickerStyle(.segmented)

            ForEach(vm.vipleIdComparisons) { item in
                LoobyGlassCard(borderColor: LoobyPalette.infinityBlue.opacity(0.32)) {
                    HStack {
                        Label(item.featureTitle, systemImage: item.icon)
                            .font(.system(size: 14.5, weight: .bold))
                            .foregroundStyle(.white)
                        Spacer()
                        LoobyBadgePill(text: item.highlightTag, color: LoobyPalette.infinityCyan)
                    }

                    if comparisonMode == "both" || comparisonMode == "legacy" {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundStyle(LoobyPalette.textMuted)
                                .font(.system(size: 13, weight: .bold))
                                .padding(.top, 2)
                            Text(item.legacyVipleIdText)
                                .font(.system(size: 12.5))
                                .foregroundStyle(LoobyPalette.textSecondary)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(LoobyPalette.bgSecondary.opacity(0.75))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    if comparisonMode == "both" || comparisonMode == "new" {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(LoobyPalette.infinityMint)
                                .font(.system(size: 13, weight: .bold))
                                .padding(.top, 2)
                            Text(item.newVipleLiveIdText)
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(LoobyPalette.infinityMint.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(LoobyPalette.infinityMint.opacity(0.35), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    // MARK: - 3. Presentation of LIVRIA (New Ecosystem Project since Looby v1)

    private var livriaDiscoverySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                LoobyBadgePill(text: "NOUVEAU DANS L'ÉCOSYSTÈME VIPLE", color: .white)
                Spacer()
                Text("LIVRIA STORE & SOCIAL")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.9))
            }

            Text("Découvrez Livria : le projet culturel né depuis l'époque de Looby")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("À l'époque de la première version de Looby, **Livria** n'existait pas encore. Aujourd'hui, Livria est devenu le pilier culturel et littéraire de Viple, déjà disponible en production sur le Web et sur iOS avec deux applications complémentaires :")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.92))
                .lineSpacing(2)

            VStack(spacing: 10) {
                livriaAppFeatureRow(
                    icon: "books.vertical.fill",
                    title: "Livria Store (Librairie Neuf, Occasion, Audio & Troc)",
                    desc: "Achetez des livres neufs ou d'occasion vérifiés sur la même fiche ISBN, écoutez des livres audio, lisez des eBooks, échangez vos livres entre lecteurs et cumulez du Cashback avec Looby+."
                )
                livriaAppFeatureRow(
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "Livria Social (Réseau Social Littéraire)",
                    desc: "Partagez vos lectures, publiez vos critiques photo/vidéo, rejoignez des clubs de lecture et discutez entre passionnés avec connexion automatique depuis Livria Store et Looby."
                )
            }

            Button {
                vm.openLivriaBookOrStore()
            } label: {
                HStack {
                    Image(systemName: "arrow.up.forward.app.fill")
                    Text("Ouvrir Livria Store maintenant")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                }
                .foregroundStyle(LoobyPalette.infinityViolet)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
            }
        }
        .padding(18)
        .background(LoobyPalette.livriaBridgeGradient)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func livriaAppFeatureRow(icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(.white.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundStyle(.white)
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.88))
            }
        }
        .padding(10)
        .background(.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - 4. Live Books Carousel from Livria Store

    private var livriaLiveCatalogPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("En direct du catalogue Livria Store")
                        .font(.system(size: 16.5, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Cliquez sur un livre pour l'ouvrir dans l'app Livria Store ou sur le site")
                        .font(.system(size: 12))
                        .foregroundStyle(LoobyPalette.textSecondary)
                }
                Spacer()
            }

            if vm.livriaFeaturedBooks.isEmpty {
                LoobyGlassCard {
                    HStack {
                        ProgressView().tint(LoobyPalette.infinityCyan)
                        Text("Synchronisation des pépites littéraires Livria…")
                            .font(.system(size: 13))
                            .foregroundStyle(LoobyPalette.textSecondary)
                    }
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(vm.livriaFeaturedBooks) { book in
                            Button {
                                vm.openLivriaBookOrStore(bookId: book.id)
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    AsyncImage(url: book.resolvedCoverURL) { img in
                                        img.resizable().scaledToFill()
                                    } placeholder: {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(LoobyPalette.bgSecondary)
                                            .overlay(
                                                Image(systemName: "book.closed.fill")
                                                    .foregroundStyle(LoobyPalette.infinityViolet)
                                            )
                                    }
                                    .frame(width: 135, height: 185)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                    Text(book.title)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)

                                    Text(book.author)
                                        .font(.system(size: 11.5))
                                        .foregroundStyle(LoobyPalette.textSecondary)
                                        .lineLimit(1)

                                    HStack {
                                        Text(String(format: "%.2f €", book.price))
                                            .font(.system(size: 12.5, weight: .black))
                                            .foregroundStyle(LoobyPalette.infinityMint)
                                        Spacer()
                                        Image(systemName: "arrow.up.right.circle.fill")
                                            .foregroundStyle(LoobyPalette.infinityCyan)
                                    }
                                }
                                .padding(10)
                                .frame(width: 155)
                                .background(LoobyPalette.cardBg)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(LoobyPalette.border, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}
