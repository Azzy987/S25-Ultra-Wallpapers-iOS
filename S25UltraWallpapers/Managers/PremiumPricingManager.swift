import SwiftUI
import Firebase
import FirebaseFirestore

// MARK: - Premium Pricing Manager
class PremiumPricingManager: ObservableObject {
    static let shared = PremiumPricingManager()
    
    @Published var pricingData: PricingData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    struct PricingData {
        let monthly: PricingTier
        let yearly: PricingTier  
        let lifetime: PricingTier
        
        struct PricingTier {
            let originalPrice: Int
            let discountedPrice: Int
            let discountPercentage: Int
            
            var formattedOriginalPrice: String {
                return "₹\(originalPrice)"
            }
            
            var formattedDiscountedPrice: String {
                return "₹\(discountedPrice)"
            }
        }
    }
    
    private init() {
        fetchPricing()
    }
    
    // MARK: - Firebase Pricing Fetch
    
    func fetchPricing() {
        isLoading = true
        errorMessage = nil
        
        db.collection("s25ultraios").limit(to: 1).getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Failed to fetch pricing: \(error.localizedDescription)"
                    print("❌ Error fetching pricing: \(error)")
                    self?.setDefaultPricing()
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    self?.errorMessage = "No pricing data found"
                    print("❌ No pricing documents found")
                    self?.setDefaultPricing()
                    return
                }
                
                let document = documents[0]
                self?.processPricingData(document)
            }
        }
    }
    
    private func processPricingData(_ document: DocumentSnapshot) {
        let data = document.data() ?? [:]
        
        // Extract base prices from Firebase
        let monthlyPrice = data["s25monthly"] as? Int ?? 99
        let yearlyPrice = data["s25yearly"] as? Int ?? 199  
        let lifetimePrice = data["s25lifetime"] as? Int ?? 399
        
        // Apply discounts and create pricing tiers
        let monthlyTier = PricingData.PricingTier(
            originalPrice: 199,  // 199 dummy price
            discountedPrice: monthlyPrice, // 99 from Firebase (50% off)
            discountPercentage: 50
        )
        
        let yearlyTier = PricingData.PricingTier(
            originalPrice: 499,  // 499 dummy price  
            discountedPrice: yearlyPrice, // 199 from Firebase (60% off)
            discountPercentage: 60
        )
        
        let lifetimeTier = PricingData.PricingTier(
            originalPrice: calculateLifetimeOriginal(discountedPrice: lifetimePrice), // Calculate 70% off original
            discountedPrice: lifetimePrice, // 399 from Firebase
            discountPercentage: 70
        )
        
        self.pricingData = PricingData(
            monthly: monthlyTier,
            yearly: yearlyTier,
            lifetime: lifetimeTier
        )
        
        print("✅ Successfully fetched pricing from Firebase")
        print("📊 Monthly: \(monthlyTier.formattedOriginalPrice) → \(monthlyTier.formattedDiscountedPrice) (\(monthlyTier.discountPercentage)% off)")
        print("📊 Yearly: \(yearlyTier.formattedOriginalPrice) → \(yearlyTier.formattedDiscountedPrice) (\(yearlyTier.discountPercentage)% off)")  
        print("📊 Lifetime: \(lifetimeTier.formattedOriginalPrice) → \(lifetimeTier.formattedDiscountedPrice) (\(lifetimeTier.discountPercentage)% off)")
    }
    
    private func calculateLifetimeOriginal(discountedPrice: Int) -> Int {
        // If discounted price is 399 and discount is 70%, original = 399 / 0.3 = 1330
        return Int(Double(discountedPrice) / 0.3)
    }
    
    private func setDefaultPricing() {
        // Fallback pricing if Firebase fails
        let monthlyTier = PricingData.PricingTier(originalPrice: 199, discountedPrice: 99, discountPercentage: 50)
        let yearlyTier = PricingData.PricingTier(originalPrice: 499, discountedPrice: 199, discountPercentage: 60)
        let lifetimeTier = PricingData.PricingTier(originalPrice: 1330, discountedPrice: 399, discountPercentage: 70)
        
        self.pricingData = PricingData(
            monthly: monthlyTier,
            yearly: yearlyTier, 
            lifetime: lifetimeTier
        )
        
        print("⚠️ Using default pricing due to Firebase error")
    }
    
    // MARK: - Purchase Simulation (for testing without StoreKit)
    
    func simulatePurchase(plan: PremiumPlan, completion: @escaping (Bool) -> Void) {
        print("🛒 Simulating purchase for \(plan.title)")
        
        // Simulate purchase delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // In real implementation, this would be StoreKit purchase
            // For simulation, mostly succeed but occasionally fail (5% chance)
            let success = Double.random(in: 0...1) > 0.05
            
            if success {
                self.handleSuccessfulPurchase(plan: plan)
                completion(true)
            } else {
                print("❌ Purchase simulation failed")
                completion(false)
            }
        }
    }
    
    func simulateRestorePurchases(completion: @escaping (Bool) -> Void) {
        print("🔄 Simulating restore purchases")
        
        // Simulate restore delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Check if user had previous premium (from UserDefaults for testing)
            let hadPremium = UserDefaults.standard.bool(forKey: "simulate_had_premium")
            
            if hadPremium {
                self.handleSuccessfulPurchase(plan: .yearly) // Simulate yearly restore
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    private func handleSuccessfulPurchase(plan: PremiumPlan) {
        Task { @MainActor in
            // Update UserManager with premium status and sync to Firebase
            UserManager.shared.setPremiumStatusWithFirebaseSync(true, plan: plan)
            
            // Save for restore simulation
            UserDefaults.standard.set(true, forKey: "simulate_had_premium")
            UserDefaults.standard.set(plan.rawValue, forKey: "premium_plan_type")
            
            print("✅ Successfully 'purchased' \(plan.title)")
        }
    }
    
    // MARK: - Computed Properties
    
    var monthlyPricing: PricingData.PricingTier? {
        return pricingData?.monthly
    }
    
    var yearlyPricing: PricingData.PricingTier? {
        return pricingData?.yearly
    }
    
    var lifetimePricing: PricingData.PricingTier? {
        return pricingData?.lifetime
    }
    
    func getPricing(for plan: PremiumPlan) -> PricingData.PricingTier? {
        switch plan {
        case .monthly:
            return monthlyPricing
        case .yearly:
            return yearlyPricing
        case .lifetime:
            return lifetimePricing
        }
    }
}

// MARK: - Premium Plan Extension

extension PremiumPlan {
    var rawValue: String {
        switch self {
        case .monthly: return "monthly"
        case .yearly: return "yearly"
        case .lifetime: return "lifetime"
        }
    }
    
    init?(rawValue: String) {
        switch rawValue {
        case "monthly": self = .monthly
        case "yearly": self = .yearly
        case "lifetime": self = .lifetime
        default: return nil
        }
    }
}
