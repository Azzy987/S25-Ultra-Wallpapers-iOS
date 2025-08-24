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
                // Sync Favorites
                SettingsRow(
                    icon: "icloud.and.arrow.up.fill",
                    iconColor: .blue,
                    title: "Sync Favorites",
                    subtitle: userManager.isSignedIn ? "Sync favorites across devices" : "Sign in to sync favorites",
                    action: {
                        if userManager.isSignedIn {
                            settingsViewModel.syncFavorites()
                        } else {
                            showingSignInAlert = true
                        }
                    },
                    isLast: true
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surface)
                    .shadow(color: theme.onSurface.opacity(0.1), radius: 2, x: 0, y: 1)
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
    }
}