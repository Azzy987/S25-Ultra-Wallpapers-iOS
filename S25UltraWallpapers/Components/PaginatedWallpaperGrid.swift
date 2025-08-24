import SwiftUI

struct PaginatedWallpaperGrid: View {
    let wallpapers: [Wallpaper]
    let isLoading: Bool
    let hasReachedEnd: Bool
    let onLoadMore: () -> Void
    @Environment(\.appTheme) private var theme
    
    private let horizontalPadding: CGFloat = 8
    private let interItemSpacing: CGFloat = 12
    private let cellHeight: CGFloat = 280 // Updated for new WallpaperCard design (220 image + 60 text area)
    
    // Calculate width based on screen width
    private var itemWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        return (screenWidth / 2) - 16
    }
    
    var body: some View {
        VStack(spacing: 0) {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(minimum: itemWidth), spacing: interItemSpacing),
                    GridItem(.flexible(minimum: itemWidth), spacing: interItemSpacing)
                ],
                spacing: 16
            ) {
                ForEach(Array(wallpapers.enumerated()), id: \.element.id) { index, wallpaper in
                    WallpaperCard(wallpaper: wallpaper, wallpapers: wallpapers, currentIndex: index)
                        .onAppear {
                            // Only trigger load more when we're close to the end (5 items before)
                            if index >= wallpapers.count - 5 && !isLoading && !hasReachedEnd {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    onLoadMore()
                                }
                            }
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
} 
