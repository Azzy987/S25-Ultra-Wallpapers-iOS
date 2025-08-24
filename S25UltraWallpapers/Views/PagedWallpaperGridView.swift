import SwiftUI

struct PagedWallpaperGridView: View {
    @ObservedObject var paginator: FirestorePaginator
    @StateObject private var scrollViewHelper = ScrollViewHelper()
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        ScrollView {
            PaginatedWallpaperGrid(
                wallpapers: paginator.wallpapers,
                isLoading: paginator.isLoading,
                hasReachedEnd: paginator.hasReachedEnd,
                onLoadMore: { paginator.loadMoreWallpapers() }
            )
            .padding(.vertical)
        }
        .coordinateSpace(name: "scroll")
        .overlay(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: ScrollViewOffsetKey.self,
                    value: proxy.frame(in: .named("scroll")).minY
                )
            }
        )
        .onPreferenceChange(ScrollViewOffsetKey.self) { offset in
            withAnimation {
                scrollViewHelper.showScrollToTop = -offset > 500
            }
        }
        .background(theme.background)
        .overlay(alignment: .bottomTrailing) {
            if scrollViewHelper.showScrollToTop {
                ScrollToTopButton {
                    scrollViewHelper.shouldScrollToTop = true
                }
                .padding(.trailing, 16)
                .padding(.bottom, 16)
            }
        }
    }
}