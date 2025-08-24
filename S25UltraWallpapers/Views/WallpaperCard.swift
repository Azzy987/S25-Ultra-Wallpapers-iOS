import SwiftUI

struct WallpaperCard: View {
    let wallpaper: Wallpaper
    let wallpapers: [Wallpaper]?
    let currentIndex: Int?
    @StateObject private var favoritesManager = FavoritesManager.shared
    @Environment(\.appTheme) private var theme
    @State private var selectedWallpaper: Wallpaper?
    @State private var showDetail = false
    @Namespace private var animation
    
    // Initializer to make wallpapers list optional
    init(wallpaper: Wallpaper, wallpapers: [Wallpaper]? = nil, currentIndex: Int? = nil) {
        self.wallpaper = wallpaper
        self.wallpapers = wallpapers
        self.currentIndex = currentIndex
    }
    
    // Calculate item width based on screen width
    private var itemWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        return (screenWidth / 2) - 16
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Image Section - Optimized for performance (with smart tap detection)
            ZStack {
                CachedAsyncImage(url: URL(string: wallpaper.thumbnail.isEmpty ? wallpaper.imageUrl : wallpaper.thumbnail)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(theme.surfaceVariant)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                                    .scaleEffect(0.8)
                            )
                            .frame(width: itemWidth, height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: itemWidth, height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    case .failure:
                        Rectangle()
                            .fill(theme.surfaceVariant)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.title)
                                    .foregroundColor(theme.onSurfaceVariant)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: itemWidth, height: 220) // Dynamic width
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .clipped()
            }
            .onTapGesture {
                print("🎯 Wallpaper tapped: \(wallpaper.wallpaperName)")
                selectedWallpaper = wallpaper
                showDetail = true
            }
            
            // Title and Favorite Section - Bottom layout
            HStack(spacing: 8) {
                ZStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(wallpaper.wallpaperName)
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(theme.onSurface)
                            .lineLimit(1) // Max 1 line as requested
                            .truncationMode(.tail) // Text overflow handling
                        
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .onTapGesture {
                    print("🎯 Wallpaper title tapped: \(wallpaper.wallpaperName)")
                    selectedWallpaper = wallpaper
                    showDetail = true
                }
                
                // Favorite Button - Bottom right position with improved tap area
                Button {
                    toggleFavorite()
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundColor(isFavorite ? .red : theme.onSurfaceVariant)
                        .padding(.horizontal, 12) // Increased horizontal padding for easier tapping
                        .padding(.vertical, 8)    // Increased vertical padding for easier tapping
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
        }
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .frame(width: itemWidth) // Dynamic width for the entire card
        .fullScreenCover(isPresented: $showDetail) {
            if let selectedWallpaper = selectedWallpaper {
                WallpaperDetailScreen(
                    wallpaper: selectedWallpaper,
                    animation: animation,
                    isPresented: $showDetail,
                    wallpapers: wallpapers,
                    currentIndex: currentIndex
                )
            } else {
                // Fallback to prevent blank screen
                WallpaperDetailScreen(
                    wallpaper: wallpaper,
                    animation: animation,
                    isPresented: $showDetail,
                    wallpapers: wallpapers,
                    currentIndex: currentIndex
                )
            }
        }
    }
    
    private var isFavorite: Bool {
        favoritesManager.isFavorite(wallpaper.id)
    }
    
    private func toggleFavorite() {
        _ = favoritesManager.toggleFavorite(wallpaper: wallpaper)
    }
} 

