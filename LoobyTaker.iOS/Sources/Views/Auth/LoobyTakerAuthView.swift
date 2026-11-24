import SwiftUI

// MARK: - Authentification Viple Live ID / Cenelis & Aperçu Programme Looby Taker (Swift 6)

public struct LoobyTakerAuthView: View {
    @EnvironmentObject private var vm: LoobyTakerViewModel

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var isShowingProgramPreview: Bool = false
    @State private var isShowingScanGuide: Bool = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    brandHeroHeader

                    if let sso = vm.detectedSsoAccount {
                        fastSsoBanner(sso)
                    }

                    credentialsLoginCard

                    discoverProgramCard

                    appearanceFooterPicker
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .loobyTakerScreenBackground()
            .sheet(isPresented: $isShowingProgramPreview) {
                LoobyTakerProgramPreviewSheet(onOpenGuide: {
                    isShowingProgramPreview = false
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        isShowingScanGuide = true
                    }
                })
                .environmentObject(vm)
            }
            .sheet(isPresented: $isShowingScanGuide) {
                NavigationStack {
                    ScanningVisualGuideView(showsCloseButton: true)
                }
                .environmentObject(vm)
            }
        }
    }

    // MARK: - 1. En-tête Identité « Looby Taker »

    private var brandHeroHeader: some View {
        VStack(spacing: 14) {
            LoobyTakerBrandMedallion(size: 86, showGlow: true)
                .padding(.top, 8)

            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(LoobyTakerPalette.amberPrimary)
                    Text("RÉSEAU OFFICIEL POINTS RELAIS LOOBY × LIVRIA")
                        .font(.system(size: 10.5, weight: .black, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(LoobyTakerPalette.amberDeep)
                }

                Text("Looby Taker")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundStyle(LoobyTakerPalette.ink)

                Text("Gérez votre Point Relais Particulier (1,00 €/colis) ou Professionnel, scannez la 2e étiquette Viple Delivery et remettez vos colis en toute simplicité.")
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(LoobyTakerPalette.inkSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
        }
    }

    // MARK: - 2. Détection SSO Rapide (`group.com.viplenetwork.shared` / `/sso/discover`)

    private func fastSsoBanner(_ sso: TakerCrossAppAccount) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(LoobyTakerPalette.signatureGradient)
                        .frame(width: 44, height: 44)
                    Text(String(sso.displayName.prefix(2)).uppercased())
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Image(systemName: "bolt.shield.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(LoobyTakerPalette.emerald)
                        Text("SESSION VIPLE DÉTECTÉE SUR CET IPHONE")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(LoobyTakerPalette.emerald)
                    }
                    Text(sso.displayName)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(LoobyTakerPalette.ink)
                    Text("\(sso.email) • via \(sso.sourceApp)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(LoobyTakerPalette.inkSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }

            Button {
                Task {
                    await vm.acceptDetectedSsoAccount(sso)
                }
            } label: {
                HStack(spacing: 8) {
                    if vm.isAuthenticating {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 16, weight: .bold))
                    }
                    Text("Continuer en 1 tap avec \(sso.displayName)")
                        .font(.system(size: 14.5, weight: .black, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(LoobyTakerPalette.goldCoralHorizontal)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(vm.isAuthenticating)
        }
        .loobyTakerCard(padding: 16)
    }

    // MARK: - 3. Formulaire de Connexion Viple Live ID / Cenelis

    private var credentialsLoginCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 8) {
                Image(systemName: "key.radiowaves.forward.fill")
                    .foregroundStyle(LoobyTakerPalette.amberPrimary)
                Text("Connexion Viple Live ID & Cenelis")
                    .font(.system(size: 16.5, weight: .black, design: .rounded))
                    .foregroundStyle(LoobyTakerPalette.ink)
            }

            Text("Compatible avec vos identifiants `@viplemail.fr`, `@cenelis.com` et tout compte Viple Live ID.")
                .font(.system(size: 12.5))
                .foregroundStyle(LoobyTakerPalette.inkSecondary)

            // Champ e-mail + raccourcis domaines rapides
            VStack(alignment: .leading, spacing: 7) {
                Text("Adresse e-mail")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(LoobyTakerPalette.inkSecondary)

                HStack(spacing: 10) {
                    Image(systemName: "at")
                        .foregroundStyle(LoobyTakerPalette.amberPrimary)
                    TextField("prenom.nom@viplemail.fr", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .font(.system(size: 15, weight: .medium))
                }
                .padding(13)
                .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(LoobyTakerPalette.cardSubtle))
                .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous).stroke(LoobyTakerPalette.border, lineWidth: 1))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        domainShortcutChip("@viplemail.fr")
                        domainShortcutChip("@cenelis.com")
                    }
                }
            }

            // Champ mot de passe
            VStack(alignment: .leading, spacing: 7) {
                Text("Mot de passe")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(LoobyTakerPalette.inkSecondary)

                HStack(spacing: 10) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(LoobyTakerPalette.amberPrimary)

                    if isPasswordVisible {
                        TextField("Votre mot de passe Viple Live ID", text: $password)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                    } else {
                        SecureField("Votre mot de passe Viple Live ID", text: $password)
                            .textInputAutocapitalization(.never)
                    }

                    Button {
                        isPasswordVisible.toggle()
                    } label: {
                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(LoobyTakerPalette.inkMuted)
                    }
                    .buttonStyle(.plain)
                }
                .padding(13)
                .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(LoobyTakerPalette.cardSubtle))
                .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous).stroke(LoobyTakerPalette.border, lineWidth: 1))
            }

            if let err = vm.authErrorMessage, !err.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.octagon.fill")
                        .foregroundStyle(LoobyTakerPalette.danger)
                    Text(err)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(LoobyTakerPalette.danger)
                }
                .padding(11)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12).fill(LoobyTakerPalette.danger.opacity(0.10)))
            }

            Button {
                Task {
                    await vm.signInWithCredentials(email: email, password: password)
                }
            } label: {
                HStack(spacing: 9) {
                    if vm.isAuthenticating {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 17, weight: .bold))
                    }
                    Text("Se connecter à Looby Taker")
                        .font(.system(size: 15.5, weight: .black, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(LoobyTakerPalette.goldCoralHorizontal)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .shadow(color: LoobyTakerPalette.amberPrimary.opacity(0.28), radius: 10, x: 0, y: 4)
            }
            .disabled(vm.isAuthenticating)
        }
        .loobyTakerCard(padding: 18)
    }

    private func domainShortcutChip(_ domain: String) -> some View {
        Button {
            let base = email.split(separator: "@").first.map(String.init) ?? email
            email = "\(base)\(domain)"
            LoobyTakerHaptics.impact(0)
        } label: {
            Text("Insérer \(domain)")
                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(LoobyTakerPalette.amberSoft))
                .foregroundStyle(LoobyTakerPalette.amberDeep)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 4. Accès Direct en Bas d'Écran : Aperçu du Programme Point Relais Particulier ou Pro

    private var discoverProgramCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.20))
                        .frame(width: 44, height: 44)
                    Image(systemName: "shippingbox.and.arrow.backward.fill")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("NOUVEAU PROGRAMME RELAIS")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.88))
                    Text("Découvrir & Devenir Point Relais Looby Taker (Particulier ou Pro)")
                        .font(.system(size: 15.5, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
            }

            Text("Particuliers à domicile (1,00 € gagné par colis remis avec code PIN sécurisé) ou Commerçants Pro (flux rapide sans code PIN, visibilité locale Looby & Livria).")
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.92))

            HStack(spacing: 10) {
                Button {
                    isShowingProgramPreview = true
                } label: {
                    Label("Découvrir le programme", systemImage: "sparkles")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white))
                        .foregroundStyle(Color(red: 0.72, green: 0.38, blue: 0.04))
                }

                Button {
                    isShowingScanGuide = true
                } label: {
                    Label("Guide 2e étiquette", systemImage: "barcode.viewfinder")
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.18)))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(18)
        .background(
            LoobyTakerHeroBackground(isProStyle: false)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        )
    }

    private var appearanceFooterPicker: some View {
        HStack(spacing: 8) {
            ForEach(LoobyTakerAppearanceMode.allCases) { mode in
                let selected = vm.appearanceMode == mode
                Button {
                    vm.appearanceMode = mode
                    LoobyTakerHaptics.impact(0)
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: mode.iconName)
                            .font(.system(size: 11, weight: .bold))
                        Text(mode.labelFr)
                            .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(selected ? LoobyTakerPalette.amberPrimary : LoobyTakerPalette.cardSurface)
                    )
                    .foregroundStyle(selected ? .white : LoobyTakerPalette.inkSecondary)
                    .overlay(
                        Capsule()
                            .stroke(selected ? Color.clear : LoobyTakerPalette.border, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 4)
    }
}

// MARK: - Feuille d'Aperçu Détaillé du Programme « Devenir Point Relais Looby Taker »

public struct LoobyTakerProgramPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    public let onOpenGuide: () -> Void

    public init(onOpenGuide: @escaping () -> Void) {
        self.onOpenGuide = onOpenGuide
    }

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            LoobyTakerBrandMedallion(size: 52, showGlow: false)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("PROGRAMME LOOBY TAKER 2026")
                                    .font(.system(size: 10.5, weight: .black, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.88))
                                Text("Deux formules adaptées : Particulier ou Pro")
                                    .font(.system(size: 19, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                            }
                        }
                        Text("Connectez-vous avec votre compte Viple Live ID pour déposer votre candidature en 2 minutes et suivre en direct les 4 étapes de validation.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.92))
                    }
                    .padding(18)
                    .background(
                        LoobyTakerHeroBackground(isProStyle: false)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    )

                    // Comparatif Particulier vs Pro
                    formulaCard(
                        badge: "FORMULE PARTICULIER • À DOMICILE",
                        title: "Taker Particulier — 1,00 € par colis remis",
                        accent: LoobyTakerPalette.amberPrimary,
                        bullets: [
                            "Recevez à domicile les colis acheminés par Viple Delivery ou UPS.",
                            "Scannez toujours la 2e étiquette Viple Delivery (VD-…) à l'arrivée.",
                            "Donnez rendez-vous au client selon vos créneaux de présence.",
                            "Échangez le Code PIN à 6 chiffres avec le client lors du retrait et gagnez 1,00 €/colis !"
                        ],
                        icon: "house.fill"
                    )

                    formulaCard(
                        badge: "FORMULE PROFESSIONNEL • COMMERCE & BOUTIQUE",
                        title: "Taker Pro — Flux comptoir ultra-rapide sans PIN",
                        accent: LoobyTakerPalette.proCobalt,
                        bullets: [
                            "Idéal pour librairies, commerces de proximité, conciergeries et boutiques.",
                            "Remise directe au comptoir sans aucun code PIN pour zéro attente en caisse.",
                            "Bouton rapide « Dire que nous sommes fermés » en 1 tap + horaires Lundi–Dimanche.",
                            "Visibilité renforcée auprès des acheteurs Livria Store, Livria Marketplace & Looby."
                        ],
                        icon: "storefront.fill"
                    )

                    Button(action: onOpenGuide) {
                        HStack(spacing: 10) {
                            Image(systemName: "barcode.viewfinder")
                                .font(.system(size: 18, weight: .bold))
                            Text("Voir le guide illustré : quelle étiquette scanner ?")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .padding(15)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(LoobyTakerPalette.amberSoft))
                        .foregroundStyle(LoobyTakerPalette.amberDeep)
                    }
                    .buttonStyle(.plain)
                }
                .padding(18)
            }
            .loobyTakerScreenBackground()
            .navigationTitle("Devenir Looby Taker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Se connecter") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                }
            }
        }
    }

    private func formulaCard(
        badge: String,
        title: String,
        accent: Color,
        bullets: [String],
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(accent)
                Text(badge)
                    .font(.system(size: 10.5, weight: .black, design: .rounded))
                    .foregroundStyle(accent)
            }

            Text(title)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(LoobyTakerPalette.ink)

            ForEach(bullets, id: \.self) { line in
                HStack(alignment: .top, spacing: 9) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(accent)
                        .padding(.top, 1)
                    Text(line)
                        .font(.system(size: 13))
                        .foregroundStyle(LoobyTakerPalette.inkSecondary)
                }
            }
        }
        .loobyTakerCard(padding: 16)
    }
}
