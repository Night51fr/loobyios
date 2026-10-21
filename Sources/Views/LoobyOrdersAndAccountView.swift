import SwiftUI
import AuthenticationServices

public struct LoobyOrdersAndAccountView: View {
    @EnvironmentObject var vm: LoobyViewModel
    @State private var showDeleteAccountAlert: Bool = false

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // 1. Viple Live ID Account Card
                vipleLiveIdAccountCard

                // 2. "Espace Mes Commandes" Switcher (Commandes Livria vs Commandes Looby v2)
                ordersSectionCard

                // 3. Saved Favorite Grand Est Merchants for 21/11/2026
                savedFavoritesSection
            }
            .padding(16)
            .padding(.bottom, 32)
        }
        .background(LoobyPalette.bgPrimary.ignoresSafeArea())
        .alert("Supprimer définitivement votre compte Viple Live ID ?", isPresented: $showDeleteAccountAlert) {
            Button("Annuler", role: .cancel) {}
            Button("Supprimer définitivement", role: .destructive) {
                Task { await vm.deleteCurrentAccount() }
            }
        } message: {
            Text("Cette action supprimera définitivement votre compte Viple Live ID (\(vm.currentUser.email)) et vos données associées.")
        }
    }

    // MARK: - 1. Viple Live ID Account Card

    private var vipleLiveIdAccountCard: some View {
        LoobyGlassCard(borderColor: vm.isAuthenticated ? LoobyPalette.infinityMint.opacity(0.55) : LoobyPalette.infinityCyan.opacity(0.45)) {
            HStack(alignment: .center, spacing: 14) {
                if vm.isAuthenticated, let avatarURL = vm.currentUser.resolvedAvatarURL {
                    AsyncImage(url: avatarURL) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        avatarCirclePlaceholder
                    }
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                } else {
                    avatarCirclePlaceholder
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(vm.isAuthenticated ? vm.currentUser.displayName : "Compte Viple Live ID")
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        if vm.isAuthenticated && vm.currentUser.isLivriaPlus {
                            LoobyBadgePill(text: "👑 Looby+ Actif", color: LoobyPalette.goldAmber)
                        }
                    }

                    Text(vm.isAuthenticated
                         ? vm.currentUser.email
                         : "Connectez-vous avec votre compte Viple Live ID pour retrouver vos commandes Livria et préparer l'ouverture de Looby v2.")
                        .font(.system(size: 12.5))
                        .foregroundStyle(LoobyPalette.textSecondary)
                }
                Spacer()
            }

            if vm.isAuthenticated {
                HStack(spacing: 10) {
                    accountMetricPill(title: "Fidélité", value: "\(vm.currentUser.loyaltyPoints) pts", color: LoobyPalette.infinityCyan)
                    accountMetricPill(title: "Cashback", value: String(format: "%.2f €", vm.currentUser.cashbackBalance), color: LoobyPalette.infinityMint)
                    accountMetricPill(title: "Niveau", value: "Niv. \(vm.currentUser.level)", color: LoobyPalette.infinityViolet)
                }

                HStack(spacing: 10) {
                    Button {
                        Task { await vm.bootstrap() }
                    } label: {
                        Label("Actualiser mes commandes", systemImage: "arrow.clockwise")
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(LoobyPalette.infinityBlue)
                            .clipShape(RoundedRectangle(cornerRadius: 11))
                    }

                    Button {
                        Task { await vm.signOut() }
                    } label: {
                        Text("Déconnexion")
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundStyle(LoobyPalette.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(LoobyPalette.bgSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 11))
                    }
                }

                Button(role: .destructive) {
                    showDeleteAccountAlert = true
                } label: {
                    Label("Supprimer mon compte Viple Live ID", systemImage: "trash")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(LoobyPalette.livriaCoral)
                }
                .padding(.top, 2)
            } else {
                Button {
                    vm.showLoginSheet = true
                } label: {
                    HStack {
                        Image(systemName: "person.badge.key.fill")
                        Text("Se connecter ou créer un Viple Live ID")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(LoobyPalette.infinityGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 13))
                }
            }
        }
    }

    private var avatarCirclePlaceholder: some View {
        ZStack {
            Circle()
                .fill(LoobyPalette.infinityGradient)
                .frame(width: 56, height: 56)
            Text(vm.isAuthenticated ? vm.currentUser.initials : "∞")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private func accountMetricPill(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(LoobyPalette.textSecondary)
            Text(value)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(color)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LoobyPalette.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 11))
    }

    // MARK: - 2. Espace Mes Commandes (Livria & Looby)

    private var ordersSectionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Espace Mes Commandes", systemImage: "shippingbox.fill")
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
                LoobyBadgePill(text: "LIVRIA & LOOBY", color: LoobyPalette.infinityCyan)
            }

            Picker("Source des commandes", selection: $vm.ordersSourceFilter) {
                Text("📚 Commandes Livria (\(vm.livriaOrders.count))").tag("livria")
                Text("🏪 Commandes Looby (0)").tag("looby")
            }
            .pickerStyle(.segmented)

            if vm.ordersSourceFilter == "livria" {
                livriaOrdersContent
            } else {
                loobyOrdersTransitionContent
            }
        }
    }

    private var livriaOrdersContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !vm.isAuthenticated {
                LoobyGlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Connectez-vous avec Viple Live ID", systemImage: "lock.open.fill")
                            .font(.system(size: 14.5, weight: .bold))
                            .foregroundStyle(LoobyPalette.infinityCyan)
                        Text("Vos commandes passées sur Livria Store sont automatiquement rattachées à votre compte Viple Live ID. Connectez-vous pour afficher votre historique et vos numéros de suivi UPS.")
                            .font(.system(size: 12.5))
                            .foregroundStyle(LoobyPalette.textSecondary)
                        Button {
                            vm.showLoginSheet = true
                        } label: {
                            Text("Se connecter avec Viple Live ID")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(LoobyPalette.infinityBlue)
                                .clipShape(Capsule())
                        }
                    }
                }
            } else if vm.livriaOrders.isEmpty {
                LoobyGlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "books.vertical.fill")
                                .foregroundStyle(LoobyPalette.infinityViolet)
                            Text("Aucune commande Livria enregistrée sur ce compte")
                                .font(.system(size: 14.5, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        Text("Dès que vous passez une commande de livres neufs, d'occasion, audio ou eBooks sur Livria Store, elle apparaît automatiquement ici avec son suivi UPS.")
                            .font(.system(size: 12.5))
                            .foregroundStyle(LoobyPalette.textSecondary)
                        Button {
                            vm.openLivriaBookOrStore()
                        } label: {
                            Label("Découvrir la boutique Livria Store", systemImage: "arrow.up.forward.app.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(LoobyPalette.livriaBridgeGradient)
                                .clipShape(Capsule())
                        }
                    }
                }
            } else {
                ForEach(vm.livriaOrders) { order in
                    LoobyGlassCard(borderColor: LoobyPalette.infinityCyan.opacity(0.35)) {
                        HStack {
                            Text(order.reference)
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                .foregroundStyle(LoobyPalette.infinityCyan)
                            Spacer()
                            LoobyBadgePill(text: order.status, color: LoobyPalette.infinityMint)
                            Text(String(format: "%.2f €", order.total))
                                .font(.system(size: 14.5, weight: .black))
                                .foregroundStyle(.white)
                        }

                        Text("Passée le \(order.createdAt) • Transporteur : \(order.carrier)")
                            .font(.system(size: 11.5))
                            .foregroundStyle(LoobyPalette.textSecondary)

                        if let trk = order.trackingNumber, !trk.isEmpty {
                            HStack {
                                Image(systemName: "shippingbox.and.arrow.backward.fill")
                                    .foregroundStyle(LoobyPalette.infinityMint)
                                Text("Suivi colis : \(trk)")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundStyle(LoobyPalette.infinityMint)
                            }
                        }

                        ForEach(order.items) { item in
                            HStack {
                                Text("• \(item.title) ×\(item.quantity) (\(item.format))")
                                    .font(.system(size: 12.5, weight: .semibold))
                                    .foregroundStyle(.white)
                                Spacer()
                                Text(String(format: "%.2f €", item.unitPrice * Double(item.quantity)))
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(LoobyPalette.textSecondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private var loobyOrdersTransitionContent: some View {
        LoobyGlassCard(borderColor: LoobyPalette.goldAmber.opacity(0.45)) {
            HStack(spacing: 10) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(LoobyPalette.goldAmber)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Aucune commande Looby active pour le moment")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Ouverture de la Marketplace B2C Grand Est le 21/11/2026")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(LoobyPalette.goldAmber)
                }
            }

            Text("L'ancienne version de Looby (modèle entre particuliers C2C) est définitivement fermée afin de laisser place à **Looby Version 2**, la nouvelle plateforme B2C réunissant les commerces locaux du Grand Est.\n\nLes nouvelles commandes Looby (Click & Collect 30 min en boutique et livraison UPS régionale) seront disponibles dès le lancement officiel le **21/11/2026**. En attendant, vos commandes culturelles passées sur **Livria Store** restent consultables à tout moment dans l'onglet « Commandes Livria » ci-dessus.")
                .font(.system(size: 12.5))
                .foregroundStyle(LoobyPalette.textSecondary)
                .lineSpacing(2)

            HStack(spacing: 10) {
                Button {
                    vm.ordersSourceFilter = "livria"
                } label: {
                    Label("Voir mes commandes Livria", systemImage: "books.vertical.fill")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(LoobyPalette.infinityBlue)
                        .clipShape(Capsule())
                }

                Button {
                    vm.selectedTab = 2
                } label: {
                    Label("Explorer les commerces Grand Est", systemImage: "storefront.fill")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundStyle(LoobyPalette.infinityMint)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(LoobyPalette.infinityMint.opacity(0.16))
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - 3. Saved Favorite Grand Est Shops for Launch Day

    private var savedFavoritesSection: some View {
        let favShops = vm.grandEstMerchants.filter { vm.favoriteMerchantIds.contains($0.id) }

        return LoobyGlassCard {
            HStack {
                Label("Mes Commerces Grand Est Favoris (\(favShops.count))", systemImage: "heart.circle.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                LoobyBadgePill(text: "21/11/2026", color: LoobyPalette.livriaCoral)
            }

            if favShops.isEmpty {
                Text("Vous n'avez pas encore ajouté de commerce local du Grand Est à votre liste de lancement. Explorez l'onglet « Grand Est B2C » pour enregistrer vos boutiques préférées !")
                    .font(.system(size: 12.5))
                    .foregroundStyle(LoobyPalette.textSecondary)
            } else {
                ForEach(favShops) { shop in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(shop.name)
                                .font(.system(size: 13.5, weight: .bold))
                                .foregroundStyle(.white)
                            Text("📍 \(shop.city) (\(shop.department)) • \(shop.category)")
                                .font(.system(size: 11.5))
                                .foregroundStyle(LoobyPalette.infinityCyan)
                        }
                        Spacer()
                        Button {
                            vm.toggleFavoriteMerchant(shop.id)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(LoobyPalette.livriaCoral)
                        }
                    }
                    .padding(10)
                    .background(LoobyPalette.bgSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
}

// MARK: - Viple Live ID Login & Registration Sheet

public struct LoobyVipleLiveIdAuthSheet: View {
    @EnvironmentObject var vm: LoobyViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var mode: String = "login" // "login" or "register"
    @State private var email: String = ""
    @State private var password: String = ""

    @State private var regEmailMode: String = "viplemail"
    @State private var regVipleUser: String = ""
    @State private var regCustomEmail: String = ""
    @State private var regFirstName: String = ""
    @State private var regLastName: String = ""
    @State private var regDisplayName: String = ""

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        LoobyAnimatedInfinityHero(size: 64)
                        VStack(alignment: .leading, spacing: 4) {
                            LoobyBadgePill(text: "PASSEPORT UNIQUE VIPLE", color: LoobyPalette.infinityCyan)
                            Text("Connexion Viple Live ID")
                                .font(.system(size: 20, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                            Text("Un seul compte pour Looby v2, Livria Store et Livria Social.")
                                .font(.system(size: 12.5))
                                .foregroundStyle(LoobyPalette.textSecondary)
                        }
                    }
                    .padding(.bottom, 4)

                    Picker("Action", selection: $mode) {
                        Text("Se connecter").tag("login")
                        Text("Créer un Viple Live ID").tag("register")
                    }
                    .pickerStyle(.segmented)

                    if mode == "login" {
                        LoobyGlassCard {
                            TextField("Adresse @viplemail.fr ou e-mail", text: $email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .padding(12)
                                .background(LoobyPalette.bgSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: 11))
                                .foregroundStyle(.white)

                            SecureField("Mot de passe Viple Live ID", text: $password)
                                .padding(12)
                                .background(LoobyPalette.bgSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: 11))
                                .foregroundStyle(.white)

                            Button {
                                Task { await vm.loginWithVipleLiveID(email: email, password: password) }
                            } label: {
                                HStack {
                                    if vm.isLoading { ProgressView().tint(.white) }
                                    Text("Se connecter avec Viple Live ID")
                                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(LoobyPalette.infinityGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(vm.isLoading)
                        }
                    } else {
                        LoobyGlassCard {
                            Picker("Type d'adresse", selection: $regEmailMode) {
                                Text("Boîte @viplemail.fr").tag("viplemail")
                                Text("E-mail personnel").tag("custom")
                            }
                            .pickerStyle(.segmented)

                            if regEmailMode == "viplemail" {
                                HStack {
                                    TextField("identifiant", text: $regVipleUser)
                                        .textInputAutocapitalization(.never)
                                        .foregroundStyle(.white)
                                    Text("@viplemail.fr")
                                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                                        .foregroundStyle(LoobyPalette.infinityCyan)
                                }
                                .padding(12)
                                .background(LoobyPalette.bgSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: 11))
                            } else {
                                TextField("Votre adresse e-mail", text: $regCustomEmail)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .padding(12)
                                    .background(LoobyPalette.bgSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 11))
                                    .foregroundStyle(.white)
                            }

                            HStack(spacing: 8) {
                                TextField("Prénom", text: $regFirstName)
                                    .padding(12)
                                    .background(LoobyPalette.bgSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 11))
                                    .foregroundStyle(.white)

                                TextField("Nom", text: $regLastName)
                                    .padding(12)
                                    .background(LoobyPalette.bgSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 11))
                                    .foregroundStyle(.white)
                            }

                            TextField("Pseudo public", text: $regDisplayName)
                                .padding(12)
                                .background(LoobyPalette.bgSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: 11))
                                .foregroundStyle(.white)

                            SecureField("Choisir un mot de passe", text: $password)
                                .padding(12)
                                .background(LoobyPalette.bgSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: 11))
                                .foregroundStyle(.white)

                            Button {
                                Task {
                                    await vm.registerWithVipleLiveID(
                                        emailMode: regEmailMode,
                                        emailUser: regVipleUser,
                                        customEmail: regCustomEmail,
                                        password: password,
                                        firstName: regFirstName,
                                        lastName: regLastName,
                                        displayName: regDisplayName.isEmpty ? "\(regFirstName) \(regLastName)" : regDisplayName
                                    )
                                }
                            } label: {
                                HStack {
                                    if vm.isLoading { ProgressView().tint(.white) }
                                    Text("Créer mon compte Viple Live ID")
                                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(LoobyPalette.infinityGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(vm.isLoading)
                        }
                    }

                    // Sign in with Apple native button
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        if case .success(let auth) = result,
                           let cred = auth.credential as? ASAuthorizationAppleIDCredential {
                            let uid = cred.user
                            let tokenStr = cred.identityToken.flatMap { String(data: $0, encoding: .utf8) }
                            let fn = cred.fullName?.givenName
                            let ln = cred.fullName?.familyName
                            let em = cred.email
                            Task {
                                if let res = try? await LoobyAPIClient.shared.signInWithApple(
                                    appleUserId: uid,
                                    identityToken: tokenStr,
                                    email: em,
                                    firstName: fn,
                                    lastName: ln
                                ), res.ok, let u = res.user {
                                    vm.currentUser = u
                                    vm.isAuthenticated = true
                                    vm.showLoginSheet = false
                                    await vm.bootstrap()
                                }
                            }
                        }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(16)
            }
            .background(LoobyPalette.bgPrimary.ignoresSafeArea())
            .navigationTitle("Viple Live ID")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
