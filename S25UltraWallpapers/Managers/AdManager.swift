//
//  AdManager.swift
//  S25UltraWallpapers
//
//  Created by AI Assistant on 15/09/25.
//

import Foundation
import GoogleMobileAds
import UIKit
import SwiftUI

class AdManager: NSObject, ObservableObject {
    static let shared = AdManager()
    
    // Ad Unit IDs
    struct AdUnitIDs {
        static let native = "ca-app-pub-6427410984085546/5102820309"
        static let interstitial = "ca-app-pub-6427410984085546/4442067647"
        static let reward = "ca-app-pub-6427410984085546/2779909293"
        
        // Test IDs for development - replace with live IDs in production
        #if DEBUG
        static let nativeTest = "ca-app-pub-3940256099942544/3986624511"
        static let interstitialTest = "ca-app-pub-3940256099942544/4411468910"
        static let rewardTest = "ca-app-pub-3940256099942544/1712485313"
        #endif
    }
    
    // Published properties for UI updates
    @Published var isInterstitialReady = false
    @Published var isRewardAdReady = false
    @Published var isLoadingInterstitial = false
    @Published var isLoadingRewardAd = false
    
    // Ad instances
    private var interstitialAd: InterstitialAd?
    private var rewardAd: RewardedAd?
    private var nativeAdLoader: AdLoader?
    
    // Callbacks
    private var rewardAdCompletionHandler: ((Bool) -> Void)?
    private var interstitialCompletionHandler: (() -> Void)?
    
    override init() {
        super.init()
        initializeGoogleMobileAds()
    }
    
    // MARK: - Initialization
    
    private func initializeGoogleMobileAds() {
        // Configure test devices for development
        #if DEBUG
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = ["SIMULATOR"]
        #endif

        // Initialize according to the official documentation
        MobileAds.shared.start(completionHandler: { [weak self] _ in
            DispatchQueue.main.async {
                print("✅ Google Mobile Ads initialized")
                // Defer ad preloading to avoid blocking app startup with WebView processes
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self?.loadInterstitialAd()
                    self?.loadRewardAd()
                }
            }
        })
    }
    
    // MARK: - Interstitial Ads
    
    func loadInterstitialAd() {
        guard interstitialAd == nil else { return }
        
        isLoadingInterstitial = true
        
        let adUnitID = AdUnitIDs.interstitial
        #if DEBUG
        // Use test ad in debug mode
        let finalAdUnitID = AdUnitIDs.interstitialTest
        #else
        let finalAdUnitID = adUnitID
        #endif
        
        let request = Request()
        
        InterstitialAd.load(with: finalAdUnitID, request: request, completionHandler: { [weak self] ad, error in
            DispatchQueue.main.async {
                self?.isLoadingInterstitial = false
                
                if let error = error {
                    print("❌ Failed to load interstitial ad: \(error.localizedDescription)")
                    self?.isInterstitialReady = false
                    return
                }
                
                self?.interstitialAd = ad
                self?.interstitialAd?.fullScreenContentDelegate = self
                self?.isInterstitialReady = true
                print("✅ Interstitial ad loaded successfully")
            }
        })
    }
    
    func showInterstitialAd(completion: (() -> Void)? = nil) {
        // Ensure we're on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                completion?()
                return
            }
            
            // Check if user is premium (should not show ads)
            if UserManager.shared.isPremium {
                completion?()
                return
            }
            
            // Validate ad and view controller
            guard let interstitialAd = self.interstitialAd else {
                print("❌ Interstitial ad not ready")
                completion?()
                return
            }
            
            // Find root view controller properly
            guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                  let window = windowScene.windows.first(where: { $0.isKeyWindow }),
                  let rootViewController = window.rootViewController else {
                print("❌ No valid root view controller found")
                completion?()
                return
            }
            
            // Find the topmost presented view controller
            var topViewController = rootViewController
            while let presentedViewController = topViewController.presentedViewController {
                topViewController = presentedViewController
            }
            
            print("✅ Presenting interstitial ad from \(type(of: topViewController))")
            self.interstitialCompletionHandler = completion
            interstitialAd.present(from: topViewController)
        }
    }
    
    // MARK: - Navigation with Ad Check (Android-like behavior)
    
    /// Navigates with ad check - shows interstitial ad if available, or navigates immediately
    /// Implements 1-second timeout like Android to ensure instant navigation
    func navigateWithAdCheck(completion: @escaping () -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                completion()
                return
            }
            
            // 1. Check premium status first - instant navigation for premium users
            if UserManager.shared.isPremium {
                print("✅ Premium user - instant navigation")
                completion()
                return
            }
            
            // 2. Check if ads should be shown
            if !self.shouldShowAds() {
                print("✅ Ads disabled - instant navigation")
                completion()
                return
            }
            
            // 3. Set up 1-second timeout (Android uses 1000ms)
            var completed = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if !completed {
                    completed = true
                    print("⏱️ Ad timeout - navigating anyway")
                    completion()
                }
            }
            
            // 4. Try to show ad if loaded
            if self.isInterstitialReady, let interstitialAd = self.interstitialAd {
                // Find root view controller
                guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                      let window = windowScene.windows.first(where: { $0.isKeyWindow }),
                      let rootViewController = window.rootViewController else {
                    if !completed {
                        completed = true
                        completion()
                    }
                    return
                }
                
                var topViewController = rootViewController
                while let presentedViewController = topViewController.presentedViewController {
                    topViewController = presentedViewController
                }
                
                print("✅ Showing interstitial ad before navigation")
                
                self.interstitialCompletionHandler = {
                    if !completed {
                        completed = true
                        completion()
                    }
                }
                
                interstitialAd.present(from: topViewController)
            } else {
                // No ad available, navigate immediately
                if !completed {
                    completed = true
                    print("✅ No ad loaded - instant navigation")
                    completion()
                }
            }
        }
    }
    
    // MARK: - Reward Ads
    
    func loadRewardAd() {
        guard rewardAd == nil else { return }
        
        isLoadingRewardAd = true
        
        let adUnitID = AdUnitIDs.reward
        #if DEBUG
        let finalAdUnitID = AdUnitIDs.rewardTest
        #else
        let finalAdUnitID = adUnitID
        #endif
        
        let request = Request()
        
        RewardedAd.load(with: finalAdUnitID, request: request, completionHandler: { [weak self] ad, error in
            DispatchQueue.main.async {
                self?.isLoadingRewardAd = false
                
                if let error = error {
                    print("❌ Failed to load reward ad: \(error.localizedDescription)")
                    self?.isRewardAdReady = false
                    return
                }
                
                self?.rewardAd = ad
                self?.rewardAd?.fullScreenContentDelegate = self
                self?.isRewardAdReady = true
                print("✅ Reward ad loaded successfully")
            }
        })
    }
    
    func showRewardAd(completion: @escaping (Bool) -> Void) {
        // Ensure we're on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                completion(false)
                return
            }
            
            guard let rewardAd = self.rewardAd else {
                print("❌ Reward ad not ready")
                completion(false)
                return
            }
            
            // Find the proper view controller to present from
            guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                  let window = windowScene.windows.first(where: { $0.isKeyWindow }),
                  let rootViewController = window.rootViewController else {
                print("❌ No valid root view controller found")
                completion(false)
                return
            }
            
            // Find the topmost presented view controller
            var topViewController = rootViewController
            while let presentedViewController = topViewController.presentedViewController {
                topViewController = presentedViewController
            }
            
            print("✅ Presenting reward ad from \(type(of: topViewController))")
            self.rewardAdCompletionHandler = completion
            
            rewardAd.present(from: topViewController, userDidEarnRewardHandler: { [weak self] in
                // User earned reward
                print("✅ User earned reward")
                self?.rewardAdCompletionHandler?(true)
                self?.rewardAdCompletionHandler = nil
            })
        }
    }
    
    // MARK: - Native Ads
    
    func createNativeAdLoader(rootViewController: UIViewController, delegate: NativeAdLoaderDelegate) -> AdLoader {
        let adUnitID = AdUnitIDs.native
        #if DEBUG
        let finalAdUnitID = AdUnitIDs.nativeTest
        #else
        let finalAdUnitID = adUnitID
        #endif
        
        let adLoader = AdLoader(
            adUnitID: finalAdUnitID,
            rootViewController: rootViewController,
            adTypes: [.native],
            options: [createNativeAdOptions()]
        )
        
        adLoader.delegate = delegate
        return adLoader
    }
    
    private func createNativeAdOptions() -> NativeAdMediaAdLoaderOptions {
        let options = NativeAdMediaAdLoaderOptions()
        options.mediaAspectRatio = .landscape
        return options
    }
    
    // MARK: - Utility Methods
    
    @MainActor 
    func shouldShowAds() -> Bool {
        // Don't show ads for premium users or users with active ad-free rewards
        return !UserManager.shared.isPremium && !TemporaryRewardManager.shared.isAdFreeActive
    }
    
    func preloadAds() {
        if !isInterstitialReady && !isLoadingInterstitial {
            loadInterstitialAd()
        }
        
        if !isRewardAdReady && !isLoadingRewardAd {
            loadRewardAd()
        }
    }
}

// MARK: - FullScreenContentDelegate

extension AdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("✅ Ad dismissed full screen content")
        
        if ad is InterstitialAd {
            interstitialAd = nil
            isInterstitialReady = false
            interstitialCompletionHandler?()
            interstitialCompletionHandler = nil
            // Preload next interstitial
            loadInterstitialAd()
        } else if ad is RewardedAd {
            rewardAd = nil
            isRewardAdReady = false
            // If completion handler wasn't called yet, user didn't earn reward
            if rewardAdCompletionHandler != nil {
                rewardAdCompletionHandler?(false)
                rewardAdCompletionHandler = nil
            }
            // Preload next reward ad
            loadRewardAd()
        }
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("❌ Ad failed to present: \(error.localizedDescription)")
        
        if ad is InterstitialAd {
            interstitialAd = nil
            isInterstitialReady = false
            interstitialCompletionHandler?()
            interstitialCompletionHandler = nil
            loadInterstitialAd()
        } else if ad is RewardedAd {
            rewardAd = nil
            isRewardAdReady = false
            rewardAdCompletionHandler?(false)
            rewardAdCompletionHandler = nil
            loadRewardAd()
        }
    }
}
