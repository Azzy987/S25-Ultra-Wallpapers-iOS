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
    @Environment(\.appTheme) private var theme
    @StateObject private var themeManager = ThemeManager.shared
    @State private var cards: [CarouselCard] = []
    @StateObject private var paginator: FirestorePaginator
    @State private var hasLoaded = false
    @StateObject private var scrollViewHelper = ScrollViewHelper()
    @StateObject private var scrollToTopNotifier = ScrollToTopNotifier.shared
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .info
    @State private var currentIndex = 0 // Start at first banner
    @State private var autoScrollTimer: Timer?
    @State private var showDetailScreen = false
    @State private var selectedBannerWallpaper: Wallpaper?
    @State private var isDraggingBanner = false
    
    // Sort related states
    @State private var selectedSort: HomeSortOption = .releaseDate
    @State private var isLoadingWallpapers = false
    @State private var isScreenActive = false

    // Task handles for cancellation on navigation away
    @State private var loadTask: Task<Void, Never>?
    @State private var diskCacheSaved = false
    
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
            ScrollViewReader { scrollProxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 8) {
                        Color.clear.frame(height: 0).id("homeTop")
                        bannerSection
                        wallpaperSection
                    }
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
                    await refreshHomeData()
                }
                .onChange(of: scrollToTopNotifier.trigger) { _ in
                    withAnimation(.easeInOut(duration: 0.4)) {
                        scrollProxy.scrollTo("homeTop", anchor: .top)
                    }
                }
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
                WallpaperDetailScreen(wallpaper: wallpaper, isPresented: $showDetailScreen)
            }
        }
        .onAppear {
            isScreenActive = true
            if !hasLoaded {
                loadData()
            }
            startAutoScroll()
        }
        .onDisappear {
            isScreenActive = false
            stopAutoScroll()
            // Cancel in-flight load tasks when navigating away
            loadTask?.cancel()
            loadTask = nil
        }
        .onChange(of: paginator.wallpapers.count) { count in
            // Save to disk cache once when the first page of wallpapers arrives
            guard !diskCacheSaved, count > 0 else { return }
            diskCacheSaved = true
            WallpaperDiskCache.shared.save(paginator.wallpapers, forKey: WallpaperDiskCache.homeKey)
        }
        .onChange(of: paginator.isLoading) { loading in
            if !loading {
                isLoadingWallpapers = false
            }
        }
        .preferredColorScheme(themeManager.themeMode == .dark ? .dark : (themeManager.themeMode == .light ? .light : nil))
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
                            BannerDragState.shared.isDragging = true
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
                            BannerDragState.shared.isDragging = false
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
        GeometryReader { geometry in
            ZStack {
                // Background image
                CachedAsyncImage(url: URL(string: card.imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(theme.surfaceVariant)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    case .failure:
                        Rectangle()
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
                
                // Banner name centered vertically and horizontally
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        Text(card.name.isEmpty ? "Featured" : card.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.ultraThinMaterial)
                            )
                        Spacer()
                    }
                    
                    Spacer()
                }
            }
        }
        .frame(width: UIScreen.main.bounds.width - 64, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
    
    @ViewBuilder
    private func bannerImageContent(phase: AsyncImagePhase, card: CarouselCard) -> some View {
        ZStack {
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
            
            // Banner name overlay (always on top regardless of phase)
            VStack {
                Spacer()
                
                HStack {
                    Spacer()
                    Text(card.name.isEmpty ? "Featured" : card.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.ultraThinMaterial)
                        )
                    Spacer()
                }
                .padding(.bottom, 24)
            }
            .allowsHitTesting(false)
            
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
                                
            PaginatedWallpaperGridWithAds(
                                    wallpapers: paginator.wallpapers,
                isLoading: paginator.isLoading,
                hasReachedEnd: paginator.hasReachedEnd,
                                    onLoadMore: {
                                        paginator.loadMoreWallpapers()
                }
                                )
                                .environmentObject(FavoritesManager.shared)
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
        print("🏠 HomeScreen.loadData() started")
        let startTime = Date()
        
        // IMMEDIATE: Show hasLoaded to prevent multiple calls
        hasLoaded = true
        
        // Load banners asynchronously (non-blocking) — store handle for cancellation
        loadTask?.cancel()
        loadTask = Task {
            print("🎨 Fetching banners...")
            let bannerStart = Date()
            
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                firebaseManager.fetchBanners {
                    continuation.resume()
                }
            }
            
            await MainActor.run {
                self.cards = self.firebaseManager.banners.map { CarouselCard(from: $0) }
                print("✅ Banners loaded in \(Date().timeIntervalSince(bannerStart))s, count: \(self.cards.count)")
                
                // Preload wallpaper data in background (non-blocking)
                Task.detached(priority: .background) {
                    await self.preloadBannerWallpapers()
                }
                
                // Set initial index
                if !self.cards.isEmpty {
                    self.currentIndex = 0
                    if self.cards.count > 1 && self.isScreenActive {
                        self.startAutoScroll()
                    }
                }
            }
        }
        
        // Load trending wallpapers in parallel (non-blocking)
        Task.detached(priority: .background) {
            print("🔥 Fetching trending wallpapers...")
            await FirebaseManager.shared.fetchTrendingWallpapersAsync()
        }
        
        // Load wallpapers only if screen is active (non-blocking)
        if isScreenActive {
            Task {
                print("📱 Loading initial wallpapers...")
                let wallpaperStart = Date()
                
                await MainActor.run {
                    self.isLoadingWallpapers = true
                    self.paginator.loadInitialWallpapers()
                }
                
                print("✅ Initial wallpapers loading started in \(Date().timeIntervalSince(wallpaperStart))s")
            }
        }

        print("🎯 HomeScreen.loadData() setup complete in \(Date().timeIntervalSince(startTime))s")
    }

    private func preloadBannerWallpapers() async {
        print("🔄 Preloading \(cards.count) banner wallpapers...")
        let start = Date()
        
        // Preload wallpaper data for all banners in background for instant access
        for card in cards {
            // Try Samsung collection first
            _ = try? await firebaseManager.db.collection("Samsung")
                .document(card.id)
                .getDocument(source: .default)
            
            // Try TrendingWallpapers collection if not found
            _ = try? await firebaseManager.db.collection("TrendingWallpapers")
                .document(card.id)
                .getDocument(source: .default)
        }
        
        print("✅ Preload complete in \(Date().timeIntervalSince(start))s")
    }
    
    @MainActor
    private func refreshHomeData() async {
        // Show loading state
        isLoadingWallpapers = true
        
        // Refresh banners
        await withCheckedContinuation { continuation in
            firebaseManager.fetchBanners {
                self.cards = self.firebaseManager.banners.map { CarouselCard(from: $0) }
                
                // Preload in background (non-blocking)
                Task.detached(priority: .background) {
                    await self.preloadBannerWallpapers()
                }
                
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

        // Scroll to top immediately so when new results arrive the user sees them
        scrollToTopNotifier.scrollToTop()

        // Create new query with selected sort
        let newQuery = FirebaseManager.shared.db.collection("Samsung")
            .order(by: selectedSort.firebaseField, descending: true)

        // Update paginator with new query
        paginator.updateQuery(newQuery)
        paginator.loadInitialWallpapers()
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
        // Find wallpaper by matching document ID in Samsung collection
        if let wallpaper = firebaseManager.wallpapers.first(where: { wallpaper in
            let wallpaperDocumentId = String(wallpaper.id.prefix(36))
            return wallpaperDocumentId == card.id || wallpaper.id == card.id
        }) {
            selectedBannerWallpaper = wallpaper
            showDetailScreen = true
        }
        // Find wallpaper by matching document ID in TrendingWallpapers collection
        else if let trendingWallpaper = firebaseManager.trendingWallpapers.first(where: { wallpaper in
            let wallpaperDocumentId = String(wallpaper.id.prefix(36))
            return wallpaperDocumentId == card.id || wallpaper.id == card.id
        }) {
            selectedBannerWallpaper = trendingWallpaper
            showDetailScreen = true
        }
        // If not found in cached collections, create wallpaper from banner immediately
        else {
            // Create wallpaper from banner data immediately (no Firebase fetch delay)
            let wallpaper = createWallpaperFromBanner(card)
            selectedBannerWallpaper = wallpaper
            showDetailScreen = true
        }
    }
    
    private func fetchWallpaperByDocumentId(card: CarouselCard) {
        
        // Try Samsung collection first (direct document lookup by ID)
        firebaseManager.db.collection("Samsung").document(card.id).getDocument { snapshot, error in
            if error != nil {
                self.searchTrendingWallpaperById(card: card)
                return
            }
            
            if let document = snapshot, document.exists, let data = document.data() {
                let wallpaper = Wallpaper(id: card.id, data: data)
                DispatchQueue.main.async {
                    self.selectedBannerWallpaper = wallpaper
                    self.showDetailScreen = true
                }
            } else {
                self.searchTrendingWallpaperById(card: card)
            }
        }
    }
    
    private func searchTrendingWallpaperById(card: CarouselCard) {
        // Try TrendingWallpapers collection (direct document lookup by ID)
        firebaseManager.db.collection("TrendingWallpapers").document(card.id).getDocument { snapshot, error in
            if error != nil {
                return
            }

            if let document = snapshot, document.exists, let data = document.data() {
                let wallpaper = Wallpaper(id: card.id, data: data)
                DispatchQueue.main.async {
                    self.selectedBannerWallpaper = wallpaper
                    self.showDetailScreen = true
                }
            } else {
                // Create a fallback mock wallpaper for banners that don't have matching wallpaper documents
                self.createFallbackWallpaper(card: card)
            }
        }
    }
    
    private func createFallbackWallpaper(card: CarouselCard) {
        let mockWallpaperData: [String: Any] = [
            "wallpaperName": card.name,
            "imageUrl": card.imageUrl,
            "thumbnail": card.imageUrl,
            "createdAt": Date(),
            "category": "Featured",
            "series": "Banner"
        ]
        let mockWallpaper = Wallpaper(id: card.id, data: mockWallpaperData)
        
        DispatchQueue.main.async {
            self.selectedBannerWallpaper = mockWallpaper
            self.showDetailScreen = true
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
