import SwiftUI

struct CategoriesScreen: View {
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @EnvironmentObject private var tabManager: TabManager
    @Environment(\.appTheme) private var theme
    @StateObject private var themeManager = ThemeManager.shared
    @State private var hasLoaded = false
    @State private var selectedCategory: Category?
    @State private var showCategoryScreen = false
    
    var filteredCategories: [Category] {
        firebaseManager.categories.filter { category in
            // Show all "main" categories and only "Samsung" from "brand" categories
            category.categoryType == "main" || (category.categoryType == "brand" && category.name == "Samsung")
        }
    }
    
    var body: some View {
        NavigationView {
            CustomRefreshView(showsIndicator: false) {
                VStack(spacing: 16) {
                    ForEach(filteredCategories) { category in
                        CategoryCard(category: category)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedCategory = category
                                showCategoryScreen = true
                            }
                    }
                }
                .padding()
            } onRefresh: {
                await refreshCategoriesData()
            }
            .navigationBarHidden(true)
            .background(theme.background.ignoresSafeArea())

        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showCategoryScreen) {
            if let selectedCategory = selectedCategory {
                CategoryScreen(category: selectedCategory)
            }
        }
        .onAppear {
            // Only load categories if this is the active tab
            if tabManager.isTabActive(1) && !hasLoaded {
                firebaseManager.fetchCategories()
                hasLoaded = true
            }
        }
        .onChange(of: tabManager.activeTab) { activeTab in
            if activeTab == 1 && !hasLoaded {
                // Tab became active and hasn't loaded yet
                firebaseManager.fetchCategories()
                hasLoaded = true
            }
        }
    }
    
    @MainActor
    private func refreshCategoriesData() async {
        firebaseManager.fetchCategories()
        
        // Wait a bit for the data to load
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    }
}


