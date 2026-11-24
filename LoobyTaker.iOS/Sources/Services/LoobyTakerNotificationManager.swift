import Foundation
import SwiftUI
import UserNotifications
#if canImport(UIKit)
import UIKit
import BackgroundTasks
#endif

// MARK: - Gestionnaire APNs (`.p8` `fr.looby.taker`) & BGTaskScheduler Strict Swift 6

private final class LoobyTakerBGTaskBox: @unchecked Sendable {
    private let lock = NSLock()
    private var didComplete = false
    private let completeBlock: (Bool) -> Void

    init(_ complete: @escaping (Bool) -> Void) {
        self.completeBlock = complete
    }

    func complete(_ ok: Bool) {
        lock.lock()
        guard !didComplete else {
            lock.unlock()
            return
        }
        didComplete = true
        lock.unlock()
        completeBlock(ok)
    }
}

#if canImport(UIKit)
public final class LoobyTakerRemoteFetchBox: @unchecked Sendable {
    private let lock = NSLock()
    private var completed = false
    private let completeBlock: (UIBackgroundFetchResult) -> Void

    public init(_ complete: @escaping (UIBackgroundFetchResult) -> Void) {
        self.completeBlock = complete
    }

    public func complete(_ result: UIBackgroundFetchResult) {
        lock.lock()
        guard !completed else {
            lock.unlock()
            return
        }
        completed = true
        lock.unlock()
        completeBlock(result)
    }
}

/// Pont strictement `nonisolated` pour `BGTaskScheduler` (`fr.looby.taker.bgrefresh` & `fr.looby.taker.bgprocessing`).
private enum LoobyTakerBackgroundRuntime {
    static let refreshIdentifier = "fr.looby.taker.bgrefresh"
    static let processingIdentifier = "fr.looby.taker.bgprocessing"

    nonisolated static func scheduleAll() {
        let refreshReq = BGAppRefreshTaskRequest(identifier: refreshIdentifier)
        refreshReq.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(refreshReq)

        let procReq = BGProcessingTaskRequest(identifier: processingIdentifier)
        procReq.requiresNetworkConnectivity = true
        procReq.requiresExternalPower = false
        procReq.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60)
        try? BGTaskScheduler.shared.submit(procReq)
    }

    nonisolated static func registerAll() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: refreshIdentifier, using: nil) { task in
            let box = LoobyTakerBGTaskBox { ok in task.setTaskCompleted(success: ok) }
            scheduleAll()
            let work = Task { @MainActor in
                let ok = await LoobyTakerNotificationManager.shared.performNotificationPollCycle(isBackground: true)
                box.complete(ok)
            }
            task.expirationHandler = {
                work.cancel()
                scheduleAll()
                box.complete(false)
            }
        }

        BGTaskScheduler.shared.register(forTaskWithIdentifier: processingIdentifier, using: nil) { task in
            let box = LoobyTakerBGTaskBox { ok in task.setTaskCompleted(success: ok) }
            scheduleAll()
            let work = Task { @MainActor in
                let ok = await LoobyTakerNotificationManager.shared.performNotificationPollCycle(isBackground: true)
                box.complete(ok)
            }
            task.expirationHandler = {
                work.cancel()
                scheduleAll()
                box.complete(false)
            }
        }
    }
}
#endif

@MainActor
public final class LoobyTakerNotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    public static let shared = LoobyTakerNotificationManager()

    public static let categoryIdentifier = "LOOBY_TAKER_EVENT"
    public static let actionOpenScanner = "OPEN_SCANNER_ACTION"
    public static let actionOpenParcels = "OPEN_PARCELS_ACTION"

    @Published public private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published public var notificationsEnabled: Bool {
        didSet {
            defaults.set(notificationsEnabled, forKey: notificationsEnabledKey)
            Task { await syncDeviceRegistration() }
        }
    }
    @Published public private(set) var apnsDeviceTokenHex: String? = nil
    @Published public private(set) var lastSyncDate: Date? = nil

    public weak var attachedViewModel: LoobyTakerViewModel?

    private let defaults = UserDefaults.standard
    private let notificationsEnabledKey = "loobytaker.ios.notif.enabled.v1"
    private let savedApnsTokenKey = "loobytaker.ios.apnsTokenHex.v1"
    private let seenNotificationIdsKey = "loobytaker.ios.seenNotifIds.v1"
    private let pendingDeepLinkKey = "loobytaker.ios.pendingDeepLink.v1"
    private let cachedUserIdKey = "loobytaker.ios.notif.userId.v1"
    private let cachedEmailKey = "loobytaker.ios.notif.email.v1"
    private let cachedCidKey = "loobytaker.ios.notif.cid.v1"

    private var didRegisterBackgroundTasks = false
    private var isPollInFlight = false
    private var foregroundLoopTask: Task<Void, Never>? = nil
    #if canImport(UIKit)
    private var backgroundGraceTaskId: UIBackgroundTaskIdentifier = .invalid
    #endif

    private override init() {
        self.notificationsEnabled = UserDefaults.standard.object(forKey: "loobytaker.ios.notif.enabled.v1") as? Bool ?? true
        self.apnsDeviceTokenHex = UserDefaults.standard.string(forKey: "loobytaker.ios.apnsTokenHex.v1")
        super.init()
    }

    public var isOsAuthorized: Bool {
        authorizationStatus == .authorized || authorizationStatus == .provisional || authorizationStatus == .ephemeral
    }

    public var statusBadgeText: String {
        if !notificationsEnabled {
            return "Alertes désactivées"
        }
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return "Push APNs actif"
        case .denied:
            return "Désactivé dans Réglages"
        case .notDetermined:
            return "Autorisation en attente"
        @unknown default:
            return "Actif"
        }
    }

    // MARK: - Configuration initiale & Permissions

    public func configureOnLaunch() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        registerNotificationCategories()
        registerBackgroundTasksIfNeeded()
        scheduleBackgroundTasks()

        Task {
            await refreshAuthorizationStatus()
            if isOsAuthorized {
                registerForRemoteNotificationsOnSystem()
            }
        }
    }

    private func registerNotificationCategories() {
        let scanAction = UNNotificationAction(
            identifier: Self.actionOpenScanner,
            title: "Ouvrir le scanner",
            options: [.foreground],
            icon: UNNotificationActionIcon(systemImageName: "barcode.viewfinder")
        )
        let parcelsAction = UNNotificationAction(
            identifier: Self.actionOpenParcels,
            title: "Voir mes colis",
            options: [.foreground],
            icon: UNNotificationActionIcon(systemImageName: "shippingbox.fill")
        )
        let category = UNNotificationCategory(
            identifier: Self.categoryIdentifier,
            actions: [scanAction, parcelsAction],
            intentIdentifiers: [],
            hiddenPreviewsBodyPlaceholder: "Nouvelle activité Point Relais Looby Taker",
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    private func registerBackgroundTasksIfNeeded() {
        guard !didRegisterBackgroundTasks else { return }
        didRegisterBackgroundTasks = true
        #if canImport(UIKit)
        LoobyTakerBackgroundRuntime.registerAll()
        #endif
    }

    public func scheduleBackgroundTasks() {
        #if canImport(UIKit)
        LoobyTakerBackgroundRuntime.scheduleAll()
        #endif
    }

    public func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        self.authorizationStatus = settings.authorizationStatus
    }

    @discardableResult
    public func requestPermissionIfNeeded(promptIfNotDetermined: Bool = true) async -> Bool {
        await refreshAuthorizationStatus()
        if authorizationStatus == .notDetermined && promptIfNotDetermined {
            do {
                let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                    options: [.alert, .sound, .badge]
                )
                await refreshAuthorizationStatus()
                if granted {
                    registerForRemoteNotificationsOnSystem()
                    await syncDeviceRegistration()
                }
                return granted
            } catch {
                return false
            }
        }
        if isOsAuthorized {
            registerForRemoteNotificationsOnSystem()
            await syncDeviceRegistration()
            return true
        }
        return false
    }

    public func registerForRemoteNotificationsOnSystem() {
        #if canImport(UIKit)
        UIApplication.shared.registerForRemoteNotifications()
        #endif
    }

    public func openSystemNotificationSettings() {
        #if canImport(UIKit)
        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
    }

    public func handleRegisteredDeviceToken(_ deviceToken: Data) {
        let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
        self.apnsDeviceTokenHex = hex
        defaults.set(hex, forKey: savedApnsTokenKey)
        Task {
            await syncDeviceRegistration()
        }
    }

    // MARK: - Identifiants Cachés & Purge Propre à la Déconnexion

    private var resolvedUserId: Int? {
        if let vm = attachedViewModel {
            guard vm.isAuthenticated, let u = vm.currentUser else { return nil }
            return u.id > 0 ? u.id : u.livriaId
        }
        let saved = defaults.integer(forKey: cachedUserIdKey)
        return saved > 0 ? saved : nil
    }

    private var resolvedEmail: String? {
        if let vm = attachedViewModel {
            guard vm.isAuthenticated, let u = vm.currentUser, !u.email.isEmpty else { return nil }
            return u.email
        }
        let em = defaults.string(forKey: cachedEmailKey) ?? ""
        return em.isEmpty ? nil : em
    }

    private var resolvedCid: String {
        if let vm = attachedViewModel, let u = vm.currentUser, !u.cid.isEmpty {
            return u.cid
        }
        return defaults.string(forKey: cachedCidKey) ?? ""
    }

    /// Purge immédiate des identifiants background et de toutes les notifications locales en attente ou délivrées.
    public func clearCachedUserStateAndNotificationsImmediately() {
        defaults.removeObject(forKey: cachedUserIdKey)
        defaults.removeObject(forKey: cachedEmailKey)
        defaults.removeObject(forKey: cachedCidKey)
        defaults.removeObject(forKey: pendingDeepLinkKey)
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    public func syncDeviceRegistration(user: TakerUserProfile? = nil, isExplicitLogin: Bool = false) async {
        let targetEmail = (user?.email ?? resolvedEmail ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let targetUid = user?.id ?? resolvedUserId ?? 0
        let targetCid = user?.cid ?? resolvedCid
        let targetDisplayName = user?.displayName ?? attachedViewModel?.currentUser?.displayName ?? ""

        guard !targetEmail.isEmpty else {
            defaults.removeObject(forKey: cachedUserIdKey)
            defaults.removeObject(forKey: cachedEmailKey)
            defaults.removeObject(forKey: cachedCidKey)
            return
        }

        let previousEmail = (defaults.string(forKey: cachedEmailKey) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !previousEmail.isEmpty && previousEmail.lowercased() != targetEmail.lowercased() {
            let center = UNUserNotificationCenter.current()
            center.removeAllPendingNotificationRequests()
            center.removeAllDeliveredNotifications()
            defaults.removeObject(forKey: seenNotificationIdsKey)
        }

        if targetUid > 0 {
            defaults.set(targetUid, forKey: cachedUserIdKey)
        }
        defaults.set(targetEmail, forKey: cachedEmailKey)
        if !targetCid.isEmpty {
            defaults.set(targetCid, forKey: cachedCidKey)
        }

        let revoked = await LoobyTakerAPIClient.shared.registerPushDevice(
            userId: max(targetUid, 1),
            email: targetEmail,
            cid: targetCid,
            displayName: targetDisplayName,
            apnsToken: apnsDeviceTokenHex,
            notificationsEnabled: notificationsEnabled,
            isExplicitLogin: isExplicitLogin
        )

        if revoked && !isExplicitLogin {
            await executeRemoteSessionRevocation()
        }
    }

    /// Déconnexion propre : purge immédiate des notifications locales + `unregisterPushDevice` avant effacement du compte.
    public func handleCleanSignOut(userId: Int?, email: String?, cid: String?) async {
        stopForegroundPollingLoop()
        clearCachedUserStateAndNotificationsImmediately()
        try? await UNUserNotificationCenter.current().setBadgeCount(0)
        await LoobyTakerAPIClient.shared.unregisterPushDevice(
            userId: userId,
            email: email,
            cid: cid
        )
    }

    public func executeRemoteSessionRevocation() async {
        stopForegroundPollingLoop()
        clearCachedUserStateAndNotificationsImmediately()
        try? await UNUserNotificationCenter.current().setBadgeCount(0)
        attachedViewModel?.handleRemoteSessionRevocation()
    }

    // MARK: - Cycle de Vie Scène & Polling

    public func enterForegroundMode() {
        endBackgroundGraceTask()
        startForegroundPollingLoop()
        Task {
            try? await UNUserNotificationCenter.current().setBadgeCount(0)
            await refreshAuthorizationStatus()
            if attachedViewModel?.isAuthenticated == true && authorizationStatus == .notDetermined {
                _ = await requestPermissionIfNeeded(promptIfNotDetermined: true)
            } else if isOsAuthorized {
                registerForRemoteNotificationsOnSystem()
                await syncDeviceRegistration()
            } else {
                await syncDeviceRegistration()
            }
            consumePendingDeepLinkIfNeeded()
        }
    }

    public func handleSceneBecameInactive() {
        scheduleBackgroundTasks()
    }

    public func enterBackgroundMode() {
        stopForegroundPollingLoop()
        scheduleBackgroundTasks()
        startBackgroundGracePoll()
    }

    private func startForegroundPollingLoop() {
        foregroundLoopTask?.cancel()
        foregroundLoopTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 8_000_000_000)
            while !Task.isCancelled {
                guard let self else { return }
                _ = await self.performNotificationPollCycle(isBackground: false)
                try? await Task.sleep(nanoseconds: 150_000_000_000)
            }
        }
    }

    private func stopForegroundPollingLoop() {
        foregroundLoopTask?.cancel()
        foregroundLoopTask = nil
    }

    private func startBackgroundGracePoll() {
        #if canImport(UIKit)
        endBackgroundGraceTask()
        backgroundGraceTaskId = UIApplication.shared.beginBackgroundTask(withName: "LoobyTakerNotifSync") { [weak self] in
            Task { @MainActor in
                self?.endBackgroundGraceTask()
            }
        }
        Task { [weak self] in
            guard let self else { return }
            _ = await self.performNotificationPollCycle(isBackground: true)
            self.endBackgroundGraceTask()
        }
        #endif
    }

    private func endBackgroundGraceTask() {
        #if canImport(UIKit)
        if backgroundGraceTaskId != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundGraceTaskId)
            backgroundGraceTaskId = .invalid
        }
        #endif
    }

    private var seenNotificationIds: [String] {
        defaults.stringArray(forKey: seenNotificationIdsKey) ?? []
    }

    private func appendSeenNotificationIds(_ ids: [String]) {
        guard !ids.isEmpty else { return }
        var current = seenNotificationIds
        for id in ids where !id.isEmpty && !current.contains(id) {
            current.append(id)
        }
        if current.count > 250 {
            current = Array(current.suffix(250))
        }
        defaults.set(current, forKey: seenNotificationIdsKey)
    }

    public func markNotificationSeenAndAck(_ notificationId: String) {
        guard !notificationId.isEmpty else { return }
        appendSeenNotificationIds([notificationId])
        let uid = resolvedUserId
        let em = resolvedEmail ?? ""
        guard !em.isEmpty else { return }
        Task {
            await LoobyTakerAPIClient.shared.ackNotifications(
                notificationIds: [notificationId],
                userId: uid,
                email: em
            )
        }
    }

    @discardableResult
    public func performNotificationPollCycle(isBackground: Bool) async -> Bool {
        guard !isPollInFlight else { return false }
        guard let pollEmail = resolvedEmail, !pollEmail.isEmpty else { return false }
        let pollUid = resolvedUserId
        let pollCid = resolvedCid

        isPollInFlight = true
        defer { isPollInFlight = false }

        do {
            let poll = try await LoobyTakerAPIClient.shared.pollNotifications(
                userId: pollUid,
                email: pollEmail,
                cid: pollCid,
                limit: 25,
                fastBackground: isBackground
            )
            self.lastSyncDate = Date()

            if poll.sessionRevoked {
                await executeRemoteSessionRevocation()
                return false
            }

            guard let activeEmail = resolvedEmail,
                  activeEmail.lowercased() == pollEmail.lowercased() else {
                return false
            }

            attachedViewModel?.notificationInbox = poll.recent

            guard notificationsEnabled else {
                if !poll.unseen.isEmpty {
                    await LoobyTakerAPIClient.shared.ackNotifications(
                        notificationIds: poll.unseen.map(\.id),
                        userId: pollUid,
                        email: pollEmail
                    )
                }
                return true
            }

            await refreshAuthorizationStatus()
            let seenSet = Set(seenNotificationIds)
            var deliveredIds: [String] = []

            for item in poll.unseen.prefix(3) {
                if seenSet.contains(item.id) {
                    deliveredIds.append(item.id)
                    continue
                }
                if isOsAuthorized {
                    let scheduled = await scheduleLocalBanner(for: item)
                    if scheduled {
                        appendSeenNotificationIds([item.id])
                        deliveredIds.append(item.id)
                    }
                }
            }

            if !deliveredIds.isEmpty {
                await LoobyTakerAPIClient.shared.ackNotifications(
                    notificationIds: deliveredIds,
                    userId: pollUid,
                    email: pollEmail
                )
            }
            return true
        } catch {
            return false
        }
    }

    private func scheduleLocalBanner(for item: TakerNotificationItem) async -> Bool {
        let content = UNMutableNotificationContent()
        content.title = item.title
        if !item.subtitle.isEmpty {
            content.subtitle = item.subtitle
        }
        content.body = item.body
        content.sound = .default
        content.categoryIdentifier = Self.categoryIdentifier
        content.threadIdentifier = "looby-taker"
        content.userInfo = [
            "notificationId": item.id,
            "deepLink": item.deepLink,
            "parcelBarcode": item.parcelBarcode ?? ""
        ]

        let req = UNNotificationRequest(
            identifier: "loobytaker.notif.\(item.id)",
            content: content,
            trigger: nil
        )
        do {
            try await UNUserNotificationCenter.current().add(req)
            return true
        } catch {
            return false
        }
    }

    public func consumePendingDeepLinkIfNeeded() {
        guard let vm = attachedViewModel, vm.isAuthenticated else { return }
        if let raw = defaults.string(forKey: pendingDeepLinkKey),
           !raw.isEmpty,
           let url = URL(string: raw) {
            defaults.removeObject(forKey: pendingDeepLinkKey)
            vm.handleIncomingURL(url)
        }
    }

    // MARK: - UNUserNotificationCenterDelegate (Strict Swift 6 `nonisolated` sans capture non-Sendable)

    nonisolated public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        let notifId = (notification.request.content.userInfo["notificationId"] as? String) ?? ""
        return await MainActor.run {
            guard let activeEmail = self.resolvedEmail, !activeEmail.isEmpty else {
                return []
            }
            if !notifId.isEmpty {
                self.markNotificationSeenAndAck(notifId)
            }
            guard self.notificationsEnabled else { return [] }
            return [.banner, .list, .sound, .badge]
        }
    }

    nonisolated public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let actionId = response.actionIdentifier
        let userInfo = response.notification.request.content.userInfo
        let notifId = (userInfo["notificationId"] as? String) ?? ""
        let deepLink = (userInfo["deepLink"] as? String) ?? ""
        let barcode = (userInfo["parcelBarcode"] as? String) ?? ""

        await MainActor.run {
            if !notifId.isEmpty {
                self.markNotificationSeenAndAck(notifId)
            }
            if actionId == Self.actionOpenScanner {
                self.attachedViewModel?.selectedTab = .scanner
                return
            }
            if actionId == Self.actionOpenParcels || !barcode.isEmpty {
                self.attachedViewModel?.selectedTab = .parcels
                return
            }
            if !deepLink.isEmpty, let url = URL(string: deepLink) {
                if let vm = self.attachedViewModel, vm.isAuthenticated {
                    vm.handleIncomingURL(url)
                } else {
                    self.defaults.set(deepLink, forKey: self.pendingDeepLinkKey)
                }
            }
        }
    }
}
