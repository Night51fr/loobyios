import SwiftUI

public struct LoobyGrandEstB2CExplorerView: View {
    @EnvironmentObject var vm: LoobyViewModel
    @State private var showSimulatorSheet: Bool = false

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // 1. Grand Est B2C Banner
                grandEstHeaderBanner

                // 2. City & Category Filters + Search
                filtersCard

                // 3. Interactive Merchants List
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("🏪 Commerces partenaires du Grand Est (\(vm.filteredMerchants.count))")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Spacer()
                        if !vm.favoriteMerchantIds.isEmpty {
                            LoobyBadgePill(text: "❤️ \(vm.favoriteMerchantIds.count) favori(s)", color: LoobyPalette.livriaCoral)
                        }
                    }

                    ForEach(vm.filteredMerchants) { shop in
                        merchantCard(shop)
                    }
                }

                // 4. Interactive B2C Merchant Simulator & Partner Application
                b2cMerchantSimulatorCard
            }
            .padding(16)
            .padding(.bottom, 32)
        }
        .background(LoobyPalette.bgPrimary.ignoresSafeArea())
        .sheet(item: $vm.selectedMerchantDetail) { shop in
            LoobyMerchantDetailSheet(merchant: shop)
                .environmentObject(vm)
        }
    }

    // MARK: - 1. Header Banner

    private var grandEstHeaderBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                LoobyBadgePill(text: "MARKETPLACE B2C • GRAND EST", color: .white)
                Spacer()
                Text("10 DÉPARTEMENTS")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.9))
            }

            Text("Les commerces locaux du Grand Est réunis sur Looby")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("Explorez les boutiques indépendantes d'Alsace, de Lorraine et de Champagne-Ardenne qui rejoignent la plateforme B2C Looby v2 pour l'ouverture du 21/11/2026.")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.9))
                .lineSpacing(2)
        }
        .padding(18)
        .background(LoobyPalette.grandEstGradient)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    // MARK: - 2. Filters Card

    private var filtersCard: some View {
        LoobyGlassCard {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(LoobyPalette.infinityCyan)
                TextField("Rechercher un commerce, une ville, un produit…", text: $vm.merchantSearchQuery)
                    .foregroundStyle(.white)
                if !vm.merchantSearchQuery.isEmpty {
                    Button {
                        vm.merchantSearchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(LoobyPalette.textMuted)
                    }
                }
            }
            .padding(11)
            .background(LoobyPalette.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // City Filter Strip
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(vm.grandEstCities, id: \.self) { city in
                        let active = vm.selectedCityFilter == city
                        Button {
                            withAnimation(.snappy) { vm.selectedCityFilter = city }
                        } label: {
                            Text(city == "Toutes" ? "📍 Toutes les villes" : "📍 \(city)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(active ? .white : LoobyPalette.textSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(active ? LoobyPalette.infinityMint : LoobyPalette.bgSecondary)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            // Category Filter Strip
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(vm.grandEstCategories, id: \.self) { cat in
                        let active = vm.selectedCategoryFilter == cat
                        Button {
                            withAnimation(.snappy) { vm.selectedCategoryFilter = cat }
                        } label: {
                            Text(cat)
                                .font(.system(size: 11.5, weight: .bold))
                                .foregroundStyle(active ? .white : LoobyPalette.textSecondary)
                                .padding(.horizontal, 11)
                                .padding(.vertical, 6)
                                .background(active ? LoobyPalette.infinityBlue : LoobyPalette.bgSecondary)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    // MARK: - 3. Single Merchant Card

    private func merchantCard(_ shop: LoobyGrandEstMerchant) -> some View {
        let isFav = vm.favoriteMerchantIds.contains(shop.id)

        return LoobyGlassCard(borderColor: isFav ? LoobyPalette.livriaCoral.opacity(0.5) : LoobyPalette.border) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: shop.icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(LoobyPalette.infinityMint)
                    .frame(width: 44, height: 44)
                    .background(LoobyPalette.infinityMint.opacity(0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(shop.name)
                            .font(.system(size: 15.5, weight: .bold))
                            .foregroundStyle(.white)
                        Spacer()
                        Button {
                            vm.toggleFavoriteMerchant(shop.id)
                        } label: {
                            Image(systemName: isFav ? "heart.fill" : "heart")
                                .font(.system(size: 17))
                                .foregroundStyle(isFav ? LoobyPalette.livriaCoral : LoobyPalette.textSecondary)
                        }
                    }

                    Text("\(shop.city) • \(shop.department) • \(shop.category)")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(LoobyPalette.infinityCyan)

                    Text(shop.tagline)
                        .font(.system(size: 12.5))
                        .foregroundStyle(LoobyPalette.textSecondary)
                }
            }

            HStack(spacing: 8) {
                LoobyBadgePill(text: "✓ \(shop.verifiedSiretBadge)", color: LoobyPalette.infinityMint)
                LoobyBadgePill(text: "⚡ Retrait \(shop.clickAndCollectMinutes) min", color: LoobyPalette.infinityCyan)
                Spacer()
                Button {
                    vm.selectedMerchantDetail = shop
                } label: {
                    Text("Vitrine & Produits →")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(LoobyPalette.infinityBlue)
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - 4. Interactive B2C Merchant Simulator & Partner Pre-registration

    private var b2cMerchantSimulatorCard: some View {
        LoobyGlassCard(borderColor: LoobyPalette.infinityCyan.opacity(0.45)) {
            HStack {
                Label("Simulateur Commerçant B2C du Grand Est", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                LoobyBadgePill(text: "OUTIL PRO", color: LoobyPalette.infinityCyan)
            }

            Text("Vous êtes commerçant, artisan ou libraire dans le Grand Est ? Estimez votre chiffre d'affaires net sur Looby v2 et pré-inscrivez votre boutique pour l'ouverture du 21/11/2026.")
                .font(.system(size: 12.5))
                .foregroundStyle(LoobyPalette.textSecondary)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Ventes mensuelles estimées sur Looby")
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(Int(vm.simMonthlySales)) € / mois")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundStyle(LoobyPalette.infinityMint)
                }
                Slider(value: $vm.simMonthlySales, in: 500...25000, step: 250)
                    .tint(LoobyPalette.infinityMint)

                HStack {
                    Text("Part des commandes en Click & Collect boutique")
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    Text("\(Int(vm.simClickAndCollectShare)) %")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundStyle(LoobyPalette.infinityCyan)
                }
                Slider(value: $vm.simClickAndCollectShare, in: 0...100, step: 5)
                    .tint(LoobyPalette.infinityCyan)

                let netRevenue = vm.simMonthlySales * 0.945 // 5.5% regional solidarity commission
                let estimatedOrders = max(1, Int(vm.simMonthlySales / max(15, vm.simAverageBasket)))

                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Revenu net commerçant (94,5 %)")
                            .font(.system(size: 11))
                            .foregroundStyle(LoobyPalette.textSecondary)
                        Text(String(format: "%.0f € / mois", netRevenue))
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(LoobyPalette.infinityMint)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Commandes locales / mois")
                            .font(.system(size: 11))
                            .foregroundStyle(LoobyPalette.textSecondary)
                        Text("~\(estimatedOrders) clients")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(LoobyPalette.infinityCyan)
                    }
                }
                .padding(12)
                .background(LoobyPalette.bgSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Divider().overlay(LoobyPalette.border)

            Text("Pré-inscrire mon commerce du Grand Est pour le 21/11/2026")
                .font(.system(size: 13.5, weight: .bold))
                .foregroundStyle(.white)

            TextField("Nom de l'enseigne ou de l'atelier", text: $vm.merchantApplicationShopName)
                .padding(10)
                .background(LoobyPalette.bgSecondary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(.white)

            HStack(spacing: 8) {
                TextField("Ville (ex: Strasbourg, Metz…)", text: $vm.merchantApplicationCity)
                    .padding(10)
                    .background(LoobyPalette.bgSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)

                TextField("E-mail professionnel", text: $vm.merchantApplicationEmail)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .padding(10)
                    .background(LoobyPalette.bgSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)
            }

            Button {
                vm.submitMerchantPreRegistration()
            } label: {
                Label(
                    vm.merchantApplicationSubmitted ? "Demande commerçant enregistrée ✓" : "Demander mon ouverture de boutique B2C",
                    systemImage: vm.merchantApplicationSubmitted ? "checkmark.seal.fill" : "paperplane.fill"
                )
                .font(.system(size: 13.5, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(LoobyPalette.infinityGradient)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - Merchant Detail Sheet

struct LoobyMerchantDetailSheet: View {
    let merchant: LoobyGrandEstMerchant
    @EnvironmentObject var vm: LoobyViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    LoobyGlassCard(borderColor: LoobyPalette.infinityMint.opacity(0.45)) {
                        HStack {
                            LoobyBadgePill(text: merchant.department, color: LoobyPalette.infinityMint)
                            Spacer()
                            LoobyBadgePill(text: merchant.category, color: LoobyPalette.infinityCyan)
                        }
                        Text(merchant.name)
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text(merchant.description)
                            .font(.system(size: 13.5))
                            .foregroundStyle(LoobyPalette.textSecondary)
                            .lineSpacing(2)
                        Text(merchant.verifiedSiretBadge)
                            .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(LoobyPalette.infinityMint)
                    }

                    Text("Aperçu du catalogue prévu le 21/11/2026")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)

                    ForEach(merchant.sampleProducts) { prod in
                        LoobyGlassCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    LoobyBadgePill(text: prod.badge, color: LoobyPalette.infinityCyan)
                                    Text(prod.title)
                                        .font(.system(size: 14.5, weight: .bold))
                                        .foregroundStyle(.white)
                                    Text("Origine : \(prod.originLabel)")
                                        .font(.system(size: 12))
                                        .foregroundStyle(LoobyPalette.textSecondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(String(format: "%.2f €", prod.price))
                                        .font(.system(size: 16, weight: .black, design: .rounded))
                                        .foregroundStyle(LoobyPalette.infinityMint)
                                    Text("Dispo le 21/11")
                                        .font(.system(size: 10.5, weight: .bold))
                                        .foregroundStyle(LoobyPalette.goldAmber)
                                }
                            }
                        }
                    }

                    Button {
                        vm.toggleFavoriteMerchant(merchant.id)
                    } label: {
                        let isFav = vm.favoriteMerchantIds.contains(merchant.id)
                        Label(
                            isFav ? "Retirer de mes commerces favoris" : "Suivre ce commerce pour le 21/11/2026",
                            systemImage: isFav ? "heart.slash.fill" : "heart.fill"
                        )
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(LoobyPalette.infinityGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 13))
                    }
                }
                .padding(16)
            }
            .background(LoobyPalette.bgPrimary.ignoresSafeArea())
            .navigationTitle(merchant.city)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
