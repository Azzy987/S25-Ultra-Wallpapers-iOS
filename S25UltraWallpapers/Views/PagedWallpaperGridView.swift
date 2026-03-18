import SwiftUI

struct PagedWallpaperGridView: View {
    @ObservedObject var paginator: FirestorePaginator
    @StateObject private var scrollToTopNotifier = ScrollToTopNotifier.shared
    @Environment(\.appTheme) private var theme

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                PaginatedWallpaperGridWithAds(
                    wallpapers: paginator.wallpapers,
                    isLoading: paginator.isLoading,
                    hasReachedEnd: paginator.hasReachedEnd,
                    onLoadMore: { paginator.loadMoreWallpapers() }
                )
                .environmentObject(FavoritesManager.shared)
                .id("pagedTop")
                .padding(.top)
                .padding(.bottom, 100) // clear floating tab bar
                .background(
                    ScrollOffsetObserver { offset in
                        TabBarVisibilityManager.shared.updateScrollOffset(offset)
                    }
                )
            }
            .onAppear {
                if paginator.wallpapers.isEmpty && !paginator.isLoading {
                    paginator.loadInitialWallpapers()
                }
            }
            .onChange(of: scrollToTopNotifier.trigger) { _ in
                withAnimation(.easeInOut(duration: 0.4)) {
                    scrollProxy.scrollTo("pagedTop", anchor: .top)
                }
            }
        }
        .background(theme.background)
    }
}
