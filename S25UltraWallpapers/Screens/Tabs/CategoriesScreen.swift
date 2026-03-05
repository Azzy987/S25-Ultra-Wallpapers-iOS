import SwiftUI

struct CategoriesScreen: View {
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @Environment(\.appTheme) private var theme
    @StateObject private var themeManager = ThemeManager.shared
    @State private var hasLoaded = false
    @State private var selectedCategory: Category?
    
    var filteredCategories: [Category] {
        firebaseManager.categories.filter { category in
            // Show all "main" categories and only "Samsung" from "brand" categories
            category.categoryType == "main" || (category.categoryType == "brand" && category.name == "Samsung")
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(filteredCategories) { category in
                        CategoryCard(category: category)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedCategory = category
                            }
                    }
                }
                .padding()
            }
            .refreshable {
                await refreshCategoriesData()
            }
            .navigationBarHidden(true)
            .background(theme.background.ignoresSafeArea())

        }
        .navigationViewStyle(.stack)
        .fullScreenCover(item: $selectedCategory) { category in
            CategoryScreen(category: category)
        }
        .onAppear {
            if !hasLoaded {
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


