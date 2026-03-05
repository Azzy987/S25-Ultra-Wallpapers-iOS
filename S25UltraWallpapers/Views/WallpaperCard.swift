import SwiftUI

struct WallpaperCard: View {
    let wallpaper: Wallpaper
    let wallpapers: [Wallpaper]?
    let currentIndex: Int?
    @EnvironmentObject private var favoritesManager: FavoritesManager
    @Environment(\.appTheme) private var theme
    @State private var showDetail = false
    // Guards against the card tap firing when the favorite button was tapped.
    // Set to true on favorite tap; the card's action checks and resets it.
    @State private var favoriteJustTapped = false

    init(wallpaper: Wallpaper, wallpapers: [Wallpaper]? = nil, currentIndex: Int? = nil) {
        self.wallpaper = wallpaper
        self.wallpapers = wallpapers
        self.currentIndex = currentIndex
    }

    private var itemWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let horizontalSpacing: CGFloat = 12
        let interItemSpacing: CGFloat = 8
        return (screenWidth - (horizontalSpacing * 2) - interItemSpacing) / 2
    }

    private var imageWidth: CGFloat { itemWidth - 16 }
    private var imageHeight: CGFloat { 240 }

    var body: some View {
        // Per SwiftUI guidelines for interactive items inside LazyVStack:
        // Use a single outer Button for the card tap, and .simultaneousGesture
        // for the inner favorite action. simultaneousGesture fires alongside the
        // outer button gesture, and we use a flag to suppress the card action.
        Button {
            if favoriteJustTapped {
                print("🚫 [WallpaperCard] Card tap BLOCKED — favorite was tapped | wallpaper: \(wallpaper.wallpaperName) | id: \(wallpaper.id)")
                favoriteJustTapped = false
                return
            }
            print("✅ [WallpaperCard] Card tapped — opening detail | wallpaper: \(wallpaper.wallpaperName) | id: \(wallpaper.id)")
            showDetail = true
        } label: {
            cardContent
        }
        .buttonStyle(CardButtonStyle())
        // Explicitly constrain the hit area to the card's visible rounded rect.
        // Without this, the Button's hit region can bleed into adjacent cards in
        // the HStack, causing the neighboring card to open when you tap this card's
        // favorite area. contentShape clips hit-testing to exactly the visible bounds.
        .contentShape(RoundedRectangle(cornerRadius: 24))
        .frame(width: itemWidth)
        .onChange(of: showDetail) { val in
            if val {
                print("🔔 [WallpaperCard] showDetail became TRUE | wallpaper: \(wallpaper.wallpaperName) | id: \(wallpaper.id) | favoriteJustTapped was: \(favoriteJustTapped)")
            }
        }
        .fullScreenCover(isPresented: $showDetail) {
            let _ = print("🖼️ [WallpaperCard] Detail screen presented | wallpaper: \(wallpaper.wallpaperName) | id: \(wallpaper.id) | index: \(currentIndex ?? -1)")
            WallpaperDetailScreen(
                wallpaper: wallpaper,
                isPresented: $showDetail,
                wallpapers: wallpapers,
                currentIndex: currentIndex
            )
        }
    }

    // Card visual content — the favorite button uses simultaneousGesture so it
    // fires at the same time as the outer Button, letting the flag suppress it.
    private var cardContent: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                // Image
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

                // Title
                Text(wallpaper.wallpaperName)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.onSurface)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 12)
                    .padding(.trailing, 44)
                    .padding(.vertical, 8)
            }
            .background(theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: theme.onSurface.opacity(0.15), radius: 8, x: 0, y: 4)
            .shadow(color: theme.onSurface.opacity(0.08), radius: 2, x: 0, y: 1)

            // Favorite hit area
            Color.clear
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .simultaneousGesture(
                    TapGesture().onEnded {
                        print("❤️ [WallpaperCard] Favorite tapped | wallpaper: \(wallpaper.wallpaperName) | id: \(wallpaper.id) | isFavorite before: \(isFavorite)")
                        favoriteJustTapped = true
                        toggleFavorite()
                    }
                )
                .overlay(
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 18))
                        .foregroundColor(isFavorite ? .red : theme.onSurfaceVariant)
                        .allowsHitTesting(false)
                )
        }
    }

    private var isFavorite: Bool {
        favoritesManager.isFavorite(wallpaper.id)
    }

    private func toggleFavorite() {
        let isAdded = favoritesManager.toggleFavorite(wallpaper: wallpaper)
        ToastManager.shared.showFavoriteToast(wallpaperName: wallpaper.wallpaperName, isAdded: isAdded)
    }
}

// Removes the default Button tap highlight while keeping the gesture.
private struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}
