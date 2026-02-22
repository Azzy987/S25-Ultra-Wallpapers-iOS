import SwiftUI

struct WallpaperCard: View {
    let wallpaper: Wallpaper
    let wallpapers: [Wallpaper]?
    let currentIndex: Int?
    @StateObject private var favoritesManager = FavoritesManager.shared
    @StateObject private var toastManager = ToastManager.shared
    @Environment(\.appTheme) private var theme
    @State private var selectedWallpaper: Wallpaper?
    @State private var showDetail = false
    
    // Initializer to make wallpapers list optional
    init(wallpaper: Wallpaper, wallpapers: [Wallpaper]? = nil, currentIndex: Int? = nil) {
        self.wallpaper = wallpaper
        self.wallpapers = wallpapers
        self.currentIndex = currentIndex
    }
    
    // Calculate item width based on screen width with minimal spacing for wider cards
    private var itemWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let horizontalSpacing: CGFloat = 12 // 6px on each side (further reduced)
        let interItemSpacing: CGFloat = 8 // Space between cards (further reduced)
        return (screenWidth - (horizontalSpacing * 2) - interItemSpacing) / 2
    }
    
    // Fixed image dimensions for consistency with increased size
    private var imageWidth: CGFloat {
        return itemWidth - 16 // 8px padding on each side (reduced for wider image)
    }
    
    private var imageHeight: CGFloat {
        return 240 // Increased height for better aspect ratio
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
                        .frame(width: imageWidth, height: imageHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: imageWidth, height: imageHeight)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                case .failure:
                    Rectangle()
                        .fill(theme.surfaceVariant)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.title)
                                .foregroundColor(theme.onSurfaceVariant)
                        )
                        .frame(width: imageWidth, height: imageHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: imageWidth, height: imageHeight)
            .padding(.top, 10)
            .onTapGesture {
                selectedWallpaper = wallpaper
                showDetail = true
            }
            
            // Title and Favorite Section - aligned with wallpaper edges
            HStack(spacing: 8) {
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

                // Favorite icon beside wallpaper name - larger tap target
                Button {
                    toggleFavorite()
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundColor(isFavorite ? .red : theme.onSurfaceVariant)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.leading, 12)
            .padding(.trailing, 8)
            .padding(.vertical, 10)
        }
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: theme.onSurface.opacity(0.15), radius: 8, x: 0, y: 4)
        .shadow(color: theme.onSurface.opacity(0.08), radius: 2, x: 0, y: 1)
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
        let isAdded = favoritesManager.toggleFavorite(wallpaper: wallpaper)
        toastManager.showFavoriteToast(wallpaperName: wallpaper.wallpaperName, isAdded: isAdded)
    }
} 

