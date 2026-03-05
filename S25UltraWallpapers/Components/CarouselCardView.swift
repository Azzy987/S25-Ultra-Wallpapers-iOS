import SwiftUI

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct CarouselCardView: View {
    let card: CarouselCard
    let isCenter: Bool
    var parallaxOffset: CGFloat = 0
    var disableInternalTap: Bool = false
    @Environment(\.appTheme) private var theme
    @State private var selectedWallpaper: Wallpaper?
    @State private var showDetail = false
    
    var body: some View {
        ZStack {
            CachedAsyncImage(url: URL(string: card.imageUrl)) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                    .frame(width: cardWidth, height: cardHeight)
                        .background(theme.surfaceVariant)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                    .frame(width: cardWidth, height: cardHeight)
                    .offset(x: parallaxOffset) // Parallax effect
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                case .failure:
                    Image(systemName: "photo")
                    .frame(width: cardWidth, height: cardHeight)
                    .background(theme.surfaceVariant)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                @unknown default:
                    EmptyView()
                }
            }
            
            // Banner name overlay with black alpha background
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    Text(card.name.isEmpty ? "Featured" : card.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Rectangle()
                                .fill(Color.black.opacity(0.75))
                        )
                        .cornerRadius(12)
                    Spacer()
                }
                .padding(.bottom, 16)
            }
            .frame(width: cardWidth, height: cardHeight)
        }
        .if(!disableInternalTap) { view in
            view.onTapGesture {
                handleBannerTap()
            }
            .fullScreenCover(isPresented: $showDetail) {
                if let wallpaper = selectedWallpaper {
                    WallpaperDetailScreen(wallpaper: wallpaper, isPresented: $showDetail)
                }
            }
        }
    }
    
    private var cardWidth: CGFloat {
        isCenter ? 280 : 240
    }
    
    private var cardHeight: CGFloat {
        isCenter ? 200 : 170
    }
    
    // MARK: - Banner Tap Handler

    /// Navigates instantly using banner data — same approach as Android.
    /// Android calls navigateToDetail(wallpaperId) and loads data AFTER the screen opens.
    /// We do the same: build a stub Wallpaper from the banner and navigate immediately.
    private func handleBannerTap() {
        // Build a stub Wallpaper from banner data — enough for the detail screen
        // to show the image right away while any extra metadata loads in background.
        let stubWallpaper = Wallpaper(
            id: card.wallpaperId,
            data: [
                "imageUrl": card.imageUrl,
                "thumbnail": card.imageUrl,
                "wallpaperName": card.name
            ]
        )
        selectedWallpaper = stubWallpaper
        showDetail = true
    }
}
