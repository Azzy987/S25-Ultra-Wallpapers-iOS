import SwiftUI

struct WallpaperCard: View {
    let wallpaper: Wallpaper
    let wallpapers: [Wallpaper]?
    let currentIndex: Int?
    @StateObject private var favoritesManager = FavoritesManager.shared
    @Environment(\.appTheme) private var theme
    @State private var selectedWallpaper: Wallpaper?
    @State private var showDetail = false
    
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
        // Container with visible background and proper spacing
        VStack(spacing: 0) {
            // Image Section (without favorite icon overlay)
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
                        .frame(width: itemWidth - 16, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: itemWidth - 16, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                case .failure:
                    Rectangle()
                        .fill(theme.surfaceVariant)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.title)
                                .foregroundColor(theme.onSurfaceVariant)
                        )
                        .frame(width: itemWidth - 16, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: itemWidth - 16, height: 220)
            .padding(.top, 8)
            .onTapGesture {
                selectedWallpaper = wallpaper
                showDetail = true
            }
            
            // Title and Favorite Section - aligned with wallpaper edges
            HStack {
                Text(wallpaper.wallpaperName)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurface)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onTapGesture {
                        selectedWallpaper = wallpaper
                        showDetail = true
                    }
                
                // Favorite icon beside wallpaper name
                Button {
                    toggleFavorite()
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundColor(isFavorite ? .red : theme.onSurfaceVariant)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.leading, 10)  // Start from same position as wallpaper (10pt from container edge)
            .padding(.trailing, 12) // 12pt spacing from right (increased by 4)
            .padding(.vertical, 12)
        }
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .frame(width: itemWidth)
        .fullScreenCover(isPresented: $showDetail) {
            if let selectedWallpaper = selectedWallpaper {
                WallpaperDetailScreen(
                    wallpaper: selectedWallpaper,
                    isPresented: $showDetail,
                    wallpapers: wallpapers,
                    currentIndex: currentIndex
                )
            } else {
                // Fallback to prevent blank screen
                WallpaperDetailScreen(
                    wallpaper: wallpaper,
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

