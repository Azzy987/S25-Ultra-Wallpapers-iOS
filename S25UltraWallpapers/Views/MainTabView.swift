import SwiftUI

// Central tab manager for controlling active tab loading
class TabManager: ObservableObject {
    static let shared = TabManager()
    @Published var activeTab: Int = 0
    private init() {}
    
    func setActiveTab(_ tab: Int) {
        activeTab = tab
    }
    
    func isTabActive(_ tab: Int) -> Bool {
        return activeTab == tab
    }
}

struct MainTabView: View {
    @Environment(\.appTheme) private var theme
    @State private var selectedTab = 0
    @State private var showSettings = false
    @StateObject private var tabManager = TabManager.shared
    @State private var dragOffset: CGFloat = 0
    
    // Calculate the display index for circular navigation
    private func getDisplayIndex() -> Int {
        // We have extra tabs at index -1 (Favorites) and index 4 (Home)
        // The actual tabs are at indices 0, 1, 2, 3 but positioned at 1, 2, 3, 4 in the HStack
        return selectedTab + 1
    }

    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Top App Bar - Fixed layout with consistent centering
                VStack(spacing: 0) {
                    HStack {
                        // Profile button (left)
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "person.circle")
                                .font(.title2)
                                .foregroundColor(theme.onSurface)
                        }
                        .frame(width: 44, height: 44) // Fixed frame for consistent layout
                        
                        Spacer()
                        
                        // Centered title - always centered regardless of tab
                        Text("S25 Ultra Wallpapers")
                            .font(.title3.bold())
                            .foregroundColor(theme.onSurface)
                        
                        Spacer()
                        
                        // Sort button for Home and Trending tabs (right side)
                        Group {
                            if selectedTab == 0 {
                                SortButtonForHome()
                            } else if selectedTab == 2 {
                                SortButtonForTrending()
                            } else {
                                // Empty placeholder to maintain layout balance
                                Color.clear
                                    .frame(width: 44, height: 44)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(theme.background)
                    
                    // Tab Bar
                    HStack(spacing: 32) {
                        TabButton(title: "Home", icon: "house", selectedTab: $selectedTab, tag: 0, dragOffset: $dragOffset)
                        TabButton(title: "Categories", icon: "square.grid.2x2", selectedTab: $selectedTab, tag: 1, dragOffset: $dragOffset)
                        TabButton(title: "Trending", icon: "flame", selectedTab: $selectedTab, tag: 2, dragOffset: $dragOffset)
                        TabButton(title: "Favorites", icon: "heart", selectedTab: $selectedTab, tag: 3, dragOffset: $dragOffset)
                    }
                    .padding(.vertical, 8)
                    .background(theme.background)
                    
                    Divider()
                        .background(theme.surfaceVariant)
                }
                    
                    // Content with circular tab navigation
                    GeometryReader { geometry in
                        let screenWidth = geometry.size.width
                        
                        HStack(spacing: 0) {
                            // Add extra tab at the beginning for circular navigation (Favorites)
                            FavoritesScreenContent()
                                .frame(width: screenWidth, height: geometry.size.height)
                                .background(theme.background)
                                .clipped()
                                .tag(-1)
                            
                            HomeScreenContent()
                                .frame(width: screenWidth, height: geometry.size.height)
                                .background(theme.background)
                                .clipped()
                                .tag(0)
                            
                            CategoriesScreenContent()
                                .frame(width: screenWidth, height: geometry.size.height)
                                .background(theme.background)
                                .clipped()
                                .tag(1)
                                
                            TrendingScreenContent()
                                .frame(width: screenWidth, height: geometry.size.height)
                                .background(theme.background)
                                .clipped()
                                .tag(2)
                                
                            FavoritesScreenContent()
                                .frame(width: screenWidth, height: geometry.size.height)
                                .background(theme.background)
                                .clipped()
                                .tag(3)
                                
                            // Add extra tab at the end for circular navigation (Home)
                            HomeScreenContent()
                                .frame(width: screenWidth, height: geometry.size.height)
                                .background(theme.background)
                                .clipped()
                                .tag(4)
                        }
                        .offset(x: -CGFloat(getDisplayIndex()) * screenWidth + dragOffset)
                        .animation(.none, value: dragOffset) // Disable animation during drag
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    // Only respond to primarily horizontal drags
                                    let horizontalAmount = abs(value.translation.width)
                                    let verticalAmount = abs(value.translation.height)
                                    
                                    // If drag is more vertical than horizontal, ignore it for tab navigation
                                    if horizontalAmount > verticalAmount && horizontalAmount > 20 {
                                        dragOffset = value.translation.width
                                    }
                                }
                                .onEnded { value in
                                    let horizontalAmount = abs(value.translation.width)
                                    let verticalAmount = abs(value.translation.height)
                                    
                                    // Only process as tab navigation if primarily horizontal
                                    if horizontalAmount > verticalAmount && horizontalAmount > 30 {
                                        let threshold = screenWidth / 3
                                        var newTab = selectedTab
                                        
                                        if value.translation.width < -threshold { // Swiped left
                                            newTab = selectedTab + 1
                                            if newTab > 3 {
                                                newTab = 0 // Circular: Favorites -> Home
                                            }
                                        } else if value.translation.width > threshold { // Swiped right
                                            newTab = selectedTab - 1
                                            if newTab < 0 {
                                                newTab = 3 // Circular: Home -> Favorites
                                            }
                                        }
                                        
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            selectedTab = newTab
                                            dragOffset = 0
                                        }
                                    } else {
                                        // Reset drag offset for non-horizontal drags
                                        dragOffset = 0
                                    }
                                }
                        )
                    }
            }
            .background(theme.background.ignoresSafeArea())
            .onChange(of: selectedTab) { newTab in
                tabManager.setActiveTab(newTab)
            }
            .onAppear {
                tabManager.setActiveTab(selectedTab)
            }
        }
        .navigationViewStyle(.stack)
        .navigationBarBackButtonHidden(false)
        .fullScreenCover(isPresented: $showSettings) {
            SettingsScreen()
        }
    }
}

// Sort button for Home screen
struct SortButtonForHome: View {
    @Environment(\.appTheme) private var theme
    @StateObject private var homeScreenState = HomeScreenState.shared
    
    var body: some View {
        Button {
            homeScreenState.showSortSheet = true
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.title2)
                .foregroundColor(theme.onSurface)
        }
        .frame(width: 44, height: 44)
    }
}

// Sort button for Trending screen
struct SortButtonForTrending: View {
    @Environment(\.appTheme) private var theme
    @StateObject private var trendingScreenState = TrendingScreenState.shared
    
    var body: some View {
        Button {
            trendingScreenState.showSortSheet = true
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.title2)
                .foregroundColor(theme.onSurface)
        }
        .frame(width: 44, height: 44)
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    @Binding var selectedTab: Int
    let tag: Int
    @Binding var dragOffset: CGFloat
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedTab = tag
                dragOffset = 0
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: selectedTab == tag ? "\(icon).fill" : icon)
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(selectedTab == tag ? theme.primary : theme.onSurface)
        }
    }
}

// HomeScreen wrapper that can access the sort state and tab manager
struct HomeScreenContent: View {
    var body: some View {
        HomeScreen()
            .environmentObject(HomeScreenState.shared)
            .environmentObject(TabManager.shared)
    }
}

// CategoriesScreen wrapper with tab manager
struct CategoriesScreenContent: View {
    var body: some View {
        CategoriesScreen()
            .environmentObject(TabManager.shared)
    }
}

// TrendingScreen wrapper that can access the sort state and tab manager
struct TrendingScreenContent: View {
    var body: some View {
        TrendingScreen()
            .environmentObject(TrendingScreenState.shared)
            .environmentObject(TabManager.shared)
    }
}

// FavoritesScreen wrapper with tab manager
struct FavoritesScreenContent: View {
    var body: some View {
        FavoritesScreen()
            .environmentObject(TabManager.shared)
    }
}

// Shared state for HomeScreen sort functionality
class HomeScreenState: ObservableObject {
    static let shared = HomeScreenState()
    @Published var showSortSheet = false
    private init() {}
}

// Shared state for TrendingScreen sort functionality
class TrendingScreenState: ObservableObject {
    static let shared = TrendingScreenState()
    @Published var showSortSheet = false
    private init() {}
} 
