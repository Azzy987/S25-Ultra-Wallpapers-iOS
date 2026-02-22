import SwiftUI

// MARK: - Toast Manager
class ToastManager: ObservableObject {
    static let shared = ToastManager()
    
    @Published var showToast = false
    @Published var toastMessage = ""
    @Published var toastType: ToastView.ToastType = .info
    
    private init() {}
    
    func showFavoriteToast(wallpaperName: String, isAdded: Bool) {
        let action = isAdded ? "added to" : "removed from"
        toastMessage = "\(wallpaperName) \(action) favorites"
        toastType = isAdded ? .favorite : .unfavorite
        showToast = true
    }
    
    func showDownloadToast(message: String) {
        toastMessage = message
        toastType = .download
        showToast = true
    }
    
    func showShareToast(message: String) {
        toastMessage = message
        toastType = .share
        showToast = true
    }
    
    func showInfoToast(message: String) {
        toastMessage = message
        toastType = .info
        showToast = true
    }
    
    func showErrorToast(message: String) {
        toastMessage = message
        toastType = .error
        showToast = true
    }
    
    func hideToast() {
        showToast = false
    }
}