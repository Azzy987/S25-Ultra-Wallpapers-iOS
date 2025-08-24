import SwiftUI

struct DownloadSuccessDialog: View {
    @Environment(\.appTheme) private var theme
    @Binding var isPresented: Bool
    let wallpaperName: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Success Icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                // Title
                Text("Download Complete")
                    .font(.title3.bold())
                    .foregroundColor(theme.onSurface)
                
                // Message
                Text("\(wallpaperName) has been saved to your photos")
                    .font(.subheadline)
                    .foregroundColor(theme.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Buttons
                VStack(spacing: 12) {
                    Button {
                        if let url = URL(string: "photos-redirect://") {
                            UIApplication.shared.open(url)
                        }
                        isPresented = false
                    } label: {
                        Text("View in Photos")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(theme.primary)
                            .cornerRadius(12)
                    }
                    
                    Button {
                        isPresented = false
                    } label: {
                        Text("Close")
                            .font(.headline)
                            .foregroundColor(theme.onSurface)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(theme.surfaceVariant)
                            .cornerRadius(12)
                    }
                }
                .padding(.top, 10)
            }
            .padding(24)
            .background(theme.surface)
            .cornerRadius(24)
            .padding(.horizontal, 40)
        }
    }
} 
