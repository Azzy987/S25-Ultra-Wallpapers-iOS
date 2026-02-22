import SwiftUI

// MARK: - Premium Badge Component
struct PremiumBadge: View {
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 20, height: 20)
                .shadow(color: .orange.opacity(0.3), radius: 2, x: 0, y: 1)
            
            // Star icon
            Image(systemName: "star.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Profile Image with Premium Badge
struct ProfileImageWithBadge: View {
    let imageURL: String?
    let showPremiumBadge: Bool
    let size: CGFloat
    @Environment(\.appTheme) private var theme
    
    init(imageURL: String?, showPremiumBadge: Bool = false, size: CGFloat = 40) {
        self.imageURL = imageURL
        self.showPremiumBadge = showPremiumBadge
        self.size = size
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Profile image
            AsyncImage(url: URL(string: imageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                // Default avatar
                Image(systemName: "person.circle.fill")
                    .font(.system(size: size * 0.8))
                    .foregroundColor(theme.onSurfaceVariant)
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .background(
                Circle()
                    .fill(theme.surfaceVariant)
            )
            
            // Premium badge
            if showPremiumBadge {
                PremiumBadge()
                    .offset(x: 2, y: -2)
            }
        }
    }
}

// MARK: - Large Profile Image with Badge (for settings)
struct LargeProfileImageWithBadge: View {
    let imageURL: String?
    let displayName: String
    let showPremiumBadge: Bool
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Large profile image
            AsyncImage(url: URL(string: imageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                // Default avatar with initials
                ZStack {
                    Circle()
                        .fill(theme.primary.opacity(0.1))
                    
                    Text(displayName.prefix(1).uppercased())
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(theme.primary)
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())
            .background(
                Circle()
                    .fill(theme.surfaceVariant)
                    .shadow(color: theme.onSurface.opacity(0.1), radius: 4, x: 0, y: 2)
            )
            
            // Premium badge (larger for big profile)
            if showPremiumBadge {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)
                        .shadow(color: .orange.opacity(0.3), radius: 3, x: 0, y: 2)
                    
                    Image(systemName: "star.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(x: 6, y: -6)
            }
        }
    }
}

// MARK: - Preview
#if DEBUG
#Preview {
    VStack(spacing: 30) {
        // Small profile with badge
        ProfileImageWithBadge(
            imageURL: nil,
            showPremiumBadge: true,
            size: 40
        )
        
        // Large profile with badge
        LargeProfileImageWithBadge(
            imageURL: nil,
            displayName: "John Doe",
            showPremiumBadge: true
        )
        
        // Without badge
        LargeProfileImageWithBadge(
            imageURL: nil,
            displayName: "Jane Smith",
            showPremiumBadge: false
        )
    }
    .padding()
    .environmentObject(ThemeManager.shared)
}
#endif