import SwiftUI

// MARK: - Developer Testing Section
// This is for testing premium features during development
// Should be disabled or hidden in production

struct DeveloperTestingSection: View {
    @StateObject private var userManager = UserManager.shared
    @StateObject private var rcManager = RevenueCatManager.shared
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
                Text("RevenueCat Offering")
                    .font(.subheadline.bold())
                    .foregroundColor(theme.onSurface)
                Spacer()
                Text(rcManager.currentOffering != nil ? "LOADED" : "LOADING")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(rcManager.currentOffering != nil ? Color.green : Color.orange)
                    .cornerRadius(8)
            }
            if let offering = rcManager.currentOffering {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Offering: \(offering.identifier)")
                        .font(.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                    ForEach(offering.availablePackages, id: \.identifier) { pkg in
                        HStack {
                            Text(pkg.storeProduct.localizedTitle)
                                .font(.caption)
                                .foregroundColor(theme.onSurface)
                            Spacer()
                            Text(pkg.storeProduct.localizedPriceString)
                                .font(.caption.bold())
                                .foregroundColor(theme.primary)
                        }
                    }
                }
            } else {
                Text("Pro entitlement: \(rcManager.isPro ? "ACTIVE" : "inactive")")
                    .font(.caption)
                    .foregroundColor(theme.onSurfaceVariant)
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