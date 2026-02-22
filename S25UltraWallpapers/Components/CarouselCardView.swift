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
    @StateObject private var firebaseManager = FirebaseManager.shared
    @StateObject private var adManager = AdManager.shared
    @State private var selectedWallpaper: Wallpaper?
    @State private var showDetail = false
    @State private var isLoadingWallpaper = false
    
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
            .overlay(
                Group {
                    if isLoadingWallpaper {
                        ZStack {
                            Color.black.opacity(0.3)
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                    }
                }
            )
        }
    }
    
    private var cardWidth: CGFloat {
        isCenter ? 280 : 240
    }
    
    private var cardHeight: CGFloat {
        isCenter ? 200 : 170
    }
    
    // MARK: - Android-like Banner Tap Handler
    
    /// Handles banner tap with instant navigation and optional ad check
    /// Matches Android implementation: navigateWithAdCheck -> navigateToDetail
    private func handleBannerTap() {
        // Show loading indicator briefly
        isLoadingWallpaper = true
        
        // Use wallpaperId directly from banner (Android approach)
        let wallpaperId = card.wallpaperId
        
        // Navigate with ad check (1-second timeout like Android)
        adManager.navigateWithAdCheck {
            // This closure is called after ad check/timeout
            // Now fetch the wallpaper and navigate
            fetchWallpaperAndNavigate(wallpaperId: wallpaperId)
        }
    }
    
    /// Fetches wallpaper data and navigates to detail screen
    private func fetchWallpaperAndNavigate(wallpaperId: String) {
        // Try to find in cached wallpapers first (instant)
        if let wallpaper = firebaseManager.wallpapers.first(where: { $0.id == wallpaperId }) {
            isLoadingWallpaper = false
            selectedWallpaper = wallpaper
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showDetail = true
            }
            return
        }
        
        // If not in cache, fetch from Firebase
        Task {
            do {
                let wallpaper = try await fetchWallpaperById(wallpaperId)
                await MainActor.run {
                    isLoadingWallpaper = false
                    selectedWallpaper = wallpaper
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showDetail = true
                    }
                }
            } catch {
                print("❌ Failed to fetch wallpaper: \(error)")
                await MainActor.run {
                    isLoadingWallpaper = false
                }
            }
        }
    }
    
    /// Fetches a specific wallpaper by ID from Firebase
    private func fetchWallpaperById(_ id: String) async throws -> Wallpaper {
        // Check Samsung collection first
        if let wallpaper = try? await firebaseManager.fetchWallpaperById(id, collection: "Samsung") {
            return wallpaper
        }
        
        // Check Trending collection as fallback
        if let wallpaper = try? await firebaseManager.fetchWallpaperById(id, collection: "TrendingWallpapers") {
            return wallpaper
        }
        
        throw NSError(domain: "WallpaperNotFound", code: 404, userInfo: [NSLocalizedDescriptionKey: "Wallpaper not found"])
    }
}
