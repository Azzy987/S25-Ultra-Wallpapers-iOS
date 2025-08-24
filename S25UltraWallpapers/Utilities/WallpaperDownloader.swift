import SwiftUI
import Photos

class WallpaperDownloader: ObservableObject {
    static let shared = WallpaperDownloader()
    
    @Published var isDownloading = false
    @Published var showToast = false
    @Published var toastMessage = ""
    @Published var showViewOption = false
    
    private init() {}
    
    func downloadWallpaper(from urlString: String) {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        switch status {
        case .notDetermined:
            requestPermissionAndDownload(from: urlString)
        case .authorized, .limited:
            startDownload(from: urlString)
        default:
            showPermissionDeniedMessage()
        }
    }
    
    private func requestPermissionAndDownload(from urlString: String) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { [weak self] status in
            DispatchQueue.main.async {
                if status == .authorized || status == .limited {
                    self?.startDownload(from: urlString)
                } else {
                    self?.showPermissionDeniedMessage()
                }
            }
        }
    }
    
    private func startDownload(from urlString: String) {
        guard let url = URL(string: urlString) else {
            showToastMessage("Invalid URL")
            return
        }
        
        isDownloading = true
        showToastMessage("Downloading wallpaper...")
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showToastMessage("Download failed: \(error.localizedDescription)")
                    self?.isDownloading = false
                    return
                }
                
                guard let data = data, let image = UIImage(data: data) else {
                    self?.showToastMessage("Failed to process image")
                    self?.isDownloading = false
                    return
                }
                
                self?.saveImageToPhotos(image)
            }
        }.resume()
    }
    
    private func saveImageToPhotos(_ image: UIImage) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isDownloading = false
                if success {
                    self?.showToastMessage("Wallpaper saved successfully")
                    self?.showViewOption = true
                } else {
                    self?.showToastMessage("Failed to save: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    private func showPermissionDeniedMessage() {
        showToastMessage("Please enable Photos access in Settings")
    }
    
    private func showToastMessage(_ message: String) {
        toastMessage = message
        showToast = true
        
        // Dismiss toast after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                self.showToast = false
            }
        }
    }
} 