import SwiftUI
import RevenueCat
import FirebaseAuth

// MARK: - RevenueCat Manager

@MainActor
class RevenueCatManager: NSObject, ObservableObject {
    static let shared = RevenueCatManager()

    // MARK: - Published State

    /// Whether the user has an active "S26 Ultra Wallpapers Pro" entitlement
    @Published var isPro: Bool = false

    /// The currently active offering from RevenueCat (used to drive PaywallView)
    @Published var currentOffering: Offering? = nil

    /// Customer info snapshot — updated on every purchase/restore/launch
    @Published var customerInfo: CustomerInfo? = nil

    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    // MARK: - Constants

    static let entitlementID = "S26 Ultra Wallpapers Pro"
    static let apiKey = "appl_test_VsMPdmmTgYCJXwZnwFdClWjFAgR"
    private static let premiumCacheKey = "is_premium_cached"
    private static let premiumRefreshCooldown: TimeInterval = 30

    // Session-level cooldown: track last full refresh time
    private var lastRefreshTime: Date = .distantPast

    // MARK: - Init

    override private init() {
        // Seed isPro from UserDefaults immediately — no Firestore call needed at startup
        isPro = UserDefaults.standard.bool(forKey: Self.premiumCacheKey)
        super.init()
        Purchases.shared.delegate = self
        Task { await refreshAll() }
    }

    // MARK: - Public API

    /// Login the current Firebase user to RevenueCat so purchases sync to their account.
    func loginWithFirebaseUID() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            let (info, _) = try await Purchases.shared.logIn(uid)
            applyCustomerInfo(info)
            print("RevenueCat: logged in as Firebase UID \(uid)")
        } catch {
            print("RevenueCat: login error: \(error.localizedDescription)")
        }
    }

    /// Log out from RevenueCat (call when user signs out of Firebase).
    func logout() async {
        do {
            let info = try await Purchases.shared.logOut()
            applyCustomerInfo(info)
            print("RevenueCat: logged out (anonymous)")
        } catch {
            print("RevenueCat: logout error: \(error.localizedDescription)")
        }
    }

    /// Purchase a package. Returns true on success, false on user cancellation, throws on error.
    @discardableResult
    func purchase(package: Package) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            applyCustomerInfo(result.customerInfo)
            return !result.userCancelled
        } catch {
            if (error as NSError).domain == "SKErrorDomain",
               (error as NSError).code == 2 { // SKErrorPaymentCancelled
                return false
            }
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Restore purchases from the App Store.
    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }
        do {
            let info = try await Purchases.shared.restorePurchases()
            applyCustomerInfo(info)
            if !isPro {
                errorMessage = "No active purchases found."
            }
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    /// Refresh customer info + current offering from RevenueCat servers.
    func refreshAll() async {
        lastRefreshTime = Date()
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.refreshCustomerInfo() }
            group.addTask { await self.fetchOffering() }
        }
    }

    /// Only refreshes if more than 30 seconds have elapsed since last refresh.
    /// Use this on screen appear instead of refreshAll() to avoid redundant network calls.
    func refreshIfNeeded() async {
        let elapsed = Date().timeIntervalSince(lastRefreshTime)
        guard elapsed >= Self.premiumRefreshCooldown else { return }
        await refreshAll()
    }

    // MARK: - Private Helpers

    private func refreshCustomerInfo() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            applyCustomerInfo(info)
        } catch {
            print("RevenueCat: customerInfo error: \(error.localizedDescription)")
        }
    }

    private func fetchOffering() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            currentOffering = offerings.current
            print("RevenueCat: loaded offering '\(currentOffering?.identifier ?? "nil")'")
        } catch {
            print("RevenueCat: offerings error: \(error.localizedDescription)")
        }
    }

    /// Apply new customer info and sync premium status into UserManager + Firebase.
    private func applyCustomerInfo(_ info: CustomerInfo) {
        customerInfo = info
        let active = info.entitlements[Self.entitlementID]?.isActive == true
        isPro = active

        // Cache premium status to UserDefaults for instant read on next launch
        UserDefaults.standard.set(active, forKey: Self.premiumCacheKey)

        // Determine plan type from active subscription
        let planType: PremiumPlan? = {
            guard active else { return nil }
            if info.entitlements["lifetime"]?.isActive == true { return .lifetime }
            let productID = info.entitlements[Self.entitlementID]?.productIdentifier ?? ""
            if productID.contains("yearly") { return .yearly }
            if productID.contains("monthly") { return .monthly }
            return .yearly // fallback
        }()

        // Sync to UserManager
        if active, let plan = planType {
            let expiryDate = info.entitlements[Self.entitlementID]?.expirationDate
            UserManager.shared.updatePremiumStatus(
                type: UserManager.PremiumType(rawValue: plan.title) ?? .none,
                activeSince: info.entitlements[Self.entitlementID]?.latestPurchaseDate,
                expiryDate: expiryDate
            )
            // Sync to Firebase
            Task {
                await FirebaseUserDataManager.shared.updatePremiumStatus(
                    premium: true,
                    premiumType: plan.title,
                    premiumSince: info.entitlements[Self.entitlementID]?.latestPurchaseDate,
                    premiumExpiry: info.entitlements[Self.entitlementID]?.expirationDate
                )
            }
        } else if !active {
            UserManager.shared.updatePremiumStatus(type: .none, activeSince: nil, expiryDate: nil)
            Task {
                await FirebaseUserDataManager.shared.updatePremiumStatus(
                    premium: false,
                    premiumType: nil,
                    premiumSince: nil,
                    premiumExpiry: nil
                )
            }
        }
    }
}

// MARK: - PurchasesDelegate

extension RevenueCatManager: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            self.applyCustomerInfo(customerInfo)
        }
    }
}
