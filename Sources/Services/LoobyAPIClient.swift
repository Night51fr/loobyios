import Foundation
#if canImport(UIKit)
import UIKit
#endif

@MainActor
public final class LoobyAPIClient {
    public static let shared = LoobyAPIClient()

    public let baseAPI = LoobyAppConfig.livriaBaseAPI
    public let socialBaseAPI = LoobyAppConfig.socialBaseAPI
    private let session: URLSession
    private let decoder: JSONDecoder

    public init() {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 20
        cfg.timeoutIntervalForResource = 25
        self.session = URLSession(configuration: cfg)
        self.decoder = JSONDecoder()
    }

    private func applyVipleDeviceHeaders(to req: inout URLRequest) {
        req.setValue("Looby", forHTTPHeaderField: "X-Viple-App-Name")
        #if canImport(UIKit)
        if let vendorId = UIDevice.current.identifierForVendor?.uuidString, !vendorId.isEmpty {
            req.setValue(vendorId, forHTTPHeaderField: "X-Viple-Vendor-Id")
        }
        let dev = UIDevice.current
        let bounds = UIScreen.main.bounds
        let sig = "\(dev.model)|\(dev.systemName)-\(dev.systemVersion)|\(Int(bounds.width))x\(Int(bounds.height))"
        req.setValue(sig, forHTTPHeaderField: "X-Viple-Device-Signature")
        #endif
    }

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
        req.setValue("Looby-iOS/2.0 (iPhone; iOS 18.0+)", forHTTPHeaderField: "User-Agent")
        applyVipleDeviceHeaders(to: &req)

        let (data, resp) = try await session.data(for: req)
        if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
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
        req.setValue("Looby-iOS/2.0 (iPhone; iOS 18.0+)", forHTTPHeaderField: "User-Agent")
        applyVipleDeviceHeaders(to: &req)
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, resp) = try await session.data(for: req)
        if let http = resp as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = (dict["error"] as? String) ?? (dict["message"] as? String) {
                throw NSError(domain: "LoobyAPI", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
            }
            throw URLError(.badServerResponse)
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
        applyVipleDeviceHeaders(to: &req)
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await session.data(for: req)
        return (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    }

    // MARK: - Viple Live ID Login, Register & Cross-App SSO

    public func fetchBootstrap(email: String?, userId: Int?) async throws -> LoobyBootstrapResponse {
        var items: [URLQueryItem] = []
        if let email, !email.isEmpty {
            items.append(URLQueryItem(name: "email", value: email))
        }
        if let userId, userId > 0 {
            items.append(URLQueryItem(name: "userId", value: String(userId)))
        }
        return try await getJSON("/bootstrap", queryItems: items)
    }

    public func loginVipleLiveID(email: String, password: String) async throws -> LoobyAuthResponse {
        try await postJSON("/auth/login", body: [
            "email": email,
            "password": password
        ])
    }

    public func registerVipleLiveID(
        emailMode: String,
        emailUser: String,
        customEmail: String,
        password: String,
        firstName: String,
        lastName: String,
        displayName: String
    ) async throws -> LoobyAuthResponse {
        let finalEmail = emailMode == "viplemail" ? "\(emailUser)@viplemail.fr" : customEmail
        return try await postJSON("/auth/register", body: [
            "emailMode": emailMode,
            "emailUser": emailUser,
            "emailDomain": "viplemail.fr",
            "customEmail": customEmail,
            "email": finalEmail,
            "password": password,
            "firstName": firstName,
            "lastName": lastName,
            "displayName": displayName
        ])
    }

    public func signInWithApple(
        appleUserId: String,
        identityToken: String?,
        email: String?,
        firstName: String?,
        lastName: String?
    ) async throws -> LoobyAuthResponse {
        var payload: [String: Any] = ["appleUserId": appleUserId]
        if let identityToken { payload["identityToken"] = identityToken }
        if let email { payload["email"] = email }
        if let firstName { payload["firstName"] = firstName }
        if let lastName { payload["lastName"] = lastName }
        return try await postJSON("/auth/apple", body: payload)
    }

    public func discoverCrossAppAccount() async -> LoobyCrossAppAccount? {
        let items = [URLQueryItem(name: "currentApp", value: "Looby")]
        if let res: LoobyCrossAppDiscoverResponse = try? await getJSON("/sso/discover", queryItems: items),
           res.hasDetectedAccount, let acc = res.account {
            return acc
        }
        if let resSocial: LoobyCrossAppDiscoverResponse = try? await getJSON("\(socialBaseAPI)/sso/discover", queryItems: items),
           resSocial.hasDetectedAccount, let acc = resSocial.account {
            return acc
        }
        return nil
    }

    public func acceptCrossAppAccount(userId: Int, email: String) async throws -> LoobyAuthResponse {
        try await postJSON("/sso/accept", body: [
            "userId": userId,
            "email": email
        ])
    }

    public func announceCrossAppSession(userId: Int, email: String) async {
        let payload: [String: Any] = [
            "sourceApp": "Looby",
            "appName": "Looby",
            "userId": userId,
            "email": email
        ]
        _ = try? await postRaw("/sso/announce", body: payload)
        _ = try? await postRaw("\(socialBaseAPI)/sso/announce", body: payload)
    }

    public func clearCrossAppSession() async {
        let payload: [String: Any] = [
            "sourceApp": "Looby",
            "appName": "Looby"
        ]
        _ = try? await postRaw("/sso/clear", body: payload)
        _ = try? await postRaw("\(socialBaseAPI)/sso/clear", body: payload)
    }

    public func deleteVipleAccount(userId: Int?, email: String?, cid: String?) async throws -> [String: Any] {
        var payload: [String: Any] = [:]
        if let userId { payload["userId"] = userId }
        if let email { payload["email"] = email }
        if let cid { payload["cid"] = cid }
        return try await postRaw("/auth/delete-account", body: payload)
    }
}
