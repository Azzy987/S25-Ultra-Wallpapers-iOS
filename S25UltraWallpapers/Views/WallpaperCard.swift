import SwiftUI

struct WallpaperCard: View {
    let wallpaper: Wallpaper
    let wallpapers: [Wallpaper]?
    let currentIndex: Int?
    @EnvironmentObject private var favoritesManager: FavoritesManager
    @Environment(\.appTheme) private var theme
    @State private var showDetail = false
    // Guards against the card tap firing when the favorite button was tapped.
    @State private var favoriteJustTapped = false
    // Fade + slide-up entrance when the card first scrolls into view.
    @State private var appeared = false
    // Heart icon bounce scale on favorite toggle.
    @State private var heartScale: CGFloat = 1.0

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
        Button {
            if favoriteJustTapped {
                favoriteJustTapped = false
                return
            }
            showDetail = true
        } label: {
            cardContent
        }
        // Press scale: card shrinks slightly to give physical press feedback.
        .buttonStyle(CardButtonStyle())
        .contentShape(RoundedRectangle(cornerRadius: 24))
        .frame(width: itemWidth)
        // Entrance animation: fade in + slide up when the card scrolls into view.
        .opacity(appeared ? 1.0 : 0.0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            guard !appeared else { return }
            withAnimation(.easeOut(duration: 0.3).delay(0.05)) {
                appeared = true
            }
        }
        // Heart settle: after bouncing to 1.3, spring back to 1.0 automatically.
        .onChange(of: heartScale) { val in
            if val == 1.3 {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.6).delay(0.12)) {
                    heartScale = 1.0
                }
            }
        }
        .fullScreenCover(isPresented: $showDetail) {
            WallpaperDetailScreen(
                wallpaper: wallpaper,
                isPresented: $showDetail,
                wallpapers: wallpapers,
                currentIndex: currentIndex
            )
        }
    }

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
                        favoriteJustTapped = true
                        // Haptic feedback
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        // Heart bounce: spring out to 1.3×, then .onChange settles it back
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                            heartScale = 1.3
                        }
                        toggleFavorite()
                    }
                )
                .overlay(
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 18))
                        .foregroundColor(isFavorite ? .red : theme.onSurfaceVariant)
                        .scaleEffect(heartScale)
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

// Press feedback: subtle opacity change instead of scale to avoid
// "pressed" feeling during tab swipe gestures. Scale effects are
// too visible when a DragGesture on the parent triggers simultaneously.
private struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
