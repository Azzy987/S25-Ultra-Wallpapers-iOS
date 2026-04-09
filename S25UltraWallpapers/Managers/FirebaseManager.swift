import SwiftUI
import Firebase
import FirebaseFirestore

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    let db = Firestore.firestore()
    
    @Published var wallpapers: [Wallpaper] = []
    @Published var banners: [Banner] = []
    @Published var categories: [Category] = []
    @Published var trendingWallpapers: [Wallpaper] = []
    @Published var paywallBanners: [String] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isInitialized = false
    
    private init() {
        print("🔥 FirebaseManager: Initializing...")
        let start = Date()
        
        // Configure Firestore settings BEFORE accessing the instance
        // Use persistent disk cache so wallpapers load instantly on subsequent launches
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: 50 * 1024 * 1024 as NSNumber) // 50MB disk cache
        settings.isSSLEnabled = true
        Firestore.firestore().settings = settings

        // Enable network first for faster loading
        Firestore.firestore().enableNetwork { error in
            if let error = error {
                AppLogger.error(AppLogger.firebase, "Firebase network error: \(error)")
            } else {
                print("✅ Firebase network enabled in \(Date().timeIntervalSince(start))s")
            }
        }
        
        print("✅ FirebaseManager initialized in \(Date().timeIntervalSince(start))s")
    }
    
    func initialize() {
        print("🚀 FirebaseManager.initialize() called")
        fetchHomeData()
    }
    
    func fetchHomeData() {
        print("📊 FirebaseManager.fetchHomeData() started")
        let startTime = Date()

        // Mark as initialized immediately to prevent blocking the UI
        DispatchQueue.main.async {
            self.isInitialized = true
            print("✅ App marked as initialized (UI unblocked) - \(Date().timeIntervalSince(startTime))s")
        }

        // Skip if already loaded
        guard wallpapers.isEmpty else {
            print("⏭️ Data already loaded, skipping fetch")
            return
        }

        // 1. Load disk cache immediately on main thread substitute
        WallpaperDiskCache.shared.loadAsync(forKey: WallpaperDiskCache.homeKey) { [weak self] cached in
            if let cached = cached, !cached.isEmpty {
                self?.wallpapers = cached
                print("📀 Disk cache hit: \(cached.count) home wallpapers")
            }
        }
        WallpaperDiskCache.shared.loadAsync(forKey: WallpaperDiskCache.trendingKey) { [weak self] cached in
            if let cached = cached, !cached.isEmpty {
                self?.trendingWallpapers = cached
                print("📀 Disk cache hit: \(cached.count) trending wallpapers")
            }
        }

        isLoading = true

        // 2. Fetch from network in background, refresh only if data changed
        Task {
            print("🔄 Starting parallel data fetch...")
            let taskStart = Date()

            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    let start = Date()
                    await self.fetchWallpapersAsync()
                    print("✅ Wallpapers loaded in \(Date().timeIntervalSince(start))s")
                }
                group.addTask {
                    let start = Date()
                    await self.fetchBannersAsync()
                    print("✅ Banners loaded in \(Date().timeIntervalSince(start))s")
                }
                group.addTask {
                    let start = Date()
                    await self.fetchTrendingWallpapersAsync()
                    print("✅ Trending loaded in \(Date().timeIntervalSince(start))s")
                }
            }

            await MainActor.run {
                self.isLoading = false
                print("🎉 All data loaded in \(Date().timeIntervalSince(taskStart))s")
                print("📈 Total time from start: \(Date().timeIntervalSince(startTime))s")
            }
        }
    }
    
    // Async versions for parallel loading
    private func fetchWallpapersAsync() async {
        do {
            // Use Firestore cache first, fall back to server
            let snapshot: QuerySnapshot
            do {
                snapshot = try await db.collection("Samsung")
                    .order(by: "timestamp", descending: true)
                    .limit(to: PaginationUtils.PAGE_SIZE)
                    .getDocuments(source: .cache)
            } catch {
                snapshot = try await db.collection("Samsung")
                    .order(by: "timestamp", descending: true)
                    .limit(to: PaginationUtils.PAGE_SIZE)
                    .getDocuments(source: .server)
            }

            let loaded = snapshot.documents.map { Wallpaper(id: $0.documentID, data: $0.data()) }
            await MainActor.run { self.wallpapers = loaded }

            // Save first page to disk cache (only if changed)
            if !loaded.isEmpty {
                WallpaperDiskCache.shared.save(loaded, forKey: WallpaperDiskCache.homeKey)
            }
        } catch {
            AppLogger.error(AppLogger.firebase, "fetchWallpapersAsync failed: \(error.localizedDescription)")
        }
    }

    private func fetchBannersAsync() async {
        do {
            let snapshot = try await db.collection("Banners")
                .document("SamsungWallpapers")
                .collection("S25UltraWallpapersBanners")
                .getDocuments()
            
            await MainActor.run {
                self.banners = snapshot.documents.map { doc in
                    Banner(id: doc.documentID, data: doc.data())
                }
            }
        } catch {
            AppLogger.error(AppLogger.firebase, "fetchBannersAsync failed: \(error.localizedDescription)")
        }
    }
    
    func fetchTrendingWallpapersAsync() async {
        do {
            let snapshot: QuerySnapshot
            do {
                snapshot = try await db.collection("TrendingWallpapers")
                    .order(by: "timestamp", descending: true)
                    .limit(to: PaginationUtils.PAGE_SIZE)
                    .getDocuments(source: .cache)
            } catch {
                snapshot = try await db.collection("TrendingWallpapers")
                    .order(by: "timestamp", descending: true)
                    .limit(to: PaginationUtils.PAGE_SIZE)
                    .getDocuments(source: .server)
            }

            let loaded = snapshot.documents.map { Wallpaper(id: $0.documentID, data: $0.data()) }
            await MainActor.run { self.trendingWallpapers = loaded }

            if !loaded.isEmpty {
                WallpaperDiskCache.shared.save(loaded, forKey: WallpaperDiskCache.trendingKey)
            }
        } catch {
            AppLogger.error(AppLogger.firebase, "fetchTrendingWallpapersAsync failed: \(error.localizedDescription)")
        }
    }
    
    private func fetchWallpapers(completion: @escaping () -> Void = {}) {
        db.collection("Samsung")
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    AppLogger.error(AppLogger.firebase, "fetchWallpapers failed: \(error.localizedDescription)")
                    DispatchQueue.main.async { completion() }
                    return
                }

                DispatchQueue.main.async {
                    self.wallpapers = snapshot?.documents.map { doc in
                        Wallpaper(id: doc.documentID, data: doc.data())
                    } ?? []

                    completion()
                }
            }
    }
    
    func fetchBanners(completion: @escaping () -> Void = {}) {
        db.collection("Banners")
            .document("SamsungWallpapers")
            .collection("S25UltraWallpapersBanners")
            .getDocuments { snapshot, error in
                if let error = error {
                    AppLogger.error(AppLogger.firebase, "fetchBanners failed: \(error.localizedDescription)")
                    DispatchQueue.main.async { completion() }
                    return
                }

                DispatchQueue.main.async {
                    self.banners = snapshot?.documents.map { doc in
                        return Banner(id: doc.documentID, data: doc.data())
                    } ?? []

                    completion()
                }
            }
    }
    
    func fetchCategories() {
        db.collection("Categories").getDocuments { snapshot, error in
            if let error = error {
                AppLogger.error(AppLogger.firebase, "fetchCategories failed: \(error.localizedDescription)")
                return
            }
            
            DispatchQueue.main.async {
                self.categories = snapshot?.documents.map { doc in
                    Category(id: doc.documentID, data: doc.data())
                } ?? []
            }
        }
    }
    
    func fetchTrendingWallpapers(limit: Int = 20, completion: @escaping () -> Void = {}) {
        db.collection("TrendingWallpapers")
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments { snapshot, error in
                if let error = error {
                    AppLogger.error(AppLogger.firebase, "fetchTrendingWallpapers failed: \(error.localizedDescription)")
                    DispatchQueue.main.async { completion() }
                    return
                }

                DispatchQueue.main.async {
                    self.trendingWallpapers = snapshot?.documents.map { doc in
                        Wallpaper(id: doc.documentID, data: doc.data())
                    } ?? []
                    completion()
                }
            }
    }
    
    /// Fetches a specific wallpaper by ID from a given collection.
    /// Tries the local Firestore cache first for instant response, then falls back to server.
    func fetchWallpaperById(_ id: String, collection: String) async throws -> Wallpaper {
        let ref = db.collection(collection).document(id)

        // Try cache first — instant if the document was fetched before
        if let cached = try? await ref.getDocument(source: .cache),
           cached.exists,
           let data = cached.data() {
            return Wallpaper(id: cached.documentID, data: data)
        }

        // Cache miss — fetch from server
        let document = try await ref.getDocument(source: .server)

        guard document.exists, let data = document.data() else {
            throw NSError(
                domain: "FirebaseManager",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Wallpaper not found in \(collection)"]
            )
        }

        return Wallpaper(id: document.documentID, data: data)
    }

    func loadPaywallBanners() {
        guard paywallBanners.isEmpty else { return }
        db.collection("PaywallWallpapers").getDocuments { [weak self] snapshot, error in
            guard let documents = snapshot?.documents, error == nil else { return }
            let urls = documents.compactMap { $0.data()["wallpaperUrl"] as? String }
            DispatchQueue.main.async {
                self?.paywallBanners = urls
            }
        }
    }

}
