import SwiftUI
import Firebase

class PaginationUtils {
    static let shared = PaginationUtils()
    static let PAGE_SIZE = 20 // Set to 20 wallpapers per page
    static let LOAD_THRESHOLD = 5 // Load more when 5 items from the end (optimized)
    
    private init() {}
    
    func shouldLoadMore(
        currentIndex: Int,
        itemCount: Int,
        isLoading: Bool,
        hasReachedEnd: Bool
    ) -> Bool {
        return !isLoading && 
               !hasReachedEnd && 
               itemCount > 0 &&
               currentIndex >= itemCount - Self.LOAD_THRESHOLD
    }
}

class FirestorePaginator: ObservableObject {
    private var lastDocument: DocumentSnapshot?
    private var hasMoreData = true
    private var baseQuery: Query
    private let pageSize: Int
    
    // Performance optimization: track loading state and prevent duplicate requests
    private var lastRequestTime: Date = Date.distantPast
    private let minRequestInterval: TimeInterval = 0.5 // Minimum 0.5 seconds between requests
    
    @Published var wallpapers: [Wallpaper] = []
    @Published var isLoading = false
    @Published var hasReachedEnd = false
    @Published var errorMessage: String?
    
    init(baseQuery: Query, pageSize: Int = PaginationUtils.PAGE_SIZE) {
        self.baseQuery = baseQuery
        self.pageSize = pageSize
    }
    
    func updateQuery(_ newQuery: Query) {
        self.baseQuery = newQuery
        // Reset pagination state
        self.lastDocument = nil
        self.hasMoreData = true
        self.hasReachedEnd = false
        self.wallpapers = []
        self.errorMessage = nil
    }
    
    func setInitialWallpapers(_ wallpapers: [Wallpaper]) {
        self.wallpapers = wallpapers
        self.hasMoreData = false
        self.hasReachedEnd = true
    }
    
    func loadInitialWallpapers() {
        guard !isLoading else { return }
        
        // Rate limiting to prevent too frequent requests
        let now = Date()
        guard now.timeIntervalSince(lastRequestTime) >= minRequestInterval else { return }
        lastRequestTime = now
        
        isLoading = true
        wallpapers = []
        lastDocument = nil
        hasMoreData = true
        hasReachedEnd = false
        errorMessage = nil
        
        baseQuery
            .limit(to: pageSize)
            .getDocuments(source: .default) { [weak self] snapshot, error in // Use cache-first strategy
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        print("FirestorePaginator ERROR: \(error)")
                        print("FirestorePaginator ERROR: Query failed with error description: \(error.localizedDescription)")
                        self.errorMessage = "Failed to load wallpapers. Please try again."
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("FirestorePaginator DEBUG: No documents returned from query")
                        self.errorMessage = "No wallpapers found."
                        return
                    }
                    
                    print("FirestorePaginator DEBUG: Successfully loaded \(documents.count) documents")
                    self.wallpapers = documents.map { Wallpaper(id: $0.documentID, data: $0.data()) }
                    print("FirestorePaginator DEBUG: Converted to \(self.wallpapers.count) wallpapers")
                    self.lastDocument = documents.last
                    self.hasMoreData = documents.count == self.pageSize
                    
                    if !self.hasMoreData {
                        self.hasReachedEnd = true
                    }
                }
            }
    }
    
    func loadMoreWallpapers() {
        guard !isLoading, hasMoreData, let lastDocument = lastDocument else { return }
        
        // Rate limiting to prevent too frequent requests
        let now = Date()
        guard now.timeIntervalSince(lastRequestTime) >= minRequestInterval else { return }
        lastRequestTime = now
        
        isLoading = true
        errorMessage = nil
        
        baseQuery
            .start(afterDocument: lastDocument)
            .limit(to: pageSize)
            .getDocuments(source: .default) { [weak self] snapshot, error in // Use cache-first strategy
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        print("Error loading more wallpapers: \(error)")
                        self.errorMessage = "Failed to load more wallpapers."
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self.hasReachedEnd = true
                        return
                    }
                    
                    let newWallpapers = documents.map { Wallpaper(id: $0.documentID, data: $0.data()) }
                    
                    // Avoid duplicate wallpapers
                    let existingIds = Set(self.wallpapers.map { $0.id })
                    let uniqueNewWallpapers = newWallpapers.filter { !existingIds.contains($0.id) }
                    
                    self.wallpapers.append(contentsOf: uniqueNewWallpapers)
                    self.lastDocument = documents.last
                    self.hasMoreData = documents.count == self.pageSize
                    self.hasReachedEnd = !self.hasMoreData
                }
            }
    }
    
    func retry() {
        if wallpapers.isEmpty {
            loadInitialWallpapers()
        } else {
            loadMoreWallpapers()
        }
    }
} 
