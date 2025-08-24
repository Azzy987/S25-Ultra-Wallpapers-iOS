import SwiftUI

struct InfoMoreSection: View {
    @StateObject private var settingsViewModel: SettingsViewModel
    @Environment(\.appTheme) private var theme
    
    init(settingsViewModel: SettingsViewModel) {
        self._settingsViewModel = StateObject(wrappedValue: settingsViewModel)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            SettingsSectionHeader(title: "Info & More")
            
            VStack(spacing: 0) {
                // Rate App
                SettingsRow(
                    icon: "star.circle.fill",
                    iconColor: .yellow,
                    title: "Rate App",
                    subtitle: "Help us improve with your feedback",
                    action: {
                        settingsViewModel.openAppStoreForRating()
                    }
                )
                
                Divider()
                    .background(theme.onSurfaceVariant.opacity(0.3))
                    .padding(.horizontal, 20)
                
                // Share App
                SettingsRow(
                    icon: "square.and.arrow.up.circle.fill",
                    iconColor: .blue,
                    title: "Share App",
                    subtitle: "Share with friends and family",
                    action: {
                        settingsViewModel.shareApp()
                    }
                )
                
                Divider()
                    .background(theme.onSurfaceVariant.opacity(0.3))
                    .padding(.horizontal, 20)
                
                // More from Developer
                SettingsRow(
                    icon: "apps.iphone",
                    iconColor: .purple,
                    title: "More from Developer",
                    subtitle: "Discover our other apps",
                    action: {
                        settingsViewModel.openDeveloperPage()
                    }
                )
                
                Divider()
                    .background(theme.onSurfaceVariant.opacity(0.3))
                    .padding(.horizontal, 20)
                
                // Privacy Policy
                SettingsRow(
                    icon: "hand.raised.circle.fill",
                    iconColor: .green,
                    title: "Privacy Policy",
                    subtitle: "How we handle your data",
                    action: {
                        settingsViewModel.showingPrivacyPolicy = true
                    }
                )
                
                Divider()
                    .background(theme.onSurfaceVariant.opacity(0.3))
                    .padding(.horizontal, 20)
                
                // Terms of Use
                SettingsRow(
                    icon: "doc.text.circle.fill",
                    iconColor: .indigo,
                    title: "Terms of Use",
                    subtitle: "App usage terms and conditions",
                    action: {
                        settingsViewModel.showingTermsOfUse = true
                    }
                )
                
                Divider()
                    .background(theme.onSurfaceVariant.opacity(0.3))
                    .padding(.horizontal, 20)
                
                // Request a Feature
                SettingsRow(
                    icon: "lightbulb.circle.fill",
                    iconColor: .orange,
                    title: "Request a Feature",
                    subtitle: "Suggest new features or improvements",
                    action: {
                        settingsViewModel.showingFeatureRequest = true
                    }
                )
                
                Divider()
                    .background(theme.onSurfaceVariant.opacity(0.3))
                    .padding(.horizontal, 20)
                
                // Report Issues
                SettingsRow(
                    icon: "exclamationmark.triangle.circle.fill",
                    iconColor: .red,
                    title: "Report Issues",
                    subtitle: "Report bugs or technical problems",
                    action: {
                        settingsViewModel.reportIssue()
                    }
                )
                
                Divider()
                    .background(theme.onSurfaceVariant.opacity(0.3))
                    .padding(.horizontal, 20)
                
                // About/Licenses
                SettingsRow(
                    icon: "info.circle.fill",
                    iconColor: .gray,
                    title: "About",
                    subtitle: "App info, credits, and licenses",
                    action: {
                        settingsViewModel.showingAboutLicenses = true
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
    }
}