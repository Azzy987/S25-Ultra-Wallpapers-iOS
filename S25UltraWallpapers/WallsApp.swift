//
//  WallsApp.swift
//  Walls
//
//  Created by Azam on 20/01/25.
//

import SwiftUI
import Firebase

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }
}

@main
struct WallsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var firebaseManager = FirebaseManager.shared
    @StateObject private var favoritesManager = FavoritesManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    init() {
        FirebaseApp.configure()
        // Initialize data on app launch
        FirebaseManager.shared.initialize()
        // Register image metadata cache for app lifecycle
        ImageMetadataCache.shared.registerForAppLifecycleNotifications()
    }
    
    static func getKeyWindow() -> UIWindow? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return nil
        }
        return window
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    MainTabView()
                        .environmentObject(firebaseManager)
                        .environmentObject(favoritesManager)
                        .environment(\.appTheme, themeManager.theme)
                        .preferredColorScheme(themeManager.theme.themeType == .dark ? .dark : .light)
                } else {
                    OnboardingScreen {
                        hasCompletedOnboarding = true
                    }
                    .environmentObject(firebaseManager)
                    .environmentObject(favoritesManager)
                    .environment(\.appTheme, themeManager.theme)
                    .preferredColorScheme(themeManager.theme.themeType == .dark ? .dark : .light)
                }
            }
                .onAppear {
                    // Setup additional theme change observer
                    NotificationCenter.default.addObserver(
                        forName: NSNotification.Name("traitCollectionDidChange"),
                        object: nil,
                        queue: .main
                    ) { _ in
                        print("🎨 System appearance changed")
                        // No longer needed since we don't support system theme
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    print("🎨 App became active")
                    // No longer needed since we don't support system theme
                }
        }
    }
}
