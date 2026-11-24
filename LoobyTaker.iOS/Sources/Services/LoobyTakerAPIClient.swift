import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Client Réseau REST Natif « Looby Taker » (`https://livria.store/api/mobile/v1` • Swift 6)

@MainActor
public final class LoobyTakerAPIClient {
    public static let shared = LoobyTakerAPIClient()

    public let baseAPI = "https://livria.store/api/mobile/v1"
    public let socialBaseAPI = "https://livriasocial.viplenetwork.com/api/mobile/v1"

    private let session: URLSession
    private let backgroundPollSession: URLSession
    private let decoder: JSONDecoder

    public var bearerToken: String? {
        get {
            UserDefaults.standard.string(forKey: "loobytaker.auth.bearerToken.v1")
        }
        set {
            if let val = newValue, !val.isEmpty {
                UserDefaults.standard.set(val, forKey: "loobytaker.auth.bearerToken.v1")
            } else {
                UserDefaults.standard.removeObject(forKey: "loobytaker.auth.bearerToken.v1")
            }
        }
    }

    public init() {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 20
        cfg.timeoutIntervalForResource = 25
        self.session = URLSession(configuration: cfg)

        let bgCfg = URLSessionConfiguration.default
        bgCfg.timeoutIntervalForRequest = 7.5
        bgCfg.timeoutIntervalForResource = 10.0
        bgCfg.waitsForConnectivity = false
        self.backgroundPollSession = URLSession(configuration: bgCfg)

        self.decoder = JSONDecoder()
    }

    // MARK: - Identité Matérielle & En-têtes Officiels `X-Viple-*`

    public var resolvedDeviceIdentifier: String {
        LoobyTakerDeviceIdentity.resolvedVendorDeviceId()
    }

    public var resolvedPhysicalDeviceId: String {
        LoobyTakerDeviceIdentity.resolvedPhysicalDeviceId(fallbackVendorId: resolvedDeviceIdentifier)
    }

    public var resolvedHardwareModelCode: String {
        LoobyTakerDeviceIdentity.hardwareModelCode()
    }

    public var resolvedHardwareModelName: String {
        LoobyTakerDeviceIdentity.commercialModelName()
    }

    public var resolvedOsVersion: String {
        LoobyTakerDeviceIdentity.osVersionString()
    }

    public func applyVipleHeaders(to req: inout URLRequest) {
        let devId = resolvedDeviceIdentifier
        let physId = resolvedPhysicalDeviceId
        let hwCode = LoobyTakerDeviceIdentity.httpHeaderSafe(resolvedHardwareModelCode)
        let hwName = LoobyTakerDeviceIdentity.httpHeaderSafe(resolvedHardwareModelName)
        let osVer = LoobyTakerDeviceIdentity.httpHeaderSafe(resolvedOsVersion)

        req.setValue(LoobyTakerDeviceIdentity.appHeaderName, forHTTPHeaderField: "X-Viple-App-Name")
        req.setValue(LoobyTakerDeviceIdentity.clientMarketingVersion, forHTTPHeaderField: "X-Viple-Client-Version")
        req.setValue(UUID().uuidString.lowercased(), forHTTPHeaderField: "X-Viple-Request-Id")

        if !devId.isEmpty {
            req.setValue(devId, forHTTPHeaderField: "X-Viple-Device-Id")
            req.setValue(devId, forHTTPHeaderField: "X-Viple-Vendor-Id")
        }
        if !physId.isEmpty {
            req.setValue(physId, forHTTPHeaderField: "X-Viple-Physical-Device-Id")
        }
        if !hwCode.isEmpty {
            req.setValue(hwCode, forHTTPHeaderField: "X-Viple-Hardware-Model")
        }
        if !hwName.isEmpty {
            req.setValue(hwName, forHTTPHeaderField: "X-Viple-Model-Name")
        }
        if !osVer.isEmpty {
            req.setValue(osVer, forHTTPHeaderField: "X-Viple-OS-Version")
        }
        if let token = bearerToken, !token.isEmpty {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.setValue(
            "LoobyTaker-iOS/\(LoobyTakerDeviceIdentity.clientMarketingVersion) (fr.looby.taker; \(hwName); \(osVer))",
            forHTTPHeaderField: "User-Agent"
        )
    }

    // MARK: - Primitives HTTP Tolérantes

    public func getJSON<T: Decodable>(_ path: String, queryItems: [URLQueryItem] = []) async throws -> T {
        let rawURL = path.hasPrefix("http") ? path : "\(baseAPI)\(path)"
        guard var comps = URLComponents(string: rawURL) else {
            throw URLError(.badURL)
        }
        if !queryItems.isEmpty {
            comps.queryItems = (comps.queryItems ?? []) + queryItems
        }
        guard let url = comps.url else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        applyVipleHeaders(to: &req)

        let (data, resp) = try await session.data(for: req)
        if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            // Décodage tolérant si le serveur renvoie une enveloppe métier structurée (ex. 400/401/422)
            if http.statusCode < 500, let decoded = try? decoder.decode(T.self, from: data) {
                return decoded
            }
            let message = Self.extractErrorMessage(from: data, statusCode: http.statusCode)
            throw NSError(domain: "LoobyTakerAPI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
        }
        return try decoder.decode(T.self, from: data)
    }

    public func postJSON<T: Decodable>(_ path: String, body: [String: Any]) async throws -> T {
        let rawURL = path.hasPrefix("http") ? path : "\(baseAPI)\(path)"
        guard let url = URL(string: rawURL) else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue(UUID().uuidString.lowercased(), forHTTPHeaderField: "X-Idempotency-Key")
        applyVipleHeaders(to: &req)
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await session.data(for: req)
        if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            if http.statusCode < 500, let decoded = try? decoder.decode(T.self, from: data) {
                return decoded
            }
            let message = Self.extractErrorMessage(from: data, statusCode: http.statusCode)
            throw NSError(domain: "LoobyTakerAPI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
        }
        return try decoder.decode(T.self, from: data)
    }

    public func postRaw(_ path: String, body: [String: Any]) async throws -> [String: Any] {
        let rawURL = path.hasPrefix("http") ? path : "\(baseAPI)\(path)"
        guard let url = URL(string: rawURL) else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        applyVipleHeaders(to: &req)
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await session.data(for: req)
        return (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    }

    private static func extractErrorMessage(from data: Data, statusCode: Int) -> String {
        if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let err = dict["error"] as? String, !err.isEmpty { return err }
            if let msg = dict["message"] as? String, !msg.isEmpty { return msg }
        }
        if statusCode >= 500 {
            return "Le service Looby Taker est momentanément indisponible (\(statusCode)). Veuillez réessayer dans un instant."
        }
        return "Requête refusée (\(statusCode)). Vérifiez vos informations et réessayez."
    }

    // MARK: - 1. Authentification & SSO Écosystème (`group.com.viplenetwork.shared` + `/sso/*`)

    public func loginTaker(email: String, password: String) async throws -> TakerAuthResponse {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let res: TakerAuthResponse = try await postJSON("/taker/auth/login", body: [
            "email": cleanEmail,
            "password": password
        ])
        if let token = res.token, !token.isEmpty {
            self.bearerToken = token
        }
        return res
    }

    /// Recherche d'une session SSO Viple/Cenelis active sur le même iPhone (App Group partagé + API `/sso/discover`).
    public func discoverCrossAppAccount() async -> TakerCrossAppAccount? {
        // 1. Lecture instantanée dans l'App Group partagé `group.com.viplenetwork.shared` / `group.store.livria.shared`
        if let localShared = readSharedAppGroupAccount() {
            return localShared
        }

        // 2. Découverte serveur `/sso/discover` par identifiant d'appareil
        let devId = resolvedDeviceIdentifier
        guard devId.count >= 6 else { return nil }
        let items = [
            URLQueryItem(name: "currentApp", value: "LoobyTaker"),
            URLQueryItem(name: "vendorId", value: devId),
            URLQueryItem(name: "deviceId", value: devId),
            URLQueryItem(name: "physicalDeviceId", value: resolvedPhysicalDeviceId)
        ]
        if let res: TakerCrossAppDiscoverResponse = try? await getJSON("/sso/discover", queryItems: items),
           res.hasDetectedAccount,
           let account = res.account,
           !account.email.isEmpty {
            return account
        }
        if let resSocial: TakerCrossAppDiscoverResponse = try? await getJSON("\(socialBaseAPI)/sso/discover", queryItems: items),
           resSocial.hasDetectedAccount,
           let account = resSocial.account,
           !account.email.isEmpty {
            return account
        }
        return nil
    }

    public func acceptCrossAppAccount(userId: Int, email: String) async throws -> TakerAuthResponse {
        let devId = resolvedDeviceIdentifier
        let res: TakerAuthResponse = try await postJSON("/sso/accept", body: [
            "userId": userId,
            "email": email,
            "vendorId": devId,
            "deviceId": devId,
            "physicalDeviceId": resolvedPhysicalDeviceId
        ])
        if let token = res.token, !token.isEmpty {
            self.bearerToken = token
        }
        return res
    }

    public func announceCrossAppSession(user: TakerUserProfile, token: String?) async {
        // Persistance dans `group.com.viplenetwork.shared` pour détection immédiate inter-applications
        if let sharedSuite = UserDefaults(suiteName: LoobyTakerDeviceIdentity.sharedSuiteName) {
            let sharedDict: [String: Any] = [
                "userId": user.id,
                "email": user.email,
                "displayName": user.displayName,
                "cid": user.cid,
                "sourceApp": "Looby Taker",
                "avatarUrl": user.avatarUrl
            ]
            if let data = try? JSONSerialization.data(withJSONObject: sharedDict) {
                sharedSuite.set(data, forKey: "viple.crossapp.shared.account.v1")
            }
            sharedSuite.set(user.email, forKey: "viple.shared.activeEmail")
            sharedSuite.set(user.id, forKey: "viple.shared.activeUserId")
            if !user.cid.isEmpty {
                sharedSuite.set(user.cid, forKey: "viple.shared.activeCid")
            }
            if let token, !token.isEmpty {
                sharedSuite.set(token, forKey: "viple.shared.ssoToken")
            }
        }

        let devId = resolvedDeviceIdentifier
        guard devId.count >= 6 else { return }
        let payload: [String: Any] = [
            "sourceApp": "LoobyTaker",
            "appName": "Looby Taker",
            "userId": user.id,
            "email": user.email,
            "vendorId": devId,
            "deviceId": devId
        ]
        _ = try? await postRaw("/sso/announce", body: payload)
    }

    public func clearCrossAppSession() async {
        if let sharedSuite = UserDefaults(suiteName: LoobyTakerDeviceIdentity.sharedSuiteName) {
            sharedSuite.removeObject(forKey: "viple.crossapp.shared.account.v1")
            sharedSuite.removeObject(forKey: "viple.shared.ssoToken")
        }
        let devId = resolvedDeviceIdentifier
        guard devId.count >= 6 else { return }
        let payload: [String: Any] = [
            "sourceApp": "LoobyTaker",
            "appName": "Looby Taker",
            "vendorId": devId,
            "deviceId": devId
        ]
        _ = try? await postRaw("/sso/clear", body: payload)
    }

    private func readSharedAppGroupAccount() -> TakerCrossAppAccount? {
        for suiteName in [LoobyTakerDeviceIdentity.sharedSuiteName, LoobyTakerDeviceIdentity.secondaryLivriaSuiteName] {
            guard let suite = UserDefaults(suiteName: suiteName) else { continue }
            for key in ["viple.crossapp.shared.account.v1", "viple.crossapp.store.account"] {
                if let data = suite.data(forKey: key),
                   let decoded = try? decoder.decode(TakerCrossAppAccount.self, from: data),
                   !decoded.email.isEmpty,
                   !decoded.email.lowercased().hasSuffix("@guest.livria.store") {
                    return decoded
                }
            }
            if let sharedEmail = suite.string(forKey: "viple.shared.activeEmail")?
                .trimmingCharacters(in: .whitespacesAndNewlines),
               !sharedEmail.isEmpty,
               !sharedEmail.lowercased().hasSuffix("@guest.livria.store") {
                let uid = suite.integer(forKey: "viple.shared.activeUserId")
                let cid = suite.string(forKey: "viple.shared.activeCid") ?? ""
                return TakerCrossAppAccount(
                    userId: uid,
                    email: sharedEmail,
                    displayName: sharedEmail.split(separator: "@").first.map(String.init) ?? sharedEmail,
                    cid: cid,
                    sourceApp: "Viple Live ID (iPhone)"
                )
            }
        }
        return nil
    }

    // MARK: - 2. Bootstrap Complet (`/taker/bootstrap`)

    public func fetchBootstrap(
        email: String,
        cid: String,
        userId: String,
        relayId: Int? = nil
    ) async throws -> TakerBootstrapResponse {
        var items: [URLQueryItem] = []
        if !email.isEmpty {
            items.append(URLQueryItem(name: "email", value: email))
        }
        if !cid.isEmpty {
            items.append(URLQueryItem(name: "cid", value: cid))
        }
        if !userId.isEmpty {
            items.append(URLQueryItem(name: "userId", value: userId))
        }
        if let relayId, relayId > 0 {
            items.append(URLQueryItem(name: "relayId", value: String(relayId)))
        }
        return try await getJSON("/taker/bootstrap", queryItems: items)
    }

    // MARK: - 3. Actions Colis & Scan (`/taker/parcels/*`)

    public func scanReceiveParcel(
        email: String,
        cid: String,
        relayId: Int,
        scannedCode: String,
        shelfLocation: String,
        conditionNotes: String,
        recipientNameOverride: String
    ) async throws -> TakerScanReceiveResponse {
        try await postJSON("/taker/parcels/scan-receive", body: [
            "email": email,
            "cid": cid,
            "relayId": relayId,
            "scannedCode": scannedCode,
            "shelfLocation": shelfLocation,
            "conditionNotes": conditionNotes,
            "recipientNameOverride": recipientNameOverride
        ])
    }

    public func scanHandoverParcel(
        email: String,
        cid: String,
        relayId: Int,
        scannedCode: String,
        parcelId: String,
        pinCode: String,
        recipientNote: String
    ) async throws -> TakerScanHandoverResponse {
        try await postJSON("/taker/parcels/scan-handover", body: [
            "email": email,
            "cid": cid,
            "relayId": relayId,
            "scannedCode": scannedCode,
            "parcelId": parcelId,
            "pinCode": pinCode,
            "recipientNote": recipientNote
        ])
    }

    public func forecastParcel(
        email: String,
        cid: String,
        relayId: Int,
        vipleBarcode: String,
        carrier: String,
        carrierTrackingNumber: String,
        recipientName: String,
        expectedArrivalDate: String,
        expectedArrivalWindow: String,
        notes: String
    ) async throws -> TakerParcelMutationResponse {
        try await postJSON("/taker/parcels/forecast", body: [
            "email": email,
            "cid": cid,
            "relayId": relayId,
            "vipleBarcode": vipleBarcode,
            "carrier": carrier,
            "carrierTrackingNumber": carrierTrackingNumber,
            "recipientName": recipientName,
            "expectedArrivalDate": expectedArrivalDate,
            "expectedArrivalWindow": expectedArrivalWindow,
            "notes": notes
        ])
    }

    public func reportReceptionIssue(
        email: String,
        cid: String,
        relayId: Int,
        parcelId: String?,
        vipleBarcode: String,
        carrierTrackingNumber: String,
        issueType: String,
        severity: String,
        description: String,
        refusedAtDoor: Bool
    ) async throws -> TakerIssueMutationResponse {
        var payload: [String: Any] = [
            "email": email,
            "cid": cid,
            "relayId": relayId,
            "vipleBarcode": vipleBarcode,
            "carrierTrackingNumber": carrierTrackingNumber,
            "issueType": issueType,
            "severity": severity,
            "description": description,
            "refusedAtDoor": refusedAtDoor
        ]
        if let parcelId, !parcelId.isEmpty {
            payload["parcelId"] = parcelId
        } else {
            payload["parcelId"] = ""
        }
        return try await postJSON("/taker/parcels/report-issue", body: payload)
    }

    // MARK: - 4. Actions Planning, RDV, Horaires, Fermeture & Vacances (`/taker/appointments/*` & `/taker/relay/*`)

    public func saveAppointment(
        email: String,
        cid: String,
        relayId: Int,
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
    ) async throws -> TakerAppointmentMutationResponse {
        try await postJSON("/taker/appointments/save", body: [
            "email": email,
            "cid": cid,
            "relayId": relayId,
            "appointmentId": appointmentId ?? "",
            "parcelId": parcelId,
            "vipleBarcode": vipleBarcode,
            "customerName": customerName,
            "customerPhone": customerPhone,
            "customerEmail": customerEmail,
            "slotDate": slotDate,
            "startTime": startTime,
            "endTime": endTime,
            "status": status,
            "notes": notes
        ])
    }

    public func updateAppointmentStatus(
        email: String,
        cid: String,
        relayId: Int,
        appointmentId: String,
        status: String,
        notes: String
    ) async throws -> TakerAppointmentMutationResponse {
        try await postJSON("/taker/appointments/status", body: [
            "email": email,
            "cid": cid,
            "relayId": relayId,
            "appointmentId": appointmentId,
            "status": status,
            "notes": notes
        ])
    }

    public func updateRelayInfo(
        email: String,
        cid: String,
        relayId: Int,
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
    ) async throws -> TakerRelayMutationResponse {
        try await postJSON("/taker/relay/update-info", body: [
            "email": email,
            "cid": cid,
            "relayId": relayId,
            "name": name,
            "relayMode": relayMode,
            "address": address,
            "postalCode": postalCode,
            "city": city,
            "phone": phone,
            "siret": siret,
            "businessCategory": businessCategory,
            "intercomAndAccessNotes": intercomAndAccessNotes,
            "maxParcelCapacity": maxParcelCapacity
        ])
    }

    public func updateRelayHours(
        email: String,
        cid: String,
        relayId: Int,
        openingHoursSummary: String,
        isCurrentlyClosedOverride: Bool,
        closureReason: String,
        weeklySchedule: [TakerDaySchedule],
        availabilities: [TakerAvailabilitySlot]
    ) async throws -> TakerRelayMutationResponse {
        try await postJSON("/taker/relay/update-hours", body: [
            "email": email,
            "cid": cid,
            "relayId": relayId,
            "openingHoursSummary": openingHoursSummary,
            "isCurrentlyClosedOverride": isCurrentlyClosedOverride,
            "closureReason": closureReason,
            "weeklySchedule": weeklySchedule.map { $0.toDictionary() },
            "availabilities": availabilities.map { $0.toDictionary() }
        ])
    }

    public func updateRelayVacation(
        email: String,
        cid: String,
        relayId: Int,
        enabled: Bool,
        startDate: String,
        endDate: String,
        message: String,
        allowExistingPickupsOnly: Bool
    ) async throws -> TakerRelayMutationResponse {
        try await postJSON("/taker/relay/vacation", body: [
            "email": email,
            "cid": cid,
            "relayId": relayId,
            "enabled": enabled,
            "startDate": startDate,
            "endDate": endDate,
            "message": message,
            "allowExistingPickupsOnly": allowExistingPickupsOnly
        ])
    }

    // MARK: - 5. Candidatures Devenir Taker & Suivi (`/taker/applications/*`)

    public func submitTakerApplication(
        email: String,
        cid: String,
        userId: String,
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
    ) async throws -> TakerApplicationMutationResponse {
        try await postJSON("/taker/applications/submit", body: [
            "email": email,
            "cid": cid,
            "userId": userId,
            "applicantType": applicantType,
            "relayName": relayName,
            "firstName": firstName,
            "lastName": lastName,
            "phone": phone,
            "siret": siret,
            "businessCategory": businessCategory,
            "address": address,
            "postalCode": postalCode,
            "city": city,
            "openingHours": openingHours,
            "storageCapacity": storageCapacity,
            "motivationAndAccessNotes": motivationAndAccessNotes
        ])
    }

    public func replyToApplicationRequest(
        email: String,
        cid: String,
        applicationId: Int,
        reference: String,
        supplementaryResponse: String
    ) async throws -> TakerApplicationMutationResponse {
        try await postJSON("/taker/applications/reply", body: [
            "email": email,
            "cid": cid,
            "applicationId": applicationId,
            "reference": reference,
            "supplementaryResponse": supplementaryResponse
        ])
    }

    // MARK: - 6. Notifications APNs (`fr.looby.taker`) & Gestionnaire d'Appareils Connectés

    @discardableResult
    public func registerPushDevice(
        userId: Int,
        email: String,
        cid: String,
        displayName: String,
        apnsToken: String?,
        notificationsEnabled: Bool,
        isExplicitLogin: Bool
    ) async -> Bool {
        let devId = resolvedDeviceIdentifier
        let physId = resolvedPhysicalDeviceId
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !devId.isEmpty, !cleanEmail.isEmpty else { return false }

        #if DEBUG
        let apnsEnv = "sandbox"
        #else
        let apnsEnv = "production"
        #endif

        let payload: [String: Any] = [
            "deviceId": devId,
            "vendorId": devId,
            "physicalDeviceId": physId,
            "userId": userId,
            "email": cleanEmail,
            "cid": cid,
            "displayName": displayName,
            "bundleId": LoobyTakerDeviceIdentity.bundleIdentifier,
            "appName": "Looby Taker",
            "appId": "looby-taker",
            "deviceModelCode": resolvedHardwareModelCode,
            "deviceModelName": resolvedHardwareModelName,
            "osVersion": resolvedOsVersion,
            "apnsToken": apnsToken ?? "",
            "apnsEnvironment": apnsEnv,
            "appleTeamId": LoobyTakerDeviceIdentity.detectAppleTeamIdFromKeychain(),
            "platform": "iOS",
            "appVersion": LoobyTakerDeviceIdentity.clientMarketingVersion,
            "notificationsEnabled": notificationsEnabled,
            "isExplicitLoginOrRegister": isExplicitLogin
        ]

        if let res = try? await postRaw("/taker/devices/register", body: payload),
           !res.isEmpty {
            return (res["sessionRevoked"] as? Bool) ?? false
        }
        if let fallback = try? await postRaw("/devices/register", body: payload) {
            return (fallback["sessionRevoked"] as? Bool) ?? false
        }
        return false
    }

    public func unregisterPushDevice(userId: Int?, email: String?, cid: String?) async {
        let devId = resolvedDeviceIdentifier
        let physId = resolvedPhysicalDeviceId
        guard !devId.isEmpty else { return }
        var payload: [String: Any] = [
            "deviceId": devId,
            "vendorId": devId,
            "physicalDeviceId": physId,
            "bundleId": LoobyTakerDeviceIdentity.bundleIdentifier,
            "appId": "looby-taker"
        ]
        if let userId, userId > 0 { payload["userId"] = userId }
        if let email, !email.isEmpty { payload["email"] = email }
        if let cid, !cid.isEmpty { payload["cid"] = cid }

        _ = try? await postRaw("/taker/devices/unregister", body: payload)
        _ = try? await postRaw("/devices/unregister", body: payload)
    }

    public func fetchConnectedDevices(
        userId: Int?,
        email: String,
        cid: String
    ) async throws -> TakerConnectedDevicesResponse {
        let devId = resolvedDeviceIdentifier
        let physId = resolvedPhysicalDeviceId
        var items: [URLQueryItem] = [
            URLQueryItem(name: "deviceId", value: devId),
            URLQueryItem(name: "physicalDeviceId", value: physId)
        ]
        if let userId, userId > 0 {
            items.append(URLQueryItem(name: "userId", value: String(userId)))
        }
        if !email.isEmpty {
            items.append(URLQueryItem(name: "email", value: email))
        }
        if !cid.isEmpty {
            items.append(URLQueryItem(name: "cid", value: cid))
        }

        if let primary: TakerConnectedDevicesResponse = try? await getJSON("/taker/devices/sessions", queryItems: items),
           primary.ok || !primary.devices.isEmpty || primary.sessionRevoked {
            return primary
        }
        return try await getJSON("/devices/sessions", queryItems: items)
    }

    public func revokeConnectedDevice(
        userId: Int?,
        email: String,
        cid: String,
        targetDeviceId: String,
        rawDeviceIds: [String],
        targetAppId: String
    ) async throws -> TakerRevokeDeviceResponse {
        var payload: [String: Any] = [
            "targetDeviceId": targetDeviceId,
            "rawDeviceIds": rawDeviceIds,
            "targetAppId": targetAppId.isEmpty ? "*" : targetAppId,
            "email": email,
            "cid": cid
        ]
        if let userId, userId > 0 {
            payload["userId"] = userId
        }
        if let primary: TakerRevokeDeviceResponse = try? await postJSON("/taker/devices/revoke", body: payload),
           primary.ok || primary.revokedCount > 0 || primary.currentDeviceRevoked {
            return primary
        }
        return try await postJSON("/devices/revoke", body: payload)
    }

    public func pollNotifications(
        userId: Int?,
        email: String,
        cid: String,
        limit: Int = 25,
        fastBackground: Bool = false
    ) async throws -> TakerNotificationPollResponse {
        let devId = resolvedDeviceIdentifier
        let physId = resolvedPhysicalDeviceId
        var items: [URLQueryItem] = [
            URLQueryItem(name: "deviceId", value: devId),
            URLQueryItem(name: "physicalDeviceId", value: physId),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "email", value: email)
        ]
        if let userId, userId > 0 {
            items.append(URLQueryItem(name: "userId", value: String(userId)))
        }
        if !cid.isEmpty {
            items.append(URLQueryItem(name: "cid", value: cid))
        }

        if fastBackground {
            guard var comps = URLComponents(string: "\(baseAPI)/taker/notifications/poll") else {
                throw URLError(.badURL)
            }
            comps.queryItems = items
            guard let url = comps.url else {
                throw URLError(.badURL)
            }
            var req = URLRequest(url: url)
            req.httpMethod = "GET"
            req.timeoutInterval = 7.0
            req.setValue("application/json", forHTTPHeaderField: "Accept")
            applyVipleHeaders(to: &req)
            let (data, resp) = try await backgroundPollSession.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
            return try decoder.decode(TakerNotificationPollResponse.self, from: data)
        }

        return try await getJSON("/taker/notifications/poll", queryItems: items)
    }

    public func ackNotifications(
        notificationIds: [String],
        userId: Int?,
        email: String
    ) async {
        let cleanIds = notificationIds.filter { !$0.isEmpty }
        guard !cleanIds.isEmpty else { return }
        let devId = resolvedDeviceIdentifier
        var payload: [String: Any] = [
            "deviceId": devId,
            "vendorId": devId,
            "notificationIds": cleanIds,
            "email": email
        ]
        if let userId, userId > 0 {
            payload["userId"] = userId
        }
        _ = try? await postRaw("/taker/notifications/ack", body: payload)
    }
}
