import SwiftUI
import AVFoundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Onglet 2 : Scanner Caméra `AVCaptureSession` + Alerte UPS `1Z…` + Clavier PIN (`ParcelScannerView.swift` • Swift 6)

public struct ParcelScannerView: View {
    @EnvironmentObject private var vm: LoobyTakerViewModel

    @State private var manualBarcodeInput: String = ""
    @State private var shelfLocationInput: String = ""
    @State private var conditionNotesInput: String = ""
    @State private var isTorchEnabled: Bool = false
    @State private var cameraPermissionStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var isProcessingScan: Bool = false
    @State private var lastScannedTimestamp: Date = .distantPast
    @State private var laserAnimateDown: Bool = false

    public init() {}

    public var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                topPermanentHelpBanner

                modeSelectorCard

                cameraScannerViewportCard

                if vm.scannerMode == .receive {
                    receiveOptionsCard
                }

                manualAndSimulatorFallbackCard

                quickSelectParcelsCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 38)
        }
        .loobyTakerScreenBackground()
        .navigationTitle("Scanner & Remise")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            refreshCameraAuthorization()
        }
    }

    // MARK: - 1. Bouton d'Aide Permanent en Haut du Scanner

    private var topPermanentHelpBanner: some View {
        Button {
            vm.isShowingVisualScanGuide = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(LoobyTakerPalette.amberDeep)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Aide : quoi scanner ? (UPS / Viple Delivery)")
                        .font(.system(size: 13.5, weight: .black, design: .rounded))
                        .foregroundStyle(LoobyTakerPalette.amberDeep)
                    Text("Scannez toujours la 2e étiquette « Viple Delivery » (VD-…), jamais le 1Z… UPS.")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(LoobyTakerPalette.inkSecondary)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(LoobyTakerPalette.amberDeep)
            }
            .padding(13)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(LoobyTakerPalette.amberSoft))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(LoobyTakerPalette.amberPrimary.opacity(0.45), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 2. Sélecteur de Mode (Réceptionner / Remettre / Signaler anomalie)

    private var modeSelectorCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ForEach(TakerScannerOperationMode.allCases) { mode in
                    let isSelected = vm.scannerMode == mode
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                            vm.scannerMode = mode
                        }
                        LoobyTakerHaptics.impact(0)
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: mode.iconName)
                                .font(.system(size: 15, weight: .bold))
                            Text(mode.titleFr)
                                .font(.system(size: 11.5, weight: .black, design: .rounded))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(isSelected ? LoobyTakerPalette.amberPrimary : LoobyTakerPalette.cardSubtle)
                        )
                        .foregroundStyle(isSelected ? .white : LoobyTakerPalette.inkSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 8) {
                Image(systemName: vm.scannerMode == .handover ? (vm.isProMode ? "bolt.checkmark.fill" : "key.fill") : "sparkles")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(vm.scannerMode == .handover ? LoobyTakerPalette.emerald : LoobyTakerPalette.amberPrimary)

                Text(
                    vm.scannerMode == .handover
                        ? (vm.isProMode
                            ? "Mode Relais Pro : remise validée immédiatement sans aucun code PIN !"
                            : "Mode Relais Particulier : le clavier Code PIN à 6 chiffres s'ouvrira après le scan (+1,00 €).")
                        : vm.scannerMode.subtitleFr
                )
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(LoobyTakerPalette.inkSecondary)
            }
        }
        .loobyTakerCard(padding: 13)
    }

    // MARK: - 3. Viseur Caméra `AVCaptureSession` + Cadre Laser Doré Animé + Lampe Torche

    private var cameraScannerViewportCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.black)
                .frame(height: 256)

            #if canImport(UIKit)
            if !LoobyTakerDeviceIdentity.isSimulator && cameraPermissionStatus == .authorized {
                LoobyTakerCameraPreview(
                    isTorchOn: isTorchEnabled,
                    isPaused: isProcessingScan || vm.upsPedagogicalWarning != nil || vm.pendingHandoverParcelForPin != nil
                ) { detectedCode in
                    let now = Date()
                    guard now.timeIntervalSince(lastScannedTimestamp) > 1.8 else { return }
                    lastScannedTimestamp = now
                    Task {
                        await triggerCodeHandling(detectedCode)
                    }
                }
                .frame(height: 256)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            } else {
                cameraFallbackBackdrop
            }
            #else
            cameraFallbackBackdrop
            #endif

            // Cadre de visée doré + ligne laser animée
            VStack {
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(isProcessingScan ? Color.orange : LoobyTakerPalette.emerald)
                            .frame(width: 8, height: 8)
                        Text(isProcessingScan ? "Analyse de l'étiquette…" : "2e étiquette VD-… prête à scanner")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.black.opacity(0.58)))

                    Spacer()

                    Button {
                        isTorchEnabled.toggle()
                        LoobyTakerHaptics.impact(0)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isTorchEnabled ? "flashlight.on.fill" : "flashlight.off.fill")
                                .font(.system(size: 13, weight: .bold))
                            Text(isTorchEnabled ? "Torche ON" : "Torche")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(isTorchEnabled ? LoobyTakerPalette.goldBright : Color.black.opacity(0.58)))
                        .foregroundStyle(isTorchEnabled ? .black : .white)
                    }
                    .buttonStyle(.plain)
                }
                .padding(14)

                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(
                            LoobyTakerPalette.signatureGradient,
                            style: StrokeStyle(lineWidth: 2.6, dash: [18, 8])
                        )
                        .frame(width: 245, height: 118)

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    LoobyTakerPalette.goldBright.opacity(0.15),
                                    LoobyTakerPalette.goldBright,
                                    LoobyTakerPalette.coralGlow,
                                    LoobyTakerPalette.goldBright.opacity(0.15)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 225, height: 2.5)
                        .shadow(color: LoobyTakerPalette.goldBright, radius: 6)
                        .offset(y: laserAnimateDown ? 44 : -44)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.65).repeatForever(autoreverses: true)) {
                                laserAnimateDown = true
                            }
                        }
                }

                Spacer()

                Text(" Visez le code-barres ou QR de la 2e étiquette Viple Delivery ")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.90))
                    .padding(.bottom, 12)
            }
            .frame(height: 256)
        }
    }

    private var cameraFallbackBackdrop: some View {
        VStack(spacing: 10) {
            Image(systemName: LoobyTakerDeviceIdentity.isSimulator ? "iphone.gen3.radiowaves.left.and.right" : "camera.viewfinder")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(LoobyTakerPalette.goldBright)

            if LoobyTakerDeviceIdentity.isSimulator {
                Text("Mode Simulateur iOS actif")
                    .font(.system(size: 13.5, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Utilisez la saisie rapide VD-… ci-dessous ou testez un scan UPS 1Z… en 1 tap.")
                    .font(.system(size: 11.5))
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            } else if cameraPermissionStatus == .denied || cameraPermissionStatus == .restricted {
                Text("Accès caméra désactivé dans Réglages")
                    .font(.system(size: 13.5, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Button("Ouvrir les Réglages iOS") {
                    #if canImport(UIKit)
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                    #endif
                }
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(LoobyTakerPalette.goldBright))
                .foregroundStyle(.black)
            }
        }
        .frame(height: 256)
    }

    // MARK: - 4. Options Contextuelles de Réception (Étagère / État)

    private var receiveOptionsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Options de rangement à la réception (facultatif)")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(LoobyTakerPalette.ink)

            HStack(spacing: 10) {
                TextField("Emplacement (ex: Étagère A2)", text: $shelfLocationInput)
                    .font(.system(size: 13))
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(LoobyTakerPalette.cardSubtle))

                TextField("Note d'état (ex: RAS)", text: $conditionNotesInput)
                    .font(.system(size: 13))
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(LoobyTakerPalette.cardSubtle))
            }
        }
        .loobyTakerCard(padding: 13)
    }

    // MARK: - 5. Saisie Manuelle `VD-…` & Simulation Pédagogique UPS `1Z…`

    private var manualAndSimulatorFallbackCard: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Label("Saisie manuelle du code-barres", systemImage: "keyboard.fill")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundStyle(LoobyTakerPalette.ink)
                Spacer()
                Button("Tester scan UPS 1Z…") {
                    let sampleUps = vm.parcels.first(where: { !$0.carrierTrackingNumber.isEmpty })?.carrierTrackingNumber
                        ?? "1Z999AA10123456784"
                    Task {
                        await triggerCodeHandling(sampleUps)
                    }
                }
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Capsule().fill(LoobyTakerPalette.coralSoft))
                .foregroundStyle(LoobyTakerPalette.coralGlow)
            }

            HStack(spacing: 10) {
                TextField("Ex : VD-2026-84920", text: $manualBarcodeInput)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled(true)
                    .font(.system(size: 14.5, weight: .bold, design: .monospaced))
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(LoobyTakerPalette.cardSubtle))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(LoobyTakerPalette.border, lineWidth: 1))

                Button {
                    let code = manualBarcodeInput
                    Task {
                        await triggerCodeHandling(code)
                        if !LoobyTakerViewModel.isUpsTrackingBarcode(code) {
                            manualBarcodeInput = ""
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        if isProcessingScan {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text("Valider")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(LoobyTakerPalette.goldCoralHorizontal)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(manualBarcodeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessingScan)
            }
        }
        .loobyTakerCard(padding: 14)
    }

    // MARK: - 6. Sélection Rapide d'un Colis Attendu / En Stock

    private var quickSelectParcelsCard: some View {
        let candidateParcels = vm.scannerMode == .receive ? vm.expectedParcels : vm.inStockParcels
        return VStack(alignment: .leading, spacing: 10) {
            Text(
                vm.scannerMode == .receive
                    ? "Colis attendus prêts à réceptionner (\(candidateParcels.count))"
                    : "Colis en stock prêts pour ce mode (\(candidateParcels.count))"
            )
            .font(.system(size: 14, weight: .black, design: .rounded))
            .foregroundStyle(LoobyTakerPalette.ink)

            if candidateParcels.isEmpty {
                Text("Aucun colis dans cette file actuellement. Vous pouvez scanner directement toute nouvelle étiquette VD-….")
                    .font(.system(size: 12))
                    .foregroundStyle(LoobyTakerPalette.inkSecondary)
            } else {
                ForEach(candidateParcels.prefix(5)) { p in
                    HStack(spacing: 10) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(p.vipleBarcode)
                                .font(.system(size: 13, weight: .black, design: .monospaced))
                                .foregroundStyle(LoobyTakerPalette.amberDeep)
                            Text("\(p.recipientName) • \(p.carrier)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(LoobyTakerPalette.inkSecondary)
                        }
                        Spacer()
                        Button {
                            Task {
                                await triggerCodeHandling(p.vipleBarcode)
                            }
                        } label: {
                            Text(vm.scannerMode == .receive ? "Réceptionner" : (vm.scannerMode == .handover ? "Remettre" : "Signaler"))
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Capsule().fill(LoobyTakerPalette.amberSoft))
                                .foregroundStyle(LoobyTakerPalette.amberDeep)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(LoobyTakerPalette.cardSubtle))
                }
            }
        }
        .loobyTakerCard(padding: 14)
    }

    // MARK: - Helpers Caméra & Exécution

    private func refreshCameraAuthorization() {
        let current = AVCaptureDevice.authorizationStatus(for: .video)
        cameraPermissionStatus = current
        if current == .notDetermined {
            Task { @MainActor in
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                cameraPermissionStatus = granted ? .authorized : .denied
            }
        }
    }

    private func triggerCodeHandling(_ code: String) async {
        guard !isProcessingScan else { return }
        isProcessingScan = true
        defer { isProcessingScan = false }
        await vm.handleScannedCode(
            code,
            mode: vm.scannerMode,
            shelfLocation: shelfLocationInput,
            conditionNotes: conditionNotesInput
        )
    }
}

// MARK: - `UIViewRepresentable` `AVCaptureSession` Strictement Conforme Swift 6

#if canImport(UIKit)
public final class ScannerPreviewUIView: UIView {
    public override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    public var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

/// Coordinateur `nonisolated` de niveau fichier afin d'éviter tout héritage `@MainActor` de `UIViewRepresentable` en Swift 6.
public final class LoobyTakerScannerCoordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate, @unchecked Sendable {
    @MainActor public var onCodeScanned: @MainActor @Sendable (String) -> Void
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "fr.looby.taker.camera.session")
    private let stateLock = NSLock()
    private var isConfigured = false
    private var pausedFlag = false

    @MainActor
    public init(onCodeScanned: @escaping @MainActor @Sendable (String) -> Void) {
        self.onCodeScanned = onCodeScanned
        super.init()
    }

    @MainActor
    public func attach(to previewView: ScannerPreviewUIView) {
        previewView.videoPreviewLayer.session = session
        sessionQueue.async { [weak self] in
            self?.configureAndStartOnQueue()
        }
    }

    private nonisolated func configureAndStartOnQueue() {
        stateLock.lock()
        let alreadyConfigured = isConfigured
        if !alreadyConfigured { isConfigured = true }
        stateLock.unlock()

        if !alreadyConfigured {
            session.beginConfiguration()
            if let videoDevice = AVCaptureDevice.default(for: .video),
               let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
               session.canAddInput(videoInput) {
                session.addInput(videoInput)
            }

            let metadataOutput = AVCaptureMetadataOutput()
            if session.canAddOutput(metadataOutput) {
                session.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)

                let desiredTypes: [AVMetadataObject.ObjectType] = [
                    .qr, .code128, .code39, .code93, .ean13, .ean8, .pdf417, .dataMatrix, .aztec, .itf14
                ]
                let supported = Set(metadataOutput.availableMetadataObjectTypes)
                metadataOutput.metadataObjectTypes = desiredTypes.filter { supported.contains($0) }
            }
            session.commitConfiguration()
        }

        if !session.isRunning {
            session.startRunning()
        }
    }

    public nonisolated func updateState(isTorchOn: Bool, isPaused: Bool) {
        stateLock.lock()
        pausedFlag = isPaused
        stateLock.unlock()

        sessionQueue.async {
            guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
            do {
                try device.lockForConfiguration()
                device.torchMode = isTorchOn ? .on : .off
                device.unlockForConfiguration()
            } catch {}
        }
    }

    public nonisolated func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
    }

    nonisolated public func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        stateLock.lock()
        let isCurrentlyPaused = pausedFlag
        stateLock.unlock()
        guard !isCurrentlyPaused else { return }

        guard let readable = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let stringValue = readable.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines),
              !stringValue.isEmpty else {
            return
        }

        Task { @MainActor [weak self] in
            self?.onCodeScanned(stringValue)
        }
    }
}

public struct LoobyTakerCameraPreview: UIViewRepresentable {
    public var isTorchOn: Bool
    public var isPaused: Bool
    public var onCodeScanned: @MainActor @Sendable (String) -> Void

    public func makeCoordinator() -> LoobyTakerScannerCoordinator {
        LoobyTakerScannerCoordinator(onCodeScanned: onCodeScanned)
    }

    public func makeUIView(context: Context) -> ScannerPreviewUIView {
        let view = ScannerPreviewUIView()
        view.backgroundColor = .black
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        context.coordinator.attach(to: view)
        return view
    }

    public func updateUIView(_ uiView: ScannerPreviewUIView, context: Context) {
        context.coordinator.onCodeScanned = onCodeScanned
        context.coordinator.updateState(isTorchOn: isTorchOn, isPaused: isPaused)
    }

    public static func dismantleUIView(_ uiView: ScannerPreviewUIView, coordinator: LoobyTakerScannerCoordinator) {
        coordinator.stopSession()
    }
}
#endif

// MARK: - Modale Pédagogique Intelligente UPS (`1Z...`) -> 2e Étiquette Viple Delivery (`VD-...`)

public struct UpsPedagogicalAlertSheet: View {
    @EnvironmentObject private var vm: LoobyTakerViewModel
    @Environment(\.dismiss) private var dismiss

    public let warning: UpsBarcodePedagogicalWarning
    @State private var isSwitchingToMatched: Bool = false

    public init(warning: UpsBarcodePedagogicalWarning) {
        self.warning = warning
    }

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    // Alerte principale
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundStyle(.white)
                            Text(warning.title)
                                .font(.system(size: 19, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                        }

                        Text("Vous avez scanné la 1re étiquette UPS (\(warning.scannedUpsCode)). Scannez la **2e étiquette Viple Delivery** (`VD-…`) collée sur le colis !")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.95))
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.84, green: 0.36, blue: 0.08), Color(red: 0.86, green: 0.20, blue: 0.22)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    )

                    // Schéma comparatif express sur le carton
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Repérez la bonne étiquette sur le carton :")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(LoobyTakerPalette.ink)

                        HStack(spacing: 12) {
                            // Étiquette 1 UPS barrée
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("ÉTIQUETTE 1 • UPS")
                                        .font(.system(size: 10, weight: .black, design: .rounded))
                                        .foregroundStyle(LoobyTakerPalette.danger)
                                    Spacer()
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(LoobyTakerPalette.danger)
                                }
                                Text(warning.scannedUpsCode)
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .strikethrough(true, color: LoobyTakerPalette.danger)
                                    .foregroundStyle(LoobyTakerPalette.inkMuted)
                                    .lineLimit(1)
                                Text("Routage chauffeur UPS uniquement")
                                    .font(.system(size: 11))
                                    .foregroundStyle(LoobyTakerPalette.danger)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 14).fill(LoobyTakerPalette.danger.opacity(0.08)))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(LoobyTakerPalette.danger.opacity(0.45), lineWidth: 1.2))

                            // Étiquette 2 Viple Delivery mise en valeur
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("2e ÉTIQUETTE • VIPLE")
                                        .font(.system(size: 10, weight: .black, design: .rounded))
                                        .foregroundStyle(LoobyTakerPalette.emerald)
                                    Spacer()
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(LoobyTakerPalette.emerald)
                                }
                                Text(warning.matchedVipleBarcode ?? "VD-2026-XXXXX")
                                    .font(.system(size: 12.5, weight: .black, design: .monospaced))
                                    .foregroundStyle(LoobyTakerPalette.ink)
                                    .lineLimit(1)
                                Text("À scanner dans Looby Taker !")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(LoobyTakerPalette.emerald)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 14).fill(LoobyTakerPalette.emeraldSoft))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(LoobyTakerPalette.emerald, lineWidth: 1.5))
                        }
                    }
                    .loobyTakerCard()

                    // Si `matchedVipleBarcode` a été identifié par le serveur ou localement, bouton pratique pour basculer dessus
                    if let matchedCode = warning.matchedVipleBarcode, !matchedCode.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(LoobyTakerPalette.amberPrimary)
                                Text("Correspondance Viple Delivery trouvée !")
                                    .font(.system(size: 14.5, weight: .black, design: .rounded))
                                    .foregroundStyle(LoobyTakerPalette.ink)
                            }

                            Text("Ce numéro UPS correspond au colis **\(matchedCode)**. Vous pouvez valider directement avec cette 2e étiquette ou rescanner le carton.")
                                .font(.system(size: 12.5))
                                .foregroundStyle(LoobyTakerPalette.inkSecondary)

                            Button {
                                Task {
                                    isSwitchingToMatched = true
                                    let targetMode = warning.intendedMode
                                    vm.upsPedagogicalWarning = nil
                                    dismiss()
                                    await vm.handleScannedCode(matchedCode, mode: targetMode)
                                    isSwitchingToMatched = false
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    if isSwitchingToMatched {
                                        ProgressView().tint(.white)
                                    } else {
                                        Image(systemName: "bolt.circle.fill")
                                    }
                                    Text("Basculer sur l'étiquette \(matchedCode)")
                                        .font(.system(size: 14, weight: .black, design: .rounded))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 13)
                                .background(LoobyTakerPalette.goldCoralHorizontal)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                        .loobyTakerCard()
                    }

                    Button {
                        vm.upsPedagogicalWarning = nil
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "barcode.viewfinder")
                            Text("Compris, rescanner la 2e étiquette VD-…")
                                .font(.system(size: 14.5, weight: .black, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(LoobyTakerPalette.emerald))
                        .foregroundStyle(.white)
                    }

                    Button {
                        vm.upsPedagogicalWarning = nil
                        dismiss()
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 300_000_000)
                            vm.isShowingVisualScanGuide = true
                        }
                    } label: {
                        Text("Ouvrir le guide illustré complet des étiquettes")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .foregroundStyle(LoobyTakerPalette.amberPrimary)
                    }
                }
                .padding(18)
            }
            .loobyTakerScreenBackground()
            .navigationTitle("Attention à l'étiquette !")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fermer") {
                        vm.upsPedagogicalWarning = nil
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Clavier Code PIN à 6 Chiffres (Remise Sécurisée Relais Particulier — 1,00 €/colis)

public struct HandoverPinPadSheet: View {
    @EnvironmentObject private var vm: LoobyTakerViewModel
    @Environment(\.dismiss) private var dismiss

    public let parcel: TakerParcel
    public let scannedCode: String

    @State private var enteredPin: String = ""
    @State private var recipientNote: String = ""
    @State private var isSubmitting: Bool = false

    private let digits = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]

    public init(parcel: TakerParcel, scannedCode: String) {
        self.parcel = parcel
        self.scannedCode = scannedCode
    }

    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    // Résumé colis & gain 1,00 €
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundStyle(LoobyTakerPalette.amberPrimary)
                            Text("REMISE SÉCURISÉE PARTICULIER • +1,00 €")
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundStyle(LoobyTakerPalette.amberDeep)
                        }

                        Text(parcel.recipientName)
                            .font(.system(size: 21, weight: .black, design: .rounded))
                            .foregroundStyle(LoobyTakerPalette.ink)

                        Text(parcel.vipleBarcode.isEmpty ? scannedCode : parcel.vipleBarcode)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(LoobyTakerPalette.amberSoft))
                            .foregroundStyle(LoobyTakerPalette.amberDeep)

                        Text("Demandez au client le Code PIN de retrait à 6 chiffres affiché dans son application Livria Store / Marketplace.")
                            .font(.system(size: 12.5))
                            .foregroundStyle(LoobyTakerPalette.inkSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)

                        if let demoHint = parcel.pinHintForDemo, !demoHint.isEmpty {
                            Button {
                                enteredPin = String(demoHint.prefix(6))
                                LoobyTakerHaptics.impact(0)
                            } label: {
                                Label("Indice démo : \(demoHint) (toucher pour remplir)", systemImage: "sparkles")
                                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                                    .padding(.horizontal, 11)
                                    .padding(.vertical, 5)
                                    .background(Capsule().fill(LoobyTakerPalette.emeraldSoft))
                                    .foregroundStyle(LoobyTakerPalette.emerald)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 6)

                    // Les 6 cases du Code PIN
                    HStack(spacing: 10) {
                        ForEach(0..<6, id: \.self) { index in
                            let charStr: String = index < enteredPin.count
                                ? String(enteredPin[enteredPin.index(enteredPin.startIndex, offsetBy: index)])
                                : ""
                            ZStack {
                                RoundedRectangle(cornerRadius: 13, style: .continuous)
                                    .fill(LoobyTakerPalette.cardSurface)
                                    .frame(width: 46, height: 56)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                                            .stroke(
                                                index == enteredPin.count
                                                    ? LoobyTakerPalette.amberPrimary
                                                    : (charStr.isEmpty ? LoobyTakerPalette.border : LoobyTakerPalette.emerald),
                                                lineWidth: index == enteredPin.count ? 2.2 : 1.2
                                            )
                                    )

                                Text(charStr)
                                    .font(.system(size: 23, weight: .black, design: .rounded))
                                    .foregroundStyle(LoobyTakerPalette.ink)
                            }
                        }
                    }

                    // Clavier numérique tactile sur mesure
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 10) {
                        ForEach(digits, id: \.self) { digit in
                            pinKeyButton(digit)
                        }

                        Button {
                            enteredPin = ""
                            LoobyTakerHaptics.impact(0)
                        } label: {
                            Text("Effacer")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .background(RoundedRectangle(cornerRadius: 14).fill(LoobyTakerPalette.cardSubtle))
                                .foregroundStyle(LoobyTakerPalette.inkSecondary)
                        }
                        .buttonStyle(.plain)

                        pinKeyButton("0")

                        Button {
                            if !enteredPin.isEmpty {
                                enteredPin.removeLast()
                                LoobyTakerHaptics.impact(0)
                            }
                        } label: {
                            Image(systemName: "delete.left.fill")
                                .font(.system(size: 18, weight: .bold))
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .background(RoundedRectangle(cornerRadius: 14).fill(LoobyTakerPalette.cardSubtle))
                                .foregroundStyle(LoobyTakerPalette.ink)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 8)

                    TextField("Note de remise optionnelle (ex: Remis en main propre)", text: $recipientNote)
                        .font(.system(size: 13))
                        .padding(11)
                        .background(RoundedRectangle(cornerRadius: 12).fill(LoobyTakerPalette.cardSurface))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(LoobyTakerPalette.border, lineWidth: 1))

                    Button {
                        Task {
                            isSubmitting = true
                            let ok = await vm.confirmHandover(
                                scannedCode: scannedCode.isEmpty ? parcel.vipleBarcode : scannedCode,
                                parcel: parcel,
                                pinCode: enteredPin,
                                recipientNote: recipientNote
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
                                Image(systemName: "checkmark.seal.fill")
                            }
                            Text("Valider le PIN & créditer +1,00 €")
                                .font(.system(size: 15, weight: .black, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            enteredPin.count >= 4
                                ? AnyShapeStyle(LoobyTakerPalette.goldCoralHorizontal)
                                : AnyShapeStyle(LoobyTakerPalette.border)
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    }
                    .disabled(enteredPin.count < 4 || isSubmitting)
                }
                .padding(18)
            }
            .loobyTakerScreenBackground()
            .navigationTitle("Code PIN Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") {
                        vm.pendingHandoverParcelForPin = nil
                        dismiss()
                    }
                }
            }
        }
    }

    private func pinKeyButton(_ digit: String) -> some View {
        Button {
            if enteredPin.count < 6 {
                enteredPin.append(digit)
                LoobyTakerHaptics.impact(0)
            }
        } label: {
            Text(digit)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(LoobyTakerPalette.cardSurface))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(LoobyTakerPalette.border, lineWidth: 1))
                .foregroundStyle(LoobyTakerPalette.ink)
        }
        .buttonStyle(.plain)
    }
}
