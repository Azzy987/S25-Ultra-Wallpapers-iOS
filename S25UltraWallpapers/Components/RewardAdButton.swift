//
//  RewardAdButton.swift
//  S25UltraWallpapers
//
//  Created by AI Assistant on 15/09/25.
//

import SwiftUI

struct RewardAdButton: View {
    let title: String
    let rewardDescription: String
    let icon: String
    let action: () -> Void
    
    @StateObject private var adManager = AdManager.shared
    @Environment(\.appTheme) private var theme
    @State private var isWatchingAd = false
    
    var body: some View {
        Button(action: {
            watchRewardAd()
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(theme.primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundColor(theme.onSurface)
                    
                    Text(rewardDescription)
                        .font(.caption)
                        .foregroundColor(theme.onSurface.opacity(0.7))
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isWatchingAd {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if adManager.isRewardAdReady {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(theme.primary)
                } else {
                    Image(systemName: "clock.circle")
                        .font(.title2)
                        .foregroundColor(theme.onSurface.opacity(0.5))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(theme.surfaceVariant)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(theme.onSurfaceVariant.opacity(0.3), lineWidth: 1)
            )
        }
        .disabled(!adManager.isRewardAdReady || isWatchingAd)
        .opacity((!adManager.isRewardAdReady || isWatchingAd) ? 0.6 : 1.0)
    }
    
    private func watchRewardAd() {
        guard adManager.isRewardAdReady else { return }
        
        isWatchingAd = true
        
        adManager.showRewardAd { success in
            DispatchQueue.main.async {
                isWatchingAd = false
                if success {
                    action()
                }
            }
        }
    }
}

// MARK: - Reward Ad Offer View

struct RewardAdOfferView: View {
    let title: String
    let subtitle: String
    let rewardItems: [RewardItem]
    let onRewardEarned: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @StateObject private var adManager = AdManager.shared
    
    struct RewardItem {
        let icon: String
        let title: String
        let description: String
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "gift.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(theme.primary)
                    
                    Text(title)
                        .font(.title2.bold())
                        .foregroundColor(theme.onSurface)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(theme.onSurface.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                
                // Rewards List
                VStack(spacing: 16) {
                    ForEach(Array(rewardItems.enumerated()), id: \.offset) { index, item in
                        HStack(spacing: 16) {
                            Image(systemName: item.icon)
                                .font(.title2)
                                .foregroundColor(theme.primary)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.subheadline.bold())
                                    .foregroundColor(theme.onSurface)
                                
                                Text(item.description)
                                    .font(.caption)
                                    .foregroundColor(theme.onSurface.opacity(0.7))
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(theme.surfaceVariant)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Watch Ad Button
                VStack(spacing: 16) {
                    Button(action: {
                        watchRewardAd()
                    }) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                            
                            Text("Watch Ad & Get Rewards")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(theme.primary)
                        .cornerRadius(12)
                    }
                    .disabled(!adManager.isRewardAdReady)
                    .opacity(adManager.isRewardAdReady ? 1.0 : 0.6)
                    
                    Button("Maybe Later") {
                        dismiss()
                    }
                    .foregroundColor(theme.onSurface.opacity(0.7))
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .background(theme.surface)
            .navigationTitle("Free Rewards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func watchRewardAd() {
        adManager.showRewardAd { success in
            DispatchQueue.main.async {
                if success {
                    onRewardEarned()
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        RewardAdButton(
            title: "Get 5 Premium Downloads",
            rewardDescription: "Watch a short ad to unlock premium wallpapers",
            icon: "gift.circle"
        ) {
            print("Reward earned!")
        }
        
        RewardAdButton(
            title: "Remove Ads for 1 Hour", 
            rewardDescription: "Enjoy ad-free browsing temporarily",
            icon: "eye.slash.circle"
        ) {
            print("Ad-free mode activated!")
        }
    }
    .padding()
    .environment(\.appTheme, AppColors.light)
}