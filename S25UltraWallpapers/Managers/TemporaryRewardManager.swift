//
//  TemporaryRewardManager.swift
//  S25UltraWallpapers
//
//  Created by AI Assistant on 15/09/25.
//

import Foundation
import SwiftUI

class TemporaryRewardManager: ObservableObject {
    static let shared = TemporaryRewardManager()
    
    @Published var premiumDownloadsRemaining: Int = 0
    @Published var isAdFreeActive: Bool = false
    @Published var adFreeExpiryDate: Date?
    
    private let premiumDownloadsKey = "temporary_premium_downloads"
    private let adFreeExpiryKey = "temporary_adfree_expiry"
    
    private init() {
        loadSavedRewards()
        startTimerForAdFreeMode()
    }
    
    // MARK: - Premium Downloads
    
    func activatePremiumDownloads(count: Int) {
        premiumDownloadsRemaining += count
        UserDefaults.standard.set(premiumDownloadsRemaining, forKey: premiumDownloadsKey)
        
        // Show success message
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowRewardSuccess"),
            object: nil,
            userInfo: ["message": "✨ You've earned \(count) premium downloads!"]
        )
        
        print("✅ Activated \(count) premium downloads. Total remaining: \(premiumDownloadsRemaining)")
    }
    
    func consumePremiumDownload() -> Bool {
        guard premiumDownloadsRemaining > 0 else { return false }
        
        premiumDownloadsRemaining -= 1
        UserDefaults.standard.set(premiumDownloadsRemaining, forKey: premiumDownloadsKey)
        
        print("✅ Consumed 1 premium download. Remaining: \(premiumDownloadsRemaining)")
        return true
    }
    
    var hasPremiumDownloads: Bool {
        return premiumDownloadsRemaining > 0
    }
    
    // MARK: - Ad-Free Mode
    
    func activateAdFreeMode(duration: TimeInterval) {
        let expiryDate = Date().addingTimeInterval(duration)
        adFreeExpiryDate = expiryDate
        isAdFreeActive = true
        
        UserDefaults.standard.set(expiryDate, forKey: adFreeExpiryKey)
        
        // Show success message
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        
        let durationText = hours > 0 ? "\(hours) hour\(hours > 1 ? "s" : "")" : "\(minutes) minutes"
        
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowRewardSuccess"),
            object: nil,
            userInfo: ["message": "🚫 Ad-free mode active for \(durationText)!"]
        )
        
        print("✅ Activated ad-free mode for \(durationText)")
    }
    
    var remainingAdFreeTime: TimeInterval? {
        guard let expiryDate = adFreeExpiryDate, isAdFreeActive else { return nil }
        let remaining = expiryDate.timeIntervalSinceNow
        return remaining > 0 ? remaining : nil
    }
    
    var adFreeTimeRemainingText: String? {
        guard let remaining = remainingAdFreeTime else { return nil }
        
        let hours = Int(remaining / 3600)
        let minutes = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m remaining"
        } else {
            return "\(minutes)m remaining"
        }
    }
    
    // MARK: - Combined Premium Check
    
    var hasActiveRewards: Bool {
        return hasPremiumDownloads || isAdFreeActive
    }
    
    @MainActor 
    func shouldShowAds() -> Bool {
        // Show ads if user is not premium and doesn't have active ad-free reward
        return !UserManager.shared.isPremium && !isAdFreeActive
    }
    
    // MARK: - Private Methods
    
    private func loadSavedRewards() {
        // Load premium downloads
        premiumDownloadsRemaining = UserDefaults.standard.integer(forKey: premiumDownloadsKey)
        
        // Load ad-free expiry
        if let savedExpiryDate = UserDefaults.standard.object(forKey: adFreeExpiryKey) as? Date {
            adFreeExpiryDate = savedExpiryDate
            isAdFreeActive = savedExpiryDate > Date()
            
            if !isAdFreeActive {
                // Expired, clear it
                UserDefaults.standard.removeObject(forKey: adFreeExpiryKey)
                adFreeExpiryDate = nil
            }
        }
    }
    
    private func startTimerForAdFreeMode() {
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            if let expiryDate = self.adFreeExpiryDate, Date() > expiryDate {
                // Ad-free mode expired
                self.isAdFreeActive = false
                self.adFreeExpiryDate = nil
                UserDefaults.standard.removeObject(forKey: self.adFreeExpiryKey)
                
                print("⏰ Ad-free mode expired")
            }
        }
    }
    
    // MARK: - Debug Methods
    
    func clearAllRewards() {
        premiumDownloadsRemaining = 0
        isAdFreeActive = false
        adFreeExpiryDate = nil
        
        UserDefaults.standard.removeObject(forKey: premiumDownloadsKey)
        UserDefaults.standard.removeObject(forKey: adFreeExpiryKey)
        
        print("🧹 Cleared all temporary rewards")
    }
}