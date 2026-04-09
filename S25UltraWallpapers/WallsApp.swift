//
//  WallsApp.swift
//  Walls
//
//  Created by Azam on 20/01/25.
//

import SwiftUI
import Firebase
import GoogleSignIn
import GoogleMobileAds
import RevenueCat

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

/// Bridges SwiftUI's @Environment(\.colorScheme) into ThemeManager so that
/// switching back to "System" mode always picks up the actual current system appearance.
struct RootView: View {
    @Binding var hasCompletedOnboarding: Bool
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.colorScheme) private var systemColorScheme

    @AppStorage("paywall_shown_after_onboarding") private var paywallShown = false
    @AppStorage("privacy_policy_accepted") private var privacyAccepted = false

    // Step 1: privacy consent (shown before paywall, once ever)
    @State private var showPrivacyConsent = false
    // Step 2: paywall (shown after consent, once ever)
    @State private var showPaywall = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingScreen {
                    hasCompletedOnboarding = true
                    if !paywallShown {
                        // Show consent first if not accepted; else go straight to paywall
                        if !privacyAccepted {
                            showPrivacyConsent = true
                        } else {
                            showPaywall = true
                        }
                    }
                }
            }
        }
        .environment(\.appTheme, themeManager.theme)
        .preferredColorScheme(preferredScheme)
        .onChange(of: systemColorScheme) { newScheme in
            if themeManager.themeMode == .system {
                themeManager.applySystemColorScheme(newScheme)
            }
        }
        .onAppear {
            print("⏱️ [Startup] RootView.onAppear — first frame rendered")
            if themeManager.themeMode == .system {
                themeManager.applySystemColorScheme(systemColorScheme)
            }
        }
        // Privacy consent gate (shown once, before paywall)
        .fullScreenCover(isPresented: $showPrivacyConsent) {
            PrivacyConsentScreen {
                showPrivacyConsent = false
                showPaywall = true
            }
            .environment(\.appTheme, themeManager.theme)
        }
        // Paywall (shown once after consent)
        .fullScreenCover(isPresented: $showPaywall) {
            OnboardingPaywallScreen {
                showPaywall = false
            }
            .environment(\.appTheme, themeManager.theme)
        }
    }

    private var preferredScheme: ColorScheme? {
        switch themeManager.themeMode {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

@main
struct WallsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var firebaseManager = FirebaseManager.shared
    @StateObject private var favoritesManager = FavoritesManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var adManager = AdManager.shared
    @StateObject private var filterLockManager = FilterLockManager.shared
    @StateObject private var userManager = UserManager.shared
    @StateObject private var rcManager = RevenueCatManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    // Removed custom splash to avoid duplicate with Launch Screen
    
    init() {
        let t0 = Date()
        FirebaseApp.configure()
        print("⏱️ [Startup] FirebaseApp.configure: \(Int(Date().timeIntervalSince(t0) * 1000))ms")

        // Use .error level even in debug to avoid verbose logging overhead
        Purchases.logLevel = .error
        #if DEBUG
        Purchases.configure(withAPIKey: "appl_test_VsMPdmmTgYCJXwZnwFdClWjFAgR")
        #else
        Purchases.configure(withAPIKey: "TODO_REPLACE_WITH_PRODUCTION_REVENUECAT_KEY")
        #endif

        // Register image metadata cache for app lifecycle
        ImageMetadataCache.shared.registerForAppLifecycleNotifications()
        print("⏱️ [Startup] WallsApp.init complete: \(Int(Date().timeIntervalSince(t0) * 1000))ms")
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
            RootView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .environmentObject(firebaseManager)
                .environmentObject(favoritesManager)
                .environmentObject(adManager)
                .environmentObject(filterLockManager)
                .environmentObject(userManager)
                .environmentObject(themeManager)
                .environmentObject(rcManager)
                .task {
                    // Defer Firebase data fetch until after first render to unblock splash screen
                    FirebaseManager.shared.initialize()
                }
        }
    }
}
