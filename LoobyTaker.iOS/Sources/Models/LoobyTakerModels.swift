import Foundation

// MARK: - Utilitaires de Décodage JSON Ultra-Tolérant (Swift 6 Sendable)

extension KeyedDecodingContainer {
    func decodeString(_ key: Key, default defaultValue: String = "") -> String {
        if let str = try? decodeIfPresent(String.self, forKey: key) {
            return str
        }
        if let intVal = try? decodeIfPresent(Int.self, forKey: key) {
            return String(intVal)
        }
        if let dblVal = try? decodeIfPresent(Double.self, forKey: key) {
            return String(dblVal)
        }
        return defaultValue
    }

    func decodeOptionalString(_ key: Key) -> String? {
        if let str = try? decodeIfPresent(String.self, forKey: key) {
            return str
        }
        if let intVal = try? decodeIfPresent(Int.self, forKey: key) {
            return String(intVal)
        }
        return nil
    }

    func decodeInt(_ key: Key, default defaultValue: Int = 0) -> Int {
        if let intVal = try? decodeIfPresent(Int.self, forKey: key) {
            return intVal
        }
        if let strVal = try? decodeIfPresent(String.self, forKey: key) {
            let digits = strVal.trimmingCharacters(in: .whitespacesAndNewlines)
            if let parsed = Int(digits) {
                return parsed
            }
            // Supporte des identifiants hybrides comme "id-2" -> 2
            let stripped = digits.replacingOccurrences(of: "id-", with: "")
            if let parsedStripped = Int(stripped) {
                return parsedStripped
            }
        }
        if let dblVal = try? decodeIfPresent(Double.self, forKey: key) {
            return Int(dblVal)
        }
        return defaultValue
    }

    func decodeOptionalInt(_ key: Key) -> Int? {
        if let intVal = try? decodeIfPresent(Int.self, forKey: key) {
            return intVal
        }
        if let strVal = try? decodeIfPresent(String.self, forKey: key),
           let parsed = Int(strVal.replacingOccurrences(of: "id-", with: "")) {
            return parsed
        }
        return nil
    }

    func decodeDouble(_ key: Key, default defaultValue: Double = 0.0) -> Double {
        if let dblVal = try? decodeIfPresent(Double.self, forKey: key) {
            return dblVal
        }
        if let intVal = try? decodeIfPresent(Int.self, forKey: key) {
            return Double(intVal)
        }
        if let strVal = try? decodeIfPresent(String.self, forKey: key),
           let parsed = Double(strVal.replacingOccurrences(of: ",", with: ".")) {
            return parsed
        }
        return defaultValue
    }

    func decodeOptionalDouble(_ key: Key) -> Double? {
        if let dblVal = try? decodeIfPresent(Double.self, forKey: key) {
            return dblVal
        }
        if let intVal = try? decodeIfPresent(Int.self, forKey: key) {
            return Double(intVal)
        }
        if let strVal = try? decodeIfPresent(String.self, forKey: key),
           let parsed = Double(strVal.replacingOccurrences(of: ",", with: ".")) {
            return parsed
        }
        return nil
    }

    func decodeBool(_ key: Key, default defaultValue: Bool = false) -> Bool {
        if let boolVal = try? decodeIfPresent(Bool.self, forKey: key) {
            return boolVal
        }
        if let intVal = try? decodeIfPresent(Int.self, forKey: key) {
            return intVal != 0
        }
        if let strVal = try? decodeIfPresent(String.self, forKey: key) {
            let lower = strVal.lowercased()
            if lower == "true" || lower == "1" || lower == "yes" { return true }
            if lower == "false" || lower == "0" || lower == "no" { return false }
        }
        return defaultValue
    }

    func decodeOptionalBool(_ key: Key) -> Bool? {
        if let boolVal = try? decodeIfPresent(Bool.self, forKey: key) {
            return boolVal
        }
        if let intVal = try? decodeIfPresent(Int.self, forKey: key) {
            return intVal != 0
        }
        if let strVal = try? decodeIfPresent(String.self, forKey: key) {
            let lower = strVal.lowercased()
            if lower == "true" || lower == "1" { return true }
            if lower == "false" || lower == "0" { return false }
        }
        return nil
    }
}

// MARK: - 1. Authentification & SSO Écosystème Viple Live ID / Cenelis

public struct TakerUserProfile: Codable, Identifiable, Equatable, Hashable, Sendable {
    public var id: Int
    public var rawUserId: String
    public var email: String
    public var displayName: String
    public var firstName: String
    public var lastName: String
    public var phone: String
    public var cid: String
    public var livriaId: Int
    public var avatarUrl: String

    public init(
        id: Int = 0,
        rawUserId: String = "",
        email: String = "",
        displayName: String = "",
        firstName: String = "",
        lastName: String = "",
        phone: String = "",
        cid: String = "",
        livriaId: Int = 0,
        avatarUrl: String = ""
    ) {
        self.id = id
        self.rawUserId = rawUserId.isEmpty ? (id > 0 ? String(id) : "") : rawUserId
        self.email = email
        self.displayName = displayName
        self.firstName = firstName
        self.lastName = lastName
        self.phone = phone
        self.cid = cid
        self.livriaId = livriaId > 0 ? livriaId : id
        self.avatarUrl = avatarUrl
    }

    enum CodingKeys: String, CodingKey {
        case id, email, displayName, firstName, lastName, phone, cid, livriaId, avatarUrl
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let rawStr = c.decodeString(.id, default: "")
        let parsedId = c.decodeInt(.id, default: 0)
        let parsedLivriaId = c.decodeInt(.livriaId, default: parsedId)
        id = parsedId > 0 ? parsedId : parsedLivriaId
        rawUserId = rawStr.isEmpty ? (id > 0 ? String(id) : "") : rawStr
        email = c.decodeString(.email)
        let fn = c.decodeString(.firstName)
        let ln = c.decodeString(.lastName)
        firstName = fn
        lastName = ln
        let dn = c.decodeString(.displayName)
        if !dn.isEmpty {
            displayName = dn
        } else if !fn.isEmpty || !ln.isEmpty {
            displayName = "\(fn) \(ln)".trimmingCharacters(in: .whitespaces)
        } else {
            displayName = email.split(separator: "@").first.map(String.init) ?? "Membre Viple"
        }
        phone = c.decodeString(.phone)
        cid = c.decodeString(.cid)
        livriaId = parsedLivriaId > 0 ? parsedLivriaId : id
        avatarUrl = c.decodeString(.avatarUrl)
    }

    public var effectiveUserIdQuery: String {
        if !rawUserId.isEmpty && rawUserId != "0" {
            return rawUserId
        }
        if livriaId > 0 {
            return String(livriaId)
        }
        if id > 0 {
            return String(id)
        }
        return ""
    }

    public var initials: String {
        let parts = displayName.split(separator: " ")
        if parts.count >= 2 {
            let a = parts[0].prefix(1).uppercased()
            let b = parts[1].prefix(1).uppercased()
            return "\(a)\(b)"
        }
        return String(displayName.prefix(2)).uppercased()
    }
}

public struct TakerAuthResponse: Codable, Equatable, Sendable {
    public var ok: Bool
    public var token: String?
    public var user: TakerUserProfile?
    public var error: String?
    public var message: String?

    public init(
        ok: Bool = false,
        token: String? = nil,
        user: TakerUserProfile? = nil,
        error: String? = nil,
        message: String? = nil
    ) {
        self.ok = ok
        self.token = token
        self.user = user
        self.error = error
        self.message = message
    }

    enum CodingKeys: String, CodingKey {
        case ok, token, user, error, message
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        user = try? c.decodeIfPresent(TakerUserProfile.self, forKey: .user)
        token = c.decodeOptionalString(.token)
        error = c.decodeOptionalString(.error)
        message = c.decodeOptionalString(.message)
        ok = c.decodeBool(.ok, default: user != nil && (error ?? "").isEmpty)
    }
}

public struct TakerCrossAppAccount: Codable, Equatable, Sendable {
    public var userId: Int
    public var email: String
    public var displayName: String
    public var cid: String
    public var sourceApp: String
    public var avatarUrl: String

    public init(
        userId: Int = 0,
        email: String = "",
        displayName: String = "",
        cid: String = "",
        sourceApp: String = "Écosystème Viple",
        avatarUrl: String = ""
    ) {
        self.userId = userId
        self.email = email
        self.displayName = displayName
        self.cid = cid
        self.sourceApp = sourceApp
        self.avatarUrl = avatarUrl
    }

    enum CodingKeys: String, CodingKey {
        case userId, id, email, displayName, cid, sourceApp, appName, avatarUrl
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let uid = c.decodeInt(.userId, default: 0)
        userId = uid > 0 ? uid : c.decodeInt(.id, default: 0)
        email = c.decodeString(.email)
        let dn = c.decodeString(.displayName)
        displayName = dn.isEmpty ? (email.split(separator: "@").first.map(String.init) ?? "Compte Viple") : dn
        cid = c.decodeString(.cid)
        let src = c.decodeString(.sourceApp)
        sourceApp = src.isEmpty ? c.decodeString(.appName, default: "Écosystème Viple") : src
        avatarUrl = c.decodeString(.avatarUrl)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(userId, forKey: .userId)
        try c.encode(email, forKey: .email)
        try c.encode(displayName, forKey: .displayName)
        try c.encode(cid, forKey: .cid)
        try c.encode(sourceApp, forKey: .sourceApp)
        try c.encode(avatarUrl, forKey: .avatarUrl)
    }
}

public struct TakerCrossAppDiscoverResponse: Codable, Equatable, Sendable {
    public var ok: Bool
    public var hasDetectedAccount: Bool
    public var account: TakerCrossAppAccount?

    enum CodingKeys: String, CodingKey {
        case ok, hasDetectedAccount, account
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        ok = c.decodeBool(.ok, default: true)
        account = try? c.decodeIfPresent(TakerCrossAppAccount.self, forKey: .account)
        hasDetectedAccount = c.decodeBool(.hasDetectedAccount, default: account != nil)
    }
}

// MARK: - 2. Planning Hebdomadaire, Disponibilités, Vacances & Statistiques du Point Relais

public struct TakerDaySchedule: Codable, Identifiable, Equatable, Hashable, Sendable {
    public var dayIndex: Int
    public var dayName: String
    public var isOpen: Bool
    public var morningStart: String
    public var morningEnd: String
    public var hasAfternoonBreak: Bool
    public var afternoonStart: String
    public var afternoonEnd: String
    public var note: String

    public var id: String { "\(dayIndex)-\(dayName)" }

    public init(
        dayIndex: Int,
        dayName: String,
        isOpen: Bool = true,
        morningStart: String = "09:00",
        morningEnd: String = "12:30",
        hasAfternoonBreak: Bool = true,
        afternoonStart: String = "14:00",
        afternoonEnd: String = "19:00",
        note: String = ""
    ) {
        self.dayIndex = dayIndex
        self.dayName = dayName
        self.isOpen = isOpen
        self.morningStart = morningStart
        self.morningEnd = morningEnd
        self.hasAfternoonBreak = hasAfternoonBreak
        self.afternoonStart = afternoonStart
        self.afternoonEnd = afternoonEnd
        self.note = note
    }

    enum CodingKeys: String, CodingKey {
        case dayIndex, dayName, day, isOpen, enabled
        case morningStart, morningOpen, openTime
        case morningEnd, morningClose
        case hasAfternoonBreak
        case afternoonStart, afternoonOpen
        case afternoonEnd, afternoonClose, closeTime
        case note
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let idx = c.decodeInt(.dayIndex, default: 1)
        dayIndex = idx
        let rawName = c.decodeString(.dayName)
        let altName = c.decodeString(.day)
        dayName = !rawName.isEmpty ? rawName : (!altName.isEmpty ? altName : Self.frenchDayName(for: idx))
        if let openExplicit = c.decodeOptionalBool(.isOpen) {
            isOpen = openExplicit
        } else if let enabledExplicit = c.decodeOptionalBool(.enabled) {
            isOpen = enabledExplicit
        } else {
            isOpen = idx != 7
        }
        let ms = c.decodeString(.morningStart)
        morningStart = !ms.isEmpty ? ms : c.decodeString(.morningOpen, default: c.decodeString(.openTime, default: "09:00"))
        let me = c.decodeString(.morningEnd)
        morningEnd = !me.isEmpty ? me : c.decodeString(.morningClose, default: "12:30")
        let afs = c.decodeString(.afternoonStart)
        afternoonStart = !afs.isEmpty ? afs : c.decodeString(.afternoonOpen, default: "14:00")
        let afe = c.decodeString(.afternoonEnd)
        afternoonEnd = !afe.isEmpty ? afe : c.decodeString(.afternoonClose, default: c.decodeString(.closeTime, default: "19:00"))
        hasAfternoonBreak = c.decodeBool(.hasAfternoonBreak, default: !afternoonStart.isEmpty && !morningEnd.isEmpty)
        note = c.decodeString(.note)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(dayIndex, forKey: .dayIndex)
        try c.encode(dayName, forKey: .dayName)
        try c.encode(isOpen, forKey: .isOpen)
        try c.encode(morningStart, forKey: .morningStart)
        try c.encode(morningEnd, forKey: .morningEnd)
        try c.encode(hasAfternoonBreak, forKey: .hasAfternoonBreak)
        try c.encode(afternoonStart, forKey: .afternoonStart)
        try c.encode(afternoonEnd, forKey: .afternoonEnd)
        try c.encode(note, forKey: .note)
    }

    public func toDictionary() -> [String: Any] {
        [
            "dayIndex": dayIndex,
            "dayName": dayName,
            "day": dayName,
            "isOpen": isOpen,
            "morningStart": morningStart,
            "morningEnd": morningEnd,
            "hasAfternoonBreak": hasAfternoonBreak,
            "afternoonStart": afternoonStart,
            "afternoonEnd": afternoonEnd,
            "note": note
        ]
    }

    public var formattedHoursFr: String {
        guard isOpen else { return "Fermé" }
        if hasAfternoonBreak {
            return "\(morningStart)–\(morningEnd) • \(afternoonStart)–\(afternoonEnd)"
        }
        return "\(morningStart)–\(afternoonEnd)"
    }

    public static func frenchDayName(for index: Int) -> String {
        switch index {
        case 1: return "Lundi"
        case 2: return "Mardi"
        case 3: return "Mercredi"
        case 4: return "Jeudi"
        case 5: return "Vendredi"
        case 6: return "Samedi"
        case 7: return "Dimanche"
        default: return "Jour \(index)"
        }
    }

    public static func defaultWeek(isPro: Bool) -> [TakerDaySchedule] {
        (1...7).map { idx in
            if isPro {
                return TakerDaySchedule(
                    dayIndex: idx,
                    dayName: frenchDayName(for: idx),
                    isOpen: idx <= 6,
                    morningStart: "09:00",
                    morningEnd: "12:30",
                    hasAfternoonBreak: true,
                    afternoonStart: "14:00",
                    afternoonEnd: "19:00"
                )
            } else {
                return TakerDaySchedule(
                    dayIndex: idx,
                    dayName: frenchDayName(for: idx),
                    isOpen: idx <= 6,
                    morningStart: idx == 6 ? "09:30" : "17:30",
                    morningEnd: idx == 6 ? "12:30" : "20:30",
                    hasAfternoonBreak: idx == 6,
                    afternoonStart: "14:00",
                    afternoonEnd: idx == 6 ? "19:00" : "20:30"
                )
            }
        }
    }
}

public struct TakerAvailabilitySlot: Codable, Identifiable, Equatable, Hashable, Sendable {
    public var id: String
    public var dayLabel: String
    public var date: String
    public var startTime: String
    public var endTime: String
    public var acceptsDeliveries: Bool
    public var acceptsCustomerPickups: Bool
    public var maxPickups: Int
    public var note: String

    public init(
        id: String = UUID().uuidString,
        dayLabel: String = "En semaine (Lun–Ven)",
        date: String = "",
        startTime: String = "17:30",
        endTime: String = "20:30",
        acceptsDeliveries: Bool = true,
        acceptsCustomerPickups: Bool = true,
        maxPickups: Int = 8,
        note: String = ""
    ) {
        self.id = id
        self.dayLabel = dayLabel
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.acceptsDeliveries = acceptsDeliveries
        self.acceptsCustomerPickups = acceptsCustomerPickups
        self.maxPickups = maxPickups
        self.note = note
    }

    enum CodingKeys: String, CodingKey {
        case id, dayLabel, label, date, startTime, endTime, acceptsDeliveries, acceptsCustomerPickups, maxPickups, note
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let rawId = c.decodeString(.id)
        id = rawId.isEmpty ? UUID().uuidString : rawId
        let dl = c.decodeString(.dayLabel)
        dayLabel = !dl.isEmpty ? dl : c.decodeString(.label, default: "Créneau de présence")
        date = c.decodeString(.date)
        startTime = c.decodeString(.startTime, default: "17:30")
        endTime = c.decodeString(.endTime, default: "20:30")
        acceptsDeliveries = c.decodeBool(.acceptsDeliveries, default: true)
        acceptsCustomerPickups = c.decodeBool(.acceptsCustomerPickups, default: true)
        maxPickups = c.decodeInt(.maxPickups, default: 8)
        note = c.decodeString(.note)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(dayLabel, forKey: .dayLabel)
        try c.encode(date, forKey: .date)
        try c.encode(startTime, forKey: .startTime)
        try c.encode(endTime, forKey: .endTime)
        try c.encode(acceptsDeliveries, forKey: .acceptsDeliveries)
        try c.encode(acceptsCustomerPickups, forKey: .acceptsCustomerPickups)
        try c.encode(maxPickups, forKey: .maxPickups)
        try c.encode(note, forKey: .note)
    }

    public func toDictionary() -> [String: Any] {
        [
            "id": id,
            "dayLabel": dayLabel,
            "label": dayLabel,
            "date": date,
            "startTime": startTime,
            "endTime": endTime,
            "acceptsDeliveries": acceptsDeliveries,
            "acceptsCustomerPickups": acceptsCustomerPickups,
            "maxPickups": maxPickups,
            "note": note
        ]
    }
}

public struct TakerVacationConfig: Codable, Equatable, Hashable, Sendable {
    public var enabled: Bool
    public var startDate: String
    public var endDate: String
    public var message: String
    public var allowExistingPickupsOnly: Bool

    public init(
        enabled: Bool = false,
        startDate: String = "",
        endDate: String = "",
        message: String = "",
        allowExistingPickupsOnly: Bool = true
    ) {
        self.enabled = enabled
        self.startDate = startDate
        self.endDate = endDate
        self.message = message
        self.allowExistingPickupsOnly = allowExistingPickupsOnly
    }

    enum CodingKeys: String, CodingKey {
        case enabled, isActive, startDate, endDate, message, allowExistingPickupsOnly
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let exp = c.decodeOptionalBool(.enabled) {
            enabled = exp
        } else {
            enabled = c.decodeBool(.isActive, default: false)
        }
        startDate = c.decodeString(.startDate)
        endDate = c.decodeString(.endDate)
        message = c.decodeString(.message)
        allowExistingPickupsOnly = c.decodeBool(.allowExistingPickupsOnly, default: true)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(enabled, forKey: .enabled)
        try c.encode(startDate, forKey: .startDate)
        try c.encode(endDate, forKey: .endDate)
        try c.encode(message, forKey: .message)
        try c.encode(allowExistingPickupsOnly, forKey: .allowExistingPickupsOnly)
    }
}

public struct TakerRelayStats: Codable, Equatable, Hashable, Sendable {
    public var expectedCount: Int
    public var inStockCount: Int
    public var handedOverTodayCount: Int
    public var handedOverTotalCount: Int
    public var todayAppointmentsCount: Int
    public var openIssuesCount: Int
    public var totalEarnedEur: Double
    public var monthEarnedEur: Double

    public init(
        expectedCount: Int = 0,
        inStockCount: Int = 0,
        handedOverTodayCount: Int = 0,
        handedOverTotalCount: Int = 0,
        todayAppointmentsCount: Int = 0,
        openIssuesCount: Int = 0,
        totalEarnedEur: Double = 0.0,
        monthEarnedEur: Double = 0.0
    ) {
        self.expectedCount = expectedCount
        self.inStockCount = inStockCount
        self.handedOverTodayCount = handedOverTodayCount
        self.handedOverTotalCount = handedOverTotalCount
        self.todayAppointmentsCount = todayAppointmentsCount
        self.openIssuesCount = openIssuesCount
        self.totalEarnedEur = totalEarnedEur
        self.monthEarnedEur = monthEarnedEur
    }

    enum CodingKeys: String, CodingKey {
        case expectedCount, expectedParcels
        case inStockCount, inStockParcels
        case handedOverTodayCount, handedOverToday
        case handedOverTotalCount, handedOverTotal, deliveredCount
        case todayAppointmentsCount, appointmentsToday
        case openIssuesCount, issuesCount
        case totalEarnedEur, earnedTotalEur, totalEarningsEur
        case monthEarnedEur, earnedMonthEur
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        expectedCount = c.decodeOptionalInt(.expectedCount) ?? c.decodeInt(.expectedParcels, default: 0)
        inStockCount = c.decodeOptionalInt(.inStockCount) ?? c.decodeInt(.inStockParcels, default: 0)
        handedOverTodayCount = c.decodeOptionalInt(.handedOverTodayCount) ?? c.decodeInt(.handedOverToday, default: 0)
        handedOverTotalCount = c.decodeOptionalInt(.handedOverTotalCount)
            ?? c.decodeOptionalInt(.handedOverTotal)
            ?? c.decodeInt(.deliveredCount, default: 0)
        todayAppointmentsCount = c.decodeOptionalInt(.todayAppointmentsCount) ?? c.decodeInt(.appointmentsToday, default: 0)
        openIssuesCount = c.decodeOptionalInt(.openIssuesCount) ?? c.decodeInt(.issuesCount, default: 0)
        totalEarnedEur = c.decodeOptionalDouble(.totalEarnedEur)
            ?? c.decodeOptionalDouble(.earnedTotalEur)
            ?? c.decodeDouble(.totalEarningsEur, default: 0.0)
        monthEarnedEur = c.decodeOptionalDouble(.monthEarnedEur)
            ?? c.decodeDouble(.earnedMonthEur, default: totalEarnedEur)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(expectedCount, forKey: .expectedCount)
        try c.encode(inStockCount, forKey: .inStockCount)
        try c.encode(handedOverTodayCount, forKey: .handedOverTodayCount)
        try c.encode(handedOverTotalCount, forKey: .handedOverTotalCount)
        try c.encode(todayAppointmentsCount, forKey: .todayAppointmentsCount)
        try c.encode(openIssuesCount, forKey: .openIssuesCount)
        try c.encode(totalEarnedEur, forKey: .totalEarnedEur)
        try c.encode(monthEarnedEur, forKey: .monthEarnedEur)
    }
}

// MARK: - 3. Point Relais « TakerRelayPoint » (Particulier & Pro)

public struct TakerRelayPoint: Codable, Identifiable, Equatable, Hashable, Sendable {
    public var id: Int
    public var name: String
    public var relayMode: String // "Particulier" ou "Pro"
    public var typeLabel: String
    public var address: String
    public var postalCode: String
    public var city: String
    public var phone: String
    public var siret: String
    public var businessCategory: String
    public var intercomAndAccessNotes: String
    public var maxParcelCapacity: Int
    public var openingHoursSummary: String
    public var isCurrentlyClosedOverride: Bool
    public var closureReason: String
    public var commissionPerParcel: Double
    public var weeklySchedule: [TakerDaySchedule]
    public var availabilities: [TakerAvailabilitySlot]
    public var vacationMode: TakerVacationConfig
    public var stats: TakerRelayStats

    public init(
        id: Int = 2,
        name: String = "Viple Taker - Chez Chris",
        relayMode: String = "Particulier",
        typeLabel: String = "Point Relais Particulier (1,00 €/colis)",
        address: String = "",
        postalCode: String = "",
        city: String = "",
        phone: String = "",
        siret: String = "",
        businessCategory: String = "",
        intercomAndAccessNotes: String = "",
        maxParcelCapacity: Int = 25,
        openingHoursSummary: String = "Lun-Ven 17h30-20h30 • Sam 09h30-19h00",
        isCurrentlyClosedOverride: Bool = false,
        closureReason: String = "",
        commissionPerParcel: Double = 1.0,
        weeklySchedule: [TakerDaySchedule] = [],
        availabilities: [TakerAvailabilitySlot] = [],
        vacationMode: TakerVacationConfig = TakerVacationConfig(),
        stats: TakerRelayStats = TakerRelayStats()
    ) {
        self.id = id
        self.name = name
        self.relayMode = relayMode
        self.typeLabel = typeLabel
        self.address = address
        self.postalCode = postalCode
        self.city = city
        self.phone = phone
        self.siret = siret
        self.businessCategory = businessCategory
        self.intercomAndAccessNotes = intercomAndAccessNotes
        self.maxParcelCapacity = maxParcelCapacity
        self.openingHoursSummary = openingHoursSummary
        self.isCurrentlyClosedOverride = isCurrentlyClosedOverride
        self.closureReason = closureReason
        self.commissionPerParcel = commissionPerParcel
        self.weeklySchedule = weeklySchedule.isEmpty ? TakerDaySchedule.defaultWeek(isPro: relayMode.lowercased() == "pro") : weeklySchedule
        self.availabilities = availabilities
        self.vacationMode = vacationMode
        self.stats = stats
    }

    enum CodingKeys: String, CodingKey {
        case id, name, relayMode, typeLabel, address, postalCode, city, phone
        case siret, businessCategory, intercomAndAccessNotes, maxParcelCapacity
        case openingHoursSummary, isCurrentlyClosedOverride, closureReason
        case commissionPerParcel, weeklySchedule, availabilities, vacationMode, stats
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeInt(.id, default: 1)
        name = c.decodeString(.name, default: "Point Relais Looby Taker")
        let rawMode = c.decodeString(.relayMode, default: "Particulier")
        let normalizedPro = rawMode.lowercased().contains("pro") || rawMode.lowercased().contains("commerce")
        relayMode = normalizedPro ? "Pro" : "Particulier"
        let defaultTypeLbl = normalizedPro ? "Point Relais Professionnel" : "Point Relais Particulier (1,00 €/colis)"
        let decodedType = c.decodeString(.typeLabel)
        typeLabel = decodedType.isEmpty ? defaultTypeLbl : decodedType
        address = c.decodeString(.address)
        postalCode = c.decodeString(.postalCode)
        city = c.decodeString(.city)
        phone = c.decodeString(.phone)
        siret = c.decodeString(.siret)
        businessCategory = c.decodeString(.businessCategory)
        intercomAndAccessNotes = c.decodeString(.intercomAndAccessNotes)
        maxParcelCapacity = c.decodeInt(.maxParcelCapacity, default: normalizedPro ? 60 : 25)
        openingHoursSummary = c.decodeString(
            .openingHoursSummary,
            default: normalizedPro ? "Lun–Sam 09h00–12h30 & 14h00–19h00" : "Lun–Ven 17h30–20h30 • Sam 09h30–19h00"
        )
        isCurrentlyClosedOverride = c.decodeBool(.isCurrentlyClosedOverride, default: false)
        closureReason = c.decodeString(.closureReason)
        commissionPerParcel = c.decodeDouble(.commissionPerParcel, default: 1.0)
        let decodedSchedule = (try? c.decodeIfPresent([TakerDaySchedule].self, forKey: .weeklySchedule)) ?? []
        weeklySchedule = decodedSchedule.isEmpty ? TakerDaySchedule.defaultWeek(isPro: normalizedPro) : decodedSchedule
        availabilities = (try? c.decodeIfPresent([TakerAvailabilitySlot].self, forKey: .availabilities)) ?? []
        vacationMode = (try? c.decodeIfPresent(TakerVacationConfig.self, forKey: .vacationMode)) ?? TakerVacationConfig()
        stats = (try? c.decodeIfPresent(TakerRelayStats.self, forKey: .stats)) ?? TakerRelayStats()
    }

    public var isPro: Bool {
        relayMode.lowercased() == "pro"
    }

    public var fullAddress: String {
        let parts = [address, "\(postalCode) \(city)".trimmingCharacters(in: .whitespaces)]
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        return parts.isEmpty ? "Adresse à compléter" : parts.joined(separator: ", ")
    }

    public var liveStatusTitle: String {
        if isCurrentlyClosedOverride {
            return "Fermeture exceptionnelle"
        }
        if vacationMode.enabled {
            return "Mode vacances actif"
        }
        return "Ouvert & opérationnel"
    }

    public var liveStatusIcon: String {
        if isCurrentlyClosedOverride {
            return "door.left.hand.closed"
        }
        if vacationMode.enabled {
            return "sun.horizon.fill"
        }
        return "checkmark.circle.fill"
    }
}

// MARK: - 4. Colis, Rendez-vous, Anomalies de Réception & Candidatures

public struct TakerParcel: Codable, Identifiable, Equatable, Hashable, Sendable {
    public var id: String
    public var relayId: Int
    public var vipleBarcode: String
    public var carrier: String
    public var carrierTrackingNumber: String
    public var sourceApp: String
    public var orderReference: String
    public var recipientName: String
    public var recipientPhone: String
    public var recipientEmail: String
    public var status: String // "expected" | "in_stock" | "handed_over" | "issue_reported"
    public var statusLabel: String
    public var shelfLocation: String
    public var requiresPinForHandover: Bool
    public var pinHintForDemo: String?
    public var expectedArrivalDate: String
    public var expectedArrivalWindow: String
    public var weightClass: String
    public var notes: String
    public var receivedAtUtc: String?
    public var handedOverAtUtc: String?
    public var appointmentId: String?
    public var hasIssue: Bool
    public var issueSummary: String?

    public init(
        id: String = UUID().uuidString,
        relayId: Int = 2,
        vipleBarcode: String = "",
        carrier: String = "Viple Delivery",
        carrierTrackingNumber: String = "",
        sourceApp: String = "Livria Store",
        orderReference: String = "",
        recipientName: String = "",
        recipientPhone: String = "",
        recipientEmail: String = "",
        status: String = "expected",
        statusLabel: String = "En approche",
        shelfLocation: String = "",
        requiresPinForHandover: Bool = true,
        pinHintForDemo: String? = nil,
        expectedArrivalDate: String = "",
        expectedArrivalWindow: String = "",
        weightClass: String = "Standard (< 2 kg)",
        notes: String = "",
        receivedAtUtc: String? = nil,
        handedOverAtUtc: String? = nil,
        appointmentId: String? = nil,
        hasIssue: Bool = false,
        issueSummary: String? = nil
    ) {
        self.id = id
        self.relayId = relayId
        self.vipleBarcode = vipleBarcode
        self.carrier = carrier
        self.carrierTrackingNumber = carrierTrackingNumber
        self.sourceApp = sourceApp
        self.orderReference = orderReference
        self.recipientName = recipientName
        self.recipientPhone = recipientPhone
        self.recipientEmail = recipientEmail
        self.status = status
        self.statusLabel = statusLabel
        self.shelfLocation = shelfLocation
        self.requiresPinForHandover = requiresPinForHandover
        self.pinHintForDemo = pinHintForDemo
        self.expectedArrivalDate = expectedArrivalDate
        self.expectedArrivalWindow = expectedArrivalWindow
        self.weightClass = weightClass
        self.notes = notes
        self.receivedAtUtc = receivedAtUtc
        self.handedOverAtUtc = handedOverAtUtc
        self.appointmentId = appointmentId
        self.hasIssue = hasIssue
        self.issueSummary = issueSummary
    }

    enum CodingKeys: String, CodingKey {
        case id, relayId, vipleBarcode, carrier, carrierTrackingNumber, sourceApp, orderReference
        case recipientName, recipientPhone, recipientEmail, status, statusLabel, shelfLocation
        case requiresPinForHandover, pinHintForDemo, expectedArrivalDate, expectedArrivalWindow
        case weightClass, notes, receivedAtUtc, handedOverAtUtc, appointmentId, hasIssue, issueSummary
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let rawId = c.decodeString(.id)
        let vb = c.decodeString(.vipleBarcode)
        id = !rawId.isEmpty ? rawId : (!vb.isEmpty ? vb : UUID().uuidString)
        relayId = c.decodeInt(.relayId, default: 0)
        vipleBarcode = vb.isEmpty ? id : vb
        carrier = c.decodeString(.carrier, default: "Viple Delivery")
        carrierTrackingNumber = c.decodeString(.carrierTrackingNumber)
        sourceApp = c.decodeString(.sourceApp, default: "Livria Store")
        orderReference = c.decodeString(.orderReference)
        recipientName = c.decodeString(.recipientName, default: "Client Livria")
        recipientPhone = c.decodeString(.recipientPhone)
        recipientEmail = c.decodeString(.recipientEmail)
        let st = c.decodeString(.status, default: "expected")
        status = st
        let stLbl = c.decodeString(.statusLabel)
        statusLabel = stLbl.isEmpty ? Self.frenchStatus(for: st) : stLbl
        shelfLocation = c.decodeString(.shelfLocation)
        requiresPinForHandover = c.decodeBool(.requiresPinForHandover, default: true)
        pinHintForDemo = c.decodeOptionalString(.pinHintForDemo)
        expectedArrivalDate = c.decodeString(.expectedArrivalDate)
        expectedArrivalWindow = c.decodeString(.expectedArrivalWindow)
        weightClass = c.decodeString(.weightClass, default: "Standard")
        notes = c.decodeString(.notes)
        receivedAtUtc = c.decodeOptionalString(.receivedAtUtc)
        handedOverAtUtc = c.decodeOptionalString(.handedOverAtUtc)
        appointmentId = c.decodeOptionalString(.appointmentId)
        issueSummary = c.decodeOptionalString(.issueSummary)
        hasIssue = c.decodeBool(.hasIssue, default: st == "issue_reported" || !(issueSummary ?? "").isEmpty)
    }

    public static func frenchStatus(for status: String) -> String {
        switch status.lowercased() {
        case "expected": return "En approche"
        case "in_stock": return "En stock"
        case "handed_over": return "Remis au client"
        case "issue_reported": return "Problème signalé"
        default: return status
        }
    }

    public var isExpected: Bool { status.lowercased() == "expected" }
    public var isInStock: Bool { status.lowercased() == "in_stock" }
    public var isHandedOver: Bool { status.lowercased() == "handed_over" }
    public var isIssueReported: Bool { status.lowercased() == "issue_reported" || hasIssue }
    public var isDeliveredByUps: Bool {
        carrier.uppercased().contains("UPS") || carrierTrackingNumber.uppercased().hasPrefix("1Z")
    }
}

public struct TakerAppointment: Codable, Identifiable, Equatable, Hashable, Sendable {
    public var id: String
    public var relayId: Int
    public var parcelId: String
    public var vipleBarcode: String
    public var customerName: String
    public var customerPhone: String
    public var customerEmail: String
    public var slotDate: String
    public var startTime: String
    public var endTime: String
    public var status: String // "Proposé" | "Confirmé" | "Reporté" | "Honoré" | "Annulé"
    public var notes: String

    public init(
        id: String = UUID().uuidString,
        relayId: Int = 2,
        parcelId: String = "",
        vipleBarcode: String = "",
        customerName: String = "",
        customerPhone: String = "",
        customerEmail: String = "",
        slotDate: String = "",
        startTime: String = "18:00",
        endTime: String = "18:30",
        status: String = "Proposé",
        notes: String = ""
    ) {
        self.id = id
        self.relayId = relayId
        self.parcelId = parcelId
        self.vipleBarcode = vipleBarcode
        self.customerName = customerName
        self.customerPhone = customerPhone
        self.customerEmail = customerEmail
        self.slotDate = slotDate
        self.startTime = startTime
        self.endTime = endTime
        self.status = status
        self.notes = notes
    }

    enum CodingKeys: String, CodingKey {
        case id, relayId, parcelId, vipleBarcode, customerName, customerPhone, customerEmail
        case slotDate, startTime, endTime, status, notes
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let rawId = c.decodeString(.id)
        id = rawId.isEmpty ? UUID().uuidString : rawId
        relayId = c.decodeInt(.relayId, default: 0)
        parcelId = c.decodeString(.parcelId)
        vipleBarcode = c.decodeString(.vipleBarcode)
        customerName = c.decodeString(.customerName, default: "Client")
        customerPhone = c.decodeString(.customerPhone)
        customerEmail = c.decodeString(.customerEmail)
        slotDate = c.decodeString(.slotDate)
        startTime = c.decodeString(.startTime, default: "18:00")
        endTime = c.decodeString(.endTime, default: "18:30")
        status = c.decodeString(.status, default: "Proposé")
        notes = c.decodeString(.notes)
    }

    public var timeRangeLabel: String {
        if endTime.isEmpty { return startTime }
        return "\(startTime) – \(endTime)"
    }
}

public struct TakerReceptionIssue: Codable, Identifiable, Equatable, Hashable, Sendable {
    public var id: String
    public var relayId: Int
    public var parcelId: String?
    public var vipleBarcode: String
    public var carrierTrackingNumber: String
    public var issueType: String
    public var severity: String
    public var description: String
    public var refusedAtDoor: Bool
    public var status: String
    public var createdAtUtc: String

    public init(
        id: String = UUID().uuidString,
        relayId: Int = 2,
        parcelId: String? = nil,
        vipleBarcode: String = "",
        carrierTrackingNumber: String = "",
        issueType: String = "Colis endommagé",
        severity: String = "Moyenne",
        description: String = "",
        refusedAtDoor: Bool = false,
        status: String = "Ouvert",
        createdAtUtc: String = ""
    ) {
        self.id = id
        self.relayId = relayId
        self.parcelId = parcelId
        self.vipleBarcode = vipleBarcode
        self.carrierTrackingNumber = carrierTrackingNumber
        self.issueType = issueType
        self.severity = severity
        self.description = description
        self.refusedAtDoor = refusedAtDoor
        self.status = status
        self.createdAtUtc = createdAtUtc
    }

    enum CodingKeys: String, CodingKey {
        case id, relayId, parcelId, vipleBarcode, carrierTrackingNumber
        case issueType, severity, description, refusedAtDoor, status, createdAtUtc
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let rawId = c.decodeString(.id)
        id = rawId.isEmpty ? UUID().uuidString : rawId
        relayId = c.decodeInt(.relayId, default: 0)
        parcelId = c.decodeOptionalString(.parcelId)
        vipleBarcode = c.decodeString(.vipleBarcode)
        carrierTrackingNumber = c.decodeString(.carrierTrackingNumber)
        issueType = c.decodeString(.issueType, default: "Anomalie de réception")
        severity = c.decodeString(.severity, default: "Moyenne")
        description = c.decodeString(.description)
        refusedAtDoor = c.decodeBool(.refusedAtDoor, default: false)
        status = c.decodeString(.status, default: "En cours d'analyse")
        createdAtUtc = c.decodeString(.createdAtUtc)
    }
}

public struct TakerApplicationRecord: Codable, Identifiable, Equatable, Hashable, Sendable {
    public var id: Int
    public var reference: String
    public var applicantType: String // "Particulier" | "Pro"
    public var relayName: String
    public var firstName: String
    public var lastName: String
    public var address: String
    public var postalCode: String
    public var city: String
    public var phone: String
    public var siret: String
    public var businessCategory: String
    public var openingHours: String
    public var storageCapacity: String
    public var motivationAndAccessNotes: String
    public var status: String
    public var stepIndex: Int
    public var requestedAdditionalInfo: String
    public var applicantSupplementaryResponse: String
    public var linkedRelayPointId: Int?
    public var createdAtUtc: String
    public var updatedAtUtc: String

    public init(
        id: Int = 0,
        reference: String = "",
        applicantType: String = "Particulier",
        relayName: String = "",
        firstName: String = "",
        lastName: String = "",
        address: String = "",
        postalCode: String = "",
        city: String = "",
        phone: String = "",
        siret: String = "",
        businessCategory: String = "",
        openingHours: String = "",
        storageCapacity: String = "",
        motivationAndAccessNotes: String = "",
        status: String = "Envoyée",
        stepIndex: Int = 1,
        requestedAdditionalInfo: String = "",
        applicantSupplementaryResponse: String = "",
        linkedRelayPointId: Int? = nil,
        createdAtUtc: String = "",
        updatedAtUtc: String = ""
    ) {
        self.id = id
        self.reference = reference
        self.applicantType = applicantType
        self.relayName = relayName
        self.firstName = firstName
        self.lastName = lastName
        self.address = address
        self.postalCode = postalCode
        self.city = city
        self.phone = phone
        self.siret = siret
        self.businessCategory = businessCategory
        self.openingHours = openingHours
        self.storageCapacity = storageCapacity
        self.motivationAndAccessNotes = motivationAndAccessNotes
        self.status = status
        self.stepIndex = stepIndex
        self.requestedAdditionalInfo = requestedAdditionalInfo
        self.applicantSupplementaryResponse = applicantSupplementaryResponse
        self.linkedRelayPointId = linkedRelayPointId
        self.createdAtUtc = createdAtUtc
        self.updatedAtUtc = updatedAtUtc
    }

    enum CodingKeys: String, CodingKey {
        case id, reference, applicantType, relayName, firstName, lastName
        case address, postalCode, city, phone, siret, businessCategory
        case openingHours, storageCapacity, motivationAndAccessNotes
        case status, stepIndex, requestedAdditionalInfo, applicantSupplementaryResponse
        case linkedRelayPointId, createdAtUtc, updatedAtUtc
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.decodeInt(.id, default: Int.random(in: 1000...9999))
        let ref = c.decodeString(.reference)
        reference = ref.isEmpty ? "LT-\(id)" : ref
        let rawType = c.decodeString(.applicantType, default: "Particulier")
        applicantType = rawType.lowercased().contains("pro") ? "Pro" : "Particulier"
        relayName = c.decodeString(.relayName, default: "Candidature Point Relais")
        firstName = c.decodeString(.firstName)
        lastName = c.decodeString(.lastName)
        address = c.decodeString(.address)
        postalCode = c.decodeString(.postalCode)
        city = c.decodeString(.city)
        phone = c.decodeString(.phone)
        siret = c.decodeString(.siret)
        businessCategory = c.decodeString(.businessCategory)
        openingHours = c.decodeString(.openingHours)
        storageCapacity = c.decodeString(.storageCapacity)
        motivationAndAccessNotes = c.decodeString(.motivationAndAccessNotes)
        let st = c.decodeString(.status, default: "Envoyée")
        status = st
        let decodedStep = c.decodeInt(.stepIndex, default: 0)
        if decodedStep > 0 {
            stepIndex = min(max(decodedStep, 1), 4)
        } else {
            stepIndex = Self.inferredStepIndex(for: st)
        }
        requestedAdditionalInfo = c.decodeString(.requestedAdditionalInfo)
        applicantSupplementaryResponse = c.decodeString(.applicantSupplementaryResponse)
        linkedRelayPointId = c.decodeOptionalInt(.linkedRelayPointId)
        createdAtUtc = c.decodeString(.createdAtUtc)
        updatedAtUtc = c.decodeString(.updatedAtUtc)
    }

    public static func inferredStepIndex(for status: String) -> Int {
        let lower = status.lowercased()
        if lower.contains("valid") || lower.contains("approuv") || lower.contains("actif") { return 4 }
        if lower.contains("refus") { return 4 }
        if lower.contains("élément") || lower.contains("element") || lower.contains("complément") || lower.contains("vérif") { return 3 }
        if lower.contains("vu") || lower.contains("traitement") || lower.contains("étude") || lower.contains("examen") { return 2 }
        return 1
    }

    public var needsSupplementaryReply: Bool {
        !requestedAdditionalInfo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            status.lowercased().contains("élément") ||
            status.lowercased().contains("complément")
    }
}

// MARK: - 5. Réponses Bootstrap & Actions Métier Looby Taker

public struct TakerBootstrapResponse: Codable, Equatable, Sendable {
    public var ok: Bool
    public var sessionRevoked: Bool
    public var hasAssignedRelay: Bool
    public var relays: [TakerRelayPoint]
    public var activeRelay: TakerRelayPoint?
    public var parcels: [TakerParcel]
    public var appointments: [TakerAppointment]
    public var issues: [TakerReceptionIssue]
    public var applications: [TakerApplicationRecord]
    public var error: String?

    enum CodingKeys: String, CodingKey {
        case ok, sessionRevoked, hasAssignedRelay, relays, activeRelay
        case parcels, appointments, issues, applications, error
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        ok = c.decodeBool(.ok, default: true)
        sessionRevoked = c.decodeBool(.sessionRevoked, default: false)
        let decodedRelays = (try? c.decodeIfPresent([TakerRelayPoint].self, forKey: .relays)) ?? []
        let decodedActive = try? c.decodeIfPresent(TakerRelayPoint.self, forKey: .activeRelay)
        relays = decodedRelays
        activeRelay = decodedActive ?? decodedRelays.first
        hasAssignedRelay = c.decodeBool(.hasAssignedRelay, default: activeRelay != nil || !decodedRelays.isEmpty)
        parcels = (try? c.decodeIfPresent([TakerParcel].self, forKey: .parcels)) ?? []
        appointments = (try? c.decodeIfPresent([TakerAppointment].self, forKey: .appointments)) ?? []
        issues = (try? c.decodeIfPresent([TakerReceptionIssue].self, forKey: .issues)) ?? []
        applications = (try? c.decodeIfPresent([TakerApplicationRecord].self, forKey: .applications)) ?? []
        error = c.decodeOptionalString(.error)
    }
}

public struct TakerScanReceiveResponse: Codable, Equatable, Sendable {
    public var ok: Bool
    public var isUpsCarrierBarcode: Bool?
    public var matchedVipleBarcode: String?
    public var warningTitle: String?
    public var error: String?
    public var message: String?
    public var parcel: TakerParcel?

    enum CodingKeys: String, CodingKey {
        case ok, isUpsCarrierBarcode, matchedVipleBarcode, warningTitle, error, message, parcel
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        ok = c.decodeBool(.ok, default: false)
        isUpsCarrierBarcode = c.decodeOptionalBool(.isUpsCarrierBarcode)
        matchedVipleBarcode = c.decodeOptionalString(.matchedVipleBarcode)
        warningTitle = c.decodeOptionalString(.warningTitle)
        error = c.decodeOptionalString(.error)
        message = c.decodeOptionalString(.message)
        parcel = try? c.decodeIfPresent(TakerParcel.self, forKey: .parcel)
    }
}

public struct TakerScanHandoverResponse: Codable, Equatable, Sendable {
    public var ok: Bool
    public var isUpsCarrierBarcode: Bool?
    public var requiresPin: Bool?
    public var error: String?
    public var message: String?
    public var parcel: TakerParcel?
    public var earnedEur: Double?

    enum CodingKeys: String, CodingKey {
        case ok, isUpsCarrierBarcode, requiresPin, error, message, parcel, earnedEur
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        ok = c.decodeBool(.ok, default: false)
        isUpsCarrierBarcode = c.decodeOptionalBool(.isUpsCarrierBarcode)
        requiresPin = c.decodeOptionalBool(.requiresPin)
        error = c.decodeOptionalString(.error)
        message = c.decodeOptionalString(.message)
        parcel = try? c.decodeIfPresent(TakerParcel.self, forKey: .parcel)
        earnedEur = c.decodeOptionalDouble(.earnedEur)
    }
}

public struct TakerParcelMutationResponse: Codable, Equatable, Sendable {
    public var ok: Bool
    public var message: String?
    public var parcel: TakerParcel?
    public var error: String?

    enum CodingKeys: String, CodingKey {
        case ok, message, parcel, error
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        parcel = try? c.decodeIfPresent(TakerParcel.self, forKey: .parcel)
        error = c.decodeOptionalString(.error)
        message = c.decodeOptionalString(.message)
        ok = c.decodeBool(.ok, default: parcel != nil && (error ?? "").isEmpty)
    }
}

public struct TakerIssueMutationResponse: Codable, Equatable, Sendable {
    public var ok: Bool
    public var message: String?
    public var issue: TakerReceptionIssue?
    public var error: String?

    enum CodingKeys: String, CodingKey {
        case ok, message, issue, error
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        issue = try? c.decodeIfPresent(TakerReceptionIssue.self, forKey: .issue)
        error = c.decodeOptionalString(.error)
        message = c.decodeOptionalString(.message)
        ok = c.decodeBool(.ok, default: issue != nil && (error ?? "").isEmpty)
    }
}

public struct TakerAppointmentMutationResponse: Codable, Equatable, Sendable {
    public var ok: Bool
    public var message: String?
    public var appointment: TakerAppointment?
    public var error: String?

    enum CodingKeys: String, CodingKey {
        case ok, message, appointment, error
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        appointment = try? c.decodeIfPresent(TakerAppointment.self, forKey: .appointment)
        error = c.decodeOptionalString(.error)
        message = c.decodeOptionalString(.message)
        ok = c.decodeBool(.ok, default: appointment != nil && (error ?? "").isEmpty)
    }
}

public struct TakerRelayMutationResponse: Codable, Equatable, Sendable {
    public var ok: Bool
    public var message: String?
    public var activeRelay: TakerRelayPoint?
    public var error: String?

    enum CodingKeys: String, CodingKey {
        case ok, message, activeRelay, relay, error
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        activeRelay = (try? c.decodeIfPresent(TakerRelayPoint.self, forKey: .activeRelay))
            ?? (try? c.decodeIfPresent(TakerRelayPoint.self, forKey: .relay))
        error = c.decodeOptionalString(.error)
        message = c.decodeOptionalString(.message)
        ok = c.decodeBool(.ok, default: activeRelay != nil && (error ?? "").isEmpty)
    }
}

public struct TakerApplicationMutationResponse: Codable, Equatable, Sendable {
    public var ok: Bool
    public var message: String?
    public var application: TakerApplicationRecord?
    public var error: String?

    enum CodingKeys: String, CodingKey {
        case ok, message, application, error
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        application = try? c.decodeIfPresent(TakerApplicationRecord.self, forKey: .application)
        error = c.decodeOptionalString(.error)
        message = c.decodeOptionalString(.message)
        ok = c.decodeBool(.ok, default: application != nil && (error ?? "").isEmpty)
    }
}

// MARK: - 6. Notifications Push APNs & Gestionnaire d'Appareils Connectés Viple Live ID

public struct TakerNotificationItem: Codable, Identifiable, Equatable, Hashable, Sendable {
    public var id: String
    public var kind: String
    public var title: String
    public var subtitle: String
    public var body: String
    public var deepLink: String
    public var parcelBarcode: String?
    public var createdAtUtc: String
    public var isSeen: Bool

    enum CodingKeys: String, CodingKey {
        case id, kind, title, subtitle, body, deepLink, parcelBarcode, vipleBarcode, createdAtUtc, isSeen
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let rawId = c.decodeString(.id)
        id = rawId.isEmpty ? UUID().uuidString : rawId
        kind = c.decodeString(.kind, default: "taker_event")
        title = c.decodeString(.title, default: "Looby Taker")
        subtitle = c.decodeString(.subtitle)
        body = c.decodeString(.body)
        deepLink = c.decodeString(.deepLink, default: "loobytaker://dashboard")
        parcelBarcode = c.decodeOptionalString(.parcelBarcode) ?? c.decodeOptionalString(.vipleBarcode)
        createdAtUtc = c.decodeString(.createdAtUtc)
        isSeen = c.decodeBool(.isSeen, default: false)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(kind, forKey: .kind)
        try c.encode(title, forKey: .title)
        try c.encode(subtitle, forKey: .subtitle)
        try c.encode(body, forKey: .body)
        try c.encode(deepLink, forKey: .deepLink)
        try c.encodeIfPresent(parcelBarcode, forKey: .parcelBarcode)
        try c.encode(createdAtUtc, forKey: .createdAtUtc)
        try c.encode(isSeen, forKey: .isSeen)
    }
}

public struct TakerNotificationPollResponse: Codable, Equatable, Sendable {
    public var ok: Bool
    public var sessionRevoked: Bool
    public var notificationsEnabled: Bool
    public var unseen: [TakerNotificationItem]
    public var recent: [TakerNotificationItem]

    enum CodingKeys: String, CodingKey {
        case ok, sessionRevoked, notificationsEnabled, unseen, recent
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        ok = c.decodeBool(.ok, default: true)
        sessionRevoked = c.decodeBool(.sessionRevoked, default: false)
        notificationsEnabled = c.decodeBool(.notificationsEnabled, default: true)
        unseen = (try? c.decodeIfPresent([TakerNotificationItem].self, forKey: .unseen)) ?? []
        recent = (try? c.decodeIfPresent([TakerNotificationItem].self, forKey: .recent)) ?? []
    }
}

public struct TakerConnectedAppBadge: Codable, Identifiable, Equatable, Hashable, Sendable {
    public var appId: String
    public var appName: String
    public var bundleId: String
    public var icon: String
    public var colorHex: String
    public var accountEmail: String
    public var appVersion: String
    public var notificationsEnabled: Bool
    public var lastSeenAtUtc: String

    public var id: String { "\(appId.lowercased())-\(accountEmail.lowercased())" }

    enum CodingKeys: String, CodingKey {
        case appId, appName, bundleId, icon, colorHex, accountEmail, appVersion, notificationsEnabled, lastSeenAtUtc
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let decodedId = c.decodeString(.appId, default: "looby-taker")
        appId = decodedId
        let name = c.decodeString(.appName)
        appName = name.isEmpty ? Self.defaultDisplayName(for: decodedId) : name
        bundleId = c.decodeString(.bundleId)
        let ic = c.decodeString(.icon)
        icon = ic.isEmpty ? Self.defaultSystemIcon(for: decodedId) : ic
        let hex = c.decodeString(.colorHex)
        colorHex = hex.isEmpty ? Self.defaultColorHex(for: decodedId) : hex
        accountEmail = c.decodeString(.accountEmail)
        appVersion = c.decodeString(.appVersion)
        notificationsEnabled = c.decodeBool(.notificationsEnabled, default: true)
        lastSeenAtUtc = c.decodeString(.lastSeenAtUtc)
    }

    public static func defaultDisplayName(for appId: String) -> String {
        switch appId.lowercased() {
        case "viple-mail", "viplemail": return "Viple Mail"
        case "livria-store", "livriastore": return "Livria Store"
        case "livria-social", "livriasocial": return "Livria Social"
        case "cenelis-academy", "cenelisacademy": return "Cenelis Academy"
        case "looby-taker", "loobytaker": return "Looby Taker"
        case "looby": return "Looby"
        case "cenelis-workspace": return "Cenelis Workspace"
        case "viple-et-moi": return "Viple & Moi"
        default: return appId
        }
    }

    public static func defaultSystemIcon(for appId: String) -> String {
        switch appId.lowercased() {
        case "viple-mail", "viplemail": return "envelope.fill"
        case "livria-store", "livriastore": return "book.closed.fill"
        case "livria-social", "livriasocial": return "bubble.left.and.bubble.right.fill"
        case "cenelis-academy", "cenelisacademy": return "graduationcap.fill"
        case "looby-taker", "loobytaker": return "shippingbox.and.arrow.backward.fill"
        case "looby": return "infinity"
        case "cenelis-workspace": return "building.columns.fill"
        default: return "app.fill"
        }
    }

    public static func defaultColorHex(for appId: String) -> String {
        switch appId.lowercased() {
        case "viple-mail", "viplemail": return "#2563EB"
        case "livria-store", "livriastore": return "#7C3AED"
        case "livria-social", "livriasocial": return "#EC4899"
        case "cenelis-academy", "cenelisacademy": return "#059669"
        case "looby-taker", "loobytaker": return "#E88E14"
        case "looby": return "#10B981"
        default: return "#D97706"
        }
    }
}

public struct TakerConnectedDevice: Codable, Identifiable, Equatable, Hashable, Sendable {
    public var deviceId: String
    public var rawDeviceIds: [String]
    public var modelName: String
    public var modelCode: String
    public var platform: String
    public var osVersion: String
    public var isCurrentDevice: Bool
    public var pushActive: Bool
    public var connectedAtUtc: String
    public var lastSeenAtUtc: String
    public var connectedApps: [TakerConnectedAppBadge]

    public var id: String { deviceId }

    enum CodingKeys: String, CodingKey {
        case deviceId, rawDeviceIds, modelName, modelCode, platform, osVersion
        case isCurrentDevice, pushActive, connectedAtUtc, lastSeenAtUtc, connectedApps
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let devId = c.decodeString(.deviceId, default: UUID().uuidString)
        deviceId = devId
        rawDeviceIds = (try? c.decodeIfPresent([String].self, forKey: .rawDeviceIds)) ?? [devId]
        let code = c.decodeString(.modelCode)
        modelCode = code
        let rawModel = c.decodeString(.modelName)
        if !rawModel.isEmpty {
            modelName = rawModel
        } else if !code.isEmpty {
            modelName = LoobyTakerDeviceIdentity.commercialModelName(for: code)
        } else {
            modelName = "Apple iPhone"
        }
        platform = c.decodeString(.platform, default: "iOS")
        osVersion = c.decodeString(.osVersion)
        isCurrentDevice = c.decodeBool(.isCurrentDevice, default: false)
        pushActive = c.decodeBool(.pushActive, default: false)
        connectedAtUtc = c.decodeString(.connectedAtUtc)
        lastSeenAtUtc = c.decodeString(.lastSeenAtUtc)
        connectedApps = (try? c.decodeIfPresent([TakerConnectedAppBadge].self, forKey: .connectedApps)) ?? []
    }

    public var displayModelName: String {
        let trimmed = modelName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Apple iPhone" : trimmed
    }

    public var displayOsLabel: String {
        let trimmed = osVersion.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? platform : trimmed
    }

    public var systemSymbolName: String {
        let combined = "\(modelName) \(modelCode) \(platform)".lowercased()
        if combined.contains("ipad") { return "ipad.gen2" }
        if combined.contains("mac") { return "laptopcomputer" }
        if combined.contains("windows") || combined.contains("web") { return "desktopcomputer" }
        return "iphone.gen3"
    }

    public var lastActivityLabelFr: String {
        guard let d = Self.parseIso(lastSeenAtUtc) else {
            return isCurrentDevice ? "Actif maintenant" : "Session active"
        }
        let elapsed = Date().timeIntervalSince(d)
        if elapsed < 90 { return "Actif à l'instant" }
        let mins = Int(elapsed / 60)
        if mins < 60 { return "Actif il y a \(max(1, mins)) min" }
        let df = DateFormatter()
        df.locale = Locale(identifier: "fr_FR")
        df.timeZone = TimeZone(identifier: "Europe/Paris") ?? .current
        df.dateFormat = "d MMM 'à' HH'h'mm"
        return "Vu le \(df.string(from: d))"
    }

    private static func parseIso(_ raw: String) -> Date? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let f1 = ISO8601DateFormatter()
        f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f1.date(from: trimmed) { return d }
        let f2 = ISO8601DateFormatter()
        f2.formatOptions = [.withInternetDateTime]
        if let d = f2.date(from: trimmed) { return d }
        return nil
    }
}

public struct TakerConnectedDevicesResponse: Codable, Equatable, Sendable {
    public var ok: Bool
    public var sessionRevoked: Bool
    public var error: String?
    public var devices: [TakerConnectedDevice]

    enum CodingKeys: String, CodingKey {
        case ok, sessionRevoked, error, devices
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        ok = c.decodeBool(.ok, default: false)
        sessionRevoked = c.decodeBool(.sessionRevoked, default: false)
        error = c.decodeOptionalString(.error)
        devices = (try? c.decodeIfPresent([TakerConnectedDevice].self, forKey: .devices)) ?? []
    }
}

public struct TakerRevokeDeviceResponse: Codable, Equatable, Sendable {
    public var ok: Bool
    public var revokedCount: Int
    public var currentDeviceRevoked: Bool
    public var error: String?

    enum CodingKeys: String, CodingKey {
        case ok, revokedCount, currentDeviceRevoked, error
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        ok = c.decodeBool(.ok, default: false)
        revokedCount = c.decodeInt(.revokedCount, default: 0)
        currentDeviceRevoked = c.decodeBool(.currentDeviceRevoked, default: false)
        error = c.decodeOptionalString(.error)
    }
}
