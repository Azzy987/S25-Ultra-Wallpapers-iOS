import SwiftUI

struct FavoritesScreen: View {
    @StateObject private var favoritesManager = FavoritesManager.shared
    @StateObject private var userManager = UserManager.shared
    @Environment(\.appTheme) private var theme
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var scrollViewHelper = ScrollViewHelper()
    @StateObject private var scrollToTopNotifier = ScrollToTopNotifier.shared
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .info
    @State private var hasLoaded = false
    @State private var isSyncing = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Check if favorites are empty *before* creating the ScrollView
            if favoritesManager.favorites.isEmpty {
                EmptyStateViewFavorites()
            } else {
                ScrollViewReader { scrollProxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        PaginatedWallpaperGrid(
                            wallpapers: favoritesManager.favorites,
                            isLoading: false,
                            hasReachedEnd: true,
                            onLoadMore: {}
                        )
                        .environmentObject(FavoritesManager.shared)
                        .id("favoritesTop")
                        .padding(.top)
                        .padding(.bottom, 100) // clear floating tab bar
                        .background(
                            ScrollOffsetObserver { offset in
                                TabBarVisibilityManager.shared.updateScrollOffset(offset)
                                withAnimation {
                                    scrollViewHelper.showScrollToTop = offset < -500
                                }
                            }
                        )
                    }
                    .refreshable {
                        await refreshFavoritesData()
                    }
                    .onChange(of: scrollToTopNotifier.trigger) { _ in
                        withAnimation(.easeInOut(duration: 0.4)) {
                            scrollProxy.scrollTo("favoritesTop", anchor: .top)
                        }
                    }
                }
            }
            
            // Premium sync button (bottom left)
            if userManager.isPremium && userManager.isSignedIn && !favoritesManager.favorites.isEmpty {
                HStack {
                    SyncFloatingButton(
                        isSyncing: $isSyncing,
                        onSync: {
                            await syncFavoritesToFirebase()
                        }
                    )
                    .padding(.leading, 16)
                    .padding(.bottom, 16)
                    
                    Spacer()
                }
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
            if !hasLoaded {
                favoritesManager.fetchFavorites()
                hasLoaded = true
            }
        }
        .preferredColorScheme(themeManager.themeMode == .dark ? .dark : (themeManager.themeMode == .light ? .light : nil))
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
    
    @MainActor
    private func syncFavoritesToFirebase() async {
        guard userManager.isPremium && userManager.isSignedIn else {
            toastMessage = "Premium subscription required"
            toastType = .error
            showToast = true
            return
        }
        
        isSyncing = true
        
        // Get favorite wallpaper IDs
        let favoriteIds = favoritesManager.favorites.map { $0.id }
        
        // Sync to Firebase
        await FirebaseUserDataManager.shared.updateFavorites(favoriteIds)
        
        // Wait a moment for visual feedback
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        isSyncing = false
        
        // Show success toast
        toastMessage = "Favorites synced to cloud ☁️"
        toastType = .info
        showToast = true
    }
}



private struct EmptyStateViewFavorites: View {
    @Environment(\.appTheme) var theme

    var body: some View {
        VStack(spacing: 20) {
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

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle()) // allow swipe gestures over empty area
    }
}

class FavoritesViewModel: ObservableObject {
    @Published var isLoading = true
    @Published var hasLoaded = false
} 
