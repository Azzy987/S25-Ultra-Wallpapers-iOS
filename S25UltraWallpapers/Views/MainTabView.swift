import SwiftUI

// MARK: - Tab Swipe Active Environment Key
// Used to suppress button press effects during tab swipe gestures

private struct TabSwipeActiveKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var isTabSwipeActive: Bool {
        get { self[TabSwipeActiveKey.self] }
        set { self[TabSwipeActiveKey.self] = newValue }
    }
}

// MARK: - Tab Manager

class TabManager: ObservableObject {
    static let shared = TabManager()
    @Published var activeTab: Int = 0
    private init() {}

    func setActiveTab(_ tab: Int) { activeTab = tab }
    func isTabActive(_ tab: Int) -> Bool { activeTab == tab }
}

// MARK: - Tab Bar Visibility Manager

class TabBarVisibilityManager: ObservableObject {
    static let shared = TabBarVisibilityManager()
    @Published var isVisible: Bool = true
    private var lastOffset: CGFloat = 0
    private var hasInitialOffset = false
    /// Accumulates small deltas before triggering show/hide
    private var accumulatedDelta: CGFloat = 0
    /// Debounce timer to prevent rapid show/hide toggling
    private var debounceWorkItem: DispatchWorkItem?
    private init() {}

    func updateScrollOffset(_ offset: CGFloat) {
        // First offset from a new scroll view — just store it, don't act
        if !hasInitialOffset {
            lastOffset = offset
            hasInitialOffset = true
            return
        }

        let delta = offset - lastOffset
        lastOffset = offset

        // Ignore large jumps (tab switches, first report, content reload)
        guard abs(delta) < 100 else {
            accumulatedDelta = 0
            return
        }

        // Ignore tiny jitter
        guard abs(delta) > 0.5 else { return }

        // Accumulate delta in the same direction; reset on direction change
        if (accumulatedDelta > 0 && delta < 0) || (accumulatedDelta < 0 && delta > 0) {
            accumulatedDelta = delta
        } else {
            accumulatedDelta += delta
        }

        // Near the top — always show
        if offset > -20 {
            accumulatedDelta = 0
            setVisible(true)
            return
        }

        // Require substantial accumulated scroll before toggling
        if accumulatedDelta < -100 {
            setVisible(false)
            accumulatedDelta = 0
        } else if accumulatedDelta > 60 {
            setVisible(true)
            accumulatedDelta = 0
        }
    }

    func resetForTabSwitch() {
        lastOffset = 0
        hasInitialOffset = false
        accumulatedDelta = 0
        debounceWorkItem?.cancel()
        show()
    }

    func show() { setVisible(true) }

    private func setVisible(_ visible: Bool) {
        guard isVisible != visible else { return }
        // Cancel any pending toggle
        debounceWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self = self, self.isVisible != visible else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { self.isVisible = visible }
        }
        debounceWorkItem = work
        // Small debounce to prevent rapid toggling
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: work)
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @Environment(\.appTheme) private var theme
    @State private var selectedTab = 0
    @State private var showSettings = false
    @StateObject private var tabManager = TabManager.shared
    @StateObject private var userManager = UserManager.shared
    @StateObject private var toastManager = ToastManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var tabBarVisibility = TabBarVisibilityManager.shared
    @StateObject private var bannerDragState = BannerDragState.shared

    // Drag state
    @State private var dragOffset: CGFloat = 0
    @State private var dragConfirmed = false
    // Track if any touch is down to suppress button press effects
    @State private var touchDown = false

    private var neighborTab: Int? {
        guard dragOffset != 0 else { return nil }
        return dragOffset < 0 ? (selectedTab + 1) % 4 : (selectedTab - 1 + 4) % 4
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ── Top App Bar ─────────────────────────────────────────
                HStack {
                    Button { showSettings = true } label: {
                        if userManager.isSignedIn,
                           let urlStr = userManager.profileImageURL,
                           let url = URL(string: urlStr) {
                            AsyncImage(url: url) { image in
                                image.resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 32, height: 32)
                                    .clipShape(Circle())
                            } placeholder: {
                                Image(systemName: "person.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(theme.onSurface)
                            }
                        } else {
                            Image(systemName: userManager.isSignedIn ? "person.circle.fill" : "person.circle")
                                .font(.title2)
                                .foregroundColor(theme.onSurface)
                        }
                    }
                    .frame(width: 44, height: 44)

                    Spacer()

                    Text("S25 Ultra Wallpapers")
                        .font(.title3.bold())
                        .foregroundColor(theme.onSurface)

                    Spacer()

                    Color.clear.frame(width: 44, height: 44) // balance
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(theme.background)

                Divider().background(theme.surfaceVariant)

                // ── Tab Content ─────────────────────────────────────────
                GeometryReader { geo in
                    let sw = geo.size.width
                    let progress = sw > 0 ? min(abs(dragOffset) / sw, 1.0) : 0

                    ZStack {
                        // All tabs kept alive; only the active one is interactive
                        Group {
                            HomeScreenContent()
                                .frame(width: sw, height: geo.size.height)
                                .opacity(selectedTab == 0 ? 1 : 0)
                                .allowsHitTesting(selectedTab == 0 && !dragConfirmed)
                            CategoriesScreenContent()
                                .frame(width: sw, height: geo.size.height)
                                .opacity(selectedTab == 1 ? 1 : 0)
                                .allowsHitTesting(selectedTab == 1 && !dragConfirmed)
                            TrendingScreenContent()
                                .frame(width: sw, height: geo.size.height)
                                .opacity(selectedTab == 2 ? 1 : 0)
                                .allowsHitTesting(selectedTab == 2 && !dragConfirmed)
                            FavoritesScreenContent()
                                .frame(width: sw, height: geo.size.height)
                                .opacity(selectedTab == 3 ? 1 : 0)
                                .allowsHitTesting(selectedTab == 3 && !dragConfirmed)
                        }
                        // Pass drag/touch state to children so button styles can suppress press effects.
                        // touchDown becomes true the instant a finger touches, BEFORE dragConfirmed.
                        .environment(\.isTabSwipeActive, touchDown || dragConfirmed)
                        // Parallax: active content slides at 30% of drag speed
                        .offset(x: dragOffset * 0.3)

                        // Neighbor slides in from the edge at 100% of drag speed
                        if let neighbor = neighborTab, dragConfirmed {
                            neighborView(for: neighbor)
                                .frame(width: sw, height: geo.size.height)
                                .offset(x: dragOffset < 0
                                    ? sw + dragOffset
                                    : -sw + dragOffset)
                                .opacity(progress)
                                .allowsHitTesting(false)
                                .clipped()
                        }
                    }
                    .clipped()
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 8)
                            .onChanged { value in
                                // Mark touch as down immediately
                                if !touchDown { touchDown = true }

                                guard !bannerDragState.isDragging else { return }
                                let h = abs(value.translation.width)
                                let v = abs(value.translation.height)

                                if !dragConfirmed {
                                    // Must be clearly horizontal
                                    guard h > v * 1.3, h > 12 else { return }
                                    dragConfirmed = true
                                }
                                if dragConfirmed {
                                    dragOffset = value.translation.width
                                }
                            }
                            .onEnded { value in
                                touchDown = false
                                let wasConfirmed = dragConfirmed

                                guard wasConfirmed, !bannerDragState.isDragging else {
                                    dragOffset = 0
                                    dragConfirmed = false
                                    return
                                }

                                let threshold = sw / 3
                                var newTab = selectedTab
                                if value.translation.width < -threshold {
                                    newTab = (selectedTab + 1) % 4
                                } else if value.translation.width > threshold {
                                    newTab = (selectedTab - 1 + 4) % 4
                                }

                                withAnimation(.spring(response: 0.32, dampingFraction: 0.76)) {
                                    dragOffset = 0
                                    if newTab != selectedTab {
                                        selectedTab = newTab
                                    }
                                }
                                dragConfirmed = false

                                if newTab != selectedTab {
                                    TabBarVisibilityManager.shared.show()
                                }
                            }
                    )
                }
            }
            .background(theme.background.ignoresSafeArea())
            .onChange(of: selectedTab) { newTab in
                tabManager.setActiveTab(newTab)
                TabBarVisibilityManager.shared.resetForTabSwitch()
            }
            .onAppear {
                tabManager.setActiveTab(selectedTab)
            }
        }
        .navigationViewStyle(.stack)
        .navigationBarBackButtonHidden(false)
        .fullScreenCover(isPresented: $showSettings) {
            SettingsScreen()
                .environment(\.appTheme, themeManager.theme)
        }
        // ── Floating tab bar + sort accessory ───────────────────────
        .overlay(alignment: .bottom) {
            FloatingTabBarRow(selectedTab: $selectedTab, dragOffset: $dragOffset)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .offset(y: tabBarVisibility.isVisible ? 0 : 140)
                .animation(.spring(response: 0.35, dampingFraction: 0.82), value: tabBarVisibility.isVisible)
        }
        // ── Scroll to top (only when tab bar is hidden) ─────────────
        .overlay(alignment: .bottomTrailing) {
            if !tabBarVisibility.isVisible {
                ScrollToTopFloatingButton()
                    .padding(.trailing, 20)
                    .padding(.bottom, 28)
                    .transition(.scale(scale: 0.6).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: tabBarVisibility.isVisible)
        // ── Toast ────────────────────────────────────────────────────
        .overlay(alignment: .bottom) {
            if toastManager.showToast {
                ToastView(
                    message: toastManager.toastMessage,
                    type: toastManager.toastType,
                    isPresented: $toastManager.showToast
                )
                .padding(.bottom, 100)
            }
        }
    }

    @ViewBuilder
    private func neighborView(for tab: Int) -> some View {
        switch tab {
        case 0: HomeScreenContent()
        case 1: CategoriesScreenContent()
        case 2: TrendingScreenContent()
        case 3: FavoritesScreenContent()
        default: EmptyView()
        }
    }
}

// MARK: - Scroll To Top Floating Button (matches tab bar style)

struct ScrollToTopFloatingButton: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            // Fire the scroll-to-top — the tab bar will auto-show once
            // the scroll view reaches the top (detected by ScrollOffsetObserver)
            ScrollToTopNotifier.shared.scrollToTop()
        } label: {
            Image(systemName: "arrow.up")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .frame(width: 52, height: 52)
                .background {
                    if #available(iOS 26.0, *) {
                        Circle()
                            .fill(Color.clear)
                            .glassEffect(.regular, in: Circle())
                    } else {
                        Circle()
                            .fill(colorScheme == .dark
                                  ? Color.white.opacity(0.22)
                                  : Color.black.opacity(0.08))
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                            )
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 4)
                            .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                    }
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

/// Shared notifier so MainTabView's scroll-to-top button can trigger
/// scrolling in whichever tab is currently active.
class ScrollToTopNotifier: ObservableObject {
    static let shared = ScrollToTopNotifier()
    @Published var trigger = false
    private init() {}

    func scrollToTop() {
        trigger.toggle()
    }
}

// MARK: - Floating Tab Bar Row (pill + optional sort button)

struct FloatingTabBarRow: View {
    @Binding var selectedTab: Int
    @Binding var dragOffset: CGFloat

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            FloatingTabBar(selectedTab: $selectedTab, dragOffset: $dragOffset)

            if selectedTab == 0 || selectedTab == 2 {
                SortAccessoryButton(selectedTab: selectedTab)
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.72), value: selectedTab)
    }
}

// MARK: - Floating Tab Bar Pill
// Uses a semi-transparent solid color + ultraThinMaterial combo
// to ensure visibility on both light AND dark wallpaper backgrounds.

struct FloatingTabBar: View {
    @Binding var selectedTab: Int
    @Binding var dragOffset: CGFloat
    @Environment(\.appTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    private let tabs: [(title: String, icon: String)] = [
        ("Home",       "house"),
        ("Categories", "square.grid.2x2"),
        ("Trending",   "flame"),
        ("Favorites",  "heart")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                FloatingTabButton(
                    title: tabs[index].title,
                    icon:  tabs[index].icon,
                    tag:   index,
                    selectedTab: $selectedTab,
                    dragOffset:  $dragOffset
                )
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
        .contentShape(Capsule())
        .background {
            if #available(iOS 26.0, *) {
                Capsule()
                    .fill(Color.clear)
                    .glassEffect(.regular, in: Capsule())
            } else {
                // Layer: solid tinted base + blur material on top = always visible
                ZStack {
                    Capsule()
                        .fill(colorScheme == .dark
                              ? Color.white.opacity(0.18)
                              : Color.black.opacity(0.06))
                    Capsule()
                        .fill(.ultraThinMaterial)
                }
                .shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 4)
                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
            }
        }
    }
}

// MARK: - Floating Tab Button
// Unselected → icon only.  Selected → expanding pill with icon + label.

struct FloatingTabButton: View {
    let title: String
    let icon: String
    let tag: Int
    @Binding var selectedTab: Int
    @Binding var dragOffset: CGFloat
    @Environment(\.appTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    private var proximity: CGFloat {
        let sw = UIScreen.main.bounds.width
        guard sw > 0 else { return selectedTab == tag ? 1.0 : 0.0 }
        let virtual = CGFloat(selectedTab) - (dragOffset / sw)
        return max(0, 1.0 - abs(virtual - CGFloat(tag)))
    }

    private var isSelected: Bool { proximity > 0.5 }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.76)) {
                selectedTab = tag
                dragOffset = 0
            }
            TabBarVisibilityManager.shared.show()
        } label: {
            HStack(spacing: 6) {
                ZStack {
                    Image(systemName: icon)
                        .opacity(isSelected ? 0 : 1)
                    Image(systemName: "\(icon).fill")
                        .opacity(isSelected ? 1 : 0)
                }
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(isSelected ? theme.primary : (colorScheme == .dark ? .white.opacity(0.8) : theme.onSurfaceVariant))

                if isSelected {
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(theme.primary)
                        .fixedSize()
                        .transition(.opacity.combined(with: .scale(scale: 0.75, anchor: .leading)))
                }
            }
            .padding(.horizontal, isSelected ? 14 : 12)
            .padding(.vertical, 10)
            .contentShape(Capsule())
            .background {
                if isSelected {
                    Capsule().fill(theme.primary.opacity(0.13))
                }
            }
            .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sort Accessory Button

private let tabBarHeight: CGFloat = 56

struct SortAccessoryButton: View {
    let selectedTab: Int
    @Environment(\.appTheme) private var theme
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var homeState     = HomeScreenState.shared
    @StateObject private var trendingState = TrendingScreenState.shared

    var body: some View {
        Button {
            if selectedTab == 0 { homeState.showSortSheet     = true }
            if selectedTab == 2 { trendingState.showSortSheet  = true }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .frame(width: tabBarHeight, height: tabBarHeight)
                .background {
                    if #available(iOS 26.0, *) {
                        Circle()
                            .fill(Color.clear)
                            .glassEffect(.regular, in: Circle())
                    } else {
                        ZStack {
                            Circle()
                                .fill(colorScheme == .dark
                                      ? Color.white.opacity(0.18)
                                      : Color.black.opacity(0.06))
                            Circle()
                                .fill(.ultraThinMaterial)
                        }
                        .shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 4)
                        .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                    }
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sort Buttons (used elsewhere if needed)

struct SortButtonForHome: View {
    @Environment(\.appTheme) private var theme
    @StateObject private var homeScreenState = HomeScreenState.shared
    var body: some View {
        Button { homeScreenState.showSortSheet = true } label: {
            Image(systemName: "arrow.up.arrow.down").font(.title2).foregroundColor(theme.onSurface)
        }
        .frame(width: 44, height: 44)
    }
}

struct SortButtonForTrending: View {
    @Environment(\.appTheme) private var theme
    @StateObject private var trendingScreenState = TrendingScreenState.shared
    var body: some View {
        Button { trendingScreenState.showSortSheet = true } label: {
            Image(systemName: "arrow.up.arrow.down").font(.title2).foregroundColor(theme.onSurface)
        }
        .frame(width: 44, height: 44)
    }
}

// MARK: - Tab Content Wrappers

struct HomeScreenContent: View {
    var body: some View { HomeScreen().environmentObject(HomeScreenState.shared) }
}

struct CategoriesScreenContent: View {
    var body: some View { CategoriesScreen() }
}

struct TrendingScreenContent: View {
    var body: some View { TrendingScreen().environmentObject(TrendingScreenState.shared) }
}

struct FavoritesScreenContent: View {
    var body: some View { FavoritesScreen() }
}

// MARK: - Shared State

class HomeScreenState: ObservableObject {
    static let shared = HomeScreenState()
    @Published var showSortSheet = false
    private init() {}
}

class BannerDragState: ObservableObject {
    static let shared = BannerDragState()
    @Published var isDragging = false
    private init() {}
}

class TrendingScreenState: ObservableObject {
    static let shared = TrendingScreenState()
    @Published var showSortSheet = false
    private init() {}
}
