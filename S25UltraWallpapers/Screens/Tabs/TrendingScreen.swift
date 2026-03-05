import SwiftUI

enum TrendingSortOption: String, CaseIterable {
    case freshDrops = "Fresh Drops"
    case hottestViews = "Hottest Views"
    case mostLoved = "Most Loved"
    
    var firebaseField: String {
        switch self {
        case .freshDrops: return "timestamp"
        case .hottestViews: return "views"
        case .mostLoved: return "downloads"
        }
    }
}

struct TrendingScreen: View {
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @EnvironmentObject private var trendingScreenState: TrendingScreenState
    @Environment(\.appTheme) private var theme
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var paginator: FirestorePaginator
    @StateObject private var scrollViewHelper = ScrollViewHelper()
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .info
    
    // Sort related states
    @State private var selectedSort: TrendingSortOption = .freshDrops
    @State private var isLoadingWallpapers = false
    @State private var isScreenActive = false
    @State private var hasLoaded = false
    
    init() {
        // Load saved sort preference
        let savedSort = UserDefaults.standard.string(forKey: "TrendingSortPreference") ?? TrendingSortOption.freshDrops.rawValue
        let sortOption = TrendingSortOption(rawValue: savedSort) ?? .freshDrops
        
        let query = FirebaseManager.shared.db.collection("TrendingWallpapers")
            .order(by: sortOption.firebaseField, descending: true)
        _paginator = StateObject(wrappedValue: FirestorePaginator(baseQuery: query))
        
        // Set the initial sort option
        _selectedSort = State(initialValue: sortOption)
    }
    
    var body: some View {
        NavigationView {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    // Loading indicator for wallpapers
                    if isLoadingWallpapers {
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                                .scaleEffect(1.2)

                            Text("Loading wallpapers...")
                                .font(.subheadline)
                                .foregroundColor(theme.onSurfaceVariant)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }

                    // Wallpapers Section
                    else if !paginator.wallpapers.isEmpty {
                        PaginatedWallpaperGridWithAds(
                            wallpapers: paginator.wallpapers,
                            isLoading: paginator.isLoading,
                            hasReachedEnd: paginator.hasReachedEnd,
                            onLoadMore: {
                                paginator.loadMoreWallpapers()
                            }
                        )
                        .environmentObject(FavoritesManager.shared)
                    } else if !paginator.isLoading && hasLoaded {
                        VStack(spacing: 12) {
                            Image(systemName: "wifi.slash")
                                .font(.system(size: 40))
                                .foregroundColor(theme.onSurfaceVariant)
                            Text("Couldn't load wallpapers")
                                .font(.subheadline)
                                .foregroundColor(theme.onSurfaceVariant)
                            Button("Try Again") {
                                loadData()
                            }
                            .foregroundColor(theme.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    }
                }
                .padding(.vertical)
            }
            .refreshable {
                await refreshTrendingData()
            }
            
            // Scroll to top button
            if scrollViewHelper.showScrollToTop {
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
        }
        .background(theme.background.ignoresSafeArea())
        .sheet(isPresented: $trendingScreenState.showSortSheet) {
            sortBottomSheet
        }
        .onAppear {
            isScreenActive = true
            if !hasLoaded {
                loadData()
            }
        }
        .onDisappear {
            isScreenActive = false
        }
        .onChange(of: paginator.isLoading) { loading in
            if !loading {
                isLoadingWallpapers = false
            }
        }
        .preferredColorScheme(themeManager.themeMode == .dark ? .dark : .light)
    }
    
    private var sortBottomSheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Sort by")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.onSurface)
                
                Spacer()
                
                Button("Done") {
                    trendingScreenState.showSortSheet = false
                }
                .foregroundColor(theme.primary)
            }
            .padding()
            
            Divider()
            
            // Sort options
            ForEach(TrendingSortOption.allCases, id: \.self) { option in
                Button(action: {
                    if selectedSort != option {
                        selectedSort = option
                        UserDefaults.standard.set(option.rawValue, forKey: "TrendingSortPreference")
                        trendingScreenState.showSortSheet = false
                        applySortAndReload()
                    }
                }) {
                    HStack {
                        Text(option.rawValue)
                            .foregroundColor(theme.onSurface)
                        
                        Spacer()
                        
                        if selectedSort == option {
                            Image(systemName: "checkmark")
                                .foregroundColor(theme.primary)
                        }
                    }
                    .padding()
                }
            }
        }
        .modifier(SheetModifier())
    }
    
    private func loadData() {
        // Load wallpapers only if screen is active
        if isScreenActive {
            isLoadingWallpapers = true
            paginator.loadInitialWallpapers()
        }

        hasLoaded = true
    }
    
    private func applySortAndReload() {
        isLoadingWallpapers = true

        // Create new query with selected sort
        let newQuery = FirebaseManager.shared.db.collection("TrendingWallpapers")
            .order(by: selectedSort.firebaseField, descending: true)

        // Update paginator with new query
        paginator.updateQuery(newQuery)
        paginator.loadInitialWallpapers()
    }
    
    @MainActor
    private func refreshTrendingData() async {
        // Show loading state
        isLoadingWallpapers = true
        
        // Refresh trending wallpapers
        firebaseManager.fetchTrendingWallpapers()
        
        // Refresh paginated wallpapers
        paginator.loadInitialWallpapers()
        
        // Wait a bit for data to load
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        isLoadingWallpapers = false
        
        // Show success toast
        toastMessage = "Trending content refreshed"
        toastType = .info
        showToast = true
    }
}




class TrendingViewModel: ObservableObject {
    @Published var isLoading = true
    @Published var hasLoaded = false
}

// iOS 16+ compatibility modifier for sheet presentation
struct SheetModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .presentationDetents([.height(240)])
                .presentationDragIndicator(.visible)
        } else {
            content
        }
    }
} 
