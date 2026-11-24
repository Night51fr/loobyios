import SwiftUI

// MARK: - Onglet 5 : Mon Relais, Aide Scan, Candidatures & Appareils Connectés (`RelayProfileAndHelpView.swift` • Swift 6)

public struct RelayProfileAndHelpView: View {
    @EnvironmentObject private var vm: LoobyTakerViewModel
    @EnvironmentObject private var notifManager: LoobyTakerNotificationManager

    @State private var showingSignOutConfirmation: Bool = false

    public init() {}

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                relaySummaryCard

                helpAndEcosystemNavigationSection

                notificationsAndAppearanceCard

                cleanSignOutCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 40)
        }
        .loobyTakerScreenBackground()
        .navigationTitle("Mon Relais & Aide")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Se déconnecter de Looby Taker ?", isPresented: $showingSignOutConfirmation) {
            Button("Annuler", role: .cancel) {}
            Button("Se déconnecter", role: .destructive) {
                Task {
                    await vm.signOutCleanly()
                }
            }
        } message: {
            Text("Toutes les notifications locales seront purgées et cet appareil sera désinscrit du push APNs avant la fermeture de votre session.")
        }
    }

    // MARK: - 1. Fiche Identité du Point Relais & Modification

    private var relaySummaryCard: some View {
        let relay = vm.activeRelay ?? TakerRelayPoint()
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                LoobyTakerBrandMedallion(size: 54, showGlow: false)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(relay.name)
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundStyle(LoobyTakerPalette.ink)
                        Text("id-\(relay.id)")
                            .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2.5)
                            .background(Capsule().fill(LoobyTakerPalette.amberSoft))
                            .foregroundStyle(LoobyTakerPalette.amberDeep)
                    }

                    Text(relay.typeLabel)
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .foregroundStyle(relay.isPro ? LoobyTakerPalette.proCobalt : LoobyTakerPalette.amberPrimary)

                    Text(relay.fullAddress)
                        .font(.system(size: 12.5))
                        .foregroundStyle(LoobyTakerPalette.inkSecondary)
                }
                Spacer(minLength: 0)
            }

            Divider()

            VStack(alignment: .leading, spacing: 7) {
                infoLine(icon: "person.crop.circle.fill", label: "Compte Taker", value: "\(vm.currentUser?.displayName ?? "") (\(vm.currentUser?.email ?? ""))")
                if !relay.phone.isEmpty {
                    infoLine(icon: "phone.fill", label: "Téléphone relais", value: relay.phone)
                }
                infoLine(icon: "shippingbox.fill", label: "Capacité max.", value: "\(relay.maxParcelCapacity) colis")
                if relay.isPro && !relay.siret.isEmpty {
                    infoLine(icon: "building.2.fill", label: "SIRET / Catégorie", value: "\(relay.siret) • \(relay.businessCategory)")
                }
                if !relay.intercomAndAccessNotes.isEmpty {
                    infoLine(icon: "key.viewfinder", label: "Accès / Digicode", value: relay.intercomAndAccessNotes)
                }
            }

            HStack(spacing: 10) {
                Button {
                    vm.isShowingRelayEditSheet = true
                } label: {
                    Label("Modifier mon Point Relais", systemImage: "pencil.line")
                        .font(.system(size: 13.5, weight: .black, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(LoobyTakerPalette.goldCoralHorizontal)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                }

                if vm.relays.count > 1 {
                    Menu {
                        ForEach(vm.relays) { r in
                            Button {
                                Task { await vm.selectRelay(r) }
                            } label: {
                                Label(r.name, systemImage: r.id == relay.id ? "checkmark.circle.fill" : "mappin.and.ellipse")
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 15, weight: .bold))
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: 13).fill(LoobyTakerPalette.amberSoft))
                            .foregroundStyle(LoobyTakerPalette.amberDeep)
                    }
                }
            }
        }
        .loobyTakerCard()
    }

    private func infoLine(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12.5, weight: .bold))
                .foregroundStyle(LoobyTakerPalette.amberPrimary)
                .frame(width: 18)
            Text("\(label) :")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(LoobyTakerPalette.inkMuted)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(LoobyTakerPalette.ink)
            Spacer(minLength: 0)
        }
    }

    // MARK: - 2. Liens Guide Visuel Scan, Candidature & Gestionnaire d'Appareils

    private var helpAndEcosystemNavigationSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text("Guides, Inscriptions & Sécurité Viple Live ID")
                .font(.system(size: 15.5, weight: .black, design: .rounded))
                .foregroundStyle(LoobyTakerPalette.ink)

            NavigationLink {
                ScanningVisualGuideView(showsCloseButton: false)
            } label: {
                navRowContent(
                    icon: "barcode.viewfinder",
                    tint: LoobyTakerPalette.emerald,
                    title: "Quoi scanner pour recevoir un colis ?",
                    subtitle: "Schéma illustré Étiquette 1 UPS (1Z…) vs 2e Étiquette Viple Delivery (VD-…)"
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                TakerApplicationAndTrackingView(showsCloseButton: false)
            } label: {
                navRowContent(
                    icon: "doc.badge.plus",
                    tint: LoobyTakerPalette.amberPrimary,
                    title: "Ouvrir un autre relais / Suivre ma demande",
                    subtitle: "Formulaire Particulier ou Pro + suivi en direct en 4 étapes"
                )
            }
            .buttonStyle(.plain)

            NavigationLink {
                LoobyTakerConnectedDevicesView()
            } label: {
                navRowContent(
                    icon: "laptopcomputer.and.iphone",
                    tint: LoobyTakerPalette.proCobalt,
                    title: "Appareils & applications connectés",
                    subtitle: "\(LoobyTakerAPIClient.shared.resolvedHardwareModelName) (\(LoobyTakerAPIClient.shared.resolvedHardwareModelCode)) • Déconnexion à distance"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func navRowContent(icon: String, tint: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(tint.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14.5, weight: .black, design: .rounded))
                    .foregroundStyle(LoobyTakerPalette.ink)
                    .multilineTextAlignment(.leading)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(LoobyTakerPalette.inkSecondary)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 4)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(LoobyTakerPalette.inkMuted)
        }
        .loobyTakerCard(padding: 14)
    }

    // MARK: - 3. Notifications Push APNs & Apparence Clair / Sombre

    private var notificationsAndAppearanceCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Label("Notifications Push APNs & Thème", systemImage: "bell.badge.fill")
                    .font(.system(size: 15.5, weight: .black, design: .rounded))
                    .foregroundStyle(LoobyTakerPalette.ink)
                Spacer()
                Text(notifManager.statusBadgeText)
                    .font(.system(size: 10.5, weight: .black, design: .rounded))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(LoobyTakerPalette.emeraldSoft))
                    .foregroundStyle(LoobyTakerPalette.emerald)
            }

            Toggle(isOn: $notifManager.notificationsEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Alertes colis en approche & RDV clients")
                        .font(.system(size: 13.5, weight: .bold, design: .rounded))
                    Text("Notifications exclusives pour le compte actif sur cet iPhone (`fr.looby.taker`).")
                        .font(.system(size: 11.5))
                        .foregroundStyle(LoobyTakerPalette.inkSecondary)
                }
            }
            .tint(LoobyTakerPalette.amberPrimary)

            if notifManager.authorizationStatus == .denied {
                Button {
                    notifManager.openSystemNotificationSettings()
                } label: {
                    Label("Autoriser les notifications dans Réglages iOS", systemImage: "gear")
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .foregroundStyle(LoobyTakerPalette.amberPrimary)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 7) {
                Text("Apparence de l'application")
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundStyle(LoobyTakerPalette.inkSecondary)

                Picker("Apparence", selection: $vm.appearanceMode) {
                    ForEach(LoobyTakerAppearanceMode.allCases) { m in
                        Text(m.labelFr).tag(m)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .loobyTakerCard()
    }

    // MARK: - 4. Déconnexion Propre

    private var cleanSignOutCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(role: .destructive) {
                showingSignOutConfirmation = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 15, weight: .bold))
                    Text("Se déconnecter de Looby Taker")
                        .font(.system(size: 14.5, weight: .black, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(LoobyTakerPalette.danger.opacity(0.12)))
                .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(LoobyTakerPalette.danger.opacity(0.32), lineWidth: 1))
                .foregroundStyle(LoobyTakerPalette.danger)
            }

            Text("Version \(LoobyTakerDeviceIdentity.clientMarketingVersion) • Bundle `fr.looby.taker` • \(LoobyTakerAPIClient.shared.resolvedHardwareModelName)")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(LoobyTakerPalette.inkMuted)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

// MARK: - Feuille d'Édition des Informations du Point Relais (`POST /taker/relay/update-info`)

public struct RelayInfoEditorSheet: View {
    @EnvironmentObject private var vm: LoobyTakerViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var relayMode: String = "Particulier"
    @State private var address: String = ""
    @State private var postalCode: String = ""
    @State private var city: String = ""
    @State private var phone: String = ""
    @State private var siret: String = ""
    @State private var businessCategory: String = ""
    @State private var intercomAndAccessNotes: String = ""
    @State private var maxParcelCapacity: Int = 25
    @State private var isSaving: Bool = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 15) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Statut de fonctionnement du relais")
                            .font(.system(size: 12.5, weight: .bold, design: .rounded))

                        Picker("Mode du relais", selection: $relayMode) {
                            Text("Particulier (1 €/colis + PIN)").tag("Particulier")
                            Text("Professionnel (Sans PIN)").tag("Pro")
                        }
                        .pickerStyle(.segmented)

                        fieldBlock("Nom affiché du Point Relais", placeholder: "Ex : Viple Taker - Chez Chris", text: $name)
                        fieldBlock("Adresse postale", placeholder: "Numéro et rue", text: $address)

                        HStack(spacing: 10) {
                            fieldBlock("Code postal", placeholder: "57000", text: $postalCode)
                                .frame(width: 120)
                            fieldBlock("Ville", placeholder: "Metz", text: $city)
                        }

                        fieldBlock("Téléphone de contact livreurs / clients", placeholder: "06 12 34 56 78", text: $phone)

                        if relayMode == "Pro" {
                            fieldBlock("Numéro SIRET (Relais Pro)", placeholder: "14 chiffres SIRET", text: $siret)
                            fieldBlock("Catégorie du commerce", placeholder: "Librairie, Presse, Épicerie fine, Conciergerie…", text: $businessCategory)
                        }

                        VStack(alignment: .leading, spacing: 5) {
                            Text("Digicode, interphone & consignes d'accès")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(LoobyTakerPalette.inkSecondary)
                            TextField("Ex : Interphone CHRIS, porte vitrée rez-de-chaussée…", text: $intercomAndAccessNotes, axis: .vertical)
                                .lineLimit(2...4)
                                .padding(11)
                                .background(RoundedRectangle(cornerRadius: 11).fill(LoobyTakerPalette.cardSubtle))
                        }

                        Stepper(value: $maxParcelCapacity, in: 5...300, step: 5) {
                            HStack {
                                Text("Capacité maximale simultanée")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                Spacer()
                                Text("\(maxParcelCapacity) colis")
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                    .foregroundStyle(LoobyTakerPalette.amberPrimary)
                            }
                        }
                    }
                    .loobyTakerCard()

                    Button {
                        Task {
                            isSaving = true
                            let ok = await vm.saveRelayInformation(
                                name: name,
                                relayMode: relayMode,
                                address: address,
                                postalCode: postalCode,
                                city: city,
                                phone: phone,
                                siret: relayMode == "Pro" ? siret : "",
                                businessCategory: relayMode == "Pro" ? businessCategory : "",
                                intercomAndAccessNotes: intercomAndAccessNotes,
                                maxParcelCapacity: maxParcelCapacity
                            )
                            isSaving = false
                            if ok {
                                dismiss()
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                            }
                            Text("Enregistrer les informations du relais")
                                .font(.system(size: 15, weight: .black, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(LoobyTakerPalette.goldCoralHorizontal)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
                .padding(18)
            }
            .loobyTakerScreenBackground()
            .navigationTitle("Modifier mon relais")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") { dismiss() }
                }
            }
            .onAppear {
                if let r = vm.activeRelay {
                    name = r.name
                    relayMode = r.isPro ? "Pro" : "Particulier"
                    address = r.address
                    postalCode = r.postalCode
                    city = r.city
                    phone = r.phone
                    siret = r.siret
                    businessCategory = r.businessCategory
                    intercomAndAccessNotes = r.intercomAndAccessNotes
                    maxParcelCapacity = r.maxParcelCapacity
                }
            }
        }
    }

    private func fieldBlock(_ title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(LoobyTakerPalette.inkSecondary)
            TextField(placeholder, text: text)
                .padding(11)
                .background(RoundedRectangle(cornerRadius: 11).fill(LoobyTakerPalette.cardSubtle))
        }
    }
}
