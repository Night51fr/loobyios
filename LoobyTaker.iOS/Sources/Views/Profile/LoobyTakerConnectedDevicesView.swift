import SwiftUI

// MARK: - Gestionnaire Centralisé des Appareils Connectés Viple Live ID (`LoobyTakerConnectedDevicesView.swift` • Swift 6)

public struct LoobyTakerConnectedDevicesView: View {
    @EnvironmentObject private var vm: LoobyTakerViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var pendingRevokeTarget: PendingRevokeTarget? = nil
    @State private var revokingDeviceId: String? = nil

    private struct PendingRevokeTarget: Identifiable, Equatable, Sendable {
        let device: TakerConnectedDevice
        let appBadge: TakerConnectedAppBadge?

        var id: String {
            "\(device.deviceId)-\(appBadge?.appId ?? "*")"
        }
    }

    public init() {}

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                hardwareHeroCard

                if vm.isLoadingConnectedDevices && vm.connectedDevices.isEmpty {
                    VStack(spacing: 12) {
                        ProgressView().tint(LoobyTakerPalette.amberPrimary)
                        Text("Synchronisation des sessions de l'écosystème Viple…")
                            .font(.system(size: 13.5, weight: .bold, design: .rounded))
                            .foregroundStyle(LoobyTakerPalette.inkSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .loobyTakerCard()
                } else {
                    ForEach(vm.connectedDevices) { device in
                        deviceCard(device)
                    }
                }

                securityFooterCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .loobyTakerScreenBackground()
        .navigationTitle("Appareils connectés")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await vm.loadConnectedDevices() }
                } label: {
                    if vm.isLoadingConnectedDevices {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .bold))
                    }
                }
            }
        }
        .refreshable {
            await vm.loadConnectedDevices()
        }
        .task {
            await vm.loadConnectedDevices()
        }
        .alert(
            revokeTitle,
            isPresented: Binding(
                get: { pendingRevokeTarget != nil },
                set: { if !$0 { pendingRevokeTarget = nil } }
            ),
            presenting: pendingRevokeTarget
        ) { target in
            Button("Annuler", role: .cancel) {
                pendingRevokeTarget = nil
            }
            Button("Déconnecter maintenant", role: .destructive) {
                let captured = target
                pendingRevokeTarget = nil
                Task {
                    revokingDeviceId = captured.device.deviceId
                    let targetApp = captured.appBadge?.appId ?? "*"
                    _ = await vm.revokeDeviceSession(device: captured.device, targetAppId: targetApp)
                    revokingDeviceId = nil
                    if !vm.isAuthenticated {
                        dismiss()
                    }
                }
            }
        } message: { target in
            if let app = target.appBadge {
                Text("\(target.device.displayModelName) sera immédiatement déconnecté de \(app.appName) et ses notifications push pour cette application seront coupées.")
            } else {
                Text("\(target.device.displayModelName) sera déconnecté de Viple Mail, Livria Store, Livria Social, Cenelis Academy et Looby Taker.")
            }
        }
    }

    private var revokeTitle: String {
        guard let target = pendingRevokeTarget else { return "Déconnecter" }
        if let app = target.appBadge {
            return "Déconnecter de \(app.appName) ?"
        }
        return "Déconnecter \(target.device.displayModelName) ?"
    }

    // MARK: - 1. En-tête Modèle Matériel `uname` & Version iOS

    private var hardwareHeroCard: some View {
        let api = LoobyTakerAPIClient.shared
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(Color.white.opacity(0.20))
                        .frame(width: 50, height: 50)
                    Image(systemName: "laptopcomputer.and.iphone")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("SÉCURITÉ ÉCOSYSTÈME VIPLE LIVE ID")
                        .font(.system(size: 10.5, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.88))
                    Text("Vos appareils & applications connectées")
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Retrouvez Viple Mail, Livria Store, Livria Social, Cenelis Academy et Looby Taker — même lorsque les applications sont fermées — et révoquez tout appareil en 1 tap.")
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(.white.opacity(0.92))
                }
            }

            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "iphone.gen3")
                        .foregroundStyle(.white)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(api.resolvedHardwareModelName)
                            .font(.system(size: 12.5, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("\(api.resolvedHardwareModelCode) • \(api.resolvedOsVersion)")
                            .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    Spacer(minLength: 0)
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 13).fill(Color.white.opacity(0.16)))
            }
        }
        .padding(18)
        .background(
            LoobyTakerHeroBackground(isProStyle: true)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        )
    }

    // MARK: - 2. Carte d'Appareil & Liste des Applications Connectées

    private func deviceCard(_ device: TakerConnectedDevice) -> some View {
        let isBusy = revokingDeviceId == device.deviceId
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(device.isCurrentDevice ? AnyShapeStyle(LoobyTakerPalette.signatureGradient) : AnyShapeStyle(LoobyTakerPalette.cardSubtle))
                        .frame(width: 48, height: 48)
                    Image(systemName: device.systemSymbolName)
                        .font(.system(size: 21, weight: .bold))
                        .foregroundStyle(device.isCurrentDevice ? .white : LoobyTakerPalette.amberPrimary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 7) {
                        Text(device.displayModelName)
                            .font(.system(size: 16.5, weight: .black, design: .rounded))
                            .foregroundStyle(LoobyTakerPalette.ink)

                        if device.isCurrentDevice {
                            Text("Cet iPhone")
                                .font(.system(size: 10.5, weight: .black, design: .rounded))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(LoobyTakerPalette.emerald))
                                .foregroundStyle(.white)
                        }
                    }

                    HStack(spacing: 8) {
                        Text(device.displayOsLabel)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(LoobyTakerPalette.proCobalt)
                        if !device.modelCode.isEmpty {
                            Text("• \(device.modelCode)")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(LoobyTakerPalette.inkMuted)
                        }
                    }

                    HStack(spacing: 8) {
                        Label(device.lastActivityLabelFr, systemImage: "clock.fill")
                            .font(.system(size: 11.5))
                            .foregroundStyle(LoobyTakerPalette.inkSecondary)

                        if device.pushActive {
                            Label("Push APNs actif", systemImage: "bell.badge.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(LoobyTakerPalette.emerald)
                        }
                    }
                }
                Spacer(minLength: 0)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Applications connectées (\(device.connectedApps.count))")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(LoobyTakerPalette.inkSecondary)
                    Spacer()
                    Text("Même fermées")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundStyle(LoobyTakerPalette.amberPrimary)
                }

                ForEach(device.connectedApps) { app in
                    let appColor = Self.hexColor(app.colorHex)
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(appColor.opacity(0.15))
                                .frame(width: 34, height: 34)
                            Image(systemName: app.icon)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(appColor)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 5) {
                                Text(app.appName)
                                    .font(.system(size: 13.5, weight: .bold, design: .rounded))
                                    .foregroundStyle(LoobyTakerPalette.ink)
                                if !app.appVersion.isEmpty {
                                    Text("v\(app.appVersion)")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundStyle(appColor)
                                }
                            }
                            if !app.accountEmail.isEmpty {
                                Text(app.accountEmail)
                                    .font(.system(size: 11))
                                    .foregroundStyle(LoobyTakerPalette.inkSecondary)
                            }
                        }

                        Spacer()

                        Button {
                            pendingRevokeTarget = PendingRevokeTarget(device: device, appBadge: app)
                        } label: {
                            Text("Déconnecter")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(LoobyTakerPalette.danger.opacity(0.11)))
                                .foregroundStyle(LoobyTakerPalette.danger)
                        }
                        .buttonStyle(.plain)
                        .disabled(isBusy)
                    }
                    .padding(9)
                    .background(RoundedRectangle(cornerRadius: 12).fill(LoobyTakerPalette.cardSubtle))
                }
            }

            Button(role: .destructive) {
                pendingRevokeTarget = PendingRevokeTarget(device: device, appBadge: nil)
            } label: {
                HStack(spacing: 8) {
                    if isBusy {
                        ProgressView().tint(LoobyTakerPalette.danger)
                    } else {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                    }
                    Text(
                        device.isCurrentDevice
                            ? "Déconnecter cet iPhone de tout l'écosystème"
                            : "Déconnecter \(device.displayModelName) en 1 tap"
                    )
                    .font(.system(size: 13.5, weight: .black, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 13).fill(LoobyTakerPalette.danger.opacity(0.12)))
                .foregroundStyle(LoobyTakerPalette.danger)
            }
            .disabled(isBusy)
        }
        .loobyTakerCard()
    }

    private var securityFooterCard: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(LoobyTakerPalette.emerald)
            VStack(alignment: .leading, spacing: 3) {
                Text("Isolation stricte des notifications APNs")
                    .font(.system(size: 13.5, weight: .black, design: .rounded))
                    .foregroundStyle(LoobyTakerPalette.ink)
                Text("Dès qu'un appareil ou une application est déconnecté, son jeton APNs est immédiatement révoqué : aucune notification ne peut être reçue pour un compte déconnecté.")
                    .font(.system(size: 12))
                    .foregroundStyle(LoobyTakerPalette.inkSecondary)
            }
        }
        .loobyTakerCard(padding: 14)
    }

    private static func hexColor(_ hex: String) -> Color {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard clean.count == 6, let val = UInt64(clean, radix: 16) else {
            return LoobyTakerPalette.amberPrimary
        }
        let r = Double((val >> 16) & 0xFF) / 255.0
        let g = Double((val >> 8) & 0xFF) / 255.0
        let b = Double(val & 0xFF) / 255.0
        return Color(red: r, green: g, blue: b)
    }
}
