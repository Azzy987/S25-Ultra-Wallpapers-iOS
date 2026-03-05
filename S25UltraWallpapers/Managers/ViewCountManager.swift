//
//  ViewCountManager.swift
//  S25UltraWallpapers
//
//  Created by AI Assistant on 15/09/25.
//

import Foundation
import SwiftUI

class ViewCountManager: ObservableObject {
    static let shared = ViewCountManager()
    
    @Published var totalWallpaperViews: Int = 0
    @Published var currentSessionViews: Int = 0
    @Published var swipeCount: Int = 0
    
    private let userDefaults = UserDefaults.standard
    private let totalViewsKey = "total_wallpaper_views"
    private let adShowIntervalKey = "interstitial_ad_interval"
    
    // Configuration
    private let viewsBeforeAd = 5 // Show ad every 5th view
    private let swipesBeforeAd = 5 // Show ad every 5th swipe in detail screen
    
    private init() {
        loadStoredData()
    }
    
    // MARK: - View Tracking
    
    func recordWallpaperView() {
        totalWallpaperViews += 1
        currentSessionViews += 1
        saveData()
        
        print("📊 Wallpaper view recorded. Total: \(totalWallpaperViews), Session: \(currentSessionViews)")
    }
    
    func recordSwipeInDetailScreen() {
        swipeCount += 1
        print("📊 Swipe recorded in detail screen. Count: \(swipeCount)")
    }
    
    // MARK: - Ad Trigger Logic
    
    func shouldShowInterstitialForView() -> Bool {
        let shouldShow = currentSessionViews > 0 && currentSessionViews % viewsBeforeAd == 0
        print("📊 Should show interstitial for view? \(shouldShow) (Session views: \(currentSessionViews))")
        return shouldShow
    }
    
    func shouldShowInterstitialForSwipe() -> Bool {
        let shouldShow = swipeCount > 0 && swipeCount % swipesBeforeAd == 0
        print("📊 Should show interstitial for swipe? \(shouldShow) (Swipe count: \(swipeCount))")
        return shouldShow
    }
    
    func resetSessionViews() {
        currentSessionViews = 0
        saveData()
        print("📊 Session views reset")
    }
    
    func resetSwipeCount() {
        swipeCount = 0
        print("📊 Swipe count reset")
    }
    
    // MARK: - Data Persistence
    
    private func loadStoredData() {
        totalWallpaperViews = userDefaults.integer(forKey: totalViewsKey)
        print("📊 Loaded total views: \(totalWallpaperViews)")
    }
    
    private func saveData() {
        userDefaults.set(totalWallpaperViews, forKey: totalViewsKey)
    }
    
    func resetAllCounts() {
        totalWallpaperViews = 0
        currentSessionViews = 0
        swipeCount = 0
        userDefaults.removeObject(forKey: totalViewsKey)
        print("📊 All view counts reset")
    }
}