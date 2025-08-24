import SwiftUI

struct FavoritesScreen: View {
    @StateObject private var favoritesManager = FavoritesManager.shared
    @EnvironmentObject private var tabManager: TabManager
    @Environment(\.appTheme) private var theme
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var scrollViewHelper = ScrollViewHelper()
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .info
    @State private var hasLoaded = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Check if favorites are empty *before* creating the ScrollView
            if favoritesManager.favorites.isEmpty {
                EmptyStateViewFavorites()
            } else {
                // The CustomRefreshView is now only created when there are items to show
                CustomRefreshView(showsIndicator: false) {
                    PaginatedWallpaperGrid(
                        wallpapers: favoritesManager.favorites,
                        isLoading: false,
                        hasReachedEnd: true,
                        onLoadMore: {}
                    )
                    .padding(.vertical)
                } onRefresh: {
                    await refreshFavoritesData()
                }
            }
            
            // Scroll to top button
            if scrollViewHelper.showScrollToTop && !favoritesManager.favorites.isEmpty {
                ScrollToTopButton {
                    scrollViewHelper.shouldScrollToTop = true
                }
                .padding(.trailing, 16)
                .padding(.bottom, 16)
            }
            
            // Toast
            if showToast {
                ToastView(
                    message: toastMessage,
                    type: toastType,
                    isPresented: $showToast
                )
            }
        }
        .onAppear {
            // Only load favorites if this is the active tab
            if tabManager.isTabActive(3) && !hasLoaded {
                favoritesManager.fetchFavorites()
                hasLoaded = true
            }
        }
        .onChange(of: tabManager.activeTab) { activeTab in
            if activeTab == 3 && !hasLoaded {
                // Tab became active and hasn't loaded yet
                favoritesManager.fetchFavorites()
                hasLoaded = true
            }
        }
        .preferredColorScheme(themeManager.themeMode == .dark ? .dark : .light)
    }
    
    @MainActor
    private func refreshFavoritesData() async {
        favoritesManager.fetchFavorites()
        
        // Wait a bit for the data to load
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Show success toast
        toastMessage = "Favorites refreshed"
        toastType = .info
        showToast = true
    }
}



private struct EmptyStateViewFavorites: View {
    @Environment(\.appTheme) var theme
    
    var body: some View {
        VStack(spacing: 20) {
            // Spacer pushes content down from the top
            Spacer()
            
            Image(systemName: "heart.slash")
                .font(.system(size: 64))
                .foregroundColor(theme.onSurfaceVariant)
            
            VStack(spacing: 12) {
                Text("No favorites yet")
                    .font(AppFonts.display(20))
                    .foregroundColor(theme.onSurface)
                
                Text("Your favorite wallpapers will appear here")
                    .font(AppFonts.body())
                    .foregroundColor(theme.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Spacer pushes content up from the bottom
            Spacer()
        }
        .frame(maxWidth: .infinity) // Ensure the VStack takes full width
    }
}

class FavoritesViewModel: ObservableObject {
    @Published var isLoading = true
    @Published var hasLoaded = false
} 
