import SwiftUI

struct SettingsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var settingsViewModel = SettingsViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Section
                    ProfileSection()
                    
                    // Premium/Subscription Section
                    PremiumSection()
                    
                    // Display Settings Section
                    DisplaySettingsSection(settingsViewModel: settingsViewModel)
                    
                    // Content & Data Section
                    ContentDataSection(settingsViewModel: settingsViewModel)
                    
                    // Notifications Section
                    NotificationsSection(settingsViewModel: settingsViewModel)
                    
                    // Info & More Section
                    InfoMoreSection(settingsViewModel: settingsViewModel)
                    
                    // Version Information
                    VersionInfoView(settingsViewModel: settingsViewModel)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(theme.onSurface)
                    }
                }
            }
            .background(theme.background)
        }
        .navigationViewStyle(.stack)
        .environment(\.colorScheme, themeManager.themeMode == .dark ? .dark : .light)
        .preferredColorScheme(themeManager.themeMode == .dark ? .dark : .light)
        // Sheet presentations for dialogs
        .sheet(isPresented: $settingsViewModel.showingPrivacyPolicy) {
            ContentDialog(
                title: "Privacy Policy",
                content: settingsViewModel.privacyPolicyText
            )
        }
        .sheet(isPresented: $settingsViewModel.showingTermsOfUse) {
            ContentDialog(
                title: "Terms of Use", 
                content: settingsViewModel.termsOfUseText
            )
        }
        .sheet(isPresented: $settingsViewModel.showingAboutLicenses) {
            ContentDialog(
                title: "About",
                content: settingsViewModel.aboutLicensesText
            )
        }
        .sheet(isPresented: $settingsViewModel.showingFeatureRequest) {
            FeatureRequestDialog(settingsViewModel: settingsViewModel)
        }
    }
}

// Helper extension to get app version
extension Bundle {
    var appVersion: String {
        if let version = infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "1.0"
    }
}

// Custom ViewModifier for scrollContentBackground availability
struct ScrollBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.scrollContentBackground(.hidden)
        } else {
            content
        }
    }
} 
