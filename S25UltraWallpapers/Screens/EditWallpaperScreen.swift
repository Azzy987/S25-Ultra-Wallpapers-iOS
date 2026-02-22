// EditWallpaperScreen.swift
import SwiftUI
import PhotosUI
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Edit Option Types
enum EditOption: String, CaseIterable {
    case filters = "Filters"
    case brightness = "Brightness"
    case contrast = "Contrast"
    case saturation = "Saturation"
    case flip = "Flip"
    case rotate = "Rotate"
    
    var icon: String {
        switch self {
        case .filters: return "camera.filters"
        case .brightness: return "sun.max"
        case .contrast: return "circle.lefthalf.filled"
        case .saturation: return "drop.fill"
        case .flip: return "flip.horizontal"
        case .rotate: return "arrow.clockwise"
        }
    }
}


struct EditWallpaperScreen: View {
    // MARK: - Properties
    let wallpaper: Wallpaper
    let originalImage: UIImage
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var filterLockManager: FilterLockManager
    @EnvironmentObject private var adManager: AdManager
    @EnvironmentObject private var userManager: UserManager
    
    // Edit options
    @State private var selectedEditOption: EditOption = .filters
    
    // Filter properties
    @State private var selectedFilter: WallpaperFilter = .noFilter
    
    // Adjustment properties
    @State private var brightness: Double = 0.0
    @State private var contrast: Double = 1.0
    @State private var saturation: Double = 1.0
    @State private var isFlippedHorizontally = false
    @State private var isFlippedVertically = false
    @State private var rotationAngle: Double = 0.0
    
    // UI State
    @State private var processedImage: UIImage?
    @State private var isProcessing = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .info
    @State private var showDownloadSuccess = false
    @State private var showFilterUnlockSheet = false
    @State private var showPremiumUpgradeDialog = false
    
    // Individual feature unlock state
    @State private var unlockedFeatures: Set<EditOption> = []

    
    // MARK: - Body
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                header
                
                // Image Preview (Full width)
                imagePreview
                
                // Edit Options Toolbar
                editOptionsToolbar
                
                // Dynamic Edit Controls
                editControlsSection
                
                // Global Reset Button
                globalResetButton
            }
            .background(theme.surface)
            
            if showToast {
                ToastView(
                    message: toastMessage,
                    type: toastType,
                    isPresented: $showToast
                )
            }
        }
        .overlay(alignment: .center) {
            if showDownloadSuccess {
                DownloadSuccessDialog(
                    isPresented: $showDownloadSuccess,
                    wallpaperName: wallpaper.wallpaperName
                )
                .transition(AnyTransition.opacity.animation(.easeInOut))
            }
        }
        .sheet(isPresented: $showFilterUnlockSheet) {
            FilterUnlockSheet(
                wallpaperId: wallpaper.id,
                lockedFilters: filterLockManager.getLockedFilters(for: wallpaper.id),
                isPresented: $showFilterUnlockSheet
            )
        }
        .overlay {
            if showPremiumUpgradeDialog {
                PremiumUpgradeDialog(
                    isPresented: $showPremiumUpgradeDialog,
                    wallpaperId: wallpaper.id,
                    unlockedFeatures: $unlockedFeatures,
                    theme: theme
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .animation(.easeInOut(duration: 0.3), value: showPremiumUpgradeDialog)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func isPremiumFeature(_ option: EditOption) -> Bool {
        // Check if user has premium status or feature is individually unlocked
        let isPremiumUser = userManager.isPremium
        let isIndividuallyUnlocked = unlockedFeatures.contains(option)
        
        switch option {
        case .filters:
            return false // Filters are always accessible (with individual filter locks)
        case .brightness, .contrast, .saturation, .flip, .rotate:
            return !isPremiumUser && !isIndividuallyUnlocked // Require premium or individual unlock
        }
    }
    
    // MARK: - Views
    private var header: some View {
        HStack(spacing: 0) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(theme.onSurface)
            }
            .padding(.leading, 20)

            Spacer()

            Text("Edit Wallpaper")
                .font(.title2.weight(.semibold))
                .foregroundColor(theme.onSurface)

            Spacer()

            // Invisible placeholder to balance the layout
            Image(systemName: "xmark")
                .font(.title2)
                .foregroundColor(.clear)
                .padding(.trailing, 20)
        }
        .padding(.vertical, 16)
        .background(theme.surface)
    }
    
    private var imagePreview: some View {
        VStack(spacing: 12) {
            if isProcessing {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                        .scaleEffect(1.2)
                    
                    Text("Processing...")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(theme.onSurfaceVariant)
                }
                .frame(maxWidth: .infinity, minHeight: 300)
            } else {
                Image(uiImage: displayImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, minHeight: 300, maxHeight: 400)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .scaleEffect(x: isFlippedHorizontally ? -1 : 1, y: isFlippedVertically ? -1 : 1)
                    .rotationEffect(.degrees(rotationAngle))
                    .animation(.easeInOut(duration: 0.3), value: isFlippedHorizontally)
                    .animation(.easeInOut(duration: 0.3), value: isFlippedVertically)
                    .animation(.easeInOut(duration: 0.3), value: rotationAngle)
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 8) // Reduced vertical padding
    }
    
    private var editOptionsToolbar: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(EditOption.allCases, id: \.self) { option in
                        EditOptionButton(
                            option: option,
                            isSelected: selectedEditOption == option,
                            theme: theme,
                            isLocked: isPremiumFeature(option)
                        ) {
                            if isPremiumFeature(option) {
                                // Show unlock dialog immediately for locked features
                                showPremiumUpgradeDialog = true
                            } else {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedEditOption = option
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 16)
        }
        .background(theme.surface)
    }
    
    private var editControlsSection: some View {
        ZStack {
            VStack(spacing: 0) {
                switch selectedEditOption {
                case .filters:
                    filtersSection
                case .brightness:
                    brightnessSection
                case .contrast:
                    contrastSection
                case .saturation:
                    saturationSection
                case .flip:
                    flipSection
                case .rotate:
                    rotateSection
                }
            }
            .background(theme.surface)
            
            // Overlay for locked features
            if isPremiumFeature(selectedEditOption) {
                LockedFeatureOverlay(theme: theme) {
                    showPremiumUpgradeDialog = true
                }
            }
        }
    }
    
    private var globalResetButton: some View {
        HStack(spacing: 16) {
            // Reset All button
            Button {
                resetAllFilters()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.callout.weight(.medium))
                    Text("Reset All")
                        .font(.callout.weight(.medium))
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red, lineWidth: 1.5)
                )
            }
            
            // Save button
            Button {
                downloadEditedWallpaper()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.callout.weight(.medium))
                    Text("Save")
                        .font(.callout.weight(.medium))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(theme.primary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal, 32) // Same horizontal padding as image preview
        .padding(.vertical, 8) // Reduced vertical padding
        .background(theme.surface)
    }
    
    // MARK: - Edit Sections
    
    private var filtersSection: some View {
        VStack(spacing: 2) {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 6) {
                    ForEach(WallpaperFilter.allCases, id: \.self) { filter in
                        FilterButton(
                            filter: filter,
                            isSelected: filter == selectedFilter,
                            image: originalImage,
                            wallpaperId: wallpaper.id,
                            action: {
                                handleFilterSelection(filter)
                            },
                            onLockedTap: {
                                showPremiumUpgradeDialog = true
                            }
                        )
                        .frame(width: 70, height: 120)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 6) // Reduced vertical padding
            }
            .frame(height: 140) // Reduced height
        }
        .padding(.vertical, 2) // Reduced vertical padding
    }
    
    // Individual adjustment sections
    private var brightnessSection: some View {
        adjustmentSliderSection(
            title: "Brightness",
            icon: "sun.max",
            value: $brightness,
            range: -1.0...1.0,
            defaultValue: 0.0
        )
        .padding(.vertical, 8)
        .frame(minHeight: 160)
    }
    
    private var contrastSection: some View {
        adjustmentSliderSection(
            title: "Contrast",
            icon: "circle.lefthalf.filled",
            value: $contrast,
            range: 0.0...2.0,
            defaultValue: 1.0
        )
        .padding(.vertical, 8)
        .frame(minHeight: 160)
    }
    
    private var saturationSection: some View {
        adjustmentSliderSection(
            title: "Saturation",
            icon: "drop.fill",
            value: $saturation,
            range: 0.0...2.0,
            defaultValue: 1.0
        )
        .padding(.vertical, 8)
        .frame(minHeight: 160)
    }
    
    
    private var flipSection: some View {
        HStack(spacing: 32) {
            FlipButton(
                title: "Horizontal",
                icon: "flip.horizontal",
                isActive: isFlippedHorizontally,
                theme: theme
            ) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isFlippedHorizontally.toggle()
                    applyTransformations()
                }
            }
            
            FlipButton(
                title: "Vertical",
                icon: "arrow.up.and.down.righttriangle.up.righttriangle.down",
                isActive: isFlippedVertically,
                theme: theme
            ) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isFlippedVertically.toggle()
                    applyTransformations()
                }
            }
        }
        .padding(.vertical, 6)
        .frame(minHeight: 160)
        .clipShape(Rectangle()) // Fix clipping at the top
    }
    
    private var rotateSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 32) {
                RotateButton(
                    icon: "rotate.left",
                    theme: theme
                ) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        rotationAngle -= 90
                        applyTransformations()
                    }
                }
                
                RotateButton(
                    icon: "rotate.right",
                    theme: theme
                ) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        rotationAngle += 90
                        applyTransformations()
                    }
                }
            }
            
            Button("Reset Rotation") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    rotationAngle = 0.0
                    applyTransformations()
                }
            }
            .font(.callout.weight(.medium))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(theme.primary)
            .clipShape(Capsule())
        }
        .padding(.vertical, 8)
        .frame(minHeight: 160)
    }
    
    private func adjustmentSliderSection(
        title: String,
        icon: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        defaultValue: Double
    ) -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(theme.primary)
                    .frame(width: 24)
                
                Text(title)
                    .font(.callout.weight(.medium))
                    .foregroundColor(theme.onSurface)
                
                Spacer()
                
                Button("Reset") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        value.wrappedValue = defaultValue
                        applyAdjustments()
                    }
                }
                .font(.caption.weight(.medium))
                .foregroundColor(theme.primary)
            }
            
            CustomSlider(
                value: value,
                range: range,
                theme: theme
            ) {
                applyAdjustments()
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .frame(height: 120)
    }
    
    // MARK: - Filter Handling
    
    private func handleFilterSelection(_ filter: WallpaperFilter) {
        let isUnlocked = filterLockManager.isFilterUnlocked(filter, for: wallpaper.id)
        
        if !isUnlocked {
            showPremiumUpgradeDialog = true
            return
        }
        
        if selectedFilter == filter {
            selectedFilter = .noFilter
            processedImage = nil
        } else {
            selectedFilter = filter
            applyFilter(filter)
        }
    }
    
    // MARK: - Filter Application
    private func applyFilter(_ filter: WallpaperFilter) {
        guard filter != .noFilter else {
            processedImage = nil
            applyAdjustments() // Re-apply adjustments if any
            return
        }
        
        isProcessing = true
        
        // Check cache first
        let cacheKey = "\(filter.rawValue)_\(originalImage.hashValue)"
        if let cachedImage = ImageFilterCache.shared.image(for: cacheKey) {
            DispatchQueue.main.async {
                self.processedImage = cachedImage
                self.isProcessing = false
                // Don't automatically apply adjustments, just show the filtered image
            }
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let context = CIContext(options: [.useSoftwareRenderer: false])
            guard let ciImage = CIImage(image: self.originalImage) else {
                DispatchQueue.main.async {
                    self.isProcessing = false
                }
                return
            }
            
            // Apply the filter
            if let filteredUIImage = filter.apply(to: ciImage, context: context) {
                // Cache the filtered image
                ImageFilterCache.shared.setImage(filteredUIImage, for: cacheKey)
                
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.processedImage = filteredUIImage
                        self.isProcessing = false
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    print("❌ Failed to apply filter: \(filter.rawValue)")
                }
            }
        }
    }
    
    // MARK: - Photo Library Access
    private func downloadEditedWallpaper() {
        let imageToSave = displayImage
        
        // Show interstitial ad before downloading edited wallpaper (for non-premium users)
        adManager.showInterstitialAd {
            self.proceedWithDownload(imageToSave)
        }
    }
    
    private func proceedWithDownload(_ imageToSave: UIImage) {
        // Apply any final transformations if needed
        let finalImage = applyFinalTransformations(to: imageToSave)
        
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch status {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                if status == .authorized {
                    self.saveToPhotos(finalImage)
                }
            }
        case .authorized, .limited:
            saveToPhotos(finalImage)
        default:
            showToast = true
            toastMessage = "Please enable Photos access in Settings"
        }
    }
    
    private func applyFinalTransformations(to image: UIImage) -> UIImage {
        var finalImage = image
        
        // Apply rotation if needed
        if rotationAngle != 0.0 {
            finalImage = finalImage.rotated(by: rotationAngle)
        }
        
        // Apply flipping if needed
        if isFlippedHorizontally || isFlippedVertically {
            finalImage = finalImage.flipped(horizontally: isFlippedHorizontally, vertically: isFlippedVertically)
        }
        
        return finalImage
    }
    
    private func saveToPhotos(_ image: UIImage) {
        // Convert WebP or any format to JPEG for iOS compatibility
        guard let jpegData = image.jpegData(compressionQuality: 0.9),
              let jpegImage = UIImage(data: jpegData) else {
            DispatchQueue.main.async {
                showToast = true
                toastMessage = "Failed to convert image format"
            }
            return
        }
        
        print("📱 [DOWNLOAD] Successfully converted edited wallpaper to JPEG format")
        
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: jpegImage)
        } completionHandler: { success, error in
            DispatchQueue.main.async {
                if success {
                    showDownloadSuccess = true
                } else {
                    showToast = true
                    toastMessage = "Failed to save wallpaper: \(error?.localizedDescription ?? "Unknown error")"
                }
            }
        }
    }
    
    private func saveWallpaper() {
        toastMessage = "Saving wallpaper..."
        toastType = .info
        showToast = true
        // ... rest of save logic
    }
    
    private func showError(_ message: String) {
        toastMessage = message
        toastType = .error
        showToast = true
    }
    
    // MARK: - Computed Properties
    
    private var displayImage: UIImage {
        return processedImage ?? originalImage
    }
    
    // MARK: - Image Processing Methods
    
    private func applyAdjustments() {
        guard brightness != 0.0 || contrast != 1.0 || saturation != 1.0 else {
            if selectedFilter == .noFilter {
                processedImage = nil
            } else {
                applyFilter(selectedFilter)
            }
            return
        }
        
        // Skip processing if already processing to prevent bouncing
        guard !isProcessing else { return }
        
        isProcessing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let baseImage = selectedFilter != .noFilter ? (self.processedImage ?? self.originalImage) : self.originalImage
            
            guard let ciImage = CIImage(image: baseImage) else {
                DispatchQueue.main.async {
                    self.isProcessing = false
                }
                return
            }
            
            // Use a single color controls filter for all adjustments
            let colorFilter = CIFilter.colorControls()
            colorFilter.inputImage = ciImage
            
            // Apply all adjustments at once
            colorFilter.brightness = Float(self.brightness)
            colorFilter.contrast = Float(self.contrast)
            colorFilter.saturation = Float(self.saturation)
            
            guard let outputImage = colorFilter.outputImage else {
                DispatchQueue.main.async {
                    self.isProcessing = false
                }
                return
            }
            
            let context = CIContext(options: [
                .useSoftwareRenderer: false,
                .priorityRequestLow: false
            ])
            
            if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
                let finalImage = UIImage(cgImage: cgImage)
                
                DispatchQueue.main.async {
                    // Remove animation to prevent bouncing
                    self.processedImage = finalImage
                    self.isProcessing = false
                }
            } else {
                DispatchQueue.main.async {
                    self.isProcessing = false
                }
            }
        }
    }
    
    private func applyTransformations() {
        // Transformations are handled visually via SwiftUI modifiers
        // The actual image transformation would be applied during save
    }
    
    private func resetAllFilters() {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedFilter = .noFilter
            processedImage = nil
            brightness = 0.0
            contrast = 1.0
            saturation = 1.0
            isFlippedHorizontally = false
            isFlippedVertically = false
            rotationAngle = 0.0
        }
    }
}

// MARK: - Premium Upgrade Dialog
struct PremiumUpgradeDialog: View {
    @Binding var isPresented: Bool
    let wallpaperId: String
    @Binding var unlockedFeatures: Set<EditOption>
    let theme: AppColorScheme
    
    @EnvironmentObject private var filterLockManager: FilterLockManager
    @EnvironmentObject private var adManager: AdManager
    
    @State private var isLoadingAd = false
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Dialog content
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.yellow)
                    
                    Text("Premium Feature")
                        .font(.title2.weight(.bold))
                        .foregroundColor(theme.onSurface)
                    
                    Text("Unlock advanced editing tools and filters")
                        .font(.body)
                        .foregroundColor(theme.onSurface.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                
                // Action buttons
                VStack(spacing: 16) {
                    // Upgrade to Premium button
                    Button {
                        // Handle premium upgrade
                        isPresented = false
                        // TODO: Implement premium upgrade flow
                    } label: {
                        HStack {
                            Image(systemName: "crown.fill")
                                .font(.title3)
                            Text("Upgrade to Premium")
                                .font(.headline.weight(.semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color.orange, Color.red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    // Watch Ad button
                    Button {
                        watchAdToUnlock()
                    } label: {
                        HStack {
                            if isLoadingAd {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "play.rectangle.fill")
                                    .font(.title3)
                            }
                            Text("Watch Ad to Unlock")
                                .font(.headline.weight(.medium))
                        }
                        .foregroundColor(theme.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(theme.surfaceVariant)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(theme.primary, lineWidth: 1)
                        )
                    }
                    .disabled(isLoadingAd)
                    
                    // Cancel button
                    Button {
                        isPresented = false
                    } label: {
                        Text("Cancel")
                            .font(.callout.weight(.medium))
                            .foregroundColor(theme.onSurface.opacity(0.6))
                            .padding(.vertical, 12)
                    }
                }
            }
            .padding(24)
            .background(theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 40)
        }
    }
    
    private func watchAdToUnlock() {
        isLoadingAd = true
        
        adManager.showRewardAd { success in
            isLoadingAd = false
            if success {
                // Unlock all filters for this wallpaper
                filterLockManager.unlockAllFiltersForWallpaper(wallpaperId)
                
                // Unlock all premium editing features for this session
                let allPremiumOptions: Set<EditOption> = [.brightness, .contrast, .saturation, .flip, .rotate]
                unlockedFeatures.formUnion(allPremiumOptions)
                
                isPresented = false
            }
        }
    }
}

// MARK: - Supporting UI Components

struct LockedFeatureOverlay: View {
    let theme: AppColorScheme
    let onTap: () -> Void
    
    var body: some View {
        Rectangle()
            .fill(Color.black.opacity(0.6))
            .overlay(
                VStack(spacing: 16) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(.white)
                    
                    VStack(spacing: 8) {
                        Text("Premium Feature")
                            .font(.title2.weight(.bold))
                            .foregroundColor(.white)
                        
                        Text("Unlock advanced editing tools")
                            .font(.callout)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                        
                        Text("TAP TO UNLOCK")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.white)
                            .padding(.top, 8)
                    }
                }
            )
            .onTapGesture {
                onTap()
            }
    }
}

struct EditOptionButton: View {
    let option: EditOption
    let isSelected: Bool
    let theme: AppColorScheme
    let isLocked: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Circular container
                ZStack {
                    Circle()
                        .fill(isSelected ? theme.primary : theme.surfaceVariant)
                        .frame(width: 64, height: 64)
                        .shadow(
                            color: isSelected ? theme.primary.opacity(0.3) : theme.onSurface.opacity(0.1),
                            radius: isSelected ? 8 : 4,
                            x: 0,
                            y: isSelected ? 4 : 2
                        )
                        .opacity(isLocked ? 0.5 : 1.0)
                    
                    Image(systemName: option.icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(isSelected ? .white : theme.onSurface)
                        .opacity(isLocked ? 0.7 : 1.0)
                    
                    // Lock overlay for locked features
                    if isLocked {
                        Circle()
                            .fill(Color.black.opacity(0.4))
                            .frame(width: 64, height: 64)
                            .overlay(
                                Image(systemName: "lock.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            )
                    }
                }
                
                Text(option.rawValue)
                    .font(.caption.weight(.medium))
                    .foregroundColor(isLocked ? theme.onSurface.opacity(0.6) : theme.onSurface)
                    .lineLimit(1)
                    .frame(width: 64) // Fixed width for consistent spacing
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// Locked Adjustment View Component
struct LockedAdjustmentView: View {
    let title: String
    let icon: String
    let theme: AppColorScheme
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(theme.surfaceVariant.opacity(0.6))
                    .frame(width: 120, height: 120)
                
                // Lock overlay
                Circle()
                    .fill(Color.black.opacity(0.4))
                    .frame(width: 120, height: 120)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: icon)
                                .font(.title)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Image(systemName: "lock.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                            
                            Text("TAP")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.white)
                                .opacity(0.9)
                        }
                    )
            }
            .onTapGesture {
                onTap()
            }
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(theme.onSurface)
                
                Text("Premium Feature")
                    .font(.caption)
                    .foregroundColor(theme.onSurface.opacity(0.6))
            }
        }
        .padding(.vertical, 20)
    }
}

struct CustomSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let theme: AppColorScheme
    let onEditingChanged: () -> Void
    
    // Convert slider value to percentage display
    private var percentageValue: Int {
        Int(value * 100)
    }
    
    private var minPercentage: Int {
        Int(range.lowerBound * 100)
    }
    
    private var maxPercentage: Int {
        Int(range.upperBound * 100)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(minPercentage)%")
                    .font(.caption2)
                    .foregroundColor(theme.onSurfaceVariant)
                
                Spacer()
                
                Text("\(percentageValue)%")
                    .font(.callout.weight(.medium))
                    .foregroundColor(theme.onSurface)
                    .frame(minWidth: 48) // Fixed width to prevent jumping
                
                Spacer()
                
                Text("\(maxPercentage)%")
                    .font(.caption2)
                    .foregroundColor(theme.onSurfaceVariant)
            }
            
            Slider(
                value: $value,
                in: range,
                onEditingChanged: { _ in onEditingChanged() }
            )
            .accentColor(theme.primary)
        }
    }
}

struct FlipButton: View {
    let title: String
    let icon: String
    let isActive: Bool
    let theme: AppColorScheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(isActive ? .white : theme.onSurface)
                
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundColor(isActive ? .white : theme.onSurface)
            }
            .frame(width: 100, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isActive ? theme.primary : theme.surfaceVariant)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RotateButton: View {
    let icon: String
    let theme: AppColorScheme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(Circle().fill(theme.primary))
                .shadow(color: theme.primary.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - UIImage Extensions for Transformations

extension UIImage {
    func rotated(by degrees: Double) -> UIImage {
        let radians = degrees * .pi / 180.0
        let rotatedSize = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: radians))
            .integral.size
        
        UIGraphicsBeginImageContextWithOptions(rotatedSize, false, scale)
        if let context = UIGraphicsGetCurrentContext() {
            let origin = CGPoint(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
            context.translateBy(x: origin.x, y: origin.y)
            context.rotate(by: radians)
            draw(in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))
        }
        
        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return rotatedImage ?? self
    }
    
    func flipped(horizontally: Bool, vertically: Bool) -> UIImage {
        guard horizontally || vertically else { return self }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        if let context = UIGraphicsGetCurrentContext() {
            var transform = CGAffineTransform.identity
            
            if horizontally {
                transform = transform.scaledBy(x: -1, y: 1)
                transform = transform.translatedBy(x: -size.width, y: 0)
            }
            
            if vertically {
                transform = transform.scaledBy(x: 1, y: -1)
                transform = transform.translatedBy(x: 0, y: -size.height)
            }
            
            context.concatenate(transform)
            draw(at: .zero)
        }
        
        let flippedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return flippedImage ?? self
    }
}
