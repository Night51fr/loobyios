import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Point d'Entrée Natif `@main` de « Looby Taker » (`fr.looby.taker` • iOS 18+ • Swift 6)

#if canImport(UIKit)
@MainActor
public final class LoobyTakerAppDelegate: NSObject, UIApplicationDelegate {
    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        LoobyTakerNotificationManager.shared.configureOnLaunch()
        return true
    }

    public func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        LoobyTakerNotificationManager.shared.handleRegisteredDeviceToken(deviceToken)
    }

    public func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        LoobyTakerNotificationManager.shared.scheduleBackgroundTasks()
    }

    public func application(
        _ application: UIApplication,
        performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        let box = LoobyTakerRemoteFetchBox(completionHandler)
        Task { @MainActor in
            LoobyTakerNotificationManager.shared.scheduleBackgroundTasks()
            let ok = await LoobyTakerNotificationManager.shared.performNotificationPollCycle(isBackground: true)
            box.complete(ok ? .newData : .noData)
        }
    }

    public func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        let remoteNotifId = (userInfo["notificationId"] as? String) ?? ""
        let box = LoobyTakerRemoteFetchBox(completionHandler)
        Task { @MainActor in
            if !remoteNotifId.isEmpty {
                LoobyTakerNotificationManager.shared.markNotificationSeenAndAck(remoteNotifId)
            }
            LoobyTakerNotificationManager.shared.scheduleBackgroundTasks()
            let ok = await LoobyTakerNotificationManager.shared.performNotificationPollCycle(isBackground: true)
            box.complete(ok ? .newData : .noData)
        }
    }
}
#endif

@main
public struct LoobyTakerApp: App {
    #if canImport(UIKit)
    @UIApplicationDelegateAdaptor(LoobyTakerAppDelegate.self) private var appDelegate
    #endif

    @StateObject private var vm = LoobyTakerViewModel()
    @StateObject private var notifManager = LoobyTakerNotificationManager.shared
    @Environment(\.scenePhase) private var scenePhase

    public init() {}

    public var body: some Scene {
        WindowGroup {
            ZStack {
                if !vm.hasCompletedLaunchIntro {
                    LoobyTakerLaunchAnimationView {
                        withAnimation(.easeInOut(duration: 0.42)) {
                            vm.hasCompletedLaunchIntro = true
                        }
                    }
                    .transition(.opacity)
                } else if vm.isAuthenticated {
                    LoobyTakerMainView()
                        .transition(.opacity)
                } else {
                    LoobyTakerAuthView()
                        .transition(.opacity)
                }
            }
            .overlay(alignment: .top) {
                if let toast = vm.activeToast {
                    LoobyTakerToastOverlayView(toast: toast) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            vm.activeToast = nil
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(999)
                }
            }
            .environmentObject(vm)
            .environmentObject(notifManager)
            .tint(LoobyTakerPalette.amberPrimary)
            .preferredColorScheme(vm.appearanceMode.colorScheme)
            .task {
                notifManager.attachedViewModel = vm
                await vm.onInitialLaunchReady()
            }
            .onOpenURL { url in
                vm.handleIncomingURL(url)
            }
            .onAppear {
                notifManager.attachedViewModel = vm
                if scenePhase != .background {
                    notifManager.enterForegroundMode()
                } else {
                    notifManager.scheduleBackgroundTasks()
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                switch newPhase {
                case .active:
                    notifManager.attachedViewModel = vm
                    notifManager.enterForegroundMode()
                case .inactive:
                    notifManager.handleSceneBecameInactive()
                case .background:
                    notifManager.enterBackgroundMode()
                @unknown default:
                    break
                }
            }
        }
    }
}

// MARK: - Bannière Toast Flottante

public struct LoobyTakerToastOverlayView: View {
    public let toast: TakerToastBanner
    public let onDismiss: () -> Void

    private var iconName: String {
        switch toast.style {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        case .info: return "sparkles"
        }
    }

    private var accentColor: Color {
        switch toast.style {
        case .success: return LoobyTakerPalette.emerald
        case .warning: return LoobyTakerPalette.amberPrimary
        case .error: return LoobyTakerPalette.danger
        case .info: return LoobyTakerPalette.proCobalt
        }
    }

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(toast.title)
                    .font(.system(size: 13.5, weight: .black, design: .rounded))
                    .foregroundStyle(LoobyTakerPalette.ink)
                if !toast.subtitle.isEmpty {
                    Text(toast.subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(LoobyTakerPalette.inkSecondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 4)

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(LoobyTakerPalette.inkMuted)
                    .padding(6)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LoobyTakerPalette.cardSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accentColor.opacity(0.45), lineWidth: 1.4)
        )
        .shadow(color: Color.black.opacity(0.14), radius: 14, x: 0, y: 6)
    }
}
