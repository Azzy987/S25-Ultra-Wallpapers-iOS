import SwiftUI

struct CarouselCardView: View {
    let card: CarouselCard
    let isCenter: Bool
    var parallaxOffset: CGFloat = 0
    @Environment(\.appTheme) private var theme
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var selectedWallpaper: Wallpaper?
    @State private var showDetail = false
    @Namespace private var animation
    
    var body: some View {
            CachedAsyncImage(url: URL(string: card.imageUrl)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                    .frame(width: cardWidth, height: cardHeight)
                        .background(theme.surfaceVariant)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                    .frame(width: cardWidth, height: cardHeight)
                    .offset(x: parallaxOffset) // Parallax effect
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                case .failure:
                    Image(systemName: "photo")
                    .frame(width: cardWidth, height: cardHeight)
                    .background(theme.surfaceVariant)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                @unknown default:
                    EmptyView()
                }
            }
            .onTapGesture {
                if let wallpaper = firebaseManager.wallpapers.first(where: { $0.id == card.id }) {
                    selectedWallpaper = wallpaper
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showDetail = true
                }
            }
        }
        .fullScreenCover(isPresented: $showDetail) {
            if let wallpaper = selectedWallpaper {
                WallpaperDetailScreen(wallpaper: wallpaper, animation: animation, isPresented: $showDetail)
            }
        }
    }
    
    private var cardWidth: CGFloat {
        isCenter ? 280 : 240
    }
    
    private var cardHeight: CGFloat {
        isCenter ? 200 : 170
    }
} 
