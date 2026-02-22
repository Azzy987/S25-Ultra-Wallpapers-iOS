//
//  FilterUnlockSheet.swift
//  S25UltraWallpapers
//
//  Created by AI Assistant on 15/09/25.
//

import SwiftUI
import GoogleMobileAds

struct FilterUnlockSheet: View {
    let wallpaperId: String
    let lockedFilters: [WallpaperFilter]
    @Binding var isPresented: Bool
    
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var adManager: AdManager
    @EnvironmentObject private var filterLockManager: FilterLockManager
    @EnvironmentObject private var userManager: UserManager
    
    @State private var showRewardAd = false
    @State private var isLoadingRewardAd = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .info
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "camera.filters")
                        .font(.system(size: 50))
                        .foregroundColor(theme.primary)
                    
                    Text("Unlock Premium Filters")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(theme.onSurface)
                    
                    Text("Enhance your wallpapers with professional-grade filters")
                        .font(.body)
                        .foregroundColor(theme.onSurface.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Locked Filters Preview
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(lockedFilters.prefix(8), id: \.self) { filter in
                            VStack(spacing: 8) {
                                Image(systemName: filterLockManager.getFilterIcon(filter))
                                    .font(.title2)
                                    .foregroundColor(theme.onSurface.opacity(0.6))
                                    .frame(width: 60, height: 60)
                                    .background(theme.surface)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(theme.primary.opacity(0.3), lineWidth: 1)
                                    )
                                    .overlay(
                                        Image(systemName: "lock.fill")
                                            .font(.caption)
                                            .foregroundColor(theme.primary)
                                            .background(Circle().fill(theme.background).frame(width: 20, height: 20))
                                            .offset(x: 20, y: -20)
                                    )
                                
                                Text(filter.displayName)
                                    .font(.caption)
                                    .foregroundColor(theme.onSurface.opacity(0.7))
                                    .lineLimit(1)
                            }
                        }
                        
                        if lockedFilters.count > 8 {
                            VStack(spacing: 8) {
                                Text("+\(lockedFilters.count - 8)")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(theme.primary)
                                    .frame(width: 60, height: 60)
                                    .background(theme.surface)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(theme.primary.opacity(0.3), lineWidth: 1)
                                    )
                                
                                Text("More")
                                    .font(.caption)
                                    .foregroundColor(theme.onSurface.opacity(0.7))
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 16) {
                    // Premium Button
                    Button {
                        // Handle premium upgrade
                        // This would typically open subscription flow
                        showToast(message: "Premium subscription coming soon!", type: .info)
                    } label: {
                        HStack {
                            Image(systemName: "crown.fill")
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Upgrade to Premium")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Text("Unlock all filters forever")
                                    .font(.caption)
                                    .opacity(0.8)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "arrow.right")
                                .font(.title3)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [theme.primary, theme.primary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    // Reward Ad Button
                    Button {
                        loadAndShowRewardAd()
                    } label: {
                        HStack {
                            if isLoadingRewardAd {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "play.rectangle.fill")
                                    .font(.title3)
                                    .foregroundColor(theme.primary)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Watch Ad to Unlock")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(theme.onSurface)
                                
                                Text("Unlock filters for this wallpaper only")
                                    .font(.caption)
                                    .foregroundColor(theme.onSurface.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            if !isLoadingRewardAd {
                                Image(systemName: "arrow.right")
                                    .font(.title3)
                                    .foregroundColor(theme.primary)
                            }
                        }
                        .padding()
                        .background(theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(theme.primary.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .disabled(isLoadingRewardAd)
                }
                .padding(.bottom)
            }
            .padding(.horizontal)
            .background(theme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(theme.onSurface)
                }
            }
        }
        .overlay(alignment: .bottom) {
            if showToast {
                ToastView(
                    message: toastMessage,
                    type: toastType,
                    isPresented: $showToast
                )
            }
        }
        .onChange(of: showRewardAd) { _ in
            if showRewardAd {
                showActualRewardAd()
            }
        }
    }
    
    // MARK: - Actions
    
    private func loadAndShowRewardAd() {
        isLoadingRewardAd = true
        
        // Load reward ad if not ready
        if !adManager.isRewardAdReady {
            adManager.loadRewardAd()
        }
        
        // Check if ad is ready after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isLoadingRewardAd = false
            
            if adManager.isRewardAdReady {
                showActualRewardAd()
            } else {
                showToast(message: "Ad not ready yet. Please try again.", type: .error)
            }
        }
    }
    
    private func showActualRewardAd() {
        adManager.showRewardAd { didEarnReward in
            DispatchQueue.main.async {
                if didEarnReward {
                    handleRewardEarned()
                } else {
                    showToast(message: "Ad was not completed. Please try again.", type: .error)
                }
            }
        }
    }
    
    private func handleRewardEarned() {
        filterLockManager.unlockAllFiltersForWallpaper(wallpaperId)
        showToast(message: "🎉 All filters unlocked for this wallpaper!", type: .info)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isPresented = false
        }
    }
    
    private func showToast(message: String, type: ToastView.ToastType) {
        toastMessage = message
        toastType = type
        showToast = true
    }
}

// MARK: - Preview
#Preview {
    FilterUnlockSheet(
        wallpaperId: "sample_wallpaper_id",
        lockedFilters: [.aden, .brooklyn, .earlybird, .gingham, .hudson],
        isPresented: .constant(true)
    )
    .environmentObject(AdManager())
    .environmentObject(FilterLockManager.shared)
    .environmentObject(UserManager.shared)
    .environmentObject(ThemeManager.shared)
}