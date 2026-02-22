//
//  FreeRewardsSheet.swift
//  S25UltraWallpapers
//
//  Created by AI Assistant on 15/09/25.
//

import SwiftUI

struct FreeRewardsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @StateObject private var rewardManager = TemporaryRewardManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "gift.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(theme.primary)
                        
                        Text("Free Rewards")
                            .font(.title2.bold())
                            .foregroundColor(theme.onSurface)
                        
                        Text("Watch short ads to unlock premium features temporarily")
                            .font(.subheadline)
                            .foregroundColor(theme.onSurface.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Current Active Rewards
                    if rewardManager.hasActiveRewards {
                        activeRewardsSection
                    }
                    
                    // Available Rewards
                    availableRewardsSection
                    
                    // Info Section
                    infoSection
                }
                .padding()
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
    
    @ViewBuilder
    private var activeRewardsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Active Rewards")
                .font(.headline.bold())
                .foregroundColor(theme.onSurface)
            
            VStack(spacing: 12) {
                if rewardManager.hasPremiumDownloads {
                    ActiveRewardCard(
                        icon: "arrow.down.circle.fill",
                        title: "Premium Downloads",
                        description: "\(rewardManager.premiumDownloadsRemaining) downloads remaining",
                        color: .blue
                    )
                }
                
                if rewardManager.isAdFreeActive, let timeText = rewardManager.adFreeTimeRemainingText {
                    ActiveRewardCard(
                        icon: "eye.slash.circle.fill",
                        title: "Ad-Free Mode",
                        description: timeText,
                        color: .green
                    )
                }
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var availableRewardsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Available Rewards")
                .font(.headline.bold())
                .foregroundColor(theme.onSurface)
            
            VStack(spacing: 16) {
                RewardAdButton(
                    title: "Get 5 Premium Downloads",
                    rewardDescription: "Access exclusive premium wallpapers",
                    icon: "gift.circle"
                ) {
                    TemporaryRewardManager.shared.activatePremiumDownloads(count: 5)
                }
                
                RewardAdButton(
                    title: "Remove Ads for 1 Hour",
                    rewardDescription: "Browse without any advertisements",
                    icon: "eye.slash.circle"
                ) {
                    TemporaryRewardManager.shared.activateAdFreeMode(duration: 3600)
                }
                
                RewardAdButton(
                    title: "Get 10 Premium Downloads",
                    rewardDescription: "Double reward! More premium wallpapers",
                    icon: "star.circle"
                ) {
                    TemporaryRewardManager.shared.activatePremiumDownloads(count: 10)
                }
                
                RewardAdButton(
                    title: "Remove Ads for 3 Hours",
                    rewardDescription: "Extended ad-free experience",
                    icon: "clock.circle"
                ) {
                    TemporaryRewardManager.shared.activateAdFreeMode(duration: 10800) // 3 hours
                }
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How it Works")
                .font(.headline.bold())
                .foregroundColor(theme.onSurface)
            
            VStack(spacing: 12) {
                InfoRow(
                    icon: "play.circle",
                    title: "Watch Short Ads",
                    description: "Watch 15-30 second video advertisements"
                )
                
                InfoRow(
                    icon: "gift",
                    title: "Earn Rewards",
                    description: "Unlock premium features temporarily"
                )
                
                InfoRow(
                    icon: "clock",
                    title: "Time Limited",
                    description: "Rewards expire after the specified duration"
                )
                
                InfoRow(
                    icon: "star",
                    title: "Premium Access",
                    description: "Get full premium with a subscription for unlimited access"
                )
            }
        }
        .padding()
        .background(theme.surfaceVariant)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct ActiveRewardCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(theme.onSurface)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(theme.onSurface.opacity(0.7))
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.green)
        }
        .padding()
        .background(theme.surfaceVariant)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(theme.primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(theme.onSurface)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(theme.onSurface.opacity(0.7))
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    FreeRewardsSheet()
    .environment(\.appTheme, AppColors.light)
}