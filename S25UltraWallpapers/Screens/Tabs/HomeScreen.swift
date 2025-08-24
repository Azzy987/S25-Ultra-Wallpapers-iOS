import SwiftUI
import FirebaseFirestore

enum HomeSortOption: String, CaseIterable {
    case releaseDate = "Release Date"
    case freshDrops = "Fresh Drops"
    case hottestViews = "Hottest Views" 
    case mostLoved = "Most Loved"
    
    var firebaseField: String {
        switch self {
        case .releaseDate: return "launchYear"
        case .freshDrops: return "timestamp"
        case .hottestViews: return "views"
        case .mostLoved: return "downloads"
        }
    }
}

struct HomeScreen: View {
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @StateObject private var homeScreenState = HomeScreenState.shared
    @EnvironmentObject private var tabManager: TabManager
    @Environment(\.appTheme) private var theme
    @StateObject private var themeManager = ThemeManager.shared
    @State private var cards: [CarouselCard] = []
    @StateObject private var paginator: FirestorePaginator
    @State private var hasLoaded = false
    @StateObject private var scrollViewHelper = ScrollViewHelper()
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .info
    @State private var currentIndex = 0 // Start at first banner
    @State private var autoScrollTimer: Timer?
    @State private var showDetailScreen = false
    @State private var selectedBannerWallpaper: Wallpaper?
    @Namespace private var bannerAnimation
    @State private var isDraggingBanner = false
    @State private var isLoadingBannerDetail = false
    
    // Sort related states
    @State private var selectedSort: HomeSortOption = .releaseDate
    @State private var isLoadingWallpapers = false
    @State private var isScreenActive = false
    
    init() {
        // Load saved sort preference - default to release date
        let savedSort = UserDefaults.standard.string(forKey: "HomeSortPreference") ?? HomeSortOption.releaseDate.rawValue
        let sortOption = HomeSortOption(rawValue: savedSort) ?? .releaseDate
        
        let query = FirebaseManager.shared.db.collection("Samsung")
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
                    bannerSection
                    wallpaperSection
                }
            } onRefresh: {
                await refreshHomeData()
            }
                
                overlayContent
            }
        }
        .background(theme.background.ignoresSafeArea())
        .sheet(isPresented: $homeScreenState.showSortSheet) {
            sortBottomSheet
        }
        .fullScreenCover(isPresented: $showDetailScreen) {
            if let wallpaper = selectedBannerWallpaper {
                WallpaperDetailScreen(wallpaper: wallpaper, animation: bannerAnimation, isPresented: $showDetailScreen)
            }
        }
        .overlay(
            // Loading overlay for banner detail loading
            Group {
                if isLoadingBannerDetail {
                    ZStack {
                        Color.black.opacity(0.7)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            
                            Text("Loading wallpaper...")
                                .font(.subheadline)
                                .foregroundColor(.white)
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                        )
                    }
                    .transition(.opacity)
                }
            }
        )
        .onAppear {
            // Only mark as active and load if this is the active tab
            if tabManager.isTabActive(0) {
                isScreenActive = true
                if !hasLoaded {
                    loadData()
                }
                startAutoScroll()
            }
        }
        .onDisappear {
            isScreenActive = false
            stopAutoScroll()
        }
        .onChange(of: tabManager.activeTab) { activeTab in
            if activeTab == 0 && !isScreenActive {
                // Tab became active
                isScreenActive = true
                if !hasLoaded {
                    loadData()
                }
                startAutoScroll()
            } else if activeTab != 0 && isScreenActive {
                // Tab became inactive
                isScreenActive = false
                stopAutoScroll()
            }
        }
        .preferredColorScheme(themeManager.themeMode == .dark ? .dark : .light)
    }
    
    @ViewBuilder
    private var bannerSection: some View {
        if !cards.isEmpty {
            ZStack(alignment: .bottom) {
                bannerCarousel
                    .frame(height: 220)
                
                pageIndicator
                    .padding(.bottom, 16)
            }
            .padding(.top, 20)
            .padding(.bottom, 16)
        }
    }
    
    @ViewBuilder
    private var bannerCarousel: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                bannerHStack
            }
            .clipped()
            .simultaneousGesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { value in
                        // Only handle horizontal swipes when horizontal movement is significantly more than vertical
                        let horizontalDistance = abs(value.translation.width)
                        let verticalDistance = abs(value.translation.height)
                        
                        // Only trigger banner drag if horizontal movement is at least 2x vertical movement
                        if horizontalDistance > verticalDistance * 2 && horizontalDistance > 30 {
                            isDraggingBanner = true
                            stopAutoScroll()
                        }
                    }
                    .onEnded { value in
                        let horizontalDistance = abs(value.translation.width)
                        let verticalDistance = abs(value.translation.height)
                        
                        // Only handle horizontal swipes when clearly horizontal
                        if horizontalDistance > verticalDistance * 2 && horizontalDistance > 30 {
                            let scrollThreshold: CGFloat = 50
                            
                            if abs(value.translation.width) > scrollThreshold {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    if value.translation.width > 0 {
                                        // Swiped right - go to previous banner
                                        currentIndex = max(0, currentIndex - 1)
                                    } else {
                                    // Swiped left - go to next banner
                                    currentIndex = min(cards.count - 1, currentIndex + 1)
                                }
                                
                                // Scroll to the new index
                                proxy.scrollTo(currentIndex, anchor: UnitPoint.center)
                            }
                            }
                        }
                        
                        // Reset dragging state after a short delay to prevent tap
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isDraggingBanner = false
                        }
                        
                        // Resume auto-scroll after manual interaction
                        if isScreenActive && cards.count > 1 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                startAutoScroll()
                            }
                        }
                    }
            )
            .onAppear {
                // Start from the current index
                if !cards.isEmpty {
                    proxy.scrollTo(currentIndex, anchor: UnitPoint.center)
                }
            }
            .onChange(of: currentIndex) { newIndex in
                withAnimation(.easeInOut(duration: 0.5)) {
                    proxy.scrollTo(newIndex, anchor: UnitPoint.center)
                }
            }
        }
    }
    
    @ViewBuilder
    private var bannerHStack: some View {
        LazyHStack(spacing: 16) {
            ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                bannerButton(for: card, at: index)
            }
        }
        .padding(.horizontal, 32)
    }
    
    @ViewBuilder
    private func bannerButton(for card: CarouselCard, at index: Int) -> some View {
        bannerImageView(for: card)
            .onTapGesture {
                // Only handle tap if we're not dragging
                if !isDraggingBanner {
                    handleBannerTap(card: card)
                }
            }
            .id(index)
    }
    
    @ViewBuilder
    private func bannerImageView(for card: CarouselCard) -> some View {
        CachedAsyncImage(url: URL(string: card.imageUrl)) { phase in
            bannerImageContent(phase: phase)
        }
        .frame(width: UIScreen.main.bounds.width - 64, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    @ViewBuilder
    private func bannerImageContent(phase: AsyncImagePhase) -> some View {
        switch phase {
        case .empty:
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surfaceVariant)
                .overlay(
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                )
        case .success(let image):
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        case .failure:
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.surfaceVariant)
                .overlay(
                    Image(systemName: "photo")
                        .font(.title)
                        .foregroundColor(theme.onSurfaceVariant)
                )
        @unknown default:
            EmptyView()
        }
    }
    
    
    @ViewBuilder
    private var wallpaperSection: some View {
        if isLoadingWallpapers {
            loadingView
        } else if !paginator.wallpapers.isEmpty {
            samsungWallpapersView
        }
    }
    
    @ViewBuilder
    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<cards.count, id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? theme.primary : theme.onSurface.opacity(0.4))
                    .frame(width: index == currentIndex ? 10 : 8, height: index == currentIndex ? 10 : 8)
                    .animation(.easeInOut(duration: 0.3), value: currentIndex)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: theme.onSurface.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    @ViewBuilder
    private var loadingView: some View {
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
    
    @ViewBuilder
    private var samsungWallpapersView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Samsung Wallpapers")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(theme.onSurface)
                
                Spacer()
            }
                                    .padding(.horizontal)
                                
            PaginatedWallpaperGrid(
                                    wallpapers: paginator.wallpapers,
                isLoading: paginator.isLoading,
                hasReachedEnd: paginator.hasReachedEnd,
                                    onLoadMore: {
                                        paginator.loadMoreWallpapers()
                }
                                )
                                .frame(maxWidth: .infinity)
        }
    }
    

    
    private var scrollOffsetOverlay: some View {
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: ScrollViewOffsetKey.self,
                            value: proxy.frame(in: .named("scroll")).minY
                        )
                    }
            }
            
    @ViewBuilder
    private var overlayContent: some View {
            if scrollViewHelper.showScrollToTop {
                ScrollToTopButton {
                    scrollViewHelper.shouldScrollToTop = true
                }
                .padding(.trailing, 16)
                .padding(.bottom, 16)
                .transition(.scale.combined(with: .opacity))
            }
            
            if showToast {
                ToastView(
                    message: toastMessage,
                    type: toastType,
                    isPresented: $showToast
                )
            }
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
                    homeScreenState.showSortSheet = false
                }
                .foregroundColor(theme.primary)
            }
            .padding()
            
            Divider()
            
            // Sort options
            ForEach(HomeSortOption.allCases, id: \.self) { option in
                Button(action: {
                    if selectedSort != option {
                        selectedSort = option
                        UserDefaults.standard.set(option.rawValue, forKey: "HomeSortPreference")
                        homeScreenState.showSortSheet = false
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
        .modifier(HomeSheetModifier())
    }
    
    private func loadData() {
        // Load banners
        firebaseManager.fetchBanners {
            self.cards = self.firebaseManager.banners.map { CarouselCard(from: $0) }
            
            // Preload wallpaper data for all banners to enable instant navigation
            self.preloadBannerWallpapers()
            
            // Set initial index to first banner
            if !self.cards.isEmpty {
                self.currentIndex = 0
                
                // Start auto-scroll only if we have more than one card
                if self.cards.count > 1 && self.isScreenActive {
                    self.startAutoScroll()
                }
            }
        }
        
        // Load trending wallpapers to ensure banner navigation works
        firebaseManager.fetchTrendingWallpapers()
        
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
    
    private func preloadBannerWallpapers() {
        // Preload wallpaper data for all banners in background for instant access
        for card in cards {
            // Try Samsung collection first
            firebaseManager.db.collection("Samsung").document(card.id).getDocument(source: .default) { document, error in
                if let document = document, document.exists {
                    // Document is now cached for instant access
                    return
                }
                
                // Try TrendingWallpapers collection
                self.firebaseManager.db.collection("TrendingWallpapers").document(card.id).getDocument(source: .default) { document, error in
                    // Document is now cached for instant access
                }
            }
        }
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
    
    @MainActor
    private func refreshHomeData() async {
        // Show loading state
        isLoadingWallpapers = true
        
        // Refresh banners
        await withCheckedContinuation { continuation in
            firebaseManager.fetchBanners {
                self.cards = self.firebaseManager.banners.map { CarouselCard(from: $0) }
                self.preloadBannerWallpapers()
                
                if !self.cards.isEmpty {
                    self.currentIndex = 0
                    if self.cards.count > 1 && self.isScreenActive {
                        self.startAutoScroll()
                    }
                }
                continuation.resume()
            }
        }
        
        // Refresh trending wallpapers
        firebaseManager.fetchTrendingWallpapers()
        
        // Refresh main wallpapers  
        paginator.loadInitialWallpapers()
        
        // Wait a bit for data to load
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        isLoadingWallpapers = false
        
        // Show success toast
        toastMessage = "Content refreshed"
        toastType = .info
        showToast = true
    }
    
    private func applySortAndReload() {
        isLoadingWallpapers = true
        
        // Create new query with selected sort
        let newQuery = FirebaseManager.shared.db.collection("Samsung")
            .order(by: selectedSort.firebaseField, descending: true)
        
        // Update paginator with new query
        paginator.updateQuery(newQuery)
        paginator.loadInitialWallpapers()
        
        // Monitor loading completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            checkLoadingStatus()
        }
    }
    
    
    private func startAutoScroll() {
        stopAutoScroll() // Stop any existing timer
        guard cards.count > 1 else { return } // Need at least 2 banners for auto-scroll
        
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 6.0, repeats: true) { _ in
            guard !self.cards.isEmpty else { return }
            
            // Only auto-scroll if the screen is active
            if self.isScreenActive {
                withAnimation(.easeInOut(duration: 0.8)) {
                    self.currentIndex = (self.currentIndex + 1) % self.cards.count
                }
            }
        }
    }
    
    private func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }
    
    // MARK: - Banner Helper Functions
    
    private func handleBannerTap(card: CarouselCard) {
        // Show loading immediately
        withAnimation(.easeInOut(duration: 0.2)) {
            isLoadingBannerDetail = true
        }
        
        // Find wallpaper with same document ID as banner for navigation
        // Check both Samsung collection and TrendingWallpapers collection first
        if let wallpaper = firebaseManager.wallpapers.first(where: { $0.id == card.id }) {
            // Found in cached data - show immediately
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.isLoadingBannerDetail = false
                }
                self.selectedBannerWallpaper = wallpaper
                self.showDetailScreen = true
            }
        } else if let trendingWallpaper = firebaseManager.trendingWallpapers.first(where: { $0.id == card.id }) {
            // Found in trending cache - show immediately
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.isLoadingBannerDetail = false
                }
                self.selectedBannerWallpaper = trendingWallpaper
                self.showDetailScreen = true
            }
        } else {
            // Fetch wallpaper directly from Firebase using banner ID with optimized approach
            fetchWallpaperFromBanner(card: card)
        }
    }
    
    
    private func fetchWallpaperFromBanner(card: CarouselCard) {
        // Use cache-first approach for instant loading
        let source: FirestoreSource = .cache
        
        // Create dispatch group for parallel queries
        let dispatchGroup = DispatchGroup()
        var foundWallpaper: Wallpaper?
        
        // Query Samsung collection from cache
        dispatchGroup.enter()
        firebaseManager.db.collection("Samsung").document(card.id).getDocument(source: source) { document, error in
            if let document = document, document.exists, let data = document.data() {
                foundWallpaper = Wallpaper(id: card.id, data: data)
            }
            dispatchGroup.leave()
        }
        
        // Query TrendingWallpapers collection from cache
        dispatchGroup.enter()
        firebaseManager.db.collection("TrendingWallpapers").document(card.id).getDocument(source: source) { document, error in
            if foundWallpaper == nil && document != nil && document!.exists, let data = document!.data() {
                foundWallpaper = Wallpaper(id: card.id, data: data)
            }
            dispatchGroup.leave()
        }
        
        // Handle results when both queries complete
        dispatchGroup.notify(queue: .main) {
            withAnimation(.easeInOut(duration: 0.2)) {
                self.isLoadingBannerDetail = false
            }
            
            if let wallpaper = foundWallpaper {
                self.selectedBannerWallpaper = wallpaper
                self.showDetailScreen = true
            } else {
                // If nothing found in cache, try server as fallback
                self.fetchWallpaperFromServer(card: card)
            }
        }
    }
    
    private func fetchWallpaperFromServer(card: CarouselCard) {
        // Fallback to server if cache miss
        let source: FirestoreSource = .server
        
        // Try Samsung collection first
        firebaseManager.db.collection("Samsung").document(card.id).getDocument(source: source) { document, error in
            DispatchQueue.main.async {
                if let document = document, document.exists, let data = document.data() {
                    let wallpaper = Wallpaper(id: card.id, data: data)
                    self.selectedBannerWallpaper = wallpaper
                    self.showDetailScreen = true
                } else {
                    // Try TrendingWallpapers collection
                    self.firebaseManager.db.collection("TrendingWallpapers").document(card.id).getDocument(source: source) { document, error in
                        DispatchQueue.main.async {
                            if let document = document, document.exists, let data = document.data() {
                                let wallpaper = Wallpaper(id: card.id, data: data)
                                self.selectedBannerWallpaper = wallpaper
                                self.showDetailScreen = true
                            } else {
                                // Final fallback: create from banner data
                                let bannerWallpaper = self.createWallpaperFromBanner(card)
                                self.selectedBannerWallpaper = bannerWallpaper
                                self.showDetailScreen = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Helper function to create Wallpaper from banner when direct match not found
    private func createWallpaperFromBanner(_ card: CarouselCard) -> Wallpaper {
        // Get banner name from banner data if available
        let bannerName = firebaseManager.banners.first(where: { $0.id == card.id })?.name ?? "Featured Wallpaper"
        
        // Create better wallpaper data structure from banner
        let wallpaperData: [String: Any] = [
            "wallpaperName": bannerName,
            "thumbnail": card.imageUrl,
            "imageUrl": card.imageUrl,
            "category": ["Featured"],
            "tags": ["featured", "banner"],
            "colors": [],
            "timestamp": Timestamp(date: Date()),
            "dimensions": "Unknown",
            "size": "Unknown",
            "source": "Featured Collection",
            "downloads": 0,
            "views": 0,
            "exclusive": false
        ]
        
        return Wallpaper(id: card.id, data: wallpaperData)
    }
}



// iOS 16+ compatibility modifier for sheet presentation
struct HomeSheetModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
        } else {
            content
        }
    }
}

// Custom ViewModifiers for iOS version compatibility
@available(iOS 17.0, *)
struct ScrollTargetLayoutModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.scrollTargetLayout()
    }
}

struct ScrollTargetLayoutFallbackModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}

struct ScrollTargetLayoutCompatModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.modifier(ScrollTargetLayoutModifier())
        } else {
            content.modifier(ScrollTargetLayoutFallbackModifier())
        }
    }
}

@available(iOS 17.0, *)
struct ScrollTargetBehaviorModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.scrollTargetBehavior(.viewAligned)
    }
}

struct ScrollTargetBehaviorFallbackModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}
