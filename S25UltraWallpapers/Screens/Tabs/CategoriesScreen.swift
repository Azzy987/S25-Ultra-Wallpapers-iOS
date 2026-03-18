import SwiftUI

struct CategoriesScreen: View {
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @Environment(\.appTheme) private var theme
    @StateObject private var themeManager = ThemeManager.shared
    @State private var hasLoaded = false
    @State private var selectedCategory: Category?

    var filteredCategories: [Category] {
        firebaseManager.categories.filter { category in
            category.categoryType == "main" || (category.categoryType == "brand" && category.name == "Samsung")
        }
    }

    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(filteredCategories) { category in
                        Button {
                            selectedCategory = category
                        } label: {
                            CategoryCard(category: category)
                        }
                        .buttonStyle(CategoryCardButtonStyle())
                        .contentShape(RoundedRectangle(cornerRadius: 24))
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                .padding(.bottom, 100) // clear floating tab bar
                .background(
                    ScrollOffsetObserver { offset in
                        TabBarVisibilityManager.shared.updateScrollOffset(offset)
                    }
                )
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
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
}

// Press feedback: subtle opacity change instead of scale to avoid
// "pressed" feeling during tab swipe gestures.
private struct CategoryCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
