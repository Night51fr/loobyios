import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@MainActor
public final class LoobyViewModel: ObservableObject {
    // MARK: - Navigation & Global UI
    @Published public var selectedTab: Int = 0
    @Published public var isLoading: Bool = false
    @Published public var toastMessage: String? = nil
    @Published public var errorMessage: String? = nil
    @Published public var showLoginSheet: Bool = false

    // MARK: - Countdown to 21/11/2026
    @Published public var daysRemaining: Int = 31
    @Published public var hoursRemaining: Int = 5
    @Published public var minutesRemaining: Int = 47
    @Published public var secondsRemaining: Int = 12
    @Published public var launchAlertSubscribed: Bool = UserDefaults.standard.bool(forKey: "looby.v2.launch_alert")

    // MARK: - Viple Live ID Session & Cross-App SSO
    @Published public var currentUser: LoobyUserProfile = .guestPlaceholder
    @Published public var isAuthenticated: Bool = false
    @Published public var detectedCrossAppAccount: LoobyCrossAppAccount? = nil
    @Published public var showCrossAppPrompt: Bool = false

    // MARK: - Orders ("Mes Commandes" : Livria + Looby v2)
    @Published public var ordersSourceFilter: String = "livria" // "livria" or "looby"
    @Published public var livriaOrders: [LoobyOrder] = []
    @Published public var livriaFeaturedBooks: [LoobyLivriaBook] = []

    // MARK: - Grand Est B2C Local Merchants Explorer & Favorites
    @Published public var selectedCityFilter: String = "Toutes"
    @Published public var selectedCategoryFilter: String = "Toutes"
    @Published public var merchantSearchQuery: String = ""
    @Published public var favoriteMerchantIds: Set<String> = []
    @Published public var selectedMerchantDetail: LoobyGrandEstMerchant? = nil

    // Interactive B2C Merchant Simulator (App Store Utility)
    @Published public var simMonthlySales: Double = 3500
    @Published public var simAverageBasket: Double = 42
    @Published public var simClickAndCollectShare: Double = 60
    @Published public var merchantApplicationShopName: String = ""
    @Published public var merchantApplicationCity: String = "Strasbourg"
    @Published public var merchantApplicationSiret: String = ""
    @Published public var merchantApplicationEmail: String = ""
    @Published public var merchantApplicationSubmitted: Bool = UserDefaults.standard.bool(forKey: "looby.v2.merchant_applied")

    // MARK: - CGU Acceptance State
    @Published public var cguAccepted: Bool = UserDefaults.standard.bool(forKey: "looby.v2.cgu_accepted")
    @Published public var cguAcceptedDateString: String = UserDefaults.standard.string(forKey: "looby.v2.cgu_date") ?? ""
    @Published public var cguSearchQuery: String = ""

    private var countdownTask: Task<Void, Never>? = nil

    public init() {
        if let savedFavs = UserDefaults.standard.stringArray(forKey: "looby.v2.fav_merchants") {
            self.favoriteMerchantIds = Set(savedFavs)
        }
        let savedEmail = UserDefaults.standard.string(forKey: "looby.auth.email") ?? ""
        let savedUserId = UserDefaults.standard.integer(forKey: "looby.auth.userId")
        if !savedEmail.isEmpty && savedUserId > 0 {
            self.isAuthenticated = true
        }
        updateCountdown()
        startCountdownTimer()
    }

    // MARK: - Countdown Logic (Target: 21/11/2026)

    public func startCountdownTimer() {
        countdownTask?.cancel()
        countdownTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard let self else { break }
                self.updateCountdown()
            }
        }
    }

    public func updateCountdown() {
        let now = Date()
        let target = LoobyAppConfig.officialLaunchDate
        let diff = max(0, Int(target.timeIntervalSince(now)))
        self.daysRemaining = diff / 86400
        self.hoursRemaining = (diff % 86400) / 3600
        self.minutesRemaining = (diff % 3600) / 60
        self.secondsRemaining = diff % 60
    }

    public func toggleLaunchAlertSubscription() {
        launchAlertSubscribed.toggle()
        UserDefaults.standard.set(launchAlertSubscribed, forKey: "looby.v2.launch_alert")
        if launchAlertSubscribed {
            showToast("🔔 Alerte activée pour le lancement officiel Looby v2 le 21/11/2026 !")
        } else {
            showToast("Rappel de lancement désactivé.")
        }
    }

    public func showToast(_ msg: String) {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
            toastMessage = msg
        }
        Task {
            try? await Task.sleep(nanoseconds: 3_600_000_000)
            if self.toastMessage == msg {
                withAnimation {
                    self.toastMessage = nil
                }
            }
        }
    }

    // MARK: - Bootstrap, Viple Live ID & Cross-App SSO

    public func bootstrap() async {
        let savedEmail = UserDefaults.standard.string(forKey: "looby.auth.email")
        let savedUserId = UserDefaults.standard.integer(forKey: "looby.auth.userId")

        do {
            let res = try await LoobyAPIClient.shared.fetchBootstrap(
                email: (savedEmail?.isEmpty == false) ? savedEmail : nil,
                userId: savedUserId > 0 ? savedUserId : nil
            )
            if let u = res.user, !u.isGuestAccount {
                self.currentUser = u
                self.isAuthenticated = true
            }
            self.livriaOrders = res.orders ?? []
            self.livriaFeaturedBooks = Array((res.books ?? []).prefix(12))
        } catch {
            // Keep graceful offline showcase experience
        }

        if !isAuthenticated {
            if let cross = await LoobyAPIClient.shared.discoverCrossAppAccount(), cross.userId > 0 {
                let dismissedKey = "looby.sso.dismissed.\(cross.userId)"
                if !UserDefaults.standard.bool(forKey: dismissedKey) {
                    self.detectedCrossAppAccount = cross
                    self.showCrossAppPrompt = true
                }
            }
        }
    }

    public func loginWithVipleLiveID(email: String, password: String) async {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Veuillez renseigner votre identifiant Viple Live ID et votre mot de passe."
            return
        }
        isLoading = true
        defer { isLoading = false }

        do {
            let res = try await LoobyAPIClient.shared.loginVipleLiveID(email: cleanEmail, password: password)
            if res.ok, let u = res.user {
                applyAuthenticatedUser(u)
                showLoginSheet = false
                await LoobyAPIClient.shared.announceCrossAppSession(userId: u.id, email: u.email)
                await bootstrap()
                showToast("Bienvenue sur Looby, \(u.displayName) !")
            } else {
                errorMessage = res.error ?? "Identifiants Viple Live ID incorrects."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func registerWithVipleLiveID(
        emailMode: String,
        emailUser: String,
        customEmail: String,
        password: String,
        firstName: String,
        lastName: String,
        displayName: String
    ) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let res = try await LoobyAPIClient.shared.registerVipleLiveID(
                emailMode: emailMode,
                emailUser: emailUser,
                customEmail: customEmail,
                password: password,
                firstName: firstName,
                lastName: lastName,
                displayName: displayName
            )
            if res.ok, let u = res.user {
                applyAuthenticatedUser(u)
                showLoginSheet = false
                await LoobyAPIClient.shared.announceCrossAppSession(userId: u.id, email: u.email)
                await bootstrap()
                showToast("Compte Viple Live ID créé avec succès !")
            } else {
                errorMessage = res.error ?? "Impossible de créer le compte Viple Live ID."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func acceptDetectedCrossAppSession() async {
        guard let acc = detectedCrossAppAccount else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let res = try await LoobyAPIClient.shared.acceptCrossAppAccount(userId: acc.userId, email: acc.email)
            if res.ok, let u = res.user {
                applyAuthenticatedUser(u)
                showCrossAppPrompt = false
                await bootstrap()
                showToast("Connecté automatiquement en tant que \(u.displayName) !")
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func dismissDetectedCrossAppSession() {
        if let acc = detectedCrossAppAccount {
            UserDefaults.standard.set(true, forKey: "looby.sso.dismissed.\(acc.userId)")
        }
        showCrossAppPrompt = false
    }

    public func signOut() async {
        UserDefaults.standard.removeObject(forKey: "looby.auth.email")
        UserDefaults.standard.removeObject(forKey: "looby.auth.userId")
        currentUser = .guestPlaceholder
        isAuthenticated = false
        livriaOrders = []
        await LoobyAPIClient.shared.clearCrossAppSession()
        showToast("Vous êtes déconnecté de Viple Live ID.")
    }

    public func deleteCurrentAccount() async {
        guard isAuthenticated else { return }
        let uid = currentUser.id
        let mail = currentUser.email
        let cid = currentUser.cid
        do {
            _ = try await LoobyAPIClient.shared.deleteVipleAccount(userId: uid, email: mail, cid: cid)
            await signOut()
            showToast("Votre compte Viple Live ID et vos données ont été supprimés.")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func applyAuthenticatedUser(_ user: LoobyUserProfile) {
        self.currentUser = user
        self.isAuthenticated = true
        UserDefaults.standard.set(user.email, forKey: "looby.auth.email")
        UserDefaults.standard.set(user.id, forKey: "looby.auth.userId")
    }

    // MARK: - Smart Deep Link to Livria Store App or Website

    public func openLivriaBookOrStore(bookId: Int? = nil) {
        #if canImport(UIKit)
        if let bookId, bookId > 0,
           let appBookURL = URL(string: "livriastore://book/\(bookId)"),
           UIApplication.shared.canOpenURL(appBookURL) {
            UIApplication.shared.open(appBookURL)
            return
        }
        if let appRootURL = URL(string: "livriastore://"),
           UIApplication.shared.canOpenURL(appRootURL) {
            UIApplication.shared.open(appRootURL)
            return
        }
        let webStr = (bookId != nil && bookId! > 0)
            ? "https://livria.store/livre/\(bookId!)"
            : "https://livria.store"
        if let webURL = URL(string: webStr) {
            UIApplication.shared.open(webURL)
        }
        #endif
    }

    // MARK: - Favorites & B2C Merchant Simulator Actions

    public func toggleFavoriteMerchant(_ merchantId: String) {
        if favoriteMerchantIds.contains(merchantId) {
            favoriteMerchantIds.remove(merchantId)
            showToast("Commerce retiré de votre sélection Grand Est.")
        } else {
            favoriteMerchantIds.insert(merchantId)
            showToast("❤️ Commerce ajouté à vos favoris pour l'ouverture du 21/11/2026 !")
        }
        UserDefaults.standard.set(Array(favoriteMerchantIds), forKey: "looby.v2.fav_merchants")
    }

    public func submitMerchantPreRegistration() {
        guard !merchantApplicationShopName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !merchantApplicationEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Veuillez indiquer le nom de votre commerce et votre adresse e-mail professionnelle."
            return
        }
        merchantApplicationSubmitted = true
        UserDefaults.standard.set(true, forKey: "looby.v2.merchant_applied")
        showToast("🏪 Pré-candidature B2C Grand Est enregistrée pour « \(merchantApplicationShopName) » !")
    }

    public func acceptLoobyCGU() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "dd/MM/yyyy 'à' HH:mm"
        let stamp = formatter.string(from: Date())
        cguAccepted = true
        cguAcceptedDateString = stamp
        UserDefaults.standard.set(true, forKey: "looby.v2.cgu_accepted")
        UserDefaults.standard.set(stamp, forKey: "looby.v2.cgu_date")
        showToast("✓ CGU de la Marketplace B2C Looby acceptées (\(stamp)).")
    }

    // MARK: - Rich Static Datasets (Grand Est B2C Merchants, Viple Live ID Comparator & CGU)

    public let grandEstCities: [String] = [
        "Toutes", "Strasbourg", "Metz", "Nancy", "Reims", "Mulhouse", "Colmar", "Épinal", "Troyes"
    ]

    public let grandEstCategories: [String] = [
        "Toutes", "Terroir & Gastronomie", "Artisanat & Déco", "Mode & Créateurs", "Culture & Papeterie", "Électronique & Reconditionné", "Bien-être & Bio"
    ]

    public let grandEstMerchants: [LoobyGrandEstMerchant] = [
        LoobyGrandEstMerchant(
            id: "maison-alsace-strasbourg",
            name: "Maison Kelsch & Terroir d'Alsace",
            city: "Strasbourg",
            department: "Bas-Rhin (67)",
            category: "Terroir & Gastronomie",
            tagline: "Épicerie fine alsacienne, miels du massif vosgien & coffrets gourmands",
            description: "Installée au cœur de Strasbourg, la Maison Kelsch réunit 28 producteurs alsaciens autour de spécialités certifiées IGP, pains d'épices artisanaux et confitures cuites au chaudron.",
            icon: "basket.fill",
            accentHex: "#10B981",
            clickAndCollectMinutes: 30,
            rating: 4.9,
            verifiedSiretBadge: "Commerçant Vérifié Grand Est • SIRET 67",
            sampleProducts: [
                LoobyGrandEstProductPreview(id: "p1", title: "Coffret Dégustation Miels des Vosges (3×250g)", price: 24.90, badge: "Récolte locale", originLabel: "Strasbourg (67)"),
                LoobyGrandEstProductPreview(id: "p2", title: "Pain d'Épices Pur Miel & Écorces d'Orange", price: 11.50, badge: "Artisanal", originLabel: "Gertwiller (67)")
            ]
        ),
        LoobyGrandEstMerchant(
            id: "atelier-mirabelle-metz",
            name: "L'Atelier de la Mirabelle & Cristallerie",
            city: "Metz",
            department: "Moselle (57)",
            category: "Artisanat & Déco",
            tagline: "Créations verrières de Lorraine, bougies parfumées et spécialités messines",
            description: "Artisans créateurs de Moselle proposant des objets décoratifs soufflés bouche, des diffuseurs à la mirabelle de Lorraine et des coffrets cadeaux fabriqués dans le bassin messin.",
            icon: "sparkles",
            accentHex: "#0EA5E9",
            clickAndCollectMinutes: 45,
            rating: 4.8,
            verifiedSiretBadge: "Commerçant Vérifié Grand Est • SIRET 57",
            sampleProducts: [
                LoobyGrandEstProductPreview(id: "p3", title: "Photophore Verre Soufflé Or de Moselle", price: 39.00, badge: "Fait main", originLabel: "Metz (57)"),
                LoobyGrandEstProductPreview(id: "p4", title: "Bougie Végétale Fleur de Mirabellier 180g", price: 19.90, badge: "Cire 100% colza", originLabel: "Metz (57)")
            ]
        ),
        LoobyGrandEstMerchant(
            id: "manufacture-stanislas-nancy",
            name: "Manufacture Art Nouveau Stanislas",
            city: "Nancy",
            department: "Meurthe-et-Moselle (54)",
            category: "Culture & Papeterie",
            tagline: "Papeterie d'art, carnets reliés main, affiches École de Nancy & bergamotes",
            description: "À deux pas de la Place Stanislas, notre atelier perpétue l'héritage graphique de l'École de Nancy avec des carnets cousus au fil de lin et des tirages d'art numérotés.",
            icon: "paintbrush.pointed.fill",
            accentHex: "#8B5CF6",
            clickAndCollectMinutes: 20,
            rating: 4.9,
            verifiedSiretBadge: "Commerçant Vérifié Grand Est • SIRET 54",
            sampleProducts: [
                LoobyGrandEstProductPreview(id: "p5", title: "Carnet Cuir & Papier Velin « École de Nancy »", price: 28.00, badge: "Série limitée", originLabel: "Nancy (54)"),
                LoobyGrandEstProductPreview(id: "p6", title: "Boîte Collector Bergamotes de Nancy IGP", price: 14.50, badge: "IGP Lorraine", originLabel: "Nancy (54)")
            ]
        ),
        LoobyGrandEstMerchant(
            id: "comptoir-craie-reims",
            name: "Le Comptoir Rémois & Biscuiterie Rose",
            city: "Reims",
            department: "Marne (51)",
            category: "Terroir & Gastronomie",
            tagline: "Biscuits roses traditionnels, accessoires d'œnologie & verrerie champenoise",
            description: "Référence champenoise réunissant les meilleurs artisans gastronomiques et verriers de Reims et d'Épernay pour une expédition directe ou un retrait boutique en 30 minutes.",
            icon: "wineglass.fill",
            accentHex: "#EC4899",
            clickAndCollectMinutes: 30,
            rating: 4.9,
            verifiedSiretBadge: "Commerçant Vérifié Grand Est • SIRET 51",
            sampleProducts: [
                LoobyGrandEstProductPreview(id: "p7", title: "Coffret 6 Flûtes Cristallin & Biscuits Roses", price: 49.00, badge: "Idée cadeau", originLabel: "Reims (51)"),
                LoobyGrandEstProductPreview(id: "p8", title: "Moutarde de Reims au Moût de Raisin", price: 7.90, badge: "Tradition 1820", originLabel: "Reims (51)")
            ]
        ),
        LoobyGrandEstMerchant(
            id: "tissage-indiennes-mulhouse",
            name: "Tissage & Créateurs de Mulhouse",
            city: "Mulhouse",
            department: "Haut-Rhin (68)",
            category: "Mode & Créateurs",
            tagline: "Linge de maison tissé dans le Haut-Rhin, écharpes et maroquinerie durable",
            description: "Héritier de la tradition textile mulhousienne, notre collectif rassemble 14 ateliers de confection du Haut-Rhin engagés dans une mode locale, traçable et durable.",
            icon: "tshirt.fill",
            accentHex: "#3B82F6",
            clickAndCollectMinutes: 40,
            rating: 4.8,
            verifiedSiretBadge: "Commerçant Vérifié Grand Est • SIRET 68",
            sampleProducts: [
                LoobyGrandEstProductPreview(id: "p9", title: "Sac Cabas Toile Jacquard Tissée à Mulhouse", price: 54.00, badge: "Tissé en Alsace", originLabel: "Mulhouse (68)"),
                LoobyGrandEstProductPreview(id: "p10", title: "Nappe Damassée Coton Bio 160×250cm", price: 69.00, badge: "Label Alsace", originLabel: "Mulhouse (68)")
            ]
        ),
        LoobyGrandEstMerchant(
            id: "recondi-tech-colmar",
            name: "Alsace RecondiTech & Mobilité",
            city: "Colmar",
            department: "Haut-Rhin (68)",
            category: "Électronique & Reconditionné",
            tagline: "Appareils reconditionnés en laboratoire à Colmar avec garantie 24 mois",
            description: "Atelier agréé du Grand Est spécialisé dans le reconditionnement de smartphones, tablettes et petit électroménager avec pièces d'origine et SAV physique en boutique.",
            icon: "iphone.gen3.radiowaves.left.and.right",
            accentHex: "#14B8A6",
            clickAndCollectMinutes: 60,
            rating: 4.7,
            verifiedSiretBadge: "Commerçant Vérifié Grand Est • SIRET 68",
            sampleProducts: [
                LoobyGrandEstProductPreview(id: "p11", title: "Casque Audio Sans Fil Reconditionné Grade A+", price: 119.00, badge: "Garantie 2 ans", originLabel: "Colmar (68)"),
                LoobyGrandEstProductPreview(id: "p12", title: "Station de Charge Bois des Vosges MagSafe", price: 44.00, badge: "Éco-conçu", originLabel: "Colmar (68)")
            ]
        ),
        LoobyGrandEstMerchant(
            id: "foret-bio-epinal",
            name: "Herboristerie & Sapin des Vosges",
            city: "Épinal",
            department: "Vosges (88)",
            category: "Bien-être & Bio",
            tagline: "Cosmétiques naturels au bourgeon de sapin, infusions bio & imagerie d'Épinal",
            description: "Laboratoire artisanal vosgien formulant des soins certifiés bio à l'eau de source et aux extraits de résineux du massif des Vosges.",
            icon: "leaf.fill",
            accentHex: "#22C55E",
            clickAndCollectMinutes: 25,
            rating: 4.9,
            verifiedSiretBadge: "Commerçant Vérifié Grand Est • SIRET 88",
            sampleProducts: [
                LoobyGrandEstProductPreview(id: "p13", title: "Baume Respiratoire Bourgeons de Sapin Bio", price: 16.50, badge: "Certifié Bio", originLabel: "Épinal (88)"),
                LoobyGrandEstProductPreview(id: "p14", title: "Infusion des Hautes-Chaumes (Menthe & Myrtille)", price: 9.80, badge: "Cueillette sauvage", originLabel: "Gérardmer (88)")
            ]
        ),
        LoobyGrandEstMerchant(
            id: "maille-champagne-troyes",
            name: "Atelier de la Maille Troyenne",
            city: "Troyes",
            department: "Aube (10)",
            category: "Mode & Créateurs",
            tagline: "Bonneterie historique de l'Aube, pulls en laine mérinos et chaussettes françaises",
            description: "Tricoté intégralement à Troyes, capitale historique de la maille, notre vestiaire associe savoir-faire bonnetier centenaire et fibres naturelles certifiées.",
            icon: "scissors",
            accentHex: "#6366F1",
            clickAndCollectMinutes: 30,
            rating: 4.8,
            verifiedSiretBadge: "Commerçant Vérifié Grand Est • SIRET 10",
            sampleProducts: [
                LoobyGrandEstProductPreview(id: "p15", title: "Pull Marin Tricoté à Troyes 100% Laine Mérinos", price: 89.00, badge: "Tricoté à Troyes", originLabel: "Troyes (10)"),
                LoobyGrandEstProductPreview(id: "p16", title: " Semainier Chaussettes Fil d'Écosse Grand Est", price: 34.00, badge: "Atelier Aube", originLabel: "Troyes (10)")
            ]
        )
    ]

    public var filteredMerchants: [LoobyGrandEstMerchant] {
        grandEstMerchants.filter { m in
            if selectedCityFilter != "Toutes" && m.city != selectedCityFilter { return false }
            if selectedCategoryFilter != "Toutes" && m.category != selectedCategoryFilter { return false }
            let q = merchantSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if !q.isEmpty {
                return m.name.lowercased().contains(q)
                    || m.city.lowercased().contains(q)
                    || m.category.lowercased().contains(q)
                    || m.tagline.lowercased().contains(q)
            }
            return true
        }
    }

    public let vipleIdComparisons: [LoobyVipleIdComparisonItem] = [
        LoobyVipleIdComparisonItem(
            featureTitle: "Connexion Inter-Applications (SSO)",
            icon: "person.2.wave.2.fill",
            legacyVipleIdText: "Ancien Viple ID : Session isolée par site. Il fallait se reconnecter manuellement sur chaque service.",
            newVipleLiveIdText: "Nouveau Viple Live ID (2026) : Détection et connexion automatique en 1 tap entre Looby, Livria Store et Livria Social sur votre iPhone.",
            highlightTag: "SSO Instantané"
        ),
        LoobyVipleIdComparisonItem(
            featureTitle: "Boîte Mail Officielle @viplemail.fr & Apple ID",
            icon: "envelope.badge.shield.half.filled",
            legacyVipleIdText: "Ancien Viple ID : Simple identifiant classique par e-mail externe sans messagerie dédiée ni Sign in with Apple natif.",
            newVipleLiveIdText: "Nouveau Viple Live ID : Adresse @viplemail.fr dédiée ou e-mail personnel au choix + prise en charge native de « Continuer avec Apple ».",
            highlightTag: "@viplemail.fr + Apple"
        ),
        LoobyVipleIdComparisonItem(
            featureTitle: "Portefeuille Looby+ & Cagnotte Unifiée",
            icon: "crown.fill",
            legacyVipleIdText: "Ancien Viple ID : Avantages limités à l'ancienne plateforme sans passerelle culturelle.",
            newVipleLiveIdText: "Nouveau Viple Live ID : Votre statut Looby+, vos points de fidélité et votre cagnotte Cashback sont partagés en temps réel entre Looby B2C et Livria.",
            highlightTag: "Avantages Unifiés"
        ),
        LoobyVipleIdComparisonItem(
            featureTitle: "Suivi Centralisé des Commandes & Bordereaux UPS",
            icon: "shippingbox.and.arrow.backward.fill",
            legacyVipleIdText: "Ancien Viple ID : Suivi séparé et manuel entre acheteurs et vendeurs particuliers.",
            newVipleLiveIdText: "Nouveau Viple Live ID : Historique unifié de vos commandes Livria Store et bientôt de vos achats chez les commerçants du Grand Est sur Looby v2.",
            highlightTag: "Suivi Temps Réel"
        ),
        LoobyVipleIdComparisonItem(
            featureTitle: "Sécurité, Contrats eIDAS & Contrôle des Données",
            icon: "lock.shield.fill",
            legacyVipleIdText: "Ancien Viple ID : Authentification standard par mot de passe simple.",
            newVipleLiveIdText: "Nouveau Viple Live ID : Identifiant cryptographique CID unique, signature électronique Viple Contractuel et gestion/suppression transparente du compte.",
            highlightTag: "Sécurité 2026"
        )
    ]

    public let legalArticles: [LoobyLegalArticle] = [
        LoobyLegalArticle(
            id: "art-1",
            number: "Article 1",
            title: "Objet & Transformation de Looby en Marketplace B2C du Grand Est",
            summaryBadge: "Modèle B2C Certifié",
            icon: "storefront.fill",
            paragraphs: [
                "1.1. La plateforme Looby, éditée par Viple SAS, opère en 2026 une refonte structurelle majeure à l'occasion de sa Version 2 dont l'ouverture commerciale est fixée au 21 novembre 2026 (21/11/2026).",
                "1.2. Anciennement conçue comme une plateforme d'échanges entre particuliers (modèle C2C), Looby devient exclusivement une place de marché professionnelle Business-to-Consumer (B2C) dédiée aux commerces de proximité, artisans, libraires, producteurs et enseignes indépendantes établis dans la région Grand Est (départements 08, 10, 51, 52, 54, 55, 57, 67, 68 et 88).",
                "1.3. Cette évolution vise à fédérer les commerçants locaux du Grand Est sur une vitrine numérique commune tout en garantissant aux consommateurs des standards professionnels de qualité, de traçabilité, de facturation et de livraison."
            ]
        ),
        LoobyLegalArticle(
            id: "art-2",
            number: "Article 2",
            title: "Compte Unique Viple Live ID & Interopérabilité avec Livria",
            summaryBadge: "Viple Live ID",
            icon: "person.badge.key.fill",
            paragraphs: [
                "2.1. L'accès aux services personnalisés de Looby v2 (suivi de commandes, sélection de commerces favoris, abonnement Looby+, réservations Click & Collect) s'effectue au moyen du compte unique Viple Live ID.",
                "2.2. Le compte Viple Live ID remplace l'ancien système Viple ID. Il permet une authentification unifiée et sécurisée sur l'ensemble des applications de l'écosystème Viple, incluant notamment Looby, Livria Store (librairie en ligne neuf et occasion) et Livria Social (réseau social littéraire).",
                "2.3. L'Utilisateur peut se connecter via une adresse officielle @viplemail.fr, une adresse électronique personnelle vérifiée ou le service « Connexion avec Apple » (Sign in with Apple)."
            ]
        ),
        LoobyLegalArticle(
            id: "art-3",
            number: "Article 3",
            title: "Sélection et Obligations des Commerçants Partenaires du Grand Est",
            summaryBadge: "Vendeurs Pros Vérifiés",
            icon: "checkmark.seal.fill",
            paragraphs: [
                "3.1. Seuls les professionnels immatriculés au Registre du Commerce et des Sociétés (RCS), au Répertoire des Métiers ou disposant d'un numéro SIRET actif avec un établissement physique ou un atelier situé dans la région Grand Est peuvent proposer des produits à la vente sur Looby v2.",
                "3.2. Chaque commerçant partenaire fait l'objet d'une vérification d'identité et de conformité contractuelle via le portail Viple Contractuel avant l'ouverture de sa boutique en ligne.",
                "3.3. Les prix affichés sur Looby v2 sont indiqués en euros toutes taxes comprises (TTC) et correspondent aux tarifs pratiqués par le commerçant local, hors offres promotionnelles ou avantages Looby+."
            ]
        ),
        LoobyLegalArticle(
            id: "art-4",
            number: "Article 4",
            title: "Commandes, Click & Collect Local et Livraison",
            summaryBadge: "Suivi & Livraison",
            icon: "shippingbox.fill",
            paragraphs: [
                "4.1. Durant la phase de pré-lancement jusqu'au 21/11/2026, aucune transaction commerciale Looby v2 n'est débitée. L'espace « Mes Commandes » de l'application permet toutefois aux titulaires d'un compte Viple Live ID de consulter en temps réel l'intégralité de leurs commandes passées sur Livria Store ainsi que leurs pré-réservations Looby v2.",
                "4.2. À compter du 21/11/2026, chaque commande passée sur Looby v2 pourra être retirée gratuitement en Click & Collect directement dans la boutique du commerçant du Grand Est ou expédiée à domicile / en point relais via notre partenaire logistique UPS."
            ]
        ),
        LoobyLegalArticle(
            id: "art-5",
            number: "Article 5",
            title: "Droit de Rétractation de 14 Jours & Garanties Légales B2C",
            summaryBadge: "Protection Consommateur",
            icon: "shield.lefthalf.filled.badge.checkmark",
            paragraphs: [
                "5.1. Contrairement à l'ancien modèle entre particuliers (C2C), le passage au modèle 100 % B2C confère de plein droit au consommateur l'ensemble des protections prévues par le Code de la consommation.",
                "5.2. L'acheteur dispose d'un délai légal de quatorze (14) jours calendaires à compter de la réception ou du retrait de son article pour exercer son droit de rétractation, sans avoir à motiver sa décision, sous réserve des exceptions légales (produits alimentaires périssables, biens personnalisés).",
                "5.3. Tous les produits vendus par les commerçants du Grand Est sur Looby v2 bénéficient de la garantie légale de conformité (articles L. 217-3 et suivants du Code de la consommation) et de la garantie contre les vices cachés."
            ]
        ),
        LoobyLegalArticle(
            id: "art-6",
            number: "Article 6",
            title: "Protection des Données Personnelles (RGPD) & Suppression de Compte",
            summaryBadge: "RGPD & Confidentialité",
            icon: "hand.raised.shield.fill",
            paragraphs: [
                "6.1. Viple SAS traite les données personnelles des utilisateurs dans le strict respect du Règlement Général sur la Protection des Données (RGPD) et de la loi Informatique et Libertés.",
                "6.2. Conformément aux exigences de l'App Store et de la réglementation européenne, chaque utilisateur peut à tout moment consulter, modifier ou supprimer définitivement et instantanément son compte Viple Live ID directement depuis l'onglet « Commandes & Compte » de l'application Looby."
            ]
        )
    ]
}
