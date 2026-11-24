import SwiftUI

// MARK: - Architecture Principale Adaptative « Looby Taker » (Relais Particulier / Pro vs Espace Candidat • Swift 6)

public struct LoobyTakerMainView: View {
    @EnvironmentObject private var vm: LoobyTakerViewModel

    public init() {}

    public var body: some View {
        Group {
            if vm.isBootstrapping && !vm.hasAssignedRelay && vm.applications.isEmpty {
                initialLoadingView
            } else if vm.hasAssignedRelay, vm.activeRelay != nil {
                activeRelayTabShell
            } else {
                LoobyTakerCandidateHomeView()
            }
        }
        // Modales globales accessibles depuis tous les onglets
        .sheet(isPresented: $vm.isShowingVisualScanGuide) {
            NavigationStack {
                ScanningVisualGuideView(showsCloseButton: true)
            }
            .environmentObject(vm)
        }
        .sheet(isPresented: $vm.isShowingForecastSheet) {
            ForecastParcelSheet()
                .environmentObject(vm)
        }
        .sheet(isPresented: $vm.isShowingReportIssueSheet) {
            ReportReceptionIssueSheet(
                initialParcel: vm.prefilledIssueParcel,
                initialBarcode: vm.prefilledIssueBarcode
            )
            .environmentObject(vm)
        }
        .sheet(isPresented: $vm.isShowingAppointmentComposer) {
            AppointmentComposerSheet(initialParcel: vm.prefilledAppointmentParcel)
                .environmentObject(vm)
        }
        .sheet(isPresented: $vm.isShowingRelayEditSheet) {
            RelayInfoEditorSheet()
                .environmentObject(vm)
        }
        .sheet(isPresented: $vm.isShowingApplicationSheet) {
            NavigationStack {
                TakerApplicationAndTrackingView(showsCloseButton: true)
            }
            .environmentObject(vm)
        }
        .sheet(item: $vm.upsPedagogicalWarning) { warning in
            UpsPedagogicalAlertSheet(warning: warning)
                .environmentObject(vm)
        }
        .sheet(item: $vm.pendingHandoverParcelForPin) { parcel in
            HandoverPinPadSheet(
                parcel: parcel,
                scannedCode: vm.pendingHandoverScannedCode
            )
            .environmentObject(vm)
        }
    }

    // MARK: - 1. Barre des 5 Onglets Adaptatifs (Particulier vs Pro)

    private var activeRelayTabShell: some View {
        TabView(selection: $vm.selectedTab) {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("Accueil", systemImage: "rectangle.grid.2x2.fill")
            }
            .tag(LoobyTakerTab.dashboard)

            NavigationStack {
                ParcelScannerView()
            }
            .tabItem {
                Label("Scanner", systemImage: "barcode.viewfinder")
            }
            .tag(LoobyTakerTab.scanner)

            NavigationStack {
                ParcelsHubView()
            }
            .tabItem {
                Label("Colis", systemImage: "shippingbox.fill")
            }
            .badge(vm.computedInStockCount > 0 ? vm.computedInStockCount : 0)
            .tag(LoobyTakerTab.parcels)

            NavigationStack {
                ScheduleAndAvailabilityView()
            }
            .tabItem {
                Label(
                    vm.isProMode ? "Horaires" : "RDV & Dispos",
                    systemImage: vm.isProMode ? "clock.badge.checkmark.fill" : "calendar.badge.clock"
                )
            }
            .tag(LoobyTakerTab.schedule)

            NavigationStack {
                RelayProfileAndHelpView()
            }
            .tabItem {
                Label("Mon Relais", systemImage: vm.isProMode ? "storefront.fill" : "house.fill")
            }
            .tag(LoobyTakerTab.profile)
        }
    }

    private var initialLoadingView: some View {
        VStack(spacing: 16) {
            LoobyTakerBrandMedallion(size: 74, showGlow: true)
            ProgressView()
                .tint(LoobyTakerPalette.amberPrimary)
            Text("Chargement de votre espace Looby Taker…")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(LoobyTakerPalette.inkSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .loobyTakerScreenBackground()
    }
}

// MARK: - 2. Espace Dédié Candidat Looby Taker (`hasAssignedRelay == false`)

public struct LoobyTakerCandidateHomeView: View {
    @EnvironmentObject private var vm: LoobyTakerViewModel
    @State private var showingConnectedDevices = false
    @State private var showingSignOutAlert = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    candidateHeroBanner

                    if !vm.applications.isEmpty {
                        liveApplicationsSection
                    }

                    applyCallToActionCard

                    scanGuidePreviewCard

                    candidateProfileAndDevicesCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
            .loobyTakerScreenBackground()
            .navigationTitle("Espace Candidat Taker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
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
            .refreshable {
                await vm.refreshBootstrap()
            }
            .navigationDestination(isPresented: $showingConnectedDevices) {
                LoobyTakerConnectedDevicesView()
            }
            .alert("Se déconnecter de Looby Taker ?", isPresented: $showingSignOutAlert) {
                Button("Annuler", role: .cancel) {}
                Button("Se déconnecter", role: .destructive) {
                    Task { await vm.signOutCleanly() }
                }
            } message: {
                Text("Vos notifications locales seront purgées et cet appareil ne recevra plus d'alertes pour ce compte.")
            }
        }
    }

    private var candidateHeroBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                LoobyTakerBrandMedallion(size: 56, showGlow: false)
                VStack(alignment: .leading, spacing: 3) {
                    Text("BIENVENUE SUR LOOBY TAKER")
                        .font(.system(size: 10.5, weight: .black, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.88))
                    Text("Bonjour \(vm.currentUser?.displayName ?? "Membre Viple")")
                        .font(.system(size: 21, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text(vm.currentUser?.email ?? "")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.86))
                }
                Spacer(minLength: 0)
            }

            Text("Aucun Point Relais actif n'est encore rattaché à votre compte. Demandez à devenir Looby Taker Particulier (1,00 €/colis à domicile) ou Professionnel (Commerce / Boutique) et suivez votre validation en direct !")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.94))

            HStack(spacing: 10) {
                Button {
                    vm.isShowingApplicationSheet = true
                } label: {
                    Label("Demander à devenir Taker", systemImage: "paperplane.fill")
                        .font(.system(size: 13.5, weight: .black, design: .rounded))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 11)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(Color.white))
                        .foregroundStyle(Color(red: 0.72, green: 0.38, blue: 0.04))
                }

                Button {
                    vm.isShowingVisualScanGuide = true
                } label: {
                    Label("Guide Scan", systemImage: "barcode.viewfinder")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 11)
                        .background(RoundedRectangle(cornerRadius: 13, style: .continuous).fill(Color.white.opacity(0.20)))
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

    private var liveApplicationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Suivi en direct de ma demande d'inscription", systemImage: "chart.bar.doc.horizontal.fill")
                    .font(.system(size: 15.5, weight: .black, design: .rounded))
                    .foregroundStyle(LoobyTakerPalette.ink)
                Spacer()
            }

            ForEach(vm.applications) { app in
                TakerApplicationTrackerCard(application: app)
            }
        }
    }

    private var applyCallToActionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(LoobyTakerPalette.amberPrimary)
                Text("Demander à devenir Looby Taker (Particulier ou Pro)")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(LoobyTakerPalette.ink)
            }

            Text("Choisissez entre le statut Particulier à domicile (1,00 € par colis remis avec code PIN client) ou Professionnel (remise directe au comptoir sans code PIN et horaires boutique).")
                .font(.system(size: 13))
                .foregroundStyle(LoobyTakerPalette.inkSecondary)

            Button {
                vm.isShowingApplicationSheet = true
            } label: {
                HStack {
                    Image(systemName: "doc.badge.plus")
                    Text(vm.applications.isEmpty ? "Ouvrir le formulaire de candidature" : "Déposer ou consulter mes demandes")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .padding(14)
                .background(LoobyTakerPalette.goldCoralHorizontal)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .loobyTakerCard()
    }

    private var scanGuidePreviewCard: some View {
        Button {
            vm.isShowingVisualScanGuide = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LoobyTakerPalette.emeraldSoft)
                        .frame(width: 50, height: 50)
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(LoobyTakerPalette.emerald)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Guide : comment fonctionne le scan de la 2e étiquette Viple Delivery ?")
                        .font(.system(size: 14.5, weight: .black, design: .rounded))
                        .foregroundStyle(LoobyTakerPalette.ink)
                        .multilineTextAlignment(.leading)
                    Text("Découvrez la différence entre l'étiquette 1 UPS (1Z…) et la 2e étiquette Viple Delivery (VD-…).")
                        .font(.system(size: 12))
                        .foregroundStyle(LoobyTakerPalette.inkSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(LoobyTakerPalette.inkMuted)
            }
            .loobyTakerCard()
        }
        .buttonStyle(.plain)
    }

    private var candidateProfileAndDevicesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mon Compte Viple Live ID & Sécurité")
                .font(.system(size: 15.5, weight: .black, design: .rounded))
                .foregroundStyle(LoobyTakerPalette.ink)

            Button {
                showingConnectedDevices = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "laptopcomputer.and.iphone")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(LoobyTakerPalette.proCobalt)
                        .frame(width: 34, height: 34)
                        .background(RoundedRectangle(cornerRadius: 10).fill(LoobyTakerPalette.proCobaltSoft))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Gestionnaire d'appareils connectés")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(LoobyTakerPalette.ink)
                        Text("\(LoobyTakerAPIClient.shared.resolvedHardwareModelName) • \(LoobyTakerAPIClient.shared.resolvedOsVersion)")
                            .font(.system(size: 11.5))
                            .foregroundStyle(LoobyTakerPalette.inkSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(LoobyTakerPalette.inkMuted)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 14).fill(LoobyTakerPalette.cardSubtle))
            }
            .buttonStyle(.plain)

            // Sélecteur Mode Clair / Sombre
            Picker("Apparence", selection: $vm.appearanceMode) {
                ForEach(LoobyTakerAppearanceMode.allCases) { m in
                    Text(m.labelFr).tag(m)
                }
            }
            .pickerStyle(.segmented)

            Button(role: .destructive) {
                showingSignOutAlert = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Se déconnecter proprement")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 13).fill(LoobyTakerPalette.danger.opacity(0.12)))
                .foregroundStyle(LoobyTakerPalette.danger)
            }
        }
        .loobyTakerCard()
    }
}
