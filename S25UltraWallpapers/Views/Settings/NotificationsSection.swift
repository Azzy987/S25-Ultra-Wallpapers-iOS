import SwiftUI
import UserNotifications

struct NotificationsSection: View {
    @StateObject private var settingsViewModel: SettingsViewModel
    @Environment(\.appTheme) private var theme
    
    init(settingsViewModel: SettingsViewModel) {
        self._settingsViewModel = StateObject(wrappedValue: settingsViewModel)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            SettingsSectionHeader(title: "Notifications")
            
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "bell.circle.fill",
                    iconColor: notificationIconColor,
                    title: notificationTitle,
                    subtitle: "Receive updates about new wallpapers",
                    action: {
                        handleNotificationAction()
                    }
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surface)
                    .shadow(color: theme.onSurface.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
        .onAppear {
            settingsViewModel.checkNotificationPermissions()
        }
    }
    
    private var notificationTitle: String {
        switch settingsViewModel.notificationPermissionStatus {
        case .authorized:
            return "Notifications Enabled"
        case .denied:
            return "Notifications Disabled"
        case .notDetermined:
            return "Enable Notifications"
        case .provisional:
            return "Notifications Enabled"
        case .ephemeral:
            return "Notifications Enabled"
        @unknown default:
            return "Enable Notifications"
        }
    }
    
    private var notificationIconColor: Color {
        switch settingsViewModel.notificationPermissionStatus {
        case .authorized, .provisional, .ephemeral:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        @unknown default:
            return .orange
        }
    }
    
    private func handleNotificationAction() {
        switch settingsViewModel.notificationPermissionStatus {
        case .notDetermined:
            settingsViewModel.requestNotificationPermissions()
        case .denied:
            settingsViewModel.openSystemNotificationSettings()
        case .authorized, .provisional, .ephemeral:
            settingsViewModel.openSystemNotificationSettings()
        @unknown default:
            settingsViewModel.requestNotificationPermissions()
        }
    }
}