import SwiftUI

struct ProfileSection: View {
    @StateObject private var userManager = UserManager.shared
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        VStack(spacing: 16) {
            SettingsSectionHeader(title: "Profile")
            
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    // Profile Image
                    Group {
                        if let imageURL = userManager.profileImageURL,
                           let url = URL(string: imageURL) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(theme.onSurfaceVariant)
                            }
                        } else {
                            Image(systemName: userManager.isSignedIn ? "person.circle.fill" : "person.circle")
                                .foregroundColor(theme.onSurfaceVariant)
                        }
                    }
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                    
                    // User Info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(userManager.displayName)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(theme.onSurface)
                            
                            if userManager.isPremium {
                                Image(systemName: "crown.fill")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 14))
                            }
                        }
                        
                        if userManager.isSignedIn {
                            Text(userManager.email)
                                .font(.system(size: 14))
                                .foregroundColor(theme.onSurfaceVariant)
                        } else {
                            Text("Sign in to sync your favorites")
                                .font(.system(size: 14))
                                .foregroundColor(theme.onSurfaceVariant)
                        }
                        
                        if userManager.isPremium {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 12))
                                
                                Text("Premium Active")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                Divider()
                    .background(theme.onSurfaceVariant.opacity(0.3))
                    .padding(.horizontal, 20)
                
                // Sign In/Out Button
                Button(action: {
                    if userManager.isSignedIn {
                        userManager.signOut()
                    } else {
                        userManager.signInWithGoogle()
                    }
                }) {
                    HStack {
                        Image(systemName: userManager.isSignedIn ? "rectangle.portrait.and.arrow.right" : "globe")
                            .foregroundColor(theme.primary)
                            .font(.system(size: 16))
                        
                        Text(userManager.isSignedIn ? "Sign Out" : "Sign In with Google")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(theme.primary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(theme.onSurfaceVariant)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity) // Ensure full width
                    .background(Color.clear)
                    .contentShape(Rectangle()) // Make entire area tappable
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surface)
                    .shadow(color: theme.onSurface.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
    }
}