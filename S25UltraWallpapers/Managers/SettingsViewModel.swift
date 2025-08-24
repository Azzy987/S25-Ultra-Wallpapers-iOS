import SwiftUI
import UserNotifications
import MessageUI

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var cacheSize: String = "0 MB"
    @Published var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    @Published var selectedRefreshRate: RefreshRate = .auto
    @Published var showingThemeSelection = false
    @Published var showingRefreshRateSelection = false
    @Published var showingPrivacyPolicy = false
    @Published var showingTermsOfUse = false
    @Published var showingAboutLicenses = false
    @Published var showingFeatureRequest = false
    @Published var showingChangelog = false
    @Published var isLoadingCacheSize = false
    
    enum RefreshRate: String, CaseIterable {
        case auto = "Auto (System)"
        case hz60 = "60Hz"
        case hz90 = "90Hz"
        case hz120 = "120Hz"
        
        var displayName: String { return self.rawValue }
    }
    
    init() {
        loadSettings()
        calculateCacheSize()
        checkNotificationPermissions()
    }
    
    private func loadSettings() {
        if let savedRefreshRate = UserDefaults.standard.string(forKey: "refreshRate") {
            selectedRefreshRate = RefreshRate(rawValue: savedRefreshRate) ?? .auto
        }
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(selectedRefreshRate.rawValue, forKey: "refreshRate")
    }
    
    func updateRefreshRate(_ rate: RefreshRate) {
        selectedRefreshRate = rate
        saveSettings()
        applyRefreshRate(rate)
    }
    
    private func applyRefreshRate(_ rate: RefreshRate) {
        // In a real app, this would configure the display refresh rate
        print("📱 Applied refresh rate: \(rate.displayName)")
    }
    
    func calculateCacheSize() {
        isLoadingCacheSize = true
        
        Task {
            let size = await getCacheSizeInBackground()
            await MainActor.run {
                self.cacheSize = size
                self.isLoadingCacheSize = false
            }
        }
    }
    
    private func getCacheSizeInBackground() async -> String {
        // Calculate actual cache size
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        var totalSize: Int64 = 0
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.fileSizeKey],
                options: .skipsHiddenFiles
            )
            
            for fileURL in contents {
                if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                   let fileSize = resourceValues.fileSize {
                    totalSize += Int64(fileSize)
                }
            }
        } catch {
            print("📱 Error calculating cache size: \(error)")
        }
        
        return ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    func clearCache() {
        Task {
            await clearCacheInBackground()
            await MainActor.run {
                self.calculateCacheSize()
            }
        }
    }
    
    private func clearCacheInBackground() async {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for url in contents {
                try FileManager.default.removeItem(at: url)
            }
            print("📱 Cache cleared successfully")
        } catch {
            print("📱 Error clearing cache: \(error)")
        }
    }
    
    func checkNotificationPermissions() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationPermissionStatus = settings.authorizationStatus
            }
        }
    }
    
    func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    self.notificationPermissionStatus = .authorized
                } else {
                    self.notificationPermissionStatus = .denied
                }
            }
        }
    }
    
    func openAppStoreForRating() {
        // In real app, replace with actual App Store ID
        let appStoreURL = "https://apps.apple.com/app/id123456789?action=write-review"
        if let url = URL(string: appStoreURL) {
            UIApplication.shared.open(url)
        }
    }
    
    func shareApp() {
        let appStoreURL = "https://apps.apple.com/app/id123456789"
        let text = "Check out this amazing wallpaper app!"
        
        let activityVC = UIActivityViewController(activityItems: [text, appStoreURL], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            
            // For iPad
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootViewController.view
                popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX, y: rootViewController.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootViewController.present(activityVC, animated: true)
        }
    }
    
    func openDeveloperPage() {
        // Replace with actual developer page
        let developerURL = "https://apps.apple.com/developer/id123456789"
        if let url = URL(string: developerURL) {
            UIApplication.shared.open(url)
        }
    }
    
    func syncFavorites() {
        guard UserManager.shared.isSignedIn else {
            // Show sign-in prompt
            print("📱 User must sign in to sync favorites")
            return
        }
        
        // In a real implementation, this would sync with Firebase
        // For now, just refresh local favorites
        FavoritesManager.shared.fetchFavorites()
        print("📱 Favorites synced successfully")
    }
    
    func sendFeatureRequest(title: String, description: String) {
        let subject = "S25UltraWallpapers: Feature Request"
        let body = """
        Feature: \(title)
        
        Description: \(description)
        
        Device: \(UIDevice.current.model) - iOS \(UIDevice.current.systemVersion)
        """
        
        sendEmail(subject: subject, body: body)
    }
    
    func reportIssue() {
        let subject = "S25UltraWallpapers: Issue Report"
        let body = """
        Issue Description:
        
        
        Device: \(UIDevice.current.model)
        iOS: \(UIDevice.current.systemVersion)
        App: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
        """
        
        sendEmail(subject: subject, body: body)
    }
    
    private func sendEmail(subject: String, body: String) {
        let email = "droidates@gmail.com"
        let urlString = "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
    
    var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    var buildNumber: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    var fullVersionString: String {
        return "Version \(appVersion) (\(buildNumber))"
    }
    
    func openSystemNotificationSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
    
    // Privacy Policy content
    var privacyPolicyText: String {
        return """
        Privacy Policy
        
        Last updated: [Date]
        
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
    
    // Terms of Use content
    var termsOfUseText: String {
        return """
        Terms of Use
        
        Last updated: [Date]
        
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
    
    // About/Licenses content
    var aboutLicensesText: String {
        return """
        About S25UltraWallpapers
        
        Version \(appVersion) (\(buildNumber))
        
        A beautiful wallpaper app featuring stunning Samsung Galaxy wallpapers.
        
        Credits:
        - Design: [Designer Name]
        - Development: [Developer Name]
        - UI Icons: SF Symbols
        
        Open Source Licenses:
        
        Firebase iOS SDK
        Copyright 2023 Google Inc.
        Licensed under the Apache License, Version 2.0
        
        SwiftUI
        Copyright 2023 Apple Inc.
        
        For complete license information, visit:
        https://yourapp.com/licenses
        """
    }
    
    // Changelog content
    var changelogText: String {
        return """
        What's New in Version \(appVersion)
        
        🎨 New Features:
        • Series filter for Samsung wallpapers
        • Improved theme support
        • Enhanced settings screen
        
        🐛 Bug Fixes:
        • Fixed banner indicator positioning
        • Improved theme switching
        • Better performance optimizations
        
        💡 Improvements:
        • Updated UI components
        • Better error handling
        • Enhanced user experience
        
        Previous versions:
        
        Version 1.0.0:
        • Initial release
        • Samsung Galaxy wallpapers
        • Trending collections
        • Favorites system
        """
    }
}