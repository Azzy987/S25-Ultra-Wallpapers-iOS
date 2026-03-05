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
    @EnvironmentObject private var favoritesManager: FavoritesManager

    private let horizontalPadding: CGFloat = 6
    private let interItemSpacing: CGFloat = 8

    private let adInterval: Int = 16

    private var groups: [GridGroup] {
        buildGroups(showAds: adManager.shouldShowAds())
    }

    var body: some View {
        VStack(spacing: 0) {
            LazyVStack(spacing: 16) {
                ForEach(groups) { group in
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
                                    if item.originalIndex >= self.wallpapers.count - 5 && !isLoading && !hasReachedEnd {
                                        onLoadMore()
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
            
            // Bottom trigger — fires when the user scrolls to the end as a
            // reliable fallback in case onAppear items missed the load-more call.
            if !isLoading && !hasReachedEnd && !wallpapers.isEmpty {
                Color.clear
                    .frame(height: 1)
                    .onAppear {
                        onLoadMore()
                    }
            }

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

    private func buildGroups(showAds: Bool) -> [GridGroup] {
        guard showAds else {
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
            let shouldInsertAd = (index + 1) % adInterval == 0 && index > 0
            if currentRow.count == 2 || shouldInsertAd || index == wallpapers.count - 1 {
                groups.append(.wallpaperRow(currentRow))
                currentRow = []
                if shouldInsertAd {
                    groups.append(.nativeAd(adPosition: adPosition))
                    adPosition += 1
                }
            }
        }
        return groups
    }

    // MARK: - Helper Types and Properties
    
    private struct WallpaperItem {
        let wallpaper: Wallpaper
        let originalIndex: Int
    }
    
    private enum GridGroup: Identifiable {
        case wallpaperRow([WallpaperItem])
        case nativeAd(adPosition: Int)

        // Use the first item's index for O(1) id — stable across renders
        var id: String {
            switch self {
            case .wallpaperRow(let items):
                return "row_\(items.first?.originalIndex ?? 0)"
            case .nativeAd(let position):
                return "native_ad_\(position)"
            }
        }
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
    .environmentObject(FavoritesManager.shared)
    .environment(\.appTheme, AppColors.light)
}