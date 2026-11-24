import Foundation
import Security
#if canImport(Darwin)
import Darwin
#endif
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Identité Matérielle Unifiée Cenelis × Viple pour « Looby Taker » (Swift 6 Sendable)

public struct LoobyTakerDeviceIdentity: Sendable {
    public static let appHeaderName = "LoobyTaker"
    public static let clientMarketingVersion = "2026.11.1"
    public static let bundleIdentifier = "fr.looby.taker"
    public static let sharedSuiteName = "group.com.viplenetwork.shared"
    public static let secondaryLivriaSuiteName = "group.store.livria.shared"
    public static let sharedPhysicalDeviceIdKey = "cenelis.shared.physicalDeviceId.v1"
    public static let sharedVendorDeviceIdKey = "viple.shared.deviceId"
    public static let localVendorDeviceIdKey = "loobytaker.local.deviceId"

    public init() {}

    @MainActor
    public static func resolvedVendorDeviceId() -> String {
        let sharedSuite = UserDefaults(suiteName: sharedSuiteName)
        #if canImport(UIKit)
        if let idfv = UIDevice.current.identifierForVendor?.uuidString,
           !idfv.isEmpty,
           idfv != "00000000-0000-0000-0000-000000000000" {
            sharedSuite?.set(idfv, forKey: sharedVendorDeviceIdKey)
            UserDefaults.standard.set(idfv, forKey: localVendorDeviceIdKey)
            return idfv
        }
        #endif
        if let shared = sharedSuite?.string(forKey: sharedVendorDeviceIdKey),
           !shared.isEmpty,
           shared != "00000000-0000-0000-0000-000000000000" {
            return shared
        }
        if let saved = UserDefaults.standard.string(forKey: localVendorDeviceIdKey),
           !saved.isEmpty {
            sharedSuite?.set(saved, forKey: sharedVendorDeviceIdKey)
            return saved
        }
        let generated = UUID().uuidString
        UserDefaults.standard.set(generated, forKey: localVendorDeviceIdKey)
        sharedSuite?.set(generated, forKey: sharedVendorDeviceIdKey)
        return generated
    }

    /// Lit ou persiste `cenelis.shared.physicalDeviceId.v1` dans `UserDefaults(suiteName: "group.com.viplenetwork.shared")`.
    public static func resolvedPhysicalDeviceId(fallbackVendorId: String) -> String {
        let cleanFallback = fallbackVendorId.trimmingCharacters(in: .whitespacesAndNewlines)
        let validFallback = (!cleanFallback.isEmpty && cleanFallback != "00000000-0000-0000-0000-000000000000")
            ? cleanFallback
            : ""

        let sharedSuite = UserDefaults(suiteName: sharedSuiteName)
        let livriaSuite = UserDefaults(suiteName: secondaryLivriaSuiteName)

        if let existing = sharedSuite?.string(forKey: sharedPhysicalDeviceIdKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           existing.count >= 6,
           existing != "00000000-0000-0000-0000-000000000000" {
            if UserDefaults.standard.string(forKey: sharedPhysicalDeviceIdKey) != existing {
                UserDefaults.standard.set(existing, forKey: sharedPhysicalDeviceIdKey)
            }
            if livriaSuite?.string(forKey: sharedPhysicalDeviceIdKey) != existing {
                livriaSuite?.set(existing, forKey: sharedPhysicalDeviceIdKey)
            }
            return existing
        }

        if let livriaExisting = livriaSuite?.string(forKey: sharedPhysicalDeviceIdKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           livriaExisting.count >= 6,
           livriaExisting != "00000000-0000-0000-0000-000000000000" {
            sharedSuite?.set(livriaExisting, forKey: sharedPhysicalDeviceIdKey)
            UserDefaults.standard.set(livriaExisting, forKey: sharedPhysicalDeviceIdKey)
            return livriaExisting
        }

        if let localExisting = UserDefaults.standard.string(forKey: sharedPhysicalDeviceIdKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           localExisting.count >= 6,
           localExisting != "00000000-0000-0000-0000-000000000000" {
            sharedSuite?.set(localExisting, forKey: sharedPhysicalDeviceIdKey)
            livriaSuite?.set(localExisting, forKey: sharedPhysicalDeviceIdKey)
            return localExisting
        }

        let created = validFallback.isEmpty ? UUID().uuidString : validFallback
        sharedSuite?.set(created, forKey: sharedPhysicalDeviceIdKey)
        livriaSuite?.set(created, forKey: sharedPhysicalDeviceIdKey)
        UserDefaults.standard.set(created, forKey: sharedPhysicalDeviceIdKey)
        return created
    }

    /// Extrait le code matériel exact via `uname(&sysInfo)` (ex. `"iPhone12,1"`, `"iPhone17,1"`).
    public static func hardwareModelCode() -> String {
        #if canImport(Darwin)
        var sysInfo = utsname()
        uname(&sysInfo)
        let mirror = Mirror(reflecting: sysInfo.machine)
        let raw = mirror.children.reduce(into: "") { acc, elem in
            guard let v = elem.value as? Int8, v != 0 else { return }
            acc.append(Character(UnicodeScalar(UInt8(bitPattern: v))))
        }.trimmingCharacters(in: .whitespacesAndNewlines)

        if raw == "arm64" || raw == "x86_64" || raw == "i386" {
            if let simId = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"]?
                .trimmingCharacters(in: .whitespacesAndNewlines),
               !simId.isEmpty {
                return simId
            }
        }
        if !raw.isEmpty {
            return raw
        }
        #endif
        return "iPhone"
    }

    public static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] != nil
        #endif
    }

    /// Nom commercial lisible de l'appareil (ex: `"iPhone 11"`, `"iPhone 16 Pro"`).
    public static func commercialModelName() -> String {
        let code = hardwareModelCode()
        return commercialModelName(for: code)
    }

    public static func commercialModelName(for code: String) -> String {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "iPhone" }
        if let mapped = appleModels[trimmed] {
            return mapped
        }
        if trimmed.hasPrefix("iPhone19,") { return "iPhone 18 Series" }
        if trimmed.hasPrefix("iPad16,") { return "iPad Pro / Air (M4)" }
        if trimmed.hasPrefix("iPad15,") { return "iPad Air (M3)" }
        if trimmed.hasPrefix("iPad14,") { return "iPad Pro / Air (M2)" }
        if trimmed.hasPrefix("iPad13,") { return "iPad Air / Pro (M1)" }
        if trimmed.hasPrefix("iPad") { return "iPad (\(trimmed))" }
        if trimmed.hasPrefix("iPhone") { return "iPhone (\(trimmed))" }
        return trimmed
    }

    public static func osVersionString() -> String {
        let ver = ProcessInfo.processInfo.operatingSystemVersion
        let number: String
        if ver.patchVersion > 0 {
            number = "\(ver.majorVersion).\(ver.minorVersion).\(ver.patchVersion)"
        } else {
            number = "\(ver.majorVersion).\(ver.minorVersion)"
        }
        if hardwareModelCode().hasPrefix("iPad") {
            return "iPadOS \(number)"
        }
        return "iOS \(number)"
    }

    public static func httpHeaderSafe(_ value: String) -> String {
        let folded = value.folding(options: .diacriticInsensitive, locale: Locale(identifier: "en_US_POSIX"))
        let scalars = folded.unicodeScalars.filter { $0.value >= 0x20 && $0.value <= 0x7E }
        return String(String.UnicodeScalarView(scalars)).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public static func detectAppleTeamIdFromKeychain() -> String {
        let account = "viple.loobytaker.apns.teamid.probe"
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "fr.looby.taker.apns.probe",
            kSecAttrAccount as String: account,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        var status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            var addQuery = query
            addQuery.removeValue(forKey: kSecMatchLimit as String)
            addQuery[kSecValueData as String] = Data("1".utf8)
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            status = SecItemAdd(addQuery as CFDictionary, &result)
        }
        if status == errSecSuccess,
           let attrs = result as? [String: Any],
           let group = attrs[kSecAttrAccessGroup as String] as? String {
            let prefix = group.split(separator: ".").first.map(String.init) ?? ""
            if prefix.count == 10 && prefix.allSatisfy({ $0.isLetter || $0.isNumber }) {
                return prefix
            }
        }
        return ""
    }

    private static let appleModels: [String: String] = [
        "i386": "Simulateur iOS",
        "x86_64": "Simulateur iOS",
        "arm64": "Simulateur iOS",
        "iPhone10,1": "iPhone 8",
        "iPhone10,4": "iPhone 8",
        "iPhone10,2": "iPhone 8 Plus",
        "iPhone10,5": "iPhone 8 Plus",
        "iPhone10,3": "iPhone X",
        "iPhone10,6": "iPhone X",
        "iPhone11,2": "iPhone XS",
        "iPhone11,4": "iPhone XS Max",
        "iPhone11,6": "iPhone XS Max",
        "iPhone11,8": "iPhone XR",
        "iPhone12,1": "iPhone 11",
        "iPhone12,3": "iPhone 11 Pro",
        "iPhone12,5": "iPhone 11 Pro Max",
        "iPhone12,8": "iPhone SE (2e gen.)",
        "iPhone13,1": "iPhone 12 mini",
        "iPhone13,2": "iPhone 12",
        "iPhone13,3": "iPhone 12 Pro",
        "iPhone13,4": "iPhone 12 Pro Max",
        "iPhone14,2": "iPhone 13 Pro",
        "iPhone14,3": "iPhone 13 Pro Max",
        "iPhone14,4": "iPhone 13 mini",
        "iPhone14,5": "iPhone 13",
        "iPhone14,6": "iPhone SE (3e gen.)",
        "iPhone14,7": "iPhone 14",
        "iPhone14,8": "iPhone 14 Plus",
        "iPhone15,2": "iPhone 14 Pro",
        "iPhone15,3": "iPhone 14 Pro Max",
        "iPhone15,4": "iPhone 15",
        "iPhone15,5": "iPhone 15 Plus",
        "iPhone16,1": "iPhone 15 Pro",
        "iPhone16,2": "iPhone 15 Pro Max",
        "iPhone17,1": "iPhone 16 Pro",
        "iPhone17,2": "iPhone 16 Pro Max",
        "iPhone17,3": "iPhone 16",
        "iPhone17,4": "iPhone 16 Plus",
        "iPhone17,5": "iPhone 16e",
        "iPhone18,1": "iPhone 17 Pro",
        "iPhone18,2": "iPhone 17 Pro Max",
        "iPhone18,3": "iPhone 17",
        "iPhone18,4": "iPhone 17 Air",
        "iPhone18,5": "iPhone 17e",
        "iPhone19,1": "iPhone 18 Pro",
        "iPhone19,2": "iPhone 18 Pro Max",
        "iPhone19,3": "iPhone 18",
        "iPhone19,4": "iPhone 18 Air"
    ]
}
