//
//  PaginatedWallpaperGridWithAds.swift
//  S25UltraWallpapers
//
//  Created by AI Assistant on 15/09/25.
//

import SwiftUI
import FirebaseFirestore

struct PaginatedWallpaperGridWithAds: View {
    let wallpapers: [Wallpaper]
    let isLoading: Bool
    let hasReachedEnd: Bool
    let onLoadMore: () -> Void
    
    @Environment(\.appTheme) private var theme
    @StateObject private var adManager = AdManager.shared
    
    private let horizontalPadding: CGFloat = 6 // 6px on each side = 12px total (reduced)
    private let interItemSpacing: CGFloat = 8 // Space between cards (reduced)
    private let cellHeight: CGFloat = 280
    
    // Calculate width based on screen width with fixed spacing
    private var itemWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let totalHorizontalSpacing = horizontalPadding * 2
        return (screenWidth - totalHorizontalSpacing - interItemSpacing) / 2
    }
    
    // Native ad placement configuration
    private let adInterval: Int = 16 // Show an ad every 16 wallpapers
    
    var body: some View {
        VStack(spacing: 0) {
            LazyVStack(spacing: 16) {
                ForEach(Array(groupedContent.enumerated()), id: \.element.id) { _, group in
                    switch group {
                    case .wallpaperRow(let wallpapers):
                        HStack(spacing: interItemSpacing) {
                            ForEach(wallpapers, id: \.wallpaper.id) { item in
                                WallpaperCard(
                                    wallpaper: item.wallpaper,
                                    wallpapers: self.wallpapers,
                                    currentIndex: item.originalIndex
                                )
                                .onAppear {
                                    // Only trigger load more when we're close to the end (5 items before)
                                    if item.originalIndex >= self.wallpapers.count - 5 && !isLoading && !hasReachedEnd {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            onLoadMore()
                                        }
                                    }
                                }
                            }
                            
                            // Fill remaining space if odd number
                            if wallpapers.count == 1 {
                                Spacer()
                            }
                        }
                    case .nativeAd(let adPosition):
                        // Full-width native ad
                        CachedNativeAdView(position: adPosition, height: 320)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 4)
                    }
                }
            }
            .padding(.horizontal, horizontalPadding)
            
            // Loading indicator at bottom
            if isLoading && !wallpapers.isEmpty {
                VStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                    
                    Text("Loading more wallpapers...")
                        .font(.caption)
                        .foregroundColor(theme.onSurfaceVariant)
                }
                .padding(.vertical, 16)
            }
            
            // End reached indicator
            if hasReachedEnd && !wallpapers.isEmpty {
                RoundedRectangle(cornerRadius: 12)
                    .fill(theme.surfaceVariant)
                    .frame(height: 40)
                    .overlay(
                        Text("You've reached the end")
                            .font(.caption)
                            .foregroundColor(theme.onSurfaceVariant)
                    )
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, 16)
            }
            
            // Initial loading state
            if isLoading && wallpapers.isEmpty {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                        .scaleEffect(1.2)
                    
                    Text("Loading wallpapers...")
                        .font(.subheadline)
                        .foregroundColor(theme.onSurfaceVariant)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
    }
    
    // MARK: - Helper Types and Properties
    
    private struct WallpaperItem {
        let wallpaper: Wallpaper
        let originalIndex: Int
    }
    
    private enum GridGroup: Identifiable {
        case wallpaperRow([WallpaperItem])
        case nativeAd(adPosition: Int)
        
        var id: String {
            switch self {
            case .wallpaperRow(let items):
                return "row_\(items.map { $0.wallpaper.id }.joined(separator: "_"))"
            case .nativeAd(let position):
                return "native_ad_\(position)"
            }
        }
    }
    
    private var groupedContent: [GridGroup] {
        guard adManager.shouldShowAds() else {
            // For premium users, group wallpapers into rows of 2
            var groups: [GridGroup] = []
            var currentRow: [WallpaperItem] = []
            
            for (index, wallpaper) in wallpapers.enumerated() {
                currentRow.append(WallpaperItem(wallpaper: wallpaper, originalIndex: index))
                
                if currentRow.count == 2 || index == wallpapers.count - 1 {
                    groups.append(.wallpaperRow(currentRow))
                    currentRow = []
                }
            }
            
            return groups
        }
        
        var groups: [GridGroup] = []
        var currentRow: [WallpaperItem] = []
        var adPosition = 0
        
        for (index, wallpaper) in wallpapers.enumerated() {
            currentRow.append(WallpaperItem(wallpaper: wallpaper, originalIndex: index))
            
            // Check if we should insert an ad after this wallpaper
            let shouldInsertAd = (index + 1) % adInterval == 0 && index > 0
            
            // Complete row when we have 2 items or need to insert ad
            if currentRow.count == 2 || shouldInsertAd || index == wallpapers.count - 1 {
                groups.append(.wallpaperRow(currentRow))
                currentRow = []
                
                // Insert ad if needed
                if shouldInsertAd {
                    groups.append(.nativeAd(adPosition: adPosition))
                    adPosition += 1
                }
            }
        }
        
        return groups
    }
}

// MARK: - Convenience View Extension


// MARK: - Preview

#Preview {
    let sampleWallpapers = (0..<20).map { index in
        Wallpaper(
            id: "sample_\(index)",
            data: [
                "wallpaperName": "Sample Wallpaper \(index + 1)",
                "imageUrl": "https://via.placeholder.com/400x800",
                "thumbnail": "https://via.placeholder.com/200x400",
                "source": "Sample",
                "series": "Test Series",
                "launchYear": 2024,
                "dimensions": "1440x3200",
                "size": "2.5MB",
                "downloads": Int.random(in: 100...5000),
                "views": Int.random(in: 500...10000),
                "category": "Abstract",
                "timestamp": Timestamp(date: Date())
            ]
        )
    }
    
    PaginatedWallpaperGridWithAds(
        wallpapers: sampleWallpapers,
        isLoading: false,
        hasReachedEnd: false,
        onLoadMore: {}
    )
    .environment(\.appTheme, AppColors.light)
}