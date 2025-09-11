import SwiftUI
import FirebaseFirestore

@MainActor
class CategoryViewModel: ObservableObject {
    let category: Category
    
    @Published var availableSubcategories: [String] = []
    @Published var currentIndex: Int = 0
    
    private var paginators: [String: FirestorePaginator] = [:]
    
    // Series filtering for Samsung categories
    @Published var availableSeries: [String] = []
    @Published var currentSeriesFilter: String? = nil
    
    var allSubcategories: [String] {
        if category.categoryType == "brand" && category.name == "Samsung" {
            // For Samsung with series filter, show series instead of subcategories
            if currentSeriesFilter != nil {
                return ["All Series"] + availableSeries
            } else {
                return ["All"] + availableSubcategories
            }
        } else {
            return ["All"] + availableSubcategories
        }
    }
    
    init(category: Category) {
        self.category = category
        print("🏠 [CATEGORY INIT] Category: \(category.name), Type: \(category.categoryType), Subcategories: \(category.subcategories)")
        loadInitialData()
    }
    
    func paginator(for subcategory: String) -> FirestorePaginator {
        if let existingPaginator = paginators[subcategory] {
            return existingPaginator
        }
        
        // Create paginator on demand if it doesn't exist
        let newPaginator = createPaginator(for: subcategory)
        paginators[subcategory] = newPaginator
        return newPaginator
    }
    
    private func createPaginator(for subcategory: String) -> FirestorePaginator {
        print("🔍 Creating paginator for subcategory: \(subcategory)")
        print("🔍 Current series filter: \(currentSeriesFilter ?? "nil")")
        let query: Query
        
        if subcategory == "All" || subcategory == "All Series" {
            // Check if there's a series filter applied
            if category.categoryType == "brand" && category.name == "Samsung" {
                if let seriesFilter = currentSeriesFilter {
                    // Apply series filter for "All Series"
                    print("🔍 Creating filtered Samsung query for series: \(seriesFilter)")
                    query = FirebaseManager.shared.db.collection("Samsung")
                        .whereField("series", isEqualTo: seriesFilter)
                        .order(by: "timestamp", descending: true)
                } else {
                    // No series filter, show all Samsung wallpapers
                    print("🔍 Creating unfiltered Samsung query")
                    query = FirebaseManager.shared.db.collection("Samsung")
                        .order(by: "timestamp", descending: true)
                }
            } else {
                print("🔍 Creating TrendingWallpapers query")
                query = FirebaseManager.shared.db.collection("TrendingWallpapers")
                    .whereField("category", isEqualTo: category.name)
                    .order(by: "timestamp", descending: true)
            }
        } else {
            // Filter by subcategory
            if category.categoryType == "brand" && category.name == "Samsung" {
                print("🔍 Creating Samsung subcategory query for: \(subcategory)")
                query = FirebaseManager.shared.db.collection("Samsung")
                    .whereField("series", isEqualTo: subcategory)
                    .order(by: "timestamp", descending: true)
            } else {
                print("🔍 Creating TrendingWallpapers subcategory query")
                query = FirebaseManager.shared.db.collection("TrendingWallpapers")
                    .whereField("category", isEqualTo: category.name)
                    .whereField("subCategory", isEqualTo: subcategory)
                    .order(by: "timestamp", descending: true)
            }
        }
        
        let paginator = FirestorePaginator(baseQuery: query)
        
        print("📎 [PAGINATOR] Created paginator for \(subcategory), loading initial wallpapers...")
        // Load initial data immediately
        paginator.loadInitialWallpapers()
        
        return paginator
    }
    
    private func loadInitialData() {
        print("📊 [LOAD DATA] Loading initial data for category: \(category.name)")
        // Load subcategories based on category type
        if category.categoryType == "brand" && category.name == "Samsung" {
            print("📊 [LOAD DATA] Loading Samsung series data")
            // For Samsung, get series from Samsung collection
            loadSamsungSeries()
        } else {
            print("📊 [LOAD DATA] Setting up main category subcategories")
            // For main categories, use subcategories from category object
            setupMainCategorySubcategories()
        }
    }
    
    private func setupMainCategorySubcategories() {
        print("📋 [SUBCATEGORIES] Setting up subcategories for \(category.name): \(category.subcategories)")
        // Filter out "None" subcategories
        let filteredSubcategories = category.subcategories.filter { $0.lowercased() != "none" }
        
        print("📋 [SUBCATEGORIES] Filtered subcategories: \(filteredSubcategories)")
        
        if !filteredSubcategories.isEmpty {
            availableSubcategories = filteredSubcategories
            print("📋 [SUBCATEGORIES] Set available subcategories: \(availableSubcategories)")
        } else {
            print("⚠️ [SUBCATEGORIES] No valid subcategories found!")
        }
    }
    
    private func loadSamsungSeries() {
        FirebaseManager.shared.db.collection("Samsung")
            .getDocuments { [weak self] snapshot, error in
                if let documents = snapshot?.documents {
                    let seriesSet = Set(documents.compactMap { $0.data()["series"] as? String })
                    let sortedSeries = Array(seriesSet).sorted()
                    DispatchQueue.main.async {
                        self?.availableSubcategories = sortedSeries
                        self?.availableSeries = sortedSeries
                    }
                }
            }
    }
    
    func applySeriesFilter(_ series: String?) {
        print("🔍 Applying series filter: \(series ?? "nil")")
        
        // Update the filter first
        currentSeriesFilter = series
        
        // Clear existing paginators to force recreation with new filter
        paginators.removeAll()
        print("🔍 Cleared paginators")
        
        // Set the correct index based on the selected series
        if let series = series {
            // Find the series in the list and set the correct index
            if let seriesIndex = availableSeries.firstIndex(of: series) {
                // Set to the specific series (add 1 because "All Series" is at index 0)
                currentIndex = seriesIndex + 1
                print("🔍 Set currentIndex to \(currentIndex) for series: \(series)")
            } else {
                // Series not found, default to "All Series"
                currentIndex = 0
                print("🔍 Series '\(series)' not found, reset to index 0")
            }
        } else {
            // No filter selected, go to "All" or "All Series"
            currentIndex = 0
            print("🔍 No series filter, reset to index 0")
        }
        
        // Force UI refresh since allSubcategories computed property changed
        objectWillChange.send()
        
        // Force immediate recreation and loading of the appropriate paginator
        let subcategory = allSubcategories[currentIndex]
        let newPaginator = paginator(for: subcategory)
        print("🔍 Created new paginator for '\(subcategory)' with \(newPaginator.wallpapers.count) wallpapers loaded")
    }
    
    // Helper function to clear series filter and return to normal subcategories
    func clearSeriesFilter() {
        currentSeriesFilter = nil
        paginators.removeAll()
        currentIndex = 0
        objectWillChange.send()
    }
}