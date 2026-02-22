import SwiftUI

struct ContentDataSection: View {
    @StateObject private var settingsViewModel: SettingsViewModel
    @StateObject private var userManager = UserManager.shared
    @Environment(\.appTheme) private var theme
    @State private var showingSignInAlert = false
    
    init(settingsViewModel: SettingsViewModel) {
        self._settingsViewModel = StateObject(wrappedValue: settingsViewModel)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            SettingsSectionHeader(title: "Content & Data")
            
            VStack(spacing: 0) {
                // Sync Favorites (Premium only)
                SettingsRow(
                    icon: "icloud.and.arrow.up.fill",
                    iconColor: userManager.isPremium ? .blue : .gray,
                    title: "Sync Favorites",
                    subtitle: getSyncSubtitle(),
                    action: {
                        if !userManager.isSignedIn {
                            showingSignInAlert = true
                        } else if userManager.isPremium {
                            settingsViewModel.syncFavorites()
                        } else {
                            // Show premium required alert
                            settingsViewModel.showPremiumRequired = true
                        }
                    },
                    isLast: true
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surface)
                    .shadow(color: theme.onSurface.opacity(0.15), radius: 8, x: 0, y: 4)
                    .shadow(color: theme.onSurface.opacity(0.08), radius: 2, x: 0, y: 1)
            )
        }
        .alert("Sign In Required", isPresented: $showingSignInAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign In") {
                userManager.signInWithGoogle()
            }
        } message: {
            Text("You need to sign in to sync your favorites across devices.")
        }
        .alert("Premium Required", isPresented: $settingsViewModel.showPremiumRequired) {
            Button("Cancel", role: .cancel) { }
            Button("Upgrade") {
                settingsViewModel.showPremiumScreen = true
            }
        } message: {
            Text("Cloud sync is a premium feature. Upgrade to sync your favorites across all devices.")
        }
    }
    
    // MARK: - Helper Methods
    
    private func getSyncSubtitle() -> String {
        if !userManager.isSignedIn {
            return "Sign in to sync favorites"
        } else if !userManager.isPremium {
            return "Premium required to sync favorites"
        } else {
            return "Sync favorites across devices"
        }
    }
}
