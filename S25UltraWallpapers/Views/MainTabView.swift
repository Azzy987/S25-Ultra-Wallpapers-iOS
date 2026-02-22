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
    @StateObject private var userManager = UserManager.shared
    @StateObject private var toastManager = ToastManager.shared
    @State private var dragOffset: CGFloat = 0
    @StateObject private var bannerDragState = BannerDragState.shared
    
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
                        // Profile button (left) - shows user photo when signed in
                        Button {
                            showSettings = true
                        } label: {
                            if userManager.isSignedIn, let profileImageURL = userManager.profileImageURL,
                               let url = URL(string: profileImageURL) {
                                // Show actual user profile picture
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 32, height: 32)
                                        .clipShape(Circle())
                                } placeholder: {
                                    Image(systemName: "person.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(theme.onSurface)
                                }
                            } else {
                                // Show default icon when not signed in or no profile picture
                                Image(systemName: userManager.isSignedIn ? "person.circle.fill" : "person.circle")
                                    .font(.title2)
                                    .foregroundColor(theme.onSurface)
                            }
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
                    
                    // Tab Bar with Liquid Glass
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
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 30)
                                .onChanged { value in
                                    // Don't drag tabs while banner carousel is being swiped
                                    guard !bannerDragState.isDragging else { return }

                                    let horizontalAmount = abs(value.translation.width)
                                    let verticalAmount = abs(value.translation.height)

                                    // Only track clearly horizontal drags (2x horizontal vs vertical)
                                    if horizontalAmount > verticalAmount * 2 && horizontalAmount > 30 {
                                        dragOffset = value.translation.width
                                    }
                                }
                                .onEnded { value in
                                    // Don't switch tabs if banner was being dragged
                                    guard !bannerDragState.isDragging else {
                                        dragOffset = 0
                                        return
                                    }

                                    let horizontalAmount = abs(value.translation.width)
                                    let verticalAmount = abs(value.translation.height)

                                    // Only process as tab navigation if clearly horizontal (2x ratio)
                                    if horizontalAmount > verticalAmount * 2 && horizontalAmount > 50 {
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
                                        // Snap back for non-qualifying drags
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                            dragOffset = 0
                                        }
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
        .overlay(alignment: .bottom) {
            if toastManager.showToast {
                ToastView(
                    message: toastManager.toastMessage,
                    type: toastManager.toastType,
                    isPresented: $toastManager.showToast
                )
            }
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
                    .font(.system(size: 20, weight: .medium))
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(selectedTab == tag ? theme.primary : theme.onSurface)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .modifier(TabButtonGlassModifier(isSelected: selectedTab == tag))
    }
}

struct TabButtonGlassModifier: ViewModifier {
    let isSelected: Bool
    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        if isSelected {
            if #available(iOS 26.0, *) {
                content.glassEffect(.regular.tint(theme.primary.opacity(0.2)).interactive(), in: RoundedRectangle(cornerRadius: 16))
            } else {
                content
                    .background(theme.primary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        } else {
            content
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

// Shared state to block tab swipe while banner is being dragged
class BannerDragState: ObservableObject {
    static let shared = BannerDragState()
    @Published var isDragging = false
    private init() {}
}

// Shared state for TrendingScreen sort functionality
class TrendingScreenState: ObservableObject {
    static let shared = TrendingScreenState()
    @Published var showSortSheet = false
    private init() {}
} 
