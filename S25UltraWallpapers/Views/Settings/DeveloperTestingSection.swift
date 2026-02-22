import SwiftUI

// MARK: - Developer Testing Section
// This is for testing premium features during development
// Should be disabled or hidden in production

struct DeveloperTestingSection: View {
    @StateObject private var userManager = UserManager.shared
    @StateObject private var pricingManager = PremiumPricingManager.shared
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        #if DEBUG
        VStack(spacing: 16) {
            SettingsSectionHeader(title: "Developer Testing")
            
            VStack(spacing: 12) {
                // Current Premium Status
                premiumStatusCard
                
                // Test Premium Buttons
                testPremiumControls
                
                // Pricing Data Status
                pricingStatusCard
                
                // Reset Button
                resetPremiumButton
            }
        }
        #endif
    }
    
    @ViewBuilder
    private var premiumStatusCard: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Premium Status")
                    .font(.headline)
                    .foregroundColor(theme.onSurface)
                Spacer()
                
                Text(userManager.isPremium ? "ACTIVE" : "FREE")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(userManager.isPremium ? Color.green : Color.gray)
                    .cornerRadius(8)
            }
            
            if userManager.isPremium {
                HStack {
                    Text(userManager.premiumStatusText)
                        .font(.subheadline)
                        .foregroundColor(theme.onSurfaceVariant)
                    Spacer()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    @ViewBuilder
    private var testPremiumControls: some View {
        VStack(spacing: 8) {
            Text("Test Premium Plans")
                .font(.subheadline.bold())
                .foregroundColor(theme.onSurface)
            
            HStack(spacing: 8) {
                testPremiumButton(plan: .monthly, title: "Monthly")
                testPremiumButton(plan: .yearly, title: "Yearly") 
                testPremiumButton(plan: .lifetime, title: "Lifetime")
            }
        }
    }
    
    @ViewBuilder
    private func testPremiumButton(plan: PremiumPlan, title: String) -> some View {
        Button(action: {
            simulateTestPremium(plan: plan)
        }) {
            Text(title)
                .font(.caption.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(theme.primary)
                .cornerRadius(8)
        }
    }
    
    @ViewBuilder
    private var pricingStatusCard: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Firebase Pricing")
                    .font(.subheadline.bold())
                    .foregroundColor(theme.onSurface)
                Spacer()
                
                Text(pricingManager.pricingData != nil ? "LOADED" : "LOADING")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(pricingManager.pricingData != nil ? Color.green : Color.orange)
                    .cornerRadius(8)
            }
            
            if let pricingData = pricingManager.pricingData {
                VStack(alignment: .leading, spacing: 4) {
                    pricingRow("Monthly", pricingData.monthly)
                    pricingRow("Yearly", pricingData.yearly)  
                    pricingRow("Lifetime", pricingData.lifetime)
                }
            } else if pricingManager.isLoading {
                ProgressView("Loading pricing...")
                    .font(.caption)
                    .foregroundColor(theme.onSurfaceVariant)
            } else if let error = pricingManager.errorMessage {
                Text("Error: \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    @ViewBuilder
    private func pricingRow(_ title: String, _ tier: PremiumPricingManager.PricingData.PricingTier) -> some View {
        HStack {
            Text("\(title):")
                .font(.caption)
                .foregroundColor(theme.onSurfaceVariant)
            
            Text(tier.formattedOriginalPrice)
                .font(.caption)
                .foregroundColor(theme.onSurfaceVariant)
                .strikethrough()
            
            Text("→")
                .font(.caption)
                .foregroundColor(theme.onSurfaceVariant)
            
            Text(tier.formattedDiscountedPrice)
                .font(.caption.bold())
                .foregroundColor(theme.primary)
            
            Text("(\(tier.discountPercentage)% off)")
                .font(.caption)
                .foregroundColor(.green)
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var resetPremiumButton: some View {
        Button(action: {
            userManager.resetPremiumStatus()
        }) {
            Text("Reset to Free")
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.red)
                .cornerRadius(8)
        }
    }
    
    // MARK: - Testing Functions
    
    private func simulateTestPremium(plan: PremiumPlan) {
        userManager.setPremiumStatus(true, plan: plan)
        print("🧪 [TEST] Activated \(plan.title) premium")
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    DeveloperTestingSection()
        .environmentObject(ThemeManager.shared)
}
#endif