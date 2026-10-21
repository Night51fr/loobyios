import Foundation
import SwiftUI

// MARK: - Configuration Officielle de l'Application « Looby » (Version 2.0 • Lancement B2C Grand Est le 21/11/2026)

public enum LoobyAppConfig: Sendable {
    public static let appName = "Looby"
    public static let bundleIdentifier = "com.viplenetwork.looby"
    public static let launchDateString = "21/11/2026"
    public static let launchISO = "2026-11-21T00:00:00+01:00"
    public static let livriaBaseAPI = "https://livria.store/api/mobile/v1"
    public static let socialBaseAPI = "https://livriasocial.viplenetwork.com/api/mobile/v1"
    public static let livriaStoreWebURL = "https://livria.store"
    public static let livriaStoreAppScheme = "livriastore"

    public static var officialLaunchDate: Date {
        var comps = DateComponents()
        comps.year = 2026
        comps.month = 11
        comps.day = 21
        comps.hour = 0
        comps.minute = 0
        comps.second = 0
        comps.timeZone = TimeZone(identifier: "Europe/Paris")
        return Calendar(identifier: .gregorian).date(from: comps) ?? Date().addingTimeInterval(86400 * 31)
    }
}

// MARK: - Viple Live ID Authentication & Cross-App SSO Models

public struct LoobyAuthResponse: Codable, Sendable {
    public var ok: Bool
    public var error: String?
    public var token: String?
    public var accountType: String?
    public var hasVipleMailBox: Bool?
    public var requiresApplePasswordSetup: Bool?
    public var icloudEmail: String?
    public var vipleMailAddress: String?
    public var needsOnboarding: Bool?
    public var appleUserId: String?
    public var appleEmail: String?
    public var suggestedFirstName: String?
    public var suggestedLastName: String?
    public var user: LoobyUserProfile?
}

public struct LoobyUserProfile: Codable, Identifiable, Equatable, Sendable {
    public var id: Int
    public var email: String
    public var displayName: String
    public var role: String?
    public var isAdmin: Bool
    public var isGuest: Bool?
    public var livriaAccountId: String
    public var accountProvider: String
    public var isLivriaPlus: Bool
    public var isBuyGod: Bool?
    public var loyaltyPoints: Int
    public var cashbackBalance: Double
    public var audioCredits: Int
    public var xp: Int
    public var level: Int
    public var streak: Int
    public var yearlyGoal: Int
    public var bio: String
    public var motto: String
    public var favoriteGenres: String
    public var accentColor: String
    public var firstName: String
    public var lastName: String
    public var phone: String
    public var address: String
    public var postalCode: String
    public var city: String
    public var cid: String
    public var avatarUrl: String

    public var isGuestAccount: Bool {
        isGuest == true || role == "Guest" || email.lowercased().hasSuffix("@guest.livria.store") || id <= 0
    }

    public var resolvedAvatarURL: URL? {
        let trimmed = avatarUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return URL(string: trimmed)
        }
        let clean = trimmed.hasPrefix("/") ? trimmed : "/\(trimmed)"
        return URL(string: "https://livria.store\(clean)")
    }

    public var initials: String {
        let parts = displayName.split(separator: " ").prefix(2)
        let str = parts.compactMap { $0.first.map(String.init) }.joined().uppercased()
        return str.isEmpty ? "VL" : str
    }

    public static let guestPlaceholder = LoobyUserProfile(
        id: 0,
        email: "invite@guest.livria.store",
        displayName: "Visiteur Looby",
        role: "Guest",
        isAdmin: false,
        isGuest: true,
        livriaAccountId: "",
        accountProvider: "Guest",
        isLivriaPlus: false,
        isBuyGod: false,
        loyaltyPoints: 0,
        cashbackBalance: 0,
        audioCredits: 0,
        xp: 0,
        level: 1,
        streak: 0,
        yearlyGoal: 12,
        bio: "",
        motto: "",
        favoriteGenres: "",
        accentColor: "#25BE9B",
        firstName: "",
        lastName: "",
        phone: "",
        address: "",
        postalCode: "",
        city: "",
        cid: "",
        avatarUrl: ""
    )
}

public struct LoobyCrossAppAccount: Codable, Equatable, Sendable, Identifiable {
    public var userId: Int
    public var email: String
    public var displayName: String
    public var firstName: String
    public var lastName: String
    public var cid: String
    public var avatarUrl: String
    public var bio: String
    public var isLivriaPlus: Bool
    public var level: Int
    public var xp: Int
    public var sourceApp: String
    public var targetApp: String

    public var id: Int { userId }

    enum CodingKeys: String, CodingKey {
        case userId, email, displayName, firstName, lastName, cid, avatarUrl, bio, isLivriaPlus, level, xp, sourceApp, targetApp
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        userId = (try? c.decode(Int.self, forKey: .userId)) ?? 0
        email = (try? c.decode(String.self, forKey: .email)) ?? ""
        displayName = (try? c.decode(String.self, forKey: .displayName)) ?? ""
        firstName = (try? c.decode(String.self, forKey: .firstName)) ?? ""
        lastName = (try? c.decode(String.self, forKey: .lastName)) ?? ""
        cid = (try? c.decode(String.self, forKey: .cid)) ?? ""
        avatarUrl = (try? c.decode(String.self, forKey: .avatarUrl)) ?? ""
        bio = (try? c.decode(String.self, forKey: .bio)) ?? ""
        isLivriaPlus = (try? c.decode(Bool.self, forKey: .isLivriaPlus)) ?? false
        level = (try? c.decode(Int.self, forKey: .level)) ?? 1
        xp = (try? c.decode(Int.self, forKey: .xp)) ?? 0
        sourceApp = (try? c.decode(String.self, forKey: .sourceApp)) ?? "Livria Store"
        targetApp = (try? c.decode(String.self, forKey: .targetApp)) ?? "Looby"
    }

    public var resolvedAvatarURL: URL? {
        let trimmed = avatarUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.hasPrefix("http") { return URL(string: trimmed) }
        return URL(string: "https://livria.store\(trimmed.hasPrefix("/") ? trimmed : "/\(trimmed)")")
    }

    public var initials: String {
        let parts = displayName.split(separator: " ").prefix(2)
        let str = parts.compactMap { $0.first.map(String.init) }.joined().uppercased()
        return str.isEmpty ? "V" : str
    }
}

public struct LoobyCrossAppDiscoverResponse: Codable, Sendable {
    public var ok: Bool
    public var hasDetectedAccount: Bool
    public var account: LoobyCrossAppAccount?

    enum CodingKeys: String, CodingKey {
        case ok, hasDetectedAccount, account
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        ok = (try? c.decode(Bool.self, forKey: .ok)) ?? false
        hasDetectedAccount = (try? c.decode(Bool.self, forKey: .hasDetectedAccount)) ?? false
        account = try? c.decodeIfPresent(LoobyCrossAppAccount.self, forKey: .account)
    }
}

// MARK: - Commandes (Livria & Looby) & Livres Livria (Synchronisés via /api/mobile/v1/bootstrap)

public struct LoobyOrderItem: Codable, Identifiable, Equatable, Sendable {
    public var id: String { "\(bookId)-\(title)-\(format)" }
    public var bookId: Int
    public var title: String
    public var author: String
    public var coverUrl: String
    public var format: String
    public var quantity: Int
    public var unitPrice: Double

    enum CodingKeys: String, CodingKey {
        case bookId, title, author, coverUrl, format, quantity, unitPrice
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        bookId = (try? c.decode(Int.self, forKey: .bookId)) ?? 0
        title = (try? c.decode(String.self, forKey: .title)) ?? "Article"
        author = (try? c.decode(String.self, forKey: .author)) ?? ""
        coverUrl = (try? c.decode(String.self, forKey: .coverUrl)) ?? ""
        format = (try? c.decode(String.self, forKey: .format)) ?? "Broché"
        quantity = (try? c.decode(Int.self, forKey: .quantity)) ?? 1
        unitPrice = (try? c.decode(Double.self, forKey: .unitPrice)) ?? 0
    }
}

public struct LoobyOrder: Codable, Identifiable, Equatable, Sendable {
    public var id: Int
    public var reference: String
    public var createdAt: String
    public var total: Double
    public var status: String
    public var carrier: String
    public var trackingNumber: String?
    public var shippingAddress: String
    public var isGiftWrapped: Bool
    public var isClickAndCollect: Bool
    public var items: [LoobyOrderItem]

    enum CodingKeys: String, CodingKey {
        case id, reference, createdAt, total, status, carrier, trackingNumber, shippingAddress, isGiftWrapped, isClickAndCollect, items
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? c.decode(Int.self, forKey: .id)) ?? 0
        reference = (try? c.decode(String.self, forKey: .reference)) ?? "#CMD-\(id)"
        createdAt = (try? c.decode(String.self, forKey: .createdAt)) ?? ""
        total = (try? c.decode(Double.self, forKey: .total)) ?? 0
        status = (try? c.decode(String.self, forKey: .status)) ?? "Payée"
        carrier = (try? c.decode(String.self, forKey: .carrier)) ?? "UPS Standard"
        trackingNumber = try? c.decodeIfPresent(String.self, forKey: .trackingNumber)
        shippingAddress = (try? c.decode(String.self, forKey: .shippingAddress)) ?? ""
        isGiftWrapped = (try? c.decode(Bool.self, forKey: .isGiftWrapped)) ?? false
        isClickAndCollect = (try? c.decode(Bool.self, forKey: .isClickAndCollect)) ?? false
        items = (try? c.decode([LoobyOrderItem].self, forKey: .items)) ?? []
    }
}

public struct LoobyLivriaBook: Codable, Identifiable, Equatable, Sendable {
    public var id: Int
    public var title: String
    public var author: String
    public var genre: String
    public var description: String
    public var coverUrl: String
    public var price: Double
    public var usedPrice: Double?
    public var stock: Int
    public var usedStock: Int?

    public var resolvedCoverURL: URL? {
        let trimmed = coverUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.hasPrefix("http") { return URL(string: trimmed) }
        return URL(string: "https://livria.store\(trimmed.hasPrefix("/") ? trimmed : "/\(trimmed)")")
    }
}

public struct LoobyBootstrapResponse: Codable, Sendable {
    public var ok: Bool
    public var user: LoobyUserProfile?
    public var books: [LoobyLivriaBook]?
    public var orders: [LoobyOrder]?
}

// MARK: - Commerces Locaux B2C du Grand Est (Exploration Interactive & Pré-réservation Lancement 21/11/2026)

public struct LoobyGrandEstProductPreview: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let price: Double
    public let badge: String
    public let originLabel: String
}

public struct LoobyGrandEstMerchant: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let city: String
    public let department: String
    public let category: String
    public let tagline: String
    public let description: String
    public let icon: String
    public let accentHex: String
    public let clickAndCollectMinutes: Int
    public let rating: Double
    public let verifiedSiretBadge: String
    public let sampleProducts: [LoobyGrandEstProductPreview]
}

// MARK: - Comparatif Viple Live ID (2026) vs Ancien Viple ID

public struct LoobyVipleIdComparisonItem: Identifiable, Sendable {
    public let id = UUID()
    public let featureTitle: String
    public let icon: String
    public let legacyVipleIdText: String
    public let newVipleLiveIdText: String
    public let highlightTag: String
}

// MARK: - Articles des CGU de la Marketplace B2C Looby

public struct LoobyLegalArticle: Identifiable, Sendable {
    public let id: String
    public let number: String
    public let title: String
    public let summaryBadge: String
    public let icon: String
    public let paragraphs: [String]
}
