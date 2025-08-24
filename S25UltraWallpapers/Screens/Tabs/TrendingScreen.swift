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
    @EnvironmentObject private var tabManager: TabManager
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
            CustomRefreshView(showsIndicator: false) {
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
                        PaginatedWallpaperGrid(
                            wallpapers: paginator.wallpapers,
                            isLoading: paginator.isLoading,
                            hasReachedEnd: paginator.hasReachedEnd,
                            onLoadMore: {
                                paginator.loadMoreWallpapers()
                            }
                        )
                    }
                }
                .padding(.vertical)
            } onRefresh: {
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
            // Only mark as active and load if this is the active tab
            if tabManager.isTabActive(2) {
                isScreenActive = true
                if !hasLoaded {
                    loadData()
                }
            }
        }
        .onDisappear {
            isScreenActive = false
        }
        .onChange(of: tabManager.activeTab) { activeTab in
            if activeTab == 2 && !isScreenActive {
                // Tab became active
                isScreenActive = true
                if !hasLoaded {
                    loadData()
                }
            } else if activeTab != 2 && isScreenActive {
                // Tab became inactive
                isScreenActive = false
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
            
            // Listen for loading completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                checkLoadingStatus()
            }
        }
        
        hasLoaded = true
    }
    
    private func checkLoadingStatus() {
        if !paginator.isLoading {
            isLoadingWallpapers = false
        } else {
            // Check again in 0.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                checkLoadingStatus()
            }
        }
    }
    
    private func applySortAndReload() {
        isLoadingWallpapers = true
        
        // Create new query with selected sort
        let newQuery = FirebaseManager.shared.db.collection("TrendingWallpapers")
            .order(by: selectedSort.firebaseField, descending: true)
        
        // Update paginator with new query
        paginator.updateQuery(newQuery)
        paginator.loadInitialWallpapers()
        
        // Monitor loading completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            checkLoadingStatus()
        }
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
