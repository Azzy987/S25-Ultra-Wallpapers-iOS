import SwiftUI

struct PremiumSection: View {
    @StateObject private var userManager = UserManager.shared
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        VStack(spacing: 16) {
            SettingsSectionHeader(title: "Premium")
            
            if userManager.isPremium {
                PremiumActiveCard()
            } else {
                UpgradeToPremiumCard()
            }
        }
    }
}

struct PremiumActiveCard: View {
    @StateObject private var userManager = UserManager.shared
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        Button(action: {
            // Open subscription management
            print("📱 Opening subscription management")
        }) {
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    // Premium Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(
                                colors: [.orange, .yellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "crown.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .bold))
                    }
                    
                    // Premium Info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("Premium Active")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(theme.onSurface)
                            
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 16))
                        }
                        
                        Text(userManager.premiumStatusText)
                            .font(.system(size: 14))
                            .foregroundColor(theme.onSurfaceVariant)
                        
                        if let activeSinceText = userManager.premiumActiveSinceText {
                            Text(activeSinceText)
                                .font(.system(size: 12))
                                .foregroundColor(theme.onSurfaceVariant)
                        }
                        
                        if let expiryText = userManager.premiumExpiryText {
                            Text(expiryText)
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(theme.onSurfaceVariant)
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surface)
                    .shadow(color: theme.onSurface.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct UpgradeToPremiumCard: View {
    @Environment(\.appTheme) private var theme
    @State private var showPremiumScreen = false
    
    var body: some View {
        Button(action: {
            showPremiumScreen = true
        }) {
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    // Premium Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "star.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .bold))
                    }
                    
                    // Premium Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Upgrade to Premium")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(theme.onSurface)
                        
                        Text("Unlock all exclusive wallpapers and features")
                            .font(.system(size: 14))
                            .foregroundColor(theme.onSurfaceVariant)
                            .multilineTextAlignment(.leading)
                        
                        HStack(spacing: 12) {
                            FeatureBadge(text: "4K Quality")
                            FeatureBadge(text: "No Ads")
                            FeatureBadge(text: "Exclusive")
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(theme.onSurfaceVariant)
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surface)
                    .shadow(color: theme.onSurface.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .fullScreenCover(isPresented: $showPremiumScreen) {
            PremiumScreen()
        }
    }
}

struct FeatureBadge: View {
    let text: String
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(theme.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.primaryContainer.opacity(0.3))
            )
    }
}

struct UpgradeToPremiumCard_Previews: PreviewProvider {
    static var previews: some View {
        UpgradeToPremiumCard()
            .environmentObject(ThemeManager.shared)
    }
}