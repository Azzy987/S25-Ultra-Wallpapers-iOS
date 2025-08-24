// EditWallpaperScreen.swift
import SwiftUI
import PhotosUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct EditWallpaperScreen: View {
    // MARK: - Properties
    let wallpaper: Wallpaper
    let originalImage: UIImage
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @State private var selectedFilter: WallpaperFilter = .noFilter
    @State private var filteredImage: UIImage?
    @State private var isProcessing = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .info
    @State private var showDownloadSuccess = false

    
    // MARK: - Body
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                header
                Divider()
                // Image Preview
                GeometryReader { geo in
                    if isProcessing {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))

                    } else {
                        Image(uiImage: filteredImage ?? originalImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(24)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding()
                Divider()
                
                // Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        ForEach(WallpaperFilter.allCases, id: \.self) { filter in
                            FilterButton(
                                filter: filter,
                                isSelected: filter == selectedFilter,
                                image: originalImage
                            ) {
                                if selectedFilter == filter {
                                    selectedFilter = .noFilter
                                    filteredImage = nil
                                } else {
                                    selectedFilter = filter
                                    applyFilter(filter)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 160)
                .background(theme.surface)
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
    }
    
    // MARK: - Views
    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title2)
            }
            
            Spacer()
            
            Text("Edit Wallpaper")
                .font(.title3)
            
            Spacer()
            
            Button {
                downloadEditedWallpaper()
            } label: {
                Image(systemName: "arrow.down")
                    .font(.title2)
            }
        }
        .foregroundColor(theme.onSurface)
        .padding()
        .background(theme.surface)
    }
    
    // MARK: - Filter Application
    private func applyFilter(_ filter: WallpaperFilter) {
        guard filter != .noFilter else {
            filteredImage = nil
            return
        }
        
        isProcessing = true
        
        // Check cache first
        let cacheKey = "\(filter.rawValue)_\(originalImage.hashValue)"
        if let cachedImage = ImageFilterCache.shared.image(for: cacheKey) {
            DispatchQueue.main.async {
                self.filteredImage = cachedImage
                self.isProcessing = false
            }
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let context = CIContext(options: [.useSoftwareRenderer: false])
            guard let ciImage = CIImage(image: originalImage) else {
                DispatchQueue.main.async {
                    self.isProcessing = false
                }
                return
            }
            
            if let outputImage = filter.apply(to: ciImage, context: context) {
                // Cache the filtered image
                ImageFilterCache.shared.setImage(outputImage, for: cacheKey)
                
                DispatchQueue.main.async {
                    withAnimation {
                        self.filteredImage = outputImage
                        self.isProcessing = false
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isProcessing = false
                }
            }
        }
    }
    
    // MARK: - Photo Library Access
    private func downloadEditedWallpaper() {
        let imageToSave = filteredImage ?? originalImage
        
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        switch status {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                if status == .authorized {
                    saveToPhotos(imageToSave)
                }
            }
        case .authorized, .limited:
            saveToPhotos(imageToSave)
        default:
            showToast = true
            toastMessage = "Please enable Photos access in Settings"
        }
    }
    
    private func saveToPhotos(_ image: UIImage) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        } completionHandler: { success, error in
            DispatchQueue.main.async {
                if success {
                    showDownloadSuccess = true
                } else {
                    showToast = true
                    toastMessage = "Failed to save wallpaper"
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
}
