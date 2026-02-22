import SwiftUI

struct PremiumScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @State private var selectedPlan: PremiumPlan = .yearly
    @StateObject private var pricingManager = PremiumPricingManager.shared
    @StateObject private var userManager = UserManager.shared
    @State private var isPurchasing = false
    @State private var showPurchaseSuccess = false
    @State private var showSignInAlert = false
    @State private var showSignInAlertForRestore = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfUse = false
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Background color
            theme.background.ignoresSafeArea()

            // Main content
            VStack(spacing: 0) {
                // Header image section with fixed height
                ZStack {
                    // Background image
                    Image("OnboardingScreen1")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 280)
                        .clipped()

                    // Black overlay
                    Color.black.opacity(0.4)

                    // Title text
                    VStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Text("S25 Ultra Wallpapers")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                            Text("Pro")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(theme.primary)
                        }
                        .padding(.bottom, 40)
                    }
                }
                .frame(height: 280)

                // Scrollable content with rounded top corners extending to bottom
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        premiumFeaturesSection
                        choosePlanSection
                        pricingPlansSection
                        continueButton
                        restoreButton
                        termsAndPrivacySection
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 0)
                }
                .background(
                    theme.background
                        .clipShape(
                            RoundedRectangle(cornerRadius: 24)
                        )
                        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: -5)
                        .padding(.top, -24)
                )
            }

            // Close button overlay
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .padding(.leading, 20)
                    .padding(.top, 50)
                    Spacer()
                }
                Spacer()
            }
        }
        .offset(y: max(0, dragOffset))
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Only allow downward swipe
                    if value.translation.height > 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    // Dismiss if swiped down more than 150 points
                    if value.translation.height > 150 {
                        dismiss()
                    } else {
                        // Snap back
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .center) {
            if showPurchaseSuccess {
                PurchaseSuccessOverlay(plan: selectedPlan, isPresented: $showPurchaseSuccess) {
                    dismiss()
                }
                .transition(AnyTransition.opacity.animation(.easeInOut))
            }
        }
        .alert("Sign In Required", isPresented: $showSignInAlert) {
            Button("Sign In") {
                userManager.signInWithGoogle()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please sign in to purchase premium features and sync your data across devices.")
        }
        .alert("Sign In Required", isPresented: $showSignInAlertForRestore) {
            Button("Sign In") {
                userManager.signInWithGoogle()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please sign in to restore your purchases and sync your data across devices.")
        }
        .sheet(isPresented: $showTermsOfUse) {
            ContentDialog(
                title: "Terms of Use",
                content: termsContent
            )
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            ContentDialog(
                title: "Privacy Policy",
                content: privacyContent
            )
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

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    PremiumFeatureRow(icon: "photo.stack.fill", iconColor: .blue, title: "Exclusive\nWallpapers")
                    PremiumFeatureRow(icon: "eye.slash.fill", iconColor: .green, title: "Ad-Free\nExperience")
                }
                HStack(spacing: 8) {
                    PremiumFeatureRow(icon: "camera.filters", iconColor: .purple, title: "Premium\nFilters")
                    PremiumFeatureRow(icon: "slider.horizontal.3", iconColor: .orange, title: "Advanced\nEditing")
                }
            }
            .padding(12)
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
            if let monthlyPricing = pricingManager.monthlyPricing {
                CompactPricingCard(
                    plan: .monthly,
                    originalPrice: monthlyPricing.originalPrice,
                    discountedPrice: monthlyPricing.discountedPrice,
                    discountPercentage: monthlyPricing.discountPercentage,
                    isSelected: selectedPlan == .monthly,
                    onSelect: { selectedPlan = .monthly }
                )
            }
            
            if let yearlyPricing = pricingManager.yearlyPricing {
                CompactPricingCard(
                    plan: .yearly,
                    originalPrice: yearlyPricing.originalPrice,
                    discountedPrice: yearlyPricing.discountedPrice,
                    discountPercentage: yearlyPricing.discountPercentage,
                    isSelected: selectedPlan == .yearly,
                    onSelect: { selectedPlan = .yearly },
                    isPopular: true
                )
            }
            
            if let lifetimePricing = pricingManager.lifetimePricing {
                CompactPricingCard(
                    plan: .lifetime,
                    originalPrice: lifetimePricing.originalPrice,
                    discountedPrice: lifetimePricing.discountedPrice,
                    discountPercentage: lifetimePricing.discountPercentage,
                    isSelected: selectedPlan == .lifetime,
                    onSelect: { selectedPlan = .lifetime }
                )
            }
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
            handlePurchase()
        }) {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: isPurchasing ? [.gray, .gray.opacity(0.8)] : [theme.primary, theme.primary.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .disabled(isPurchasing)
    }
    
    private var restoreButton: some View {
        Button(action: {
            handleRestorePurchases()
        }) {
            HStack {
                if isPurchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                        .scaleEffect(0.7)
                }
                Text("Restore Purchases")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(theme.primary)
        }
        .disabled(isPurchasing)
    }
    
    private var termsAndPrivacySection: some View {
        HStack(spacing: 40) {
            Button("Terms of Use") {
                showTermsOfUse = true
            }
            .font(.system(size: 13))
            .foregroundColor(theme.onSurfaceVariant)

            Spacer()

            Button("Privacy Policy") {
                showPrivacyPolicy = true
            }
            .font(.system(size: 13))
            .foregroundColor(theme.onSurfaceVariant)
        }
    }
    
    // MARK: - Content Properties
    
    private var termsContent: String {
        return """
        Terms of Use
        
        Last updated: December 2024
        
        By using this app, you agree to these terms.
        
        1. Acceptable Use
        - Use the app only for lawful purposes
        - Do not attempt to reverse engineer the app
        - Respect intellectual property rights
        
        2. Premium Features
        - Premium subscriptions provide access to exclusive content
        - Subscriptions auto-renew unless cancelled
        - Refunds subject to App Store policies
        
        3. Limitation of Liability
        The app is provided "as is" without warranties.
        
        4. Changes to Terms
        We may update these terms from time to time.
        
        5. Contact
        Questions about these terms: droidates@gmail.com
        """
    }
    
    private var privacyContent: String {
        return """
        Privacy Policy
        
        Last updated: December 2024
        
        We respect your privacy and are committed to protecting your personal data.
        
        1. Information We Collect
        - Device information for crash reporting
        - Usage analytics to improve the app
        - Account information if you sign in
        
        2. How We Use Information
        - To provide and maintain our service
        - To notify you about changes to our service
        - To provide customer support
        
        3. Data Security
        We implement appropriate security measures to protect your personal information.
        
        4. Contact Us
        If you have questions about this Privacy Policy, contact us at: droidates@gmail.com
        """
    }
    
    // MARK: - Purchase Handling
    
    private func handlePurchase() {
        guard !isPurchasing else { return }
        
        // Check if user is signed in before proceeding with purchase
        guard userManager.isSignedIn else {
            showSignInAlert = true
            return
        }
        
        isPurchasing = true
        
        pricingManager.simulatePurchase(plan: selectedPlan) { success in
            DispatchQueue.main.async {
                isPurchasing = false
                
                if success {
                    showPurchaseSuccess = true
                } else {
                    print("❌ Purchase failed for \(selectedPlan.title)")
                    // In real app, show error alert
                }
            }
        }
    }
    
    private func handleRestorePurchases() {
        guard !isPurchasing else { return }
        
        // Check if user is signed in before proceeding with restore
        guard userManager.isSignedIn else {
            showSignInAlertForRestore = true
            return
        }
        
        isPurchasing = true
        
        pricingManager.simulateRestorePurchases { success in
            DispatchQueue.main.async {
                isPurchasing = false
                
                if success {
                    print("✅ Purchases restored successfully")
                    // In real app, show success message and dismiss
                    dismiss()
                } else {
                    print("⚠️ No purchases to restore")
                    // In real app, show "no purchases found" alert
                }
            }
        }
    }
}

// MARK: - Purchase Success Overlay

struct PurchaseSuccessOverlay: View {
    let plan: PremiumPlan
    @Binding var isPresented: Bool
    let onDismiss: () -> Void
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Success Icon
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Success Message
                VStack(spacing: 12) {
                    Text("Welcome to Premium!")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text("You now have access to all premium features with your \(plan.title.lowercased()) subscription.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Premium Features
                VStack(spacing: 8) {
                    PremiumBenefitRow(icon: "photo.stack.fill", text: "Unlimited exclusive wallpapers")
                    PremiumBenefitRow(icon: "eye.slash.fill", text: "Complete ad-free experience")
                    PremiumBenefitRow(icon: "camera.filters", text: "Access to premium filters")
                    PremiumBenefitRow(icon: "slider.horizontal.3", text: "Advanced editing tools")
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                )
                
                // Continue Button
                Button(action: {
                    isPresented = false
                    onDismiss()
                }) {
                    Text("Start Exploring")
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
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black.opacity(0.9))
            )
            .padding(.horizontal, 24)
        }
    }
}

struct PremiumBenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.green)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
        }
    }
}

struct PremiumFeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Environment(\.appTheme) private var theme

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 16, weight: .medium))
            }

            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(theme.onSurface)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .frame(minHeight: 54)
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