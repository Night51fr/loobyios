import SwiftUI

// MARK: - Candidature « Devenir Looby Taker (Particulier ou Pro) » & Suivi Détaillé en 4 Étapes (`TakerApplicationAndTrackingView.swift` • Swift 6)

public struct TakerApplicationAndTrackingView: View {
    @EnvironmentObject private var vm: LoobyTakerViewModel
    @Environment(\.dismiss) private var dismiss

    public var showsCloseButton: Bool

    @State private var applicantType: String = "Particulier"
    @State private var relayName: String = ""
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var phone: String = ""
    @State private var siret: String = ""
    @State private var businessCategory: String = "Librairie / Commerce culturel"
    @State private var address: String = ""
    @State private var postalCode: String = ""
    @State private var city: String = ""
    @State private var openingHours: String = "Lun–Ven 17h30–20h30 • Sam 09h30–19h00"
    @State private var storageCapacity: String = "15 à 30 colis / semaine"
    @State private var motivationAndAccessNotes: String = ""
    @State private var acceptsCharter: Bool = true
    @State private var isSubmitting: Bool = false

    private let capacityChoices = [
        "5 à 15 colis / semaine",
        "15 à 30 colis / semaine",
        "30 à 60 colis / semaine",
        "Plus de 60 colis / semaine (Local Pro)"
    ]

    public init(showsCloseButton: Bool = false) {
        self.showsCloseButton = showsCloseButton
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                headerBanner

                if !vm.applications.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Suivi en direct de vos demandes (\(vm.applications.count))")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(LoobyTakerPalette.ink)

                        ForEach(vm.applications) { record in
                            TakerApplicationTrackerCard(application: record)
                        }
                    }
                }

                applicationFormCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .loobyTakerScreenBackground()
        .navigationTitle("Devenir Looby Taker")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsCloseButton {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") { dismiss() }
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
            }
        }
        .onAppear {
            prefillFromCurrentUser()
        }
    }

    private var headerBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "shippingbox.and.arrow.backward.fill")
                    .foregroundStyle(.white)
                Text("CANDIDATURE POINT RELAIS LOOBY TAKER")
                    .font(.system(size: 10.5, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.90))
            }

            Text("Ouvrez un Point Relais Particulier (1,00 €/colis) ou Professionnel")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("Recevez les colis Viple Delivery et UPS, scannez la 2e étiquette VD-… avec Looby Taker et suivez chaque étape d'instruction de votre dossier ci-dessous.")
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(.white.opacity(0.92))
        }
        .padding(18)
        .background(
            LoobyTakerHeroBackground(isProStyle: applicantType == "Pro")
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        )
    }

    // MARK: - Formulaire Complet Particulier / Pro (`POST /taker/applications/submit`)

    private var applicationFormCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Nouvelle demande d'ouverture de relais")
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(LoobyTakerPalette.ink)

            Picker("Profil de candidat", selection: $applicantType) {
                Text("Taker Particulier (1 €/colis)").tag("Particulier")
                Text("Taker Pro (Commerce / SIRET)").tag("Pro")
            }
            .pickerStyle(.segmented)
            .onChange(of: applicantType) { _, newType in
                if newType == "Pro" {
                    openingHours = "Lun–Sam 09h00–12h30 & 14h00–19h00"
                    if relayName.hasPrefix("Viple Taker - Chez") {
                        relayName = ""
                    }
                } else {
                    openingHours = "Lun–Ven 17h30–20h30 • Sam 09h30–19h00"
                }
            }

            HStack(spacing: 10) {
                labeledField("Prénom", placeholder: "Chris", text: $firstName)
                labeledField("Nom", placeholder: "Martin", text: $lastName)
            }

            labeledField(
                applicantType == "Pro" ? "Enseigne commerciale du Point Relais" : "Nom affiché de votre relais Particulier",
                placeholder: applicantType == "Pro" ? "Ex : Librairie du Parc - Relais Looby" : "Ex : Viple Taker - Chez Chris",
                text: $relayName
            )

            labeledField("Téléphone mobile / boutique", placeholder: "06 12 34 56 78", text: $phone)

            if applicantType == "Pro" {
                labeledField("Numéro SIRET (14 chiffres)", placeholder: "Ex : 89234567800014", text: $siret)
                labeledField("Activité / Catégorie commerciale", placeholder: "Librairie, Presse, Boutique, Conciergerie…", text: $businessCategory)
            }

            labeledField("Adresse complète de réception", placeholder: "Numéro et rue", text: $address)

            HStack(spacing: 10) {
                labeledField("Code postal", placeholder: "57000", text: $postalCode)
                    .frame(width: 120)
                labeledField("Ville", placeholder: "Metz", text: $city)
            }

            labeledField("Horaires d'accueil prévus", placeholder: "Lun–Ven 17h30–20h30", text: $openingHours)

            VStack(alignment: .leading, spacing: 5) {
                Text("Capacité de stockage hebdomadaire")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(LoobyTakerPalette.inkSecondary)
                Picker("Capacité", selection: $storageCapacity) {
                    ForEach(capacityChoices, id: \.self) { opt in
                        Text(opt).tag(opt)
                    }
                }
                .pickerStyle(.menu)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 11).fill(LoobyTakerPalette.cardSubtle))
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Motivations, digicode & consignes d'accès livreurs")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(LoobyTakerPalette.inkSecondary)
                TextField("Précisez l'accès rez-de-chaussée, interphone, pièce dédiée au sec…", text: $motivationAndAccessNotes, axis: .vertical)
                    .lineLimit(2...5)
                    .padding(11)
                    .background(RoundedRectangle(cornerRadius: 11).fill(LoobyTakerPalette.cardSubtle))
            }

            Toggle(isOn: $acceptsCharter) {
                Text(
                    applicantType == "Pro"
                        ? "Je m'engage à scanner la 2e étiquette Viple Delivery (VD-…) à réception et à remettre les colis aux clients durant mes horaires d'ouverture."
                        : "Je m'engage à scanner la 2e étiquette Viple Delivery (VD-…) à réception et à remettre les colis sur RDV contre le Code PIN client (1,00 €/colis)."
                )
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(LoobyTakerPalette.inkSecondary)
            }
            .tint(LoobyTakerPalette.amberPrimary)

            Button {
                Task {
                    isSubmitting = true
                    let finalRelayName = relayName.trimmingCharacters(in: .whitespaces).isEmpty
                        ? (applicantType == "Pro" ? "Relais Pro \(city)" : "Viple Taker - Chez \(firstName.isEmpty ? "Moi" : firstName)")
                        : relayName
                    let ok = await vm.submitApplication(
                        applicantType: applicantType,
                        relayName: finalRelayName,
                        firstName: firstName,
                        lastName: lastName,
                        phone: phone,
                        siret: applicantType == "Pro" ? siret : "",
                        businessCategory: applicantType == "Pro" ? businessCategory : "Particulier à domicile",
                        address: address,
                        postalCode: postalCode,
                        city: city,
                        openingHours: openingHours,
                        storageCapacity: storageCapacity,
                        motivationAndAccessNotes: motivationAndAccessNotes
                    )
                    isSubmitting = false
                    if ok && showsCloseButton {
                        dismiss()
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
                    Text("Envoyer ma demande Taker \(applicantType)")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(LoobyTakerPalette.goldCoralHorizontal)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            }
            .disabled(!acceptsCharter || address.trimmingCharacters(in: .whitespaces).isEmpty || city.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
        }
        .loobyTakerCard()
    }

    private func labeledField(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(LoobyTakerPalette.inkSecondary)
            TextField(placeholder, text: text)
                .padding(11)
                .background(RoundedRectangle(cornerRadius: 11).fill(LoobyTakerPalette.cardSubtle))
        }
    }

    private func prefillFromCurrentUser() {
        guard let u = vm.currentUser else { return }
        if firstName.isEmpty { firstName = u.firstName }
        if lastName.isEmpty { lastName = u.lastName }
        if phone.isEmpty { phone = u.phone }
        if relayName.isEmpty && !u.displayName.isEmpty {
            relayName = "Viple Taker - Chez \(u.displayName)"
        }
    }
}

// MARK: - Carte de Suivi Détaillé en 4 Étapes + Réponse aux Demandes d'Éléments Supplémentaires (`POST /taker/applications/reply`)

public struct TakerApplicationTrackerCard: View {
    @EnvironmentObject private var vm: LoobyTakerViewModel

    public let application: TakerApplicationRecord
    @State private var supplementaryReplyText: String = ""
    @State private var isSendingReply: Bool = false

    private let fourSteps: [(Int, String, String)] = [
        (1, "1. Dossier envoyé", "Candidature enregistrée et transmise à l'équipe réseau Looby × Viple."),
        (2, "2. Étude par Viple", "Analyse de la zone géographique, des horaires et de la capacité d'accueil."),
        (3, "3. Vérification & compléments", "Validation des consignes d'accès livreurs Viple Delivery / UPS."),
        (4, "4. Activation du Point Relais", "Ouverture officielle du relais dans Looby Taker et sur Livria Store.")
    ]

    public init(application: TakerApplicationRecord) {
        self.application = application
    }

    private var isRejected: Bool {
        application.status.lowercased().contains("refus")
    }

    private var isApproved: Bool {
        application.status.lowercased().contains("valid") || application.status.lowercased().contains("actif")
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(application.applicantType.uppercased())
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(LoobyTakerPalette.amberSoft))
                            .foregroundStyle(LoobyTakerPalette.amberDeep)

                        Text(application.reference)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(LoobyTakerPalette.inkMuted)
                    }
                    Text(application.relayName)
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(LoobyTakerPalette.ink)
                }
                Spacer()

                Text(application.status)
                    .font(.system(size: 11.5, weight: .black, design: .rounded))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule().fill(
                            isRejected
                                ? LoobyTakerPalette.danger.opacity(0.15)
                                : (isApproved ? LoobyTakerPalette.emeraldSoft : LoobyTakerPalette.amberSoft)
                        )
                    )
                    .foregroundStyle(
                        isRejected
                            ? LoobyTakerPalette.danger
                            : (isApproved ? LoobyTakerPalette.emerald : LoobyTakerPalette.amberDeep)
                    )
            }

            // Timeline en 4 étapes
            VStack(alignment: .leading, spacing: 10) {
                ForEach(fourSteps, id: \.0) { stepNum, title, desc in
                    let done = isApproved || application.stepIndex > stepNum
                    let current = !isApproved && application.stepIndex == stepNum

                    HStack(alignment: .top, spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(
                                    done ? LoobyTakerPalette.emerald :
                                    (current ? LoobyTakerPalette.amberPrimary : LoobyTakerPalette.cardSubtle)
                                )
                                .frame(width: 24, height: 24)

                            if done {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundStyle(.white)
                            } else {
                                Text("\(stepNum)")
                                    .font(.system(size: 11, weight: .black, design: .rounded))
                                    .foregroundStyle(current ? .white : LoobyTakerPalette.inkMuted)
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(.system(size: 13, weight: current || done ? .black : .semibold, design: .rounded))
                                .foregroundStyle(current || done ? LoobyTakerPalette.ink : LoobyTakerPalette.inkMuted)
                            Text(desc)
                                .font(.system(size: 11.5))
                                .foregroundStyle(LoobyTakerPalette.inkSecondary)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 14).fill(LoobyTakerPalette.cardSubtle))

            // Réponse directe si l'équipe Viple demande des éléments supplémentaires
            if application.needsSupplementaryReply {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.bubble.fill")
                            .foregroundStyle(LoobyTakerPalette.amberPrimary)
                        Text("Précision demandée par l'équipe Viple :")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(LoobyTakerPalette.ink)
                    }

                    Text(
                        application.requestedAdditionalInfo.isEmpty
                            ? "Merci de confirmer vos créneaux de présence et les modalités d'accès pour le chauffeur Viple Delivery / UPS."
                            : application.requestedAdditionalInfo
                    )
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(LoobyTakerPalette.amberDeep)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 10).fill(LoobyTakerPalette.amberSoft))

                    TextField("Votre réponse complémentaire pour Viple…", text: $supplementaryReplyText, axis: .vertical)
                        .lineLimit(2...5)
                        .padding(11)
                        .background(RoundedRectangle(cornerRadius: 10).fill(LoobyTakerPalette.cardSurface))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(LoobyTakerPalette.border, lineWidth: 1))

                    Button {
                        Task {
                            isSendingReply = true
                            let ok = await vm.sendApplicationSupplementaryReply(
                                application: application,
                                supplementaryResponse: supplementaryReplyText
                            )
                            isSendingReply = false
                            if ok {
                                supplementaryReplyText = ""
                            }
                        }
                    } label: {
                        HStack(spacing: 7) {
                            if isSendingReply {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "paperplane.fill")
                            }
                            Text("Envoyer ma réponse à Viple")
                                .font(.system(size: 13.5, weight: .black, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(LoobyTakerPalette.goldCoralHorizontal)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .disabled(supplementaryReplyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSendingReply)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 15).fill(LoobyTakerPalette.amberSoft.opacity(0.45)))
                .overlay(RoundedRectangle(cornerRadius: 15).stroke(LoobyTakerPalette.amberPrimary.opacity(0.45), lineWidth: 1))
            }
        }
        .loobyTakerCard()
        .onAppear {
            if supplementaryReplyText.isEmpty && !application.applicantSupplementaryResponse.isEmpty {
                supplementaryReplyText = application.applicantSupplementaryResponse
            }
        }
    }
}
