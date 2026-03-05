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
        loadInitialData()
    }
    
    func paginator(for subcategory: String) -> FirestorePaginator {
        if let existingPaginator = paginators[subcategory] {
            return existingPaginator
        }
        let newPaginator = createPaginator(for: subcategory)
        paginators[subcategory] = newPaginator
        return newPaginator
    }

    /// Returns the paginator for the given subcategory, triggering initial load if not yet loaded.
    func loadPaginator(for subcategory: String) {
        let p = paginator(for: subcategory)
        if p.wallpapers.isEmpty && !p.isLoading {
            p.loadInitialWallpapers()
        }
    }
    
    private func createPaginator(for subcategory: String) -> FirestorePaginator {
        let query: Query
        let db = FirebaseManager.shared.db

        if subcategory == "All" || subcategory == "All Series" {
            if category.categoryType == "brand" && category.name == "Samsung" {
                if let seriesFilter = currentSeriesFilter {
                    // Single whereField — no composite index needed
                    query = db.collection("Samsung")
                        .whereField("series", isEqualTo: seriesFilter)
                } else {
                    // Single orderBy on timestamp — single-field index exists by default
                    query = db.collection("Samsung")
                        .order(by: "timestamp", descending: true)
                }
            } else {
                // Non-Samsung categories live in TrendingWallpapers collection
                // Single whereField — no composite index needed
                query = db.collection("TrendingWallpapers")
                    .whereField("category", isEqualTo: category.name)
            }
        } else {
            if category.categoryType == "brand" && category.name == "Samsung" {
                // Single whereField — no composite index needed
                query = db.collection("Samsung")
                    .whereField("series", isEqualTo: subcategory)
            } else {
                // Two whereFields — no orderBy, so no composite index needed
                query = db.collection("TrendingWallpapers")
                    .whereField("category", isEqualTo: category.name)
                    .whereField("subCategory", isEqualTo: subcategory)
            }
        }

        return FirestorePaginator(baseQuery: query)
    }
    
    private func loadInitialData() {
        if category.categoryType == "brand" && category.name == "Samsung" {
            loadSamsungSeries()
        } else {
            setupMainCategorySubcategories()
        }
    }

    private func setupMainCategorySubcategories() {
        let filteredSubcategories = category.subcategories.filter { $0.lowercased() != "none" }
        if !filteredSubcategories.isEmpty {
            availableSubcategories = filteredSubcategories
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
        currentSeriesFilter = series
        paginators.removeAll()

        if let series = series, let seriesIndex = availableSeries.firstIndex(of: series) {
            currentIndex = seriesIndex + 1
        } else {
            currentIndex = 0
        }

        objectWillChange.send()
        loadPaginator(for: allSubcategories[currentIndex])
    }
    
    // Helper function to clear series filter and return to normal subcategories
    func clearSeriesFilter() {
        currentSeriesFilter = nil
        paginators.removeAll()
        currentIndex = 0
        objectWillChange.send()
    }
}