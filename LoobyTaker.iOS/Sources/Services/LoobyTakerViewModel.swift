import Foundation
import SwiftUI

// MARK: - Onglets & Modes de Scan « Looby Taker »

public enum LoobyTakerTab: String, CaseIterable, Identifiable, Sendable {
    case dashboard
    case scanner
    case parcels
    case schedule
    case profile

    public var id: String { rawValue }
}

public enum TakerScannerOperationMode: String, CaseIterable, Identifiable, Sendable {
    case receive = "receive"
    case handover = "handover"
    case reportIssue = "report_issue"

    public var id: String { rawValue }

    public var titleFr: String {
        switch self {
        case .receive: return "Réceptionner"
        case .handover: return "Remettre au client"
        case .reportIssue: return "Signaler anomalie"
        }
    }

    public var subtitleFr: String {
        switch self {
        case .receive:
            return "Livreur Viple Delivery ou UPS — Scannez la 2e étiquette VD-…"
        case .handover:
            return "Scannez le colis en stock pour valider la remise au destinataire"
        case .reportIssue:
            return "Scannez l'étiquette pour pré-remplir la fiche d'incident"
        }
    }

    public var iconName: String {
        switch self {
        case .receive: return "shippingbox.and.arrow.backward.fill"
        case .handover: return "checkmark.seal.fill"
        case .reportIssue: return "exclamationmark.triangle.fill"
        }
    }
}

public enum TakerParcelsSegment: String, CaseIterable, Identifiable, Sendable {
    case expected = "expected"
    case inStock = "in_stock"
    case handedOver = "handed_over"
    case issues = "issues"

    public var id: String { rawValue }

    public var labelFr: String {
        switch self {
        case .expected: return "En approche"
        case .inStock: return "En stock"
        case .handedOver: return "Remis"
        case .issues: return "Problèmes"
        }
    }
}

public struct TakerToastBanner: Identifiable, Equatable, Sendable {
    public enum Style: Sendable {
        case success
        case warning
        case error
        case info
    }

    public let id = UUID()
    public let title: String
    public let subtitle: String
    public let style: Style

    public init(title: String, subtitle: String = "", style: Style = .success) {
        self.title = title
        self.subtitle = subtitle
        self.style = style
    }
}

public struct UpsBarcodePedagogicalWarning: Identifiable, Equatable, Sendable {
    public let id = UUID()
    public let scannedUpsCode: String
    public let matchedVipleBarcode: String?
    public let title: String
    public let message: String
    public let intendedMode: TakerScannerOperationMode

    public init(
        scannedUpsCode: String,
        matchedVipleBarcode: String?,
        title: String = "Étiquette UPS (1Z…) détectée !",
        message: String = "Vous avez scanné la 1re étiquette transporteur UPS (1Z…). Pour enregistrer le colis dans Looby Taker, scannez toujours la 2e étiquette « Viple Delivery » (VD-…) collée sur le carton !",
        intendedMode: TakerScannerOperationMode
    ) {
        self.scannedUpsCode = scannedUpsCode
        self.matchedVipleBarcode = matchedVipleBarcode
        self.title = title
        self.message = message
        self.intendedMode = intendedMode
    }
}

// MARK: - ViewModel Central `@MainActor` « Looby Taker » (Swift 6)

@MainActor
public final class LoobyTakerViewModel: ObservableObject {
    // Cycle de vie lancement & thème
    @Published public var hasCompletedLaunchIntro: Bool = false
    @Published public var appearanceMode: LoobyTakerAppearanceMode {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: appearanceKey)
        }
    }

    // Authentification & SSO
    @Published public var isAuthenticated: Bool = false
    @Published public var currentUser: TakerUserProfile? = nil
    @Published public var detectedSsoAccount: TakerCrossAppAccount? = nil
    @Published public var isAuthenticating: Bool = false
    @Published public var authErrorMessage: String? = nil

    // Bootstrap & Données Point Relais
    @Published public var isBootstrapping: Bool = false
    @Published public var bootstrapErrorMessage: String? = nil
    @Published public var hasAssignedRelay: Bool = false
    @Published public var relays: [TakerRelayPoint] = []
    @Published public var activeRelay: TakerRelayPoint? = nil
    @Published public var parcels: [TakerParcel] = []
    @Published public var appointments: [TakerAppointment] = []
    @Published public var issues: [TakerReceptionIssue] = []
    @Published public var applications: [TakerApplicationRecord] = []

    // Aperçu instantané Particulier / Pro (sans écraser le serveur tant qu'on ne sauvegarde pas, ou bascule rapide)
    @Published public var previewRelayModeOverride: String? = nil

    // Navigation par onglets & feuilles globales
    @Published public var selectedTab: LoobyTakerTab = .dashboard
    @Published public var scannerMode: TakerScannerOperationMode = .receive
    @Published public var parcelsSegment: TakerParcelsSegment = .inStock

    @Published public var isShowingVisualScanGuide: Bool = false
    @Published public var isShowingForecastSheet: Bool = false
    @Published public var isShowingReportIssueSheet: Bool = false
    @Published public var prefilledIssueBarcode: String = ""
    @Published public var prefilledIssueParcel: TakerParcel? = nil

    @Published public var isShowingAppointmentComposer: Bool = false
    @Published public var prefilledAppointmentParcel: TakerParcel? = nil

    @Published public var isShowingRelayEditSheet: Bool = false
    @Published public var isShowingApplicationSheet: Bool = false

    // Alertes Scanner & Remise PIN
    @Published public var upsPedagogicalWarning: UpsBarcodePedagogicalWarning? = nil
    @Published public var pendingHandoverParcelForPin: TakerParcel? = nil
    @Published public var pendingHandoverScannedCode: String = ""

    // Appareils Connectés & Notifications
    @Published public var connectedDevices: [TakerConnectedDevice] = []
    @Published public var isLoadingConnectedDevices: Bool = false
    @Published public var notificationInbox: [TakerNotificationItem] = []

    // Toast feedback
    @Published public var activeToast: TakerToastBanner? = nil

    private let api = LoobyTakerAPIClient.shared
    private let defaults = UserDefaults.standard
    private let savedUserKey = "loobytaker.ios.savedUser.v1"
    private let savedActiveRelayIdKey = "loobytaker.ios.activeRelayId.v1"
    private let appearanceKey = "loobytaker.ios.appearance.v1"

    public init() {
        let rawAppearance = UserDefaults.standard.string(forKey: "loobytaker.ios.appearance.v1") ?? "system"
        self.appearanceMode = LoobyTakerAppearanceMode(rawValue: rawAppearance) ?? .system

        if let data = UserDefaults.standard.data(forKey: savedUserKey),
           let savedUser = try? JSONDecoder().decode(TakerUserProfile.self, from: data),
           !savedUser.email.isEmpty {
            self.currentUser = savedUser
            self.isAuthenticated = true
        }
    }

    // MARK: - Propriétés Calculées Adaptatives Particulier vs Pro

    /// Mode effectif affiché dans l'interface (`"Particulier"` ou `"Pro"`).
    public var effectiveRelayMode: String {
        if let override = previewRelayModeOverride, !override.isEmpty {
            return override
        }
        return activeRelay?.relayMode ?? "Particulier"
    }

    public var isProMode: Bool {
        effectiveRelayMode.lowercased() == "pro"
    }

    public var isParticulierMode: Bool {
        !isProMode
    }

    public var isPreviewingAlternateMode: Bool {
        guard let override = previewRelayModeOverride, let real = activeRelay?.relayMode else {
            return false
        }
        return override.lowercased() != real.lowercased()
    }

    public var expectedParcels: [TakerParcel] {
        parcels.filter { $0.isExpected }
    }

    public var inStockParcels: [TakerParcel] {
        parcels.filter { $0.isInStock }
    }

    public var handedOverParcels: [TakerParcel] {
        parcels.filter { $0.isHandedOver }
    }

    public var issueParcels: [TakerParcel] {
        parcels.filter { $0.isIssueReported }
    }

    public var activeAppointments: [TakerAppointment] {
        appointments.filter {
            let s = $0.status.lowercased()
            return s != "annulé" && s != "honoré"
        }
    }

    public var computedExpectedCount: Int {
        max(activeRelay?.stats.expectedCount ?? 0, expectedParcels.count)
    }

    public var computedInStockCount: Int {
        max(activeRelay?.stats.inStockCount ?? 0, inStockParcels.count)
    }

    public var computedTodayAppointmentsCount: Int {
        max(activeRelay?.stats.todayAppointmentsCount ?? 0, activeAppointments.count)
    }

    public var computedOpenIssuesCount: Int {
        max(activeRelay?.stats.openIssuesCount ?? 0, issues.count)
    }

    public var computedTotalEarnedEur: Double {
        let serverTotal = activeRelay?.stats.totalEarnedEur ?? 0
        let rate = activeRelay?.commissionPerParcel ?? 1.0
        let fromParcels = Double(handedOverParcels.count) * rate
        return max(serverTotal, fromParcels)
    }

    public func togglePreviewRelayMode() {
        let next = isProMode ? "Particulier" : "Pro"
        if next.lowercased() == activeRelay?.relayMode.lowercased() {
            previewRelayModeOverride = nil
        } else {
            previewRelayModeOverride = next
        }
        LoobyTakerHaptics.impact(1)
        showToast(
            title: "Mode \(next) affiché",
            subtitle: next == "Pro"
                ? "Remise directe sans code PIN, horaires boutique & fermeture 1-tap."
                : "Remise sécurisée par code PIN client (1,00 €/colis), RDV & disponibilités.",
            style: .info
        )
    }

    // MARK: - Démarrage, Découverte SSO & Authentification

    public func onInitialLaunchReady() async {
        if isAuthenticated {
            await refreshBootstrap()
        } else {
            await checkCrossAppSSO()
        }
    }

    public func checkCrossAppSSO() async {
        let discovered = await api.discoverCrossAppAccount()
        self.detectedSsoAccount = discovered
    }

    public func signInWithCredentials(email: String, password: String) async {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanEmail.isEmpty, !password.isEmpty else {
            authErrorMessage = "Veuillez saisir votre adresse e-mail Viple / Cenelis et votre mot de passe."
            return
        }
        isAuthenticating = true
        authErrorMessage = nil
        defer { isAuthenticating = false }

        do {
            let res = try await api.loginTaker(email: cleanEmail, password: password)
            guard res.ok, let user = res.user else {
                authErrorMessage = res.error ?? "Identifiants incorrects. Vérifiez votre compte Viple Live ID / Cenelis."
                LoobyTakerHaptics.error()
                return
            }
            await completeAuthenticatedSession(user: user, token: res.token, isExplicitLogin: true)
        } catch {
            authErrorMessage = error.localizedDescription
            LoobyTakerHaptics.error()
        }
    }

    public func acceptDetectedSsoAccount(_ sso: TakerCrossAppAccount) async {
        isAuthenticating = true
        authErrorMessage = nil
        defer { isAuthenticating = false }

        do {
            let res = try await api.acceptCrossAppAccount(userId: sso.userId, email: sso.email)
            if res.ok, let user = res.user {
                await completeAuthenticatedSession(user: user, token: res.token, isExplicitLogin: true)
                return
            }
            // Si le jeton AppGroup local provient d'une autre app Cenelis sur le même iPhone, ouverture directe via bootstrap
            let fallbackUser = TakerUserProfile(
                id: sso.userId,
                email: sso.email,
                displayName: sso.displayName,
                cid: sso.cid,
                livriaId: sso.userId,
                avatarUrl: sso.avatarUrl
            )
            await completeAuthenticatedSession(user: fallbackUser, token: res.token, isExplicitLogin: true)
        } catch {
            let fallbackUser = TakerUserProfile(
                id: sso.userId,
                email: sso.email,
                displayName: sso.displayName,
                cid: sso.cid,
                livriaId: sso.userId,
                avatarUrl: sso.avatarUrl
            )
            await completeAuthenticatedSession(user: fallbackUser, token: nil, isExplicitLogin: true)
        }
    }

    private func completeAuthenticatedSession(
        user: TakerUserProfile,
        token: String?,
        isExplicitLogin: Bool
    ) async {
        self.currentUser = user
        self.isAuthenticated = true
        self.previewRelayModeOverride = nil
        persistUser(user)

        await api.announceCrossAppSession(user: user, token: token)
        await LoobyTakerNotificationManager.shared.syncDeviceRegistration(user: user, isExplicitLogin: isExplicitLogin)
        _ = await LoobyTakerNotificationManager.shared.requestPermissionIfNeeded(promptIfNotDetermined: true)

        LoobyTakerHaptics.success()
        await refreshBootstrap()
    }

    private func persistUser(_ user: TakerUserProfile?) {
        if let user, let data = try? JSONEncoder().encode(user) {
            defaults.set(data, forKey: savedUserKey)
        } else {
            defaults.removeObject(forKey: savedUserKey)
        }
    }

    /// Déconnexion propre : purge immédiate des notifications locales + `unregisterPushDevice` AVANT effacement du compte.
    public func signOutCleanly() async {
        let prevUid = currentUser?.id
        let prevEmail = currentUser?.email
        let prevCid = currentUser?.cid

        // 1. Purge immédiate des notifications locales + désenregistrement APNs sur le serveur
        await LoobyTakerNotificationManager.shared.handleCleanSignOut(
            userId: prevUid,
            email: prevEmail,
            cid: prevCid
        )
        await api.clearCrossAppSession()

        // 2. Effacement complet de la session locale
        api.bearerToken = nil
        persistUser(nil)
        defaults.removeObject(forKey: savedActiveRelayIdKey)

        currentUser = nil
        isAuthenticated = false
        hasAssignedRelay = false
        relays = []
        activeRelay = nil
        parcels = []
        appointments = []
        issues = []
        applications = []
        connectedDevices = []
        notificationInbox = []
        previewRelayModeOverride = nil
        selectedTab = .dashboard

        LoobyTakerHaptics.impact(1)
        await checkCrossAppSSO()
    }

    public func handleRemoteSessionRevocation() {
        api.bearerToken = nil
        persistUser(nil)
        currentUser = nil
        isAuthenticated = false
        hasAssignedRelay = false
        relays = []
        activeRelay = nil
        parcels = []
        appointments = []
        issues = []
        applications = []
        connectedDevices = []
        previewRelayModeOverride = nil
        showToast(
            title: "Session déconnectée à distance",
            subtitle: "Cet appareil a été révoqué depuis le gestionnaire d'appareils Viple Live ID.",
            style: .warning
        )
    }

    // MARK: - Bootstrap & Changement de Point Relais Actif

    public func refreshBootstrap(preferredRelayId: Int? = nil) async {
        guard let user = currentUser, !user.email.isEmpty else { return }
        isBootstrapping = true
        bootstrapErrorMessage = nil
        defer { isBootstrapping = false }

        let targetRelayId = preferredRelayId
            ?? activeRelay?.id
            ?? (defaults.integer(forKey: savedActiveRelayIdKey) > 0 ? defaults.integer(forKey: savedActiveRelayIdKey) : nil)

        do {
            let res = try await api.fetchBootstrap(
                email: user.email,
                cid: user.cid,
                userId: user.effectiveUserIdQuery,
                relayId: targetRelayId
            )
            if res.sessionRevoked {
                await LoobyTakerNotificationManager.shared.executeRemoteSessionRevocation()
                return
            }
            self.relays = res.relays
            self.activeRelay = res.activeRelay ?? res.relays.first
            self.hasAssignedRelay = res.hasAssignedRelay || self.activeRelay != nil
            self.parcels = res.parcels
            self.appointments = res.appointments
            self.issues = res.issues
            self.applications = res.applications

            if let rid = self.activeRelay?.id, rid > 0 {
                defaults.set(rid, forKey: savedActiveRelayIdKey)
            }
        } catch {
            bootstrapErrorMessage = error.localizedDescription
        }
    }

    public func selectRelay(_ relay: TakerRelayPoint) async {
        previewRelayModeOverride = nil
        activeRelay = relay
        defaults.set(relay.id, forKey: savedActiveRelayIdKey)
        LoobyTakerHaptics.impact(1)
        await refreshBootstrap(preferredRelayId: relay.id)
    }

    // MARK: - Logique Métier Scan & Remise (UPS `1Z...` vs Viple Delivery `VD-...`, PIN Particulier vs Sans PIN Pro)

    public static func isUpsTrackingBarcode(_ rawCode: String) -> Bool {
        let cleaned = rawCode
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .uppercased()
        return cleaned.hasPrefix("1Z") && cleaned.count >= 8
    }

    public func findMatchingParcelForUpsCode(_ upsCode: String) -> TakerParcel? {
        let clean = upsCode.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "").uppercased()
        return parcels.first {
            $0.carrierTrackingNumber.replacingOccurrences(of: " ", with: "").uppercased() == clean
        }
    }

    /// Point d'entrée unifié lorsqu'un code-barres est lu par la caméra ou saisi manuellement.
    public func handleScannedCode(
        _ rawCode: String,
        mode: TakerScannerOperationMode,
        shelfLocation: String = "",
        conditionNotes: String = "",
        recipientNameOverride: String = ""
    ) async {
        let code = rawCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return }

        // Mode 3 : Signalement direct d'anomalie
        if mode == .reportIssue {
            let matched = parcels.first {
                $0.vipleBarcode.caseInsensitiveCompare(code) == .orderedSame ||
                $0.carrierTrackingNumber.caseInsensitiveCompare(code) == .orderedSame
            }
            prefilledIssueParcel = matched
            prefilledIssueBarcode = code
            isShowingReportIssueSheet = true
            LoobyTakerHaptics.warning()
            return
        }

        // Détection préventive locale d'une 1re étiquette UPS `1Z...` + appel serveur pour récupérer `matchedVipleBarcode`
        if Self.isUpsTrackingBarcode(code) {
            let localMatch = findMatchingParcelForUpsCode(code)?.vipleBarcode
            if mode == .receive, let user = currentUser, let relay = activeRelay {
                if let res = try? await api.scanReceiveParcel(
                    email: user.email,
                    cid: user.cid,
                    relayId: relay.id,
                    scannedCode: code,
                    shelfLocation: shelfLocation,
                    conditionNotes: conditionNotes,
                    recipientNameOverride: recipientNameOverride
                ), res.isUpsCarrierBarcode == true || !res.ok {
                    LoobyTakerHaptics.warning()
                    upsPedagogicalWarning = UpsBarcodePedagogicalWarning(
                        scannedUpsCode: code,
                        matchedVipleBarcode: res.matchedVipleBarcode ?? localMatch,
                        title: res.warningTitle ?? "1re étiquette UPS (1Z…) détectée !",
                        message: res.message ?? res.error ?? "Vous avez scanné la 1re étiquette UPS (1Z…). Scannez la 2e étiquette Viple Delivery (VD-…) collée sur le colis !",
                        intendedMode: mode
                    )
                    return
                }
            }
            LoobyTakerHaptics.warning()
            upsPedagogicalWarning = UpsBarcodePedagogicalWarning(
                scannedUpsCode: code,
                matchedVipleBarcode: localMatch,
                intendedMode: mode
            )
            return
        }

        switch mode {
        case .receive:
            await executeScanReceive(
                vipleCode: code,
                shelfLocation: shelfLocation,
                conditionNotes: conditionNotes,
                recipientNameOverride: recipientNameOverride
            )
        case .handover:
            await initiateHandoverFlow(scannedCode: code, explicitParcel: nil)
        case .reportIssue:
            break
        }
    }

    public func executeScanReceive(
        vipleCode: String,
        shelfLocation: String = "",
        conditionNotes: String = "",
        recipientNameOverride: String = ""
    ) async {
        guard let user = currentUser, let relay = activeRelay else { return }
        do {
            let res = try await api.scanReceiveParcel(
                email: user.email,
                cid: user.cid,
                relayId: relay.id,
                scannedCode: vipleCode,
                shelfLocation: shelfLocation,
                conditionNotes: conditionNotes,
                recipientNameOverride: recipientNameOverride
            )
            if res.isUpsCarrierBarcode == true {
                LoobyTakerHaptics.warning()
                upsPedagogicalWarning = UpsBarcodePedagogicalWarning(
                    scannedUpsCode: vipleCode,
                    matchedVipleBarcode: res.matchedVipleBarcode,
                    title: res.warningTitle ?? "1re étiquette UPS (1Z…) détectée !",
                    message: res.message ?? res.error ?? "Vous avez scanné la 1re étiquette UPS (1Z…). Scannez la 2e étiquette Viple Delivery (VD-…) collée sur le colis !",
                    intendedMode: .receive
                )
                return
            }
            guard res.ok else {
                LoobyTakerHaptics.error()
                showToast(
                    title: "Réception impossible",
                    subtitle: res.error ?? res.message ?? "Vérifiez le code Viple Delivery (VD-…).",
                    style: .error
                )
                return
            }
            if let updated = res.parcel {
                upsertParcelLocally(updated)
            }
            LoobyTakerHaptics.success()
            showToast(
                title: "Colis réceptionné en stock !",
                subtitle: res.message ?? "Étiquette \(res.parcel?.vipleBarcode ?? vipleCode) enregistrée pour \(res.parcel?.recipientName ?? "le client").",
                style: .success
            )
            await refreshBootstrap(preferredRelayId: relay.id)
        } catch {
            LoobyTakerHaptics.error()
            showToast(title: "Erreur réseau", subtitle: error.localizedDescription, style: .error)
        }
    }

    /// Déclenche la remise d'un colis :
    /// - En mode **Particulier** : ouvre automatiquement le clavier Code PIN à 6 chiffres à échanger avec le client.
    /// - En mode **Pro** : valide immédiatement sans aucun code PIN !
    public func initiateHandoverFlow(scannedCode: String, explicitParcel: TakerParcel?) async {
        let matched = explicitParcel ?? parcels.first {
            $0.vipleBarcode.caseInsensitiveCompare(scannedCode) == .orderedSame ||
            $0.id.caseInsensitiveCompare(scannedCode) == .orderedSame
        }

        let targetCode = scannedCode.isEmpty ? (matched?.vipleBarcode ?? "") : scannedCode

        if isProMode {
            // Relais Professionnel : validation directe SANS aucun code PIN !
            await confirmHandover(
                scannedCode: targetCode,
                parcel: matched,
                pinCode: "",
                recipientNote: "Remise directe comptoir Pro (sans code PIN)"
            )
        } else {
            // Relais Particulier : demande du Code PIN à 6 chiffres présenté par l'acheteur
            let placeholderParcel = matched ?? TakerParcel(
                relayId: activeRelay?.id ?? 2,
                vipleBarcode: targetCode,
                recipientName: "Client au retrait",
                status: "in_stock",
                statusLabel: "En stock",
                requiresPinForHandover: true
            )
            pendingHandoverScannedCode = targetCode
            pendingHandoverParcelForPin = placeholderParcel
            LoobyTakerHaptics.impact(1)
        }
    }

    @discardableResult
    public func confirmHandover(
        scannedCode: String,
        parcel: TakerParcel?,
        pinCode: String,
        recipientNote: String
    ) async -> Bool {
        guard let user = currentUser, let relay = activeRelay else { return false }
        let cleanCode = scannedCode.isEmpty ? (parcel?.vipleBarcode ?? "") : scannedCode
        do {
            let res = try await api.scanHandoverParcel(
                email: user.email,
                cid: user.cid,
                relayId: relay.id,
                scannedCode: cleanCode,
                parcelId: parcel?.id ?? "",
                pinCode: pinCode,
                recipientNote: recipientNote
            )
            if res.isUpsCarrierBarcode == true {
                LoobyTakerHaptics.warning()
                upsPedagogicalWarning = UpsBarcodePedagogicalWarning(
                    scannedUpsCode: cleanCode,
                    matchedVipleBarcode: findMatchingParcelForUpsCode(cleanCode)?.vipleBarcode,
                    intendedMode: .handover
                )
                return false
            }
            if !res.ok {
                if res.requiresPin == true && pendingHandoverParcelForPin == nil {
                    pendingHandoverScannedCode = cleanCode
                    pendingHandoverParcelForPin = parcel ?? TakerParcel(
                        relayId: relay.id,
                        vipleBarcode: cleanCode,
                        recipientName: "Client au retrait",
                        status: "in_stock",
                        requiresPinForHandover: true
                    )
                }
                LoobyTakerHaptics.error()
                showToast(
                    title: "Validation refusée",
                    subtitle: res.error ?? res.message ?? "Code PIN invalide ou colis introuvable.",
                    style: .error
                )
                return false
            }

            if let updated = res.parcel {
                upsertParcelLocally(updated)
            }
            pendingHandoverParcelForPin = nil
            pendingHandoverScannedCode = ""
            LoobyTakerHaptics.success()

            let earnedText: String
            if let eur = res.earnedEur, eur > 0, isParticulierMode {
                earnedText = String(format: "+%.2f € crédités sur votre cagnotte Taker !", eur)
                    .replacingOccurrences(of: ".", with: ",")
            } else if isParticulierMode {
                earnedText = "+1,00 € crédité sur votre cagnotte Taker !"
            } else {
                earnedText = res.message ?? "Remise Pro enregistrée sans code PIN."
            }
            showToast(
                title: "Colis remis au client !",
                subtitle: earnedText,
                style: .success
            )
            await refreshBootstrap(preferredRelayId: relay.id)
            return true
        } catch {
            LoobyTakerHaptics.error()
            showToast(title: "Erreur lors de la remise", subtitle: error.localizedDescription, style: .error)
            return false
        }
    }

    private func upsertParcelLocally(_ parcel: TakerParcel) {
        if let idx = parcels.firstIndex(where: { $0.id == parcel.id || $0.vipleBarcode == parcel.vipleBarcode }) {
            parcels[idx] = parcel
        } else {
            parcels.insert(parcel, at: 0)
        }
    }

    // MARK: - Actions Colis : Prévoir une arrivée & Signaler un problème

    public func submitParcelForecast(
        vipleBarcode: String,
        carrier: String,
        carrierTrackingNumber: String,
        recipientName: String,
        expectedArrivalDate: String,
        expectedArrivalWindow: String,
        notes: String
    ) async -> Bool {
        guard let user = currentUser, let relay = activeRelay else { return false }
        do {
            let res = try await api.forecastParcel(
                email: user.email,
                cid: user.cid,
                relayId: relay.id,
                vipleBarcode: vipleBarcode,
                carrier: carrier,
                carrierTrackingNumber: carrierTrackingNumber,
                recipientName: recipientName,
                expectedArrivalDate: expectedArrivalDate,
                expectedArrivalWindow: expectedArrivalWindow,
                notes: notes
            )
            guard res.ok else {
                LoobyTakerHaptics.error()
                showToast(title: "Prévision refusée", subtitle: res.error ?? "Vérifiez les champs saisis.", style: .error)
                return false
            }
            if let p = res.parcel {
                upsertParcelLocally(p)
            }
            LoobyTakerHaptics.success()
            showToast(
                title: "Arrivée de colis prévue !",
                subtitle: res.message ?? "Le colis est désormais suivi dans « En approche ».",
                style: .success
            )
            await refreshBootstrap(preferredRelayId: relay.id)
            return true
        } catch {
            LoobyTakerHaptics.error()
            showToast(title: "Erreur réseau", subtitle: error.localizedDescription, style: .error)
            return false
        }
    }

    public func submitReceptionIssue(
        parcelId: String?,
        vipleBarcode: String,
        carrierTrackingNumber: String,
        issueType: String,
        severity: String,
        description: String,
        refusedAtDoor: Bool
    ) async -> Bool {
        guard let user = currentUser, let relay = activeRelay else { return false }
        do {
            let res = try await api.reportReceptionIssue(
                email: user.email,
                cid: user.cid,
                relayId: relay.id,
                parcelId: parcelId,
                vipleBarcode: vipleBarcode,
                carrierTrackingNumber: carrierTrackingNumber,
                issueType: issueType,
                severity: severity,
                description: description,
                refusedAtDoor: refusedAtDoor
            )
            guard res.ok else {
                LoobyTakerHaptics.error()
                showToast(title: "Signalement refusé", subtitle: res.error ?? "Veuillez préciser l'anomalie.", style: .error)
                return false
            }
            if let issue = res.issue {
                issues.insert(issue, at: 0)
            }
            LoobyTakerHaptics.success()
            showToast(
                title: "Problème signalé à Viple Delivery",
                subtitle: res.message ?? "Notre équipe logistique prend le relais immédiatement.",
                style: .warning
            )
            await refreshBootstrap(preferredRelayId: relay.id)
            return true
        } catch {
            LoobyTakerHaptics.error()
            showToast(title: "Erreur réseau", subtitle: error.localizedDescription, style: .error)
            return false
        }
    }

    // MARK: - Actions RDV, Horaires, Fermeture Pro & Mode Vacances

    public func saveCustomerAppointment(
        appointmentId: String?,
        parcelId: String,
        vipleBarcode: String,
        customerName: String,
        customerPhone: String,
        customerEmail: String,
        slotDate: String,
        startTime: String,
        endTime: String,
        status: String,
        notes: String
    ) async -> Bool {
        guard let user = currentUser, let relay = activeRelay else { return false }
        do {
            let res = try await api.saveAppointment(
                email: user.email,
                cid: user.cid,
                relayId: relay.id,
                appointmentId: appointmentId,
                parcelId: parcelId,
                vipleBarcode: vipleBarcode,
                customerName: customerName,
                customerPhone: customerPhone,
                customerEmail: customerEmail,
                slotDate: slotDate,
                startTime: startTime,
                endTime: endTime,
                status: status,
                notes: notes
            )
            guard res.ok else {
                LoobyTakerHaptics.error()
                showToast(title: "RDV impossible", subtitle: res.error ?? "Vérifiez le créneau choisi.", style: .error)
                return false
            }
            LoobyTakerHaptics.success()
            showToast(
                title: "Rendez-vous enregistré",
                subtitle: res.message ?? "Créneau avec \(customerName) planifié le \(slotDate) (\(startTime)).",
                style: .success
            )
            await refreshBootstrap(preferredRelayId: relay.id)
            return true
        } catch {
            LoobyTakerHaptics.error()
            showToast(title: "Erreur réseau", subtitle: error.localizedDescription, style: .error)
            return false
        }
    }

    public func changeAppointmentStatus(appointment: TakerAppointment, newStatus: String, notes: String = "") async {
        guard let user = currentUser, let relay = activeRelay else { return }
        do {
            let res = try await api.updateAppointmentStatus(
                email: user.email,
                cid: user.cid,
                relayId: relay.id,
                appointmentId: appointment.id,
                status: newStatus,
                notes: notes.isEmpty ? appointment.notes : notes
            )
            if res.ok {
                LoobyTakerHaptics.success()
                showToast(
                    title: "Statut du RDV : \(newStatus)",
                    subtitle: "Client : \(appointment.customerName)",
                    style: .success
                )
                await refreshBootstrap(preferredRelayId: relay.id)
            } else {
                showToast(title: "Mise à jour refusée", subtitle: res.error ?? "", style: .error)
            }
        } catch {
            showToast(title: "Erreur réseau", subtitle: error.localizedDescription, style: .error)
        }
    }

    public func saveRelayInformation(
        name: String,
        relayMode: String,
        address: String,
        postalCode: String,
        city: String,
        phone: String,
        siret: String,
        businessCategory: String,
        intercomAndAccessNotes: String,
        maxParcelCapacity: Int
    ) async -> Bool {
        guard let user = currentUser, let relay = activeRelay else { return false }
        do {
            let res = try await api.updateRelayInfo(
                email: user.email,
                cid: user.cid,
                relayId: relay.id,
                name: name,
                relayMode: relayMode,
                address: address,
                postalCode: postalCode,
                city: city,
                phone: phone,
                siret: siret,
                businessCategory: businessCategory,
                intercomAndAccessNotes: intercomAndAccessNotes,
                maxParcelCapacity: maxParcelCapacity
            )
            guard res.ok else {
                LoobyTakerHaptics.error()
                showToast(title: "Sauvegarde refusée", subtitle: res.error ?? "Vérifiez les informations du relais.", style: .error)
                return false
            }
            previewRelayModeOverride = nil
            if let updated = res.activeRelay {
                activeRelay = updated
            }
            LoobyTakerHaptics.success()
            showToast(
                title: "Point Relais mis à jour !",
                subtitle: res.message ?? "Les modifications sont visibles immédiatement.",
                style: .success
            )
            await refreshBootstrap(preferredRelayId: relay.id)
            return true
        } catch {
            LoobyTakerHaptics.error()
            showToast(title: "Erreur réseau", subtitle: error.localizedDescription, style: .error)
            return false
        }
    }

    public func saveRelayHoursAndClosure(
        openingHoursSummary: String,
        isCurrentlyClosedOverride: Bool,
        closureReason: String,
        weeklySchedule: [TakerDaySchedule],
        availabilities: [TakerAvailabilitySlot]
    ) async -> Bool {
        guard let user = currentUser, let relay = activeRelay else { return false }
        do {
            let res = try await api.updateRelayHours(
                email: user.email,
                cid: user.cid,
                relayId: relay.id,
                openingHoursSummary: openingHoursSummary,
                isCurrentlyClosedOverride: isCurrentlyClosedOverride,
                closureReason: closureReason,
                weeklySchedule: weeklySchedule,
                availabilities: availabilities
            )
            guard res.ok else {
                LoobyTakerHaptics.error()
                showToast(title: "Sauvegarde refusée", subtitle: res.error ?? "", style: .error)
                return false
            }
            if let updated = res.activeRelay {
                activeRelay = updated
            }
            LoobyTakerHaptics.success()
            showToast(
                title: isCurrentlyClosedOverride ? "Relais marqué fermé" : "Horaires & disponibilités enregistrés",
                subtitle: res.message ?? (isCurrentlyClosedOverride ? "Les clients et livreurs sont informés en temps réel." : "Votre planning est synchronisé."),
                style: isCurrentlyClosedOverride ? .warning : .success
            )
            await refreshBootstrap(preferredRelayId: relay.id)
            return true
        } catch {
            LoobyTakerHaptics.error()
            showToast(title: "Erreur réseau", subtitle: error.localizedDescription, style: .error)
            return false
        }
    }

    public func saveVacationMode(
        enabled: Bool,
        startDate: String,
        endDate: String,
        message: String,
        allowExistingPickupsOnly: Bool
    ) async -> Bool {
        guard let user = currentUser, let relay = activeRelay else { return false }
        do {
            let res = try await api.updateRelayVacation(
                email: user.email,
                cid: user.cid,
                relayId: relay.id,
                enabled: enabled,
                startDate: startDate,
                endDate: endDate,
                message: message,
                allowExistingPickupsOnly: allowExistingPickupsOnly
            )
            guard res.ok else {
                LoobyTakerHaptics.error()
                showToast(title: "Erreur mode vacances", subtitle: res.error ?? "", style: .error)
                return false
            }
            if let updated = res.activeRelay {
                activeRelay = updated
            }
            LoobyTakerHaptics.success()
            showToast(
                title: enabled ? "Mode vacances activé" : "Mode vacances désactivé",
                subtitle: res.message ?? (enabled ? "Vos dates de congés sont publiées." : "Les livraisons reprennent normalement."),
                style: .success
            )
            await refreshBootstrap(preferredRelayId: relay.id)
            return true
        } catch {
            LoobyTakerHaptics.error()
            showToast(title: "Erreur réseau", subtitle: error.localizedDescription, style: .error)
            return false
        }
    }

    // MARK: - Candidature Devenir Taker & Réponse Complémentaire

    public func submitApplication(
        applicantType: String,
        relayName: String,
        firstName: String,
        lastName: String,
        phone: String,
        siret: String,
        businessCategory: String,
        address: String,
        postalCode: String,
        city: String,
        openingHours: String,
        storageCapacity: String,
        motivationAndAccessNotes: String
    ) async -> Bool {
        guard let user = currentUser else { return false }
        do {
            let res = try await api.submitTakerApplication(
                email: user.email,
                cid: user.cid,
                userId: user.effectiveUserIdQuery,
                applicantType: applicantType,
                relayName: relayName,
                firstName: firstName,
                lastName: lastName,
                phone: phone,
                siret: siret,
                businessCategory: businessCategory,
                address: address,
                postalCode: postalCode,
                city: city,
                openingHours: openingHours,
                storageCapacity: storageCapacity,
                motivationAndAccessNotes: motivationAndAccessNotes
            )
            guard res.ok else {
                LoobyTakerHaptics.error()
                showToast(title: "Envoi refusé", subtitle: res.error ?? "Veuillez vérifier le formulaire.", style: .error)
                return false
            }
            if let app = res.application {
                applications.removeAll { $0.id == app.id || $0.reference == app.reference }
                applications.insert(app, at: 0)
            }
            LoobyTakerHaptics.success()
            showToast(
                title: "Candidature Looby Taker envoyée !",
                subtitle: res.message ?? "Suivez en direct les 4 étapes de validation.",
                style: .success
            )
            await refreshBootstrap()
            return true
        } catch {
            LoobyTakerHaptics.error()
            showToast(title: "Erreur réseau", subtitle: error.localizedDescription, style: .error)
            return false
        }
    }

    public func sendApplicationSupplementaryReply(
        application: TakerApplicationRecord,
        supplementaryResponse: String
    ) async -> Bool {
        guard let user = currentUser else { return false }
        do {
            let res = try await api.replyToApplicationRequest(
                email: user.email,
                cid: user.cid,
                applicationId: application.id,
                reference: application.reference,
                supplementaryResponse: supplementaryResponse
            )
            guard res.ok else {
                LoobyTakerHaptics.error()
                showToast(title: "Envoi impossible", subtitle: res.error ?? "", style: .error)
                return false
            }
            if let updated = res.application,
               let idx = applications.firstIndex(where: { $0.id == updated.id }) {
                applications[idx] = updated
            }
            LoobyTakerHaptics.success()
            showToast(
                title: "Éléments transmis à Viple !",
                subtitle: res.message ?? "Votre dossier poursuit son instruction.",
                style: .success
            )
            await refreshBootstrap()
            return true
        } catch {
            LoobyTakerHaptics.error()
            showToast(title: "Erreur réseau", subtitle: error.localizedDescription, style: .error)
            return false
        }
    }

    // MARK: - Gestionnaire d'Appareils Connectés

    public func loadConnectedDevices() async {
        guard let user = currentUser, !user.email.isEmpty else { return }
        isLoadingConnectedDevices = true
        defer { isLoadingConnectedDevices = false }

        do {
            let res = try await api.fetchConnectedDevices(
                userId: user.id,
                email: user.email,
                cid: user.cid
            )
            if res.sessionRevoked {
                await LoobyTakerNotificationManager.shared.executeRemoteSessionRevocation()
                return
            }
            self.connectedDevices = res.devices
        } catch {
            // Si hors-ligne ou premier enregistrement, affiche au moins l'iPhone courant de façon transparente
            if connectedDevices.isEmpty {
                let fallbackJson: [String: Any] = [
                    "deviceId": api.resolvedDeviceIdentifier,
                    "rawDeviceIds": [api.resolvedDeviceIdentifier],
                    "modelName": api.resolvedHardwareModelName,
                    "modelCode": api.resolvedHardwareModelCode,
                    "platform": "iOS",
                    "osVersion": api.resolvedOsVersion,
                    "isCurrentDevice": true,
                    "pushActive": LoobyTakerNotificationManager.shared.isOsAuthorized,
                    "connectedApps": [
                        [
                            "appId": "looby-taker",
                            "appName": "Looby Taker",
                            "bundleId": LoobyTakerDeviceIdentity.bundleIdentifier,
                            "accountEmail": user.email,
                            "appVersion": LoobyTakerDeviceIdentity.clientMarketingVersion,
                            "notificationsEnabled": LoobyTakerNotificationManager.shared.notificationsEnabled
                        ]
                    ]
                ]
                if let data = try? JSONSerialization.data(withJSONObject: fallbackJson),
                   let localDev = try? JSONDecoder().decode(TakerConnectedDevice.self, from: data) {
                    self.connectedDevices = [localDev]
                }
            }
        }
    }

    public func revokeDeviceSession(device: TakerConnectedDevice, targetAppId: String) async -> Bool {
        guard let user = currentUser else { return false }
        let normalizedTarget = targetAppId.lowercased()
        let revokesSelf = device.isCurrentDevice &&
            (targetAppId == "*" || normalizedTarget == "looby-taker" || normalizedTarget == "loobytaker")

        do {
            let res = try await api.revokeConnectedDevice(
                userId: user.id,
                email: user.email,
                cid: user.cid,
                targetDeviceId: device.deviceId,
                rawDeviceIds: device.rawDeviceIds,
                targetAppId: targetAppId
            )
            if revokesSelf || res.currentDeviceRevoked {
                await signOutCleanly()
                return true
            }
            LoobyTakerHaptics.success()
            showToast(
                title: "Session déconnectée",
                subtitle: "\(device.displayModelName) a bien été révoqué.",
                style: .success
            )
            await loadConnectedDevices()
            return res.ok
        } catch {
            if revokesSelf {
                await signOutCleanly()
                return true
            }
            LoobyTakerHaptics.error()
            showToast(title: "Révocation impossible", subtitle: error.localizedDescription, style: .error)
            return false
        }
    }

    // MARK: - Deep Links & Toasts

    public func handleIncomingURL(_ url: URL) {
        let host = (url.host ?? "").lowercased()
        switch host {
        case "scan", "scanner":
            selectedTab = .scanner
        case "parcels", "colis":
            selectedTab = .parcels
        case "schedule", "rdv", "hours":
            selectedTab = .schedule
        case "guide":
            isShowingVisualScanGuide = true
        case "devices":
            selectedTab = .profile
        default:
            selectedTab = .dashboard
        }
    }

    public func showToast(title: String, subtitle: String = "", style: TakerToastBanner.Style = .success) {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
            activeToast = TakerToastBanner(title: title, subtitle: subtitle, style: style)
        }
        let currentId = activeToast?.id
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            guard let self, self.activeToast?.id == currentId else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                self.activeToast = nil
            }
        }
    }
}
