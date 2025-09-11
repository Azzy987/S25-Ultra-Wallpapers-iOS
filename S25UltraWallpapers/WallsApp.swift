//
//  WallsApp.swift
//  Walls
//
//  Created by Azam on 20/01/25.
//

import SwiftUI
import Firebase
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Google Sign-In
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            print("❌ Failed to get Google Sign-In client ID")
            return true
        }
        
        let config = GIDConfiguration(clientID: clientId)
        GIDSignIn.sharedInstance.configuration = config
        
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
}

@main
struct WallsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var firebaseManager = FirebaseManager.shared
    @StateObject private var favoritesManager = FavoritesManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    // Removed custom splash to avoid duplicate with Launch Screen
    
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
                        .preferredColorScheme(colorScheme(for: themeManager.themeMode, theme: themeManager.theme))
                } else {
                    OnboardingScreen {
                        hasCompletedOnboarding = true
                    }
                    .environmentObject(firebaseManager)
                    .environmentObject(favoritesManager)
                    .environment(\.appTheme, themeManager.theme)
                    .preferredColorScheme(colorScheme(for: themeManager.themeMode, theme: themeManager.theme))
                }
            }
            .onAppear {
                // No forced window background; follow system appearance
                
                // Setup additional theme change observer
                NotificationCenter.default.addObserver(
                    forName: NSNotification.Name("traitCollectionDidChange"),
                    object: nil,
                    queue: .main
                ) { _ in
                    // Theme will auto-update through ThemeManager observers
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                // Theme will auto-update through ThemeManager observers
            }
        }
    }
    
    private func colorScheme(for mode: ThemeManager.ThemeMode, theme: AppColorScheme) -> ColorScheme? {
        switch mode {
        case .system:
            return nil // Let system decide
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
