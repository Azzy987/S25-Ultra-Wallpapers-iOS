import SwiftUI

struct PremiumScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @State private var selectedPlan: PremiumPlan = .yearly
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header with onboarding image (25% of screen)
                headerImageSection
                    .frame(height: UIScreen.main.bounds.height * 0.25)
                
                // Content area (75% of screen) - below the image
                VStack(spacing: 16) {
                    premiumFeaturesSection
                    choosePlanSection
                    pricingPlansSection
                    continueButton
                    restoreButton
                    termsAndPrivacySection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(theme.background)
                .frame(maxHeight: UIScreen.main.bounds.height * 0.75)
            }
            
            // Close button overlay - positioned absolutely
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.black)
                            .padding(10)
                            .background(Color.white.opacity(0.95))
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .padding(.leading, 20)
                    .padding(.top, 50) // Account for status bar
                    
                    Spacer()
                }
                Spacer()
            }
        }
        .ignoresSafeArea(.all)
        .navigationBarHidden(true)
    }
    
    private var headerImageSection: some View {
        ZStack {
            // Onboarding background image
            Image("OnboardingScreen1")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            
            // Black alpha overlay
            Color.black.opacity(0.4)
            
            // App name with Pro at bottom
            VStack {
                Spacer()
                HStack {
                    Text("S25 Ultra Wallpapers ")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    + Text("Pro")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(theme.primary)
                }
                .padding(.bottom, 16)
            }
        }
    }
    
    private var premiumFeaturesSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Premium Features")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(theme.onSurface)
                Spacer()
            }
            .padding(.horizontal, 4)
            
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    PremiumFeatureRow(icon: "photo.stack.fill", iconColor: .blue, title: "Exclusive\nWallpapers")
                    PremiumFeatureRow(icon: "eye.slash.fill", iconColor: .green, title: "Ad-Free\nExperience")
                }
                HStack(spacing: 12) {
                    PremiumFeatureRow(icon: "camera.filters", iconColor: .purple, title: "Premium\nFilters")
                    PremiumFeatureRow(icon: "slider.horizontal.3", iconColor: .orange, title: "Advanced\nEditing")
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.surface)
                    .shadow(color: theme.onSurface.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
    }
    
    private var choosePlanSection: some View {
        HStack {
            Text("Choose Your Plan")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(theme.onSurface)
            Spacer()
        }
        .padding(.horizontal, 4)
    }
    
    private var pricingPlansSection: some View {
        HStack(spacing: 8) {
            CompactPricingCard(
                plan: .monthly,
                originalPrice: 99,
                discountedPrice: 49,
                discountPercentage: 50,
                isSelected: selectedPlan == .monthly,
                onSelect: { selectedPlan = .monthly }
            )
            
            CompactPricingCard(
                plan: .yearly,
                originalPrice: 399,
                discountedPrice: 160,
                discountPercentage: 60,
                isSelected: selectedPlan == .yearly,
                onSelect: { selectedPlan = .yearly },
                isPopular: true
            )
            
            CompactPricingCard(
                plan: .lifetime,
                originalPrice: 799,
                discountedPrice: 239,
                discountPercentage: 70,
                isSelected: selectedPlan == .lifetime,
                onSelect: { selectedPlan = .lifetime }
            )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(theme.surface)
                .shadow(color: theme.onSurface.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    private var continueButton: some View {
        Button(action: {
            print("🔥 Purchasing \(selectedPlan.title)")
        }) {
            Text("Continue")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [theme.primary, theme.primary.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
        }
    }
    
    private var restoreButton: some View {
        Button(action: {
            // Restore purchases
            print("🔄 Restoring purchases")
        }) {
            Text("Restore Purchases")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(theme.primary)
        }
    }
    
    private var termsAndPrivacySection: some View {
        HStack {
            Button("Terms of Use") {
                // Open terms
            }
            .font(.system(size: 12))
            .foregroundColor(theme.onSurfaceVariant)
            
            Spacer()
            
            Button("Privacy Policy") {
                // Open privacy
            }
            .font(.system(size: 12))
            .foregroundColor(theme.onSurfaceVariant)
        }
        .padding(.top, 8)
    }
}

struct PremiumFeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 18, weight: .medium))
            }
            
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(theme.onSurface)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .frame(minHeight: 60)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(theme.surfaceVariant.opacity(0.3))
        )
    }
}

struct CompactPricingCard: View {
    let plan: PremiumPlan
    let originalPrice: Int
    let discountedPrice: Int
    let discountPercentage: Int
    let isSelected: Bool
    let onSelect: () -> Void
    let isPopular: Bool
    @Environment(\.appTheme) private var theme
    
    init(plan: PremiumPlan, originalPrice: Int, discountedPrice: Int, discountPercentage: Int, isSelected: Bool, onSelect: @escaping () -> Void, isPopular: Bool = false) {
        self.plan = plan
        self.originalPrice = originalPrice
        self.discountedPrice = discountedPrice
        self.discountPercentage = discountPercentage
        self.isSelected = isSelected
        self.onSelect = onSelect
        self.isPopular = isPopular
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                if isPopular {
                    Text("POPULAR")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(theme.primary)
                        .cornerRadius(4)
                }
                
                Text(plan.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(theme.onSurface)
                
                VStack(spacing: 2) {
                    Text("$\(discountedPrice)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(theme.onSurface)
                    
                    Text("$\(originalPrice)")
                        .font(.system(size: 12))
                        .foregroundColor(theme.onSurfaceVariant)
                        .strikethrough()
                    
                    Text("\(discountPercentage)% OFF")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.green)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? theme.primaryContainer.opacity(0.2) : theme.surfaceVariant.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? theme.primary : Color.clear, lineWidth: 2)
                    )
                    .shadow(color: theme.onSurface.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

enum PremiumPlan: CaseIterable {
    case monthly
    case yearly
    case lifetime
    
    var title: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        case .lifetime: return "Lifetime"
        }
    }
    
    var subtitle: String {
        switch self {
        case .monthly: return "Billed monthly"
        case .yearly: return "Billed annually"
        case .lifetime: return "One-time payment"
        }
    }
    
    var period: String {
        switch self {
        case .monthly: return "month"
        case .yearly: return "year"
        case .lifetime: return "lifetime"
        }
    }
    
    func formattedDiscountedPrice(for price: Int) -> String {
        return "$\(price)"
    }
    
    var formattedDiscountedPrice: String {
        switch self {
        case .monthly: return "$49"
        case .yearly: return "$160"
        case .lifetime: return "$239"
        }
    }
}

#Preview {
    PremiumScreen()
        .environmentObject(ThemeManager.shared)
}