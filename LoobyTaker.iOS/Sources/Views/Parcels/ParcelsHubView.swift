import SwiftUI

// MARK: - Onglet 3 : Hub Colis, Prévisions d'Arrivée & Anomalies de Réception (`ParcelsHubView.swift` • Swift 6)

public struct ParcelsHubView: View {
    @EnvironmentObject private var vm: LoobyTakerViewModel

    @State private var searchText: String = ""
    @State private var selectedParcelForDetail: TakerParcel? = nil

    public init() {}

    private var filteredParcels: [TakerParcel] {
        let base: [TakerParcel]
        switch vm.parcelsSegment {
        case .expected:
            base = vm.expectedParcels
        case .inStock:
            base = vm.inStockParcels
        case .handedOver:
            base = vm.handedOverParcels
        case .issues:
            base = vm.issueParcels
        }
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return base }
        return base.filter {
            $0.vipleBarcode.lowercased().contains(q) ||
            $0.recipientName.lowercased().contains(q) ||
            $0.carrierTrackingNumber.lowercased().contains(q) ||
            $0.orderReference.lowercased().contains(q)
        }
    }

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                topActionButtonsRow

                searchAndSegmentBar

                if vm.parcelsSegment == .issues {
                    issuesDedicatedListSection
                } else {
                    parcelsListSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 38)
        }
        .loobyTakerScreenBackground()
        .navigationTitle("Colis & Anomalies")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await vm.refreshBootstrap()
        }
        .sheet(item: $selectedParcelForDetail) { parcel in
            ParcelDetailSheet(parcel: parcel)
                .environmentObject(vm)
        }
    }

    // MARK: - 1. Boutons d'Action « Prévoir l'arrivée » & « Signaler un problème »

    private var topActionButtonsRow: some View {
        HStack(spacing: 10) {
            Button {
                vm.isShowingForecastSheet = true
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 15, weight: .bold))
                    Text("Prévoir l'arrivée d'un colis")
                        .font(.system(size: 12.5, weight: .black, design: .rounded))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(LoobyTakerPalette.goldCoralHorizontal)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            }

            Button {
                vm.prefilledIssueParcel = nil
                vm.prefilledIssueBarcode = ""
                vm.isShowingReportIssueSheet = true
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 15, weight: .bold))
                    Text("Signaler un problème")
                        .font(.system(size: 12.5, weight: .black, design: .rounded))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(LoobyTakerPalette.coralSoft))
                .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(LoobyTakerPalette.coralGlow.opacity(0.45), lineWidth: 1))
                .foregroundStyle(LoobyTakerPalette.danger)
            }
        }
    }

    // MARK: - 2. Recherche & Segments (En approche / En stock / Remis / Problèmes)

    private var searchAndSegmentBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 9) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(LoobyTakerPalette.inkMuted)
                TextField("Rechercher un destinataire, code VD-… ou suivi 1Z…", text: $searchText)
                    .font(.system(size: 13.5))
                    .autocorrectionDisabled(true)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(LoobyTakerPalette.inkMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(11)
            .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(LoobyTakerPalette.cardSurface))
            .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous).stroke(LoobyTakerPalette.border, lineWidth: 1))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TakerParcelsSegment.allCases) { seg in
                        let isSelected = vm.parcelsSegment == seg
                        let count = segmentCount(seg)
                        Button {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                                vm.parcelsSegment = seg
                            }
                            LoobyTakerHaptics.impact(0)
                        } label: {
                            HStack(spacing: 6) {
                                Text(seg.labelFr)
                                    .font(.system(size: 12.5, weight: .black, design: .rounded))
                                Text("\(count)")
                                    .font(.system(size: 11, weight: .black, design: .rounded))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule().fill(isSelected ? Color.white.opacity(0.24) : LoobyTakerPalette.cardSubtle)
                                    )
                            }
                            .padding(.horizontal, 13)
                            .padding(.vertical, 9)
                            .background(
                                Capsule().fill(isSelected ? LoobyTakerPalette.amberPrimary : LoobyTakerPalette.cardSurface)
                            )
                            .overlay(
                                Capsule().stroke(isSelected ? Color.clear : LoobyTakerPalette.border, lineWidth: 1)
                            )
                            .foregroundStyle(isSelected ? .white : LoobyTakerPalette.inkSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func segmentCount(_ seg: TakerParcelsSegment) -> Int {
        switch seg {
        case .expected: return vm.expectedParcels.count
        case .inStock: return vm.inStockParcels.count
        case .handedOver: return vm.handedOverParcels.count
        case .issues: return max(vm.issues.count, vm.issueParcels.count)
        }
    }

    // MARK: - 3. Liste des Colis & Actions Rapides

    private var parcelsListSection: some View {
        VStack(spacing: 12) {
            if filteredParcels.isEmpty {
                emptyParcelState
            } else {
                ForEach(filteredParcels) { parcel in
                    parcelCard(parcel)
                }
            }
        }
    }

    private func parcelCard(_ parcel: TakerParcel) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(parcel.vipleBarcode)
                            .font(.system(size: 13.5, weight: .black, design: .monospaced))
                            .foregroundStyle(LoobyTakerPalette.amberDeep)

                        if parcel.isDeliveredByUps {
                            Text("UPS + 2e étiquette VD")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2.5)
                                .background(Capsule().fill(LoobyTakerPalette.amberSoft))
                                .foregroundStyle(LoobyTakerPalette.upsBrown)
                        }
                    }

                    Text(parcel.recipientName)
                        .font(.system(size: 16.5, weight: .black, design: .rounded))
                        .foregroundStyle(LoobyTakerPalette.ink)
                }

                Spacer()

                statusPill(for: parcel)
            }

            HStack(spacing: 12) {
                Label(parcel.carrier, systemImage: "truck.box.fill")
                if !parcel.shelfLocation.isEmpty {
                    Label(parcel.shelfLocation, systemImage: "cabinet.fill")
                }
                if !parcel.expectedArrivalDate.isEmpty && parcel.isExpected {
                    Label(parcel.expectedArrivalDate, systemImage: "calendar")
                }
            }
            .font(.system(size: 11.5, weight: .semibold))
            .foregroundStyle(LoobyTakerPalette.inkSecondary)

            if let issue = parcel.issueSummary, !issue.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(LoobyTakerPalette.danger)
                    Text(issue)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(LoobyTakerPalette.danger)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(LoobyTakerPalette.danger.opacity(0.09)))
            }

            Divider()

            HStack(spacing: 8) {
                Button {
                    selectedParcelForDetail = parcel
                } label: {
                    Label("Fiche détail", systemImage: "doc.text.magnifyingglass")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .padding(.horizontal, 11)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 10).fill(LoobyTakerPalette.cardSubtle))
                        .foregroundStyle(LoobyTakerPalette.ink)
                }
                .buttonStyle(.plain)

                Spacer()

                if parcel.isExpected {
                    Button {
                        Task {
                            await vm.executeScanReceive(vipleCode: parcel.vipleBarcode)
                        }
                    } label: {
                        Label("Valider réception", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(LoobyTakerPalette.amberPrimary))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                } else if parcel.isInStock {
                    if vm.isParticulierMode {
                        Button {
                            vm.prefilledAppointmentParcel = parcel
                            vm.isShowingAppointmentComposer = true
                        } label: {
                            Label("RDV", systemImage: "calendar.badge.plus")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(LoobyTakerPalette.proCobaltSoft))
                                .foregroundStyle(LoobyTakerPalette.proCobalt)
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        Task {
                            await vm.initiateHandoverFlow(scannedCode: parcel.vipleBarcode, explicitParcel: parcel)
                        }
                    } label: {
                        Label(
                            vm.isProMode ? "Remettre (Sans PIN)" : "Remettre (PIN)",
                            systemImage: vm.isProMode ? "bolt.checkmark.fill" : "key.fill"
                        )
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(LoobyTakerPalette.emerald))
                        .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .loobyTakerCard(padding: 15)
    }

    private func statusPill(for parcel: TakerParcel) -> some View {
        let color: Color = {
            if parcel.isIssueReported { return LoobyTakerPalette.danger }
            if parcel.isInStock { return LoobyTakerPalette.emerald }
            if parcel.isHandedOver { return LoobyTakerPalette.proCobalt }
            return LoobyTakerPalette.amberPrimary
        }()
        return Text(parcel.statusLabel)
            .font(.system(size: 11, weight: .black, design: .rounded))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(color.opacity(0.14)))
            .foregroundStyle(color)
    }

    private var emptyParcelState: some View {
        VStack(spacing: 12) {
            Image(systemName: "shippingbox")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(LoobyTakerPalette.amberPrimary)
            Text("Aucun colis dans cet onglet")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(LoobyTakerPalette.ink)
            Text("Vous pouvez prévoir l'arrivée d'un colis attendu ou scanner directement une 2e étiquette Viple Delivery (VD-…).")
                .font(.system(size: 12.5))
                .foregroundStyle(LoobyTakerPalette.inkSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .loobyTakerCard()
    }

    // MARK: - 4. Section Problèmes Signalés (`issues` + `issueParcels`)

    private var issuesDedicatedListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if vm.issues.isEmpty && vm.issueParcels.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(LoobyTakerPalette.emerald)
                    Text("Aucune anomalie en cours")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(LoobyTakerPalette.ink)
                    Text("Colis abîmé, 2e étiquette Viple Delivery illisible ou erreur UPS ? Utilisez « Signaler un problème » ci-dessus.")
                        .font(.system(size: 12.5))
                        .foregroundStyle(LoobyTakerPalette.inkSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 26)
                .loobyTakerCard()
            } else {
                ForEach(vm.issues) { issue in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label(issue.issueType, systemImage: "exclamationmark.triangle.fill")
                                .font(.system(size: 14.5, weight: .black, design: .rounded))
                                .foregroundStyle(LoobyTakerPalette.danger)
                            Spacer()
                            Text(issue.severity)
                                .font(.system(size: 10.5, weight: .black, design: .rounded))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(LoobyTakerPalette.coralSoft))
                                .foregroundStyle(LoobyTakerPalette.danger)
                        }

                        if !issue.vipleBarcode.isEmpty || !issue.carrierTrackingNumber.isEmpty {
                            Text("Étiquette : \(issue.vipleBarcode.isEmpty ? issue.carrierTrackingNumber : issue.vipleBarcode)")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(LoobyTakerPalette.amberDeep)
                        }

                        if !issue.description.isEmpty {
                            Text(issue.description)
                                .font(.system(size: 13))
                                .foregroundStyle(LoobyTakerPalette.inkSecondary)
                        }

                        HStack {
                            Text("Statut : \(issue.status)")
                                .font(.system(size: 11.5, weight: .bold))
                                .foregroundStyle(LoobyTakerPalette.inkSecondary)
                            Spacer()
                            if issue.refusedAtDoor {
                                Text("Refusé à la livraison")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundStyle(LoobyTakerPalette.danger)
                            }
                        }
                    }
                    .loobyTakerCard(padding: 14)
                }

                ForEach(vm.issueParcels) { p in
                    parcelCard(p)
                }
            }
        }
    }
}

// MARK: - Fiche Détail d'un Colis avec Actions Contextuelles Complètes

public struct ParcelDetailSheet: View {
    @EnvironmentObject private var vm: LoobyTakerViewModel
    @Environment(\.dismiss) private var dismiss

    public let parcel: TakerParcel

    public init(parcel: TakerParcel) {
        self.parcel = parcel
    }

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(parcel.statusLabel.uppercased())
                            .font(.system(size: 10.5, weight: .black, design: .rounded))
                            .foregroundStyle(.white.opacity(0.88))
                        Text(parcel.recipientName)
                            .font(.system(size: 23, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("2e Étiquette Viple Delivery : \(parcel.vipleBarcode)")
                            .font(.system(size: 13.5, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.95))
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LoobyTakerHeroBackground(isProStyle: vm.isProMode)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    )

                    VStack(alignment: .leading, spacing: 10) {
                        detailRow("Transporteur", parcel.carrier)
                        if !parcel.carrierTrackingNumber.isEmpty {
                            detailRow("Suivi transporteur (1re étiquette)", parcel.carrierTrackingNumber)
                        }
                        if !parcel.sourceApp.isEmpty {
                            detailRow("Origine commande", "\(parcel.sourceApp) \(parcel.orderReference)")
                        }
                        if !parcel.recipientPhone.isEmpty {
                            detailRow("Téléphone client", parcel.recipientPhone)
                        }
                        if !parcel.shelfLocation.isEmpty {
                            detailRow("Emplacement relais", parcel.shelfLocation)
                        }
                        if !parcel.expectedArrivalDate.isEmpty {
                            detailRow("Arrivée attendue", "\(parcel.expectedArrivalDate) \(parcel.expectedArrivalWindow)")
                        }
                        if !parcel.weightClass.isEmpty {
                            detailRow("Format / Poids", parcel.weightClass)
                        }
                        if !parcel.notes.isEmpty {
                            detailRow("Notes", parcel.notes)
                        }
                    }
                    .loobyTakerCard()

                    // Actions contextuelles
                    VStack(spacing: 10) {
                        if parcel.isExpected {
                            Button {
                                Task {
                                    await vm.executeScanReceive(vipleCode: parcel.vipleBarcode)
                                    dismiss()
                                }
                            } label: {
                                Label("Valider la réception en stock", systemImage: "shippingbox.and.arrow.backward.fill")
                                    .font(.system(size: 15, weight: .black, design: .rounded))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(LoobyTakerPalette.goldCoralHorizontal)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }

                        if !parcel.isHandedOver {
                            if vm.isParticulierMode {
                                Button {
                                    let p = parcel
                                    dismiss()
                                    Task { @MainActor in
                                        try? await Task.sleep(nanoseconds: 250_000_000)
                                        vm.prefilledAppointmentParcel = p
                                        vm.isShowingAppointmentComposer = true
                                    }
                                } label: {
                                    Label("Donner un RDV de retrait au client", systemImage: "calendar.badge.plus")
                                        .font(.system(size: 14.5, weight: .black, design: .rounded))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 13)
                                        .background(RoundedRectangle(cornerRadius: 14).fill(LoobyTakerPalette.proCobaltSoft))
                                        .foregroundStyle(LoobyTakerPalette.proCobalt)
                                }
                            }

                            if parcel.isInStock {
                                Button {
                                    let p = parcel
                                    dismiss()
                                    Task { @MainActor in
                                        try? await Task.sleep(nanoseconds: 250_000_000)
                                        await vm.initiateHandoverFlow(scannedCode: p.vipleBarcode, explicitParcel: p)
                                    }
                                } label: {
                                    Label(
                                        vm.isProMode
                                            ? "Remettre sans code PIN (Validation Pro)"
                                            : "Remettre avec Code PIN client (+1,00 €)",
                                        systemImage: vm.isProMode ? "bolt.checkmark.fill" : "key.fill"
                                    )
                                    .font(.system(size: 15, weight: .black, design: .rounded))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(RoundedRectangle(cornerRadius: 14).fill(LoobyTakerPalette.emerald))
                                    .foregroundStyle(.white)
                                }
                            }
                        }

                        Button(role: .destructive) {
                            let p = parcel
                            dismiss()
                            Task { @MainActor in
                                try? await Task.sleep(nanoseconds: 250_000_000)
                                vm.prefilledIssueParcel = p
                                vm.prefilledIssueBarcode = p.vipleBarcode
                                vm.isShowingReportIssueSheet = true
                            }
                        } label: {
                            Label("Signaler un problème sur ce colis", systemImage: "exclamationmark.triangle.fill")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(RoundedRectangle(cornerRadius: 14).fill(LoobyTakerPalette.danger.opacity(0.11)))
                                .foregroundStyle(LoobyTakerPalette.danger)
                        }
                    }
                }
                .padding(18)
            }
            .loobyTakerScreenBackground()
            .navigationTitle("Détail du colis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(LoobyTakerPalette.inkMuted)
            Spacer(minLength: 12)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(LoobyTakerPalette.ink)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Formulaire « Prévoir l'arrivée d'un colis » (`POST /taker/parcels/forecast`)

public struct ForecastParcelSheet: View {
    @EnvironmentObject private var vm: LoobyTakerViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var carrier: String = "Viple Delivery"
    @State private var vipleBarcode: String = ""
    @State private var carrierTrackingNumber: String = ""
    @State private var recipientName: String = ""
    @State private var expectedArrivalDate: String = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "fr_FR")
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: Date())
    }()
    @State private var expectedArrivalWindow: String = "14h00 – 18h00"
    @State private var notes: String = ""
    @State private var isSubmitting: Bool = false

    private let carriers = ["Viple Delivery", "UPS (avec 2e étiquette Viple Delivery)"]
    private let windows = ["09h00 – 12h30", "14h00 – 18h00", "17h30 – 20h30", "Toute la journée"]

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Enregistrez à l'avance un colis annoncé par un client ou un livreur Viple Delivery / UPS afin de préparer votre capacité de stockage.")
                        .font(.system(size: 13))
                        .foregroundStyle(LoobyTakerPalette.inkSecondary)

                    VStack(alignment: .leading, spacing: 12) {
                        fieldLabel("Transporteur annoncé")
                        Picker("Transporteur", selection: $carrier) {
                            ForEach(carriers, id: \.self) { c in
                                Text(c).tag(c)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 11).fill(LoobyTakerPalette.cardSubtle))

                        fieldLabel("Code 2e étiquette Viple Delivery (VD-…)")
                        TextField("Ex : VD-2026-90412 (généré auto si vide)", text: $vipleBarcode)
                            .textInputAutocapitalization(.characters)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .padding(11)
                            .background(RoundedRectangle(cornerRadius: 11).fill(LoobyTakerPalette.cardSubtle))

                        fieldLabel("N° suivi UPS éventuel (1Z… — informatif)")
                        TextField("Ex : 1Z999AA10123456784 (optionnel)", text: $carrierTrackingNumber)
                            .textInputAutocapitalization(.characters)
                            .font(.system(size: 13.5, design: .monospaced))
                            .padding(11)
                            .background(RoundedRectangle(cornerRadius: 11).fill(LoobyTakerPalette.cardSubtle))

                        fieldLabel("Nom du client destinataire")
                        TextField("Ex : Camille Laurent", text: $recipientName)
                            .padding(11)
                            .background(RoundedRectangle(cornerRadius: 11).fill(LoobyTakerPalette.cardSubtle))

                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 5) {
                                fieldLabel("Date attendue")
                                TextField("2026-11-25", text: $expectedArrivalDate)
                                    .padding(11)
                                    .background(RoundedRectangle(cornerRadius: 11).fill(LoobyTakerPalette.cardSubtle))
                            }
                            VStack(alignment: .leading, spacing: 5) {
                                fieldLabel("Créneau")
                                Picker("Créneau", selection: $expectedArrivalWindow) {
                                    ForEach(windows, id: \.self) { w in
                                        Text(w).tag(w)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding(6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 11).fill(LoobyTakerPalette.cardSubtle))
                            }
                        }

                        fieldLabel("Consignes ou notes")
                        TextField("Ex : Colis volumineux, appel avant passage…", text: $notes, axis: .vertical)
                            .lineLimit(2...4)
                            .padding(11)
                            .background(RoundedRectangle(cornerRadius: 11).fill(LoobyTakerPalette.cardSubtle))
                    }
                    .loobyTakerCard()

                    Button {
                        Task {
                            isSubmitting = true
                            let finalVd = vipleBarcode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? "VD-2026-\(Int.random(in: 10000...99999))"
                                : vipleBarcode.trimmingCharacters(in: .whitespacesAndNewlines)
                            let ok = await vm.submitParcelForecast(
                                vipleBarcode: finalVd,
                                carrier: carrier.contains("UPS") ? "UPS" : "Viple Delivery",
                                carrierTrackingNumber: carrierTrackingNumber,
                                recipientName: recipientName.isEmpty ? "Client Livria" : recipientName,
                                expectedArrivalDate: expectedArrivalDate,
                                expectedArrivalWindow: expectedArrivalWindow,
                                notes: notes
                            )
                            isSubmitting = false
                            if ok {
                                dismiss()
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if isSubmitting {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "calendar.badge.plus")
                            }
                            Text("Enregistrer cette prévision d'arrivée")
                                .font(.system(size: 15, weight: .black, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(LoobyTakerPalette.goldCoralHorizontal)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    }
                    .disabled(isSubmitting)
                }
                .padding(18)
            }
            .loobyTakerScreenBackground()
            .navigationTitle("Prévoir un colis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") { dismiss() }
                }
            }
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(LoobyTakerPalette.inkSecondary)
    }
}

// MARK: - Formulaire « Signaler un problème de réception » (`POST /taker/parcels/report-issue`)

public struct ReportReceptionIssueSheet: View {
    @EnvironmentObject private var vm: LoobyTakerViewModel
    @Environment(\.dismiss) private var dismiss

    public let initialParcel: TakerParcel?
    public let initialBarcode: String

    @State private var vipleBarcode: String = ""
    @State private var carrierTrackingNumber: String = ""
    @State private var issueType: String = "2e étiquette Viple Delivery illisible / absente"
    @State private var severity: String = "Moyenne"
    @State private var refusedAtDoor: Bool = false
    @State private var descriptionText: String = ""
    @State private var isSubmitting: Bool = false

    private let issueTypes = [
        "2e étiquette Viple Delivery illisible / absente",
        "Colis endommagé / carton ouvert",
        "Erreur de point relais UPS (mauvaise adresse)",
        "Refusé par manque de place au relais",
        "Destinataire inconnu / anomalie d'étiquetage"
    ]

    private let severities = ["Faible", "Moyenne", "Haute", "Critique"]

    public init(initialParcel: TakerParcel?, initialBarcode: String) {
        self.initialParcel = initialParcel
        self.initialBarcode = initialBarcode
    }

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Signalez immédiatement toute anomalie constatée lors du passage du livreur Viple Delivery ou UPS afin de protéger votre responsabilité de Taker.")
                        .font(.system(size: 13))
                        .foregroundStyle(LoobyTakerPalette.inkSecondary)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Nature du problème")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                        Picker("Type d'incident", selection: $issueType) {
                            ForEach(issueTypes, id: \.self) { t in
                                Text(t).tag(t)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 11).fill(LoobyTakerPalette.cardSubtle))

                        Text("Gravité")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                        Picker("Gravité", selection: $severity) {
                            ForEach(severities, id: \.self) { s in
                                Text(s).tag(s)
                            }
                        }
                        .pickerStyle(.segmented)

                        Text("Code 2e étiquette Viple Delivery (VD-…) si visible")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                        TextField("Ex : VD-2026-84920", text: $vipleBarcode)
                            .textInputAutocapitalization(.characters)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .padding(11)
                            .background(RoundedRectangle(cornerRadius: 11).fill(LoobyTakerPalette.cardSubtle))

                        Text("N° suivi transporteur UPS (1Z…) si présent")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                        TextField("Ex : 1Z999AA10123456784", text: $carrierTrackingNumber)
                            .textInputAutocapitalization(.characters)
                            .font(.system(size: 13.5, design: .monospaced))
                            .padding(11)
                            .background(RoundedRectangle(cornerRadius: 11).fill(LoobyTakerPalette.cardSubtle))

                        Toggle(isOn: $refusedAtDoor) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Colis refusé directement auprès du livreur")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                Text("Activez si vous n'avez pas pris le colis en charge.")
                                    .font(.system(size: 11.5))
                                    .foregroundStyle(LoobyTakerPalette.inkSecondary)
                            }
                        }
                        .tint(LoobyTakerPalette.danger)

                        Text("Description & constat précis")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                        TextField("Précisez l'état du carton, les réserves émises au chauffeur…", text: $descriptionText, axis: .vertical)
                            .lineLimit(3...6)
                            .padding(11)
                            .background(RoundedRectangle(cornerRadius: 11).fill(LoobyTakerPalette.cardSubtle))
                    }
                    .loobyTakerCard()

                    Button {
                        Task {
                            isSubmitting = true
                            let ok = await vm.submitReceptionIssue(
                                parcelId: initialParcel?.id,
                                vipleBarcode: vipleBarcode,
                                carrierTrackingNumber: carrierTrackingNumber,
                                issueType: issueType,
                                severity: severity,
                                description: descriptionText.isEmpty ? issueType : descriptionText,
                                refusedAtDoor: refusedAtDoor
                            )
                            isSubmitting = false
                            if ok {
                                dismiss()
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if isSubmitting {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "exclamationmark.bubble.fill")
                            }
                            Text("Transmettre le signalement à Viple")
                                .font(.system(size: 15, weight: .black, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(LoobyTakerPalette.danger))
                        .foregroundStyle(.white)
                    }
                    .disabled(isSubmitting)
                }
                .padding(18)
            }
            .loobyTakerScreenBackground()
            .navigationTitle("Signaler une anomalie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") { dismiss() }
                }
            }
            .onAppear {
                if let p = initialParcel {
                    vipleBarcode = p.vipleBarcode
                    carrierTrackingNumber = p.carrierTrackingNumber
                } else if !initialBarcode.isEmpty {
                    if LoobyTakerViewModel.isUpsTrackingBarcode(initialBarcode) {
                        carrierTrackingNumber = initialBarcode
                    } else {
                        vipleBarcode = initialBarcode
                    }
                }
            }
        }
    }
}
