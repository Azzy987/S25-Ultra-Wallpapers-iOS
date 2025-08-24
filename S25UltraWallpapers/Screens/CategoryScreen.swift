import SwiftUI
import FirebaseFirestore

struct CategoryScreen: View {
    let category: Category
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @State private var selectedWallpaper: Wallpaper?
    @State private var hasLoaded = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .info
    @StateObject private var scrollViewHelper = ScrollViewHelper()
    @State private var showDetail = false
    @Namespace private var animation
    @State private var dragOffset: CGFloat = 0
    @State private var showSeriesFilter = false
    @StateObject private var viewModel: CategoryViewModel
    
    init(category: Category) {
        self.category = category
        self._viewModel = StateObject(wrappedValue: CategoryViewModel(category: category))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Fixed header - always at top
            header
                .zIndex(1000) // Ensure header stays on top
            
            // Main content WITH subcategories
            ScrollViewReader { proxy in
                VStack(spacing: 0) {
                    // Subcategories horizontal scroll
                    if !viewModel.availableSubcategories.isEmpty {
                        subcategoriesScrollView
                    }
                    
                    // Smooth pager implementation
                    GeometryReader { geo in
                        let screenWidth = geo.size.width
                        let allSubcategories = viewModel.allSubcategories
                        
                        HStack(spacing: 0) {
                            // Create a page for each subcategory
                            ForEach(allSubcategories, id: \.self) { subcategory in
                                // Get the correct paginator from the ViewModel for this specific page
                                let paginator = viewModel.paginator(for: subcategory)
                                
                                // Display the grid for that paginator
                                PagedWallpaperGridView(paginator: paginator)
                                    .frame(width: screenWidth)
                            }
                        }
                        // 7. The offset is calculated based on the current page and the live drag
                        .offset(x: -CGFloat(viewModel.currentIndex) * screenWidth + dragOffset)
                        .animation(.none, value: dragOffset) // No animation on drag
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    // Let the view track the finger's movement
                                    dragOffset = value.translation.width
                                }
                                .onEnded { value in
                                    let threshold = screenWidth / 3 // User must swipe at least 1/3 of the screen
                                    var newIndex = viewModel.currentIndex
                                    
                                    // Check if swipe was far enough to trigger a page change
                                    if value.translation.width < -threshold { // Swiped left
                                        newIndex = min(viewModel.currentIndex + 1, allSubcategories.count - 1)
                                    } else if value.translation.width > threshold { // Swiped right
                                        newIndex = max(viewModel.currentIndex - 1, 0)
                                    }
                                    
                                    // Animate the snap to the final position
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        viewModel.currentIndex = newIndex
                                        dragOffset = 0 // Reset drag offset for the next swipe
                                    }
                                }
                        )
                    }
                }
            }
            .background(theme.background)
            
            
            // Scroll to top button overlay
            if scrollViewHelper.showScrollToTop {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ScrollToTopButton {
                            scrollViewHelper.shouldScrollToTop = true
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
            
            // Toast overlay
            if showToast {
                ToastView(
                    message: toastMessage,
                    type: toastType,
                    isPresented: $showToast
                )
            }
        }
        .background(theme.background)
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showDetail) {
            if let wallpaper = selectedWallpaper {
                WallpaperDetailScreen(
                    wallpaper: wallpaper,
                    animation: animation,
                    isPresented: $showDetail
                )
            }
        }
        .sheet(isPresented: $showSeriesFilter) {
            SeriesFilterSheet(
                availableSeries: viewModel.availableSeries,
                selectedSeries: $viewModel.currentSeriesFilter
            ) { selectedSeries in
                viewModel.applySeriesFilter(selectedSeries)
            }
        }
        .onAppear {
            if !hasLoaded {
                loadInitialData()
                hasLoaded = true
            }
        }
    }
    
    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
            }
            
            Text(category.name)
                .font(.title3.bold())
                .frame(maxWidth: .infinity, alignment: .center)
            
            // Filter button for Samsung categories
            if category.categoryType == "brand" && category.name == "Samsung" {
                Button {
                    showSeriesFilter = true
                } label: {
                    Image(systemName: "line.horizontal.3.decrease.circle")
                        .font(.title2)
                }
            } else {
                // Invisible placeholder to balance the layout
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .opacity(0)
            }
        }
        .foregroundColor(theme.onSurface)
        .padding()
        .background(theme.surface)
        .animation(.none, value: dragOffset) // Disable ALL animations
    }
    
    private var subcategoriesScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Create buttons for all subcategories using ViewModel
                    ForEach(Array(viewModel.allSubcategories.enumerated()), id: \.element) { index, subcategory in
                        SubcategoryButton(
                            title: subcategory,
                            isSelected: viewModel.currentIndex == index,
                            action: {
                                // Animate the change when a button is tapped
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    viewModel.currentIndex = index
                                }
                            }
                        )
                        .id(subcategory)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            .background(theme.surface)
            .onChange(of: viewModel.currentIndex) { newIndex in
                // Make the pager change the selected button: scroll to active tab when currentIndex changes
                let selected = viewModel.allSubcategories[newIndex]
                withAnimation {
                    proxy.scrollTo(selected, anchor: .center)
                }
            }
        }
    }
    
    private func loadInitialData() {
        // ViewModel handles all initialization automatically
        // Load initial wallpapers for the first page
        let firstPaginator = viewModel.paginator(for: viewModel.allSubcategories[0])
        firstPaginator.loadInitialWallpapers()
    }
    
}

struct SubcategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(isSelected ? .white : theme.onSurface)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? theme.primary : theme.surfaceVariant)
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}

 