import SwiftUI

// MARK: - Onglet 1 : Tableau de Bord Adaptatif Particulier vs Pro (`DashboardView.swift` • Swift 6)

public struct DashboardView: View {
    @EnvironmentObject private var vm: LoobyTakerViewModel

    @State private var quickClosureReasonDraft: String = ""
    @State private var isUpdatingQuickClosure: Bool = false

    public init() {}

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                relayIdentityHeroCard

                animatedMetricsGrid

                quickActionsSection

                if vm.isProMode {
                    proShopQuickControlCard
                } else {
                    particulierUpcomingAppointmentsCard
                }

                recentActivityInStockPreview
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 36)
        }
        .loobyTakerScreenBackground()
        .navigationTitle("Looby Taker")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                HStack(spacing: 7) {
                    LoobyTakerBrandMedallion(size: 28, showGlow: false)
                    if vm.relays.count > 1 {
                        Menu {
                            ForEach(vm.relays) { r in
                                Button {
                                    Task { await vm.selectRelay(r) }
                                } label: {
                                    Label(
                                        "\(r.name) (\(r.relayMode))",
                                        systemImage: r.id == vm.activeRelay?.id ? "checkmark.circle.fill" : "mappin.circle"
                                    )
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text("Changer de relais")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundStyle(LoobyTakerPalette.amberPrimary)
                        }
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 10) {
                    Button {
                        vm.isShowingVisualScanGuide = true
                    } label: {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(LoobyTakerPalette.amberPrimary)
                    }

                    Button {
                        Task { await vm.refreshBootstrap() }
                    } label: {
                        if vm.isBootstrapping {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .bold))
                        }
                    }
                }
            }
        }
        .refreshable {
            await vm.refreshBootstrap()
        }
        .onAppear {
            if quickClosureReasonDraft.isEmpty {
                quickClosureReasonDraft = vm.activeRelay?.closureReason ?? ""
            }
        }
    }

    // MARK: - 1. Carte d'Identité du Point Relais (Particulier 1 €/colis vs Professionnel)

    private var relayIdentityHeroCard: some View {
        let relay = vm.activeRelay ?? TakerRelayPoint()
        return VStack(alignment: .leading, spacing: 14) {
            // Ligne supérieure : Badge mode + Statut temps réel
            HStack(spacing: 8) {
                HStack(spacing: 5) {
                    Image(systemName: vm.isProMode ? "storefront.fill" : "eurosign.circle.fill")
                        .font(.system(size: 11.5, weight: .bold))
                    Text(
                        vm.isProMode
                            ? "RELAIS PROFESSIONNEL"
                            : String(format: "PARTICULIER • %.2f €/COLIS", relay.commissionPerParcel).replacingOccurrences(of: ".", with: ",")
                    )
                    .font(.system(size: 10.5, weight: .black, design: .rounded))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.white))
                .foregroundStyle(vm.isProMode ? Color(red: 0.12, green: 0.28, blue: 0.64) : Color(red: 0.72, green: 0.38, blue: 0.04))

                Spacer(minLength: 4)

                HStack(spacing: 5) {
                    Image(systemName: relay.liveStatusIcon)
                        .font(.system(size: 11, weight: .bold))
                    Text(relay.liveStatusTitle)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule().fill(
                        relay.isCurrentlyClosedOverride
                            ? Color.red.opacity(0.88)
                            : (relay.vacationMode.enabled ? Color.orange.opacity(0.88) : Color.black.opacity(0.24))
                    )
                )
                .foregroundStyle(.white)
            }

            // Nom du relais & adresse
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(relay.name)
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("id-\(relay.id)")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.white.opacity(0.18)))
                        .foregroundStyle(.white)
                }

                Label(relay.fullAddress, systemImage: "mappin.and.ellipse")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.90))

                Label(relay.openingHoursSummary, systemImage: "clock.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.85))
            }

            if vm.isPreviewingAlternateMode {
                HStack(spacing: 6) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text("Aperçu de l'interface \(vm.effectiveRelayMode) activé")
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 9).fill(Color.white.opacity(0.20)))
                .foregroundStyle(.white)
            }

            // Raccourcis rapides : Basculer l'aperçu Particulier / Pro OU Modifier mon relais
            HStack(spacing: 8) {
                Button {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                        vm.togglePreviewRelayMode()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.left.arrow.right.circle.fill")
                            .font(.system(size: 13, weight: .bold))
                        Text("Aperçu \(vm.isProMode ? "Particulier" : "Pro")")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white.opacity(0.20)))
                    .foregroundStyle(.white)
                }

                Button {
                    vm.isShowingRelayEditSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 13, weight: .bold))
                        Text("Modifier mon relais")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white))
                    .foregroundStyle(vm.isProMode ? Color(red: 0.12, green: 0.28, blue: 0.64) : Color(red: 0.72, green: 0.38, blue: 0.04))
                }
            }
        }
        .padding(18)
        .background(
            LoobyTakerHeroBackground(isProStyle: vm.isProMode)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        )
        .shadow(color: LoobyTakerPalette.amberPrimary.opacity(0.20), radius: 14, x: 0, y: 6)
    }

    // MARK: - 2. Compteurs Animés (Adaptés Particulier vs Pro)

    private var animatedMetricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            metricTile(
                title: "Colis en approche",
                valueText: "\(vm.computedExpectedCount)",
                subtitle: "Viple Delivery & UPS",
                icon: "truck.box.fill",
                tint: LoobyTakerPalette.amberPrimary
            ) {
                vm.parcelsSegment = .expected
                vm.selectedTab = .parcels
            }

            metricTile(
                title: "En stock à remettre",
                valueText: "\(vm.computedInStockCount)",
                subtitle: vm.isProMode ? "Remise directe sans PIN" : "Retrait avec Code PIN",
                icon: "shippingbox.fill",
                tint: LoobyTakerPalette.emerald
            ) {
                vm.parcelsSegment = .inStock
                vm.selectedTab = .parcels
            }

            if vm.isParticulierMode {
                metricTile(
                    title: "RDV clients actifs",
                    valueText: "\(vm.computedTodayAppointmentsCount)",
                    subtitle: "Créneaux programmés",
                    icon: "calendar.badge.clock",
                    tint: LoobyTakerPalette.proCobalt
                ) {
                    vm.selectedTab = .schedule
                }

                metricTile(
                    title: "Gains cumulés",
                    valueText: String(format: "%.2f €", vm.computedTotalEarnedEur).replacingOccurrences(of: ".", with: ","),
                    subtitle: "1,00 € par colis remis",
                    icon: "eurosign.circle.fill",
                    tint: LoobyTakerPalette.coralGlow
                ) {
                    vm.parcelsSegment = .handedOver
                    vm.selectedTab = .parcels
                }
            } else {
                metricTile(
                    title: "Signalements",
                    valueText: "\(vm.computedOpenIssuesCount)",
                    subtitle: "Anomalies réception",
                    icon: "exclamationmark.triangle.fill",
                    tint: LoobyTakerPalette.coralGlow
                ) {
                    vm.parcelsSegment = .issues
                    vm.selectedTab = .parcels
                }

                metricTile(
                    title: "Colis remis",
                    valueText: "\(max(vm.activeRelay?.stats.handedOverTotalCount ?? 0, vm.handedOverParcels.count))",
                    subtitle: "Flux comptoir validé",
                    icon: "checkmark.seal.fill",
                    tint: LoobyTakerPalette.proCobalt
                ) {
                    vm.parcelsSegment = .handedOver
                    vm.selectedTab = .parcels
                }
            }
        }
    }

    private func metricTile(
        title: String,
        valueText: String,
        subtitle: String,
        icon: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(tint.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(tint)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(LoobyTakerPalette.inkMuted)
                }

                Text(valueText)
                    .font(.system(size: 25, weight: .black, design: .rounded))
                    .foregroundStyle(LoobyTakerPalette.ink)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: valueText)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(LoobyTakerPalette.ink)
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(LoobyTakerPalette.inkSecondary)
                        .lineLimit(1)
                }
            }
            .loobyTakerCard(padding: 14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 3. Actions Rapides en 1 Tap

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text("Actions rapides en 1 tap")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(LoobyTakerPalette.ink)

            VStack(spacing: 10) {
                quickActionRow(
                    title: "Scanner une réception livreur",
                    subtitle: "Viple Delivery ou UPS — Scannez la 2e étiquette VD-…",
                    icon: "barcode.viewfinder",
                    tint: LoobyTakerPalette.amberPrimary
                ) {
                    vm.scannerMode = .receive
                    vm.selectedTab = .scanner
                }

                quickActionRow(
                    title: vm.isProMode
                        ? "Remettre un colis (Remise directe sans PIN)"
                        : "Remettre un colis (Échange Code PIN client)",
                    subtitle: vm.isProMode
                        ? "Validation immédiate au comptoir sans aucun code PIN"
                        : "Validez le Code PIN à 6 chiffres du client (+1,00 €)",
                    icon: vm.isProMode ? "bolt.checkmark.fill" : "lock.shield.fill",
                    tint: LoobyTakerPalette.emerald
                ) {
                    vm.scannerMode = .handover
                    vm.selectedTab = .scanner
                }

                HStack(spacing: 10) {
                    compactActionCard(
                        title: "Prévoir l'arrivée d'un colis",
                        icon: "calendar.badge.plus",
                        tint: LoobyTakerPalette.proCobalt
                    ) {
                        vm.isShowingForecastSheet = true
                    }

                    compactActionCard(
                        title: "Quelle étiquette scanner ? (UPS / VD)",
                        icon: "doc.viewfinder.fill",
                        tint: LoobyTakerPalette.coralGlow
                    ) {
                        vm.isShowingVisualScanGuide = true
                    }
                }
            }
        }
    }

    private func quickActionRow(
        title: String,
        subtitle: String,
        icon: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 13) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(tint.opacity(0.15))
                        .frame(width: 46, height: 46)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .bold))
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
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(LoobyTakerPalette.inkMuted)
            }
            .loobyTakerCard(padding: 14)
        }
        .buttonStyle(.plain)
    }

    private func compactActionCard(
        title: String,
        icon: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(tint)
                    .frame(width: 36, height: 36)
                    .background(RoundedRectangle(cornerRadius: 10).fill(tint.opacity(0.15)))

                Text(title)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(LoobyTakerPalette.ink)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .loobyTakerCard(padding: 14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 4A. Section Particulier : Prochains RDV Clients

    private var particulierUpcomingAppointmentsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Prochains RDV clients", systemImage: "calendar.badge.clock")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(LoobyTakerPalette.ink)
                Spacer()
                Button {
                    vm.prefilledAppointmentParcel = vm.inStockParcels.first
                    vm.isShowingAppointmentComposer = true
                } label: {
                    Label("Donner un RDV", systemImage: "plus.circle.fill")
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .foregroundStyle(LoobyTakerPalette.amberPrimary)
                }
            }

            if vm.activeAppointments.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.system(size: 22))
                        .foregroundStyle(LoobyTakerPalette.amberPrimary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Aucun RDV programmé pour l'instant")
                            .font(.system(size: 13.5, weight: .bold, design: .rounded))
                            .foregroundStyle(LoobyTakerPalette.ink)
                        Text("Proposez un créneau à vos clients dès qu'un colis est scanné en stock.")
                            .font(.system(size: 12))
                            .foregroundStyle(LoobyTakerPalette.inkSecondary)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 14).fill(LoobyTakerPalette.cardSubtle))
            } else {
                ForEach(vm.activeAppointments.prefix(3)) { appt in
                    HStack(spacing: 12) {
                        VStack(spacing: 2) {
                            Text(appt.startTime)
                                .font(.system(size: 13, weight: .black, design: .monospaced))
                                .foregroundStyle(LoobyTakerPalette.amberDeep)
                            Text(appt.slotDate)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(LoobyTakerPalette.inkMuted)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 7)
                        .background(RoundedRectangle(cornerRadius: 10).fill(LoobyTakerPalette.amberSoft))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(appt.customerName)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(LoobyTakerPalette.ink)
                            Text("\(appt.vipleBarcode) • \(appt.status)")
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundStyle(LoobyTakerPalette.inkSecondary)
                        }
                        Spacer()

                        if appt.status != "Confirmé" {
                            Button("Confirmer") {
                                Task { await vm.changeAppointmentStatus(appointment: appt, newStatus: "Confirmé") }
                            }
                            .font(.system(size: 11.5, weight: .bold, design: .rounded))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(LoobyTakerPalette.emeraldSoft))
                            .foregroundStyle(LoobyTakerPalette.emerald)
                        } else {
                            Button("Remettre") {
                                Task {
                                    let matched = vm.parcels.first { $0.id == appt.parcelId || $0.vipleBarcode == appt.vipleBarcode }
                                    await vm.initiateHandoverFlow(scannedCode: appt.vipleBarcode, explicitParcel: matched)
                                }
                            }
                            .font(.system(size: 11.5, weight: .bold, design: .rounded))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(LoobyTakerPalette.amberSoft))
                            .foregroundStyle(LoobyTakerPalette.amberDeep)
                        }
                    }
                    .padding(11)
                    .background(RoundedRectangle(cornerRadius: 14).fill(LoobyTakerPalette.cardSubtle))
                }
            }
        }
        .loobyTakerCard()
    }

    // MARK: - 4B. Section Pro : Contrôle Rapide « Boutique Ouverte / Dire que nous sommes fermés »

    private var proShopQuickControlCard: some View {
        let relay = vm.activeRelay ?? TakerRelayPoint(relayMode: "Pro")
        let isClosed = relay.isCurrentlyClosedOverride

        return VStack(alignment: .leading, spacing: 13) {
            HStack {
                Label(
                    isClosed ? "Fermeture exceptionnelle active" : "Boutique ouverte aux retraits",
                    systemImage: isClosed ? "door.left.hand.closed" : "door.left.hand.open"
                )
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(isClosed ? LoobyTakerPalette.danger : LoobyTakerPalette.emerald)

                Spacer()

                Text("CONTRÔLE PRO")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(LoobyTakerPalette.proCobaltSoft))
                    .foregroundStyle(LoobyTakerPalette.proCobalt)
            }

            Text("Besoin de fermer exceptionnellement votre boutique pendant quelques heures ? Informez immédiatement les acheteurs Livria & livreurs Viple Delivery en 1 bouton.")
                .font(.system(size: 12.5))
                .foregroundStyle(LoobyTakerPalette.inkSecondary)

            TextField("Motif affiché aux clients (ex: Inventaire jusqu'à 15h00)", text: $quickClosureReasonDraft)
                .font(.system(size: 13))
                .padding(11)
                .background(RoundedRectangle(cornerRadius: 11).fill(LoobyTakerPalette.cardSubtle))
                .overlay(RoundedRectangle(cornerRadius: 11).stroke(LoobyTakerPalette.border, lineWidth: 1))

            Button {
                Task {
                    isUpdatingQuickClosure = true
                    let targetClosed = !isClosed
                    let reason = targetClosed
                        ? (quickClosureReasonDraft.trimmingCharacters(in: .whitespaces).isEmpty ? "Fermeture exceptionnelle momentanée" : quickClosureReasonDraft)
                        : ""
                    _ = await vm.saveRelayHoursAndClosure(
                        openingHoursSummary: relay.openingHoursSummary,
                        isCurrentlyClosedOverride: targetClosed,
                        closureReason: reason,
                        weeklySchedule: relay.weeklySchedule,
                        availabilities: relay.availabilities
                    )
                    isUpdatingQuickClosure = false
                }
            } label: {
                HStack(spacing: 8) {
                    if isUpdatingQuickClosure {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: isClosed ? "checkmark.circle.fill" : "hand.raised.fill")
                    }
                    Text(isClosed ? "Rouvrir la boutique maintenant" : "Dire que nous sommes fermés")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(isClosed ? LoobyTakerPalette.emerald : LoobyTakerPalette.danger)
                )
                .foregroundStyle(.white)
            }
            .disabled(isUpdatingQuickClosure)
        }
        .loobyTakerCard()
    }

    // MARK: - 5. Aperçu Rapide des Colis en Stock Prêts à Remettre

    private var recentActivityInStockPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Colis prêts à remettre (\(vm.inStockParcels.count))")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(LoobyTakerPalette.ink)
                Spacer()
                Button("Tout voir") {
                    vm.parcelsSegment = .inStock
                    vm.selectedTab = .parcels
                }
                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                .foregroundStyle(LoobyTakerPalette.amberPrimary)
            }

            if vm.inStockParcels.isEmpty {
                Text("Aucun colis en attente de retrait. Scannez une 2e étiquette Viple Delivery (VD-…) dès l'arrivée d'un livreur !")
                    .font(.system(size: 12.5))
                    .foregroundStyle(LoobyTakerPalette.inkSecondary)
                    .padding(.vertical, 6)
            } else {
                ForEach(vm.inStockParcels.prefix(3)) { parcel in
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .fill(LoobyTakerPalette.emeraldSoft)
                                .frame(width: 40, height: 40)
                            Image(systemName: "shippingbox.fill")
                                .foregroundStyle(LoobyTakerPalette.emerald)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(parcel.recipientName)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(LoobyTakerPalette.ink)
                            Text("\(parcel.vipleBarcode)\(parcel.shelfLocation.isEmpty ? "" : " • \(parcel.shelfLocation)")")
                                .font(.system(size: 11.5, weight: .semibold, design: .monospaced))
                                .foregroundStyle(LoobyTakerPalette.inkSecondary)
                        }

                        Spacer()

                        Button {
                            Task {
                                await vm.initiateHandoverFlow(scannedCode: parcel.vipleBarcode, explicitParcel: parcel)
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: vm.isProMode ? "checkmark.circle.fill" : "key.fill")
                                    .font(.system(size: 11, weight: .bold))
                                Text(vm.isProMode ? "Remettre" : "PIN Client")
                                    .font(.system(size: 11.5, weight: .black, design: .rounded))
                            }
                            .padding(.horizontal, 11)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(LoobyTakerPalette.goldCoralHorizontal))
                            .foregroundStyle(.white)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 13).fill(LoobyTakerPalette.cardSubtle))
                }
            }
        }
        .loobyTakerCard()
    }
}
