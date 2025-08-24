// FilterButton.swift
import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct FilterButton: View {
    // MARK: - Properties
    let filter: WallpaperFilter
    let isSelected: Bool
    let image: UIImage
    let action: () -> Void
    @Environment(\.appTheme) private var theme
    
    @State private var filteredPreview: UIImage?
    @State private var isLoading = true
    
    // MARK: - Body
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .frame(width: 90, height: 120)
                        .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))

                } else {
                    (filteredPreview != nil ? Image(uiImage: filteredPreview!) : Image(uiImage: image))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 90, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? theme.primary : Color.clear, lineWidth: 4)
                        )
                }
                
                Text(filter.rawValue)
                    .font(.caption)
                    .foregroundColor(theme.onSurface)
            }
        }
        .onAppear {
            if filter == .noFilter {
                self.filteredPreview = image
                self.isLoading = false
            } else {
                generateFilterPreview()
            }
        }
    }
    
    // MARK: - Preview Generation
    private func generateFilterPreview() {
        isLoading = true
        
        // Check cache first
        let cacheKey = "\(filter.rawValue)_preview_\(image.hashValue)"
        if let cachedImage = ImageFilterCache.shared.image(for: cacheKey) {
            DispatchQueue.main.async {
                self.filteredPreview = cachedImage
                self.isLoading = false
            }
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Create a shared context
            let context = CIContext(options: [
                .useSoftwareRenderer: false,
                .workingColorSpace: CGColorSpaceCreateDeviceRGB()
            ])
            
            // Resize image for preview
            let size = CGSize(width: 90, height: 120)
            let resizedImage = image.resized(to: size)
            
            guard let ciImage = CIImage(image: resizedImage) else {
                DispatchQueue.main.async {
                    self.filteredPreview = resizedImage
                    self.isLoading = false
                }
                return
            }
            
            if let outputImage = filter.apply(to: ciImage, context: context) {
                // Cache the preview
                ImageFilterCache.shared.setImage(outputImage, for: cacheKey)
                
                DispatchQueue.main.async {
                    self.filteredPreview = outputImage
                    self.isLoading = false
                }
            } else {
                DispatchQueue.main.async {
                    self.filteredPreview = resizedImage
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - UIImage Extension
extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - WallpaperFilter Extension
extension WallpaperFilter {
    func apply(to image: CIImage, context: CIContext) -> UIImage? {
        var outputImage: CIImage?
        
        switch self {
        case .noFilter:
            return UIImage(ciImage: image)
            
        case .addictiveBlue:
            outputImage = applyColorFilter(to: image, r: 0.8, g: 1.0, b: 1.2)
            
        case .addictiveRed:
            outputImage = applyColorFilter(to: image, r: 1.2, g: 0.8, b: 0.8)
            
        case .aden:
            outputImage = applyFilter(to: image, brightness: 1.1, contrast: 1.1, saturation: 1.1)
            
        case .brooklyn:
            outputImage = applyFilter(to: image, brightness: 1.0, contrast: 1.1, saturation: 1.2)
            
        case .earlybird:
            outputImage = applyFilter(to: image, brightness: 0.9, contrast: 1.2, saturation: 0.8)
            
        case .gingham:
            outputImage = applyFilter(to: image, brightness: 1.1, contrast: 0.9, saturation: 0.9)
            
        case .hudson:
            outputImage = applyFilter(to: image, brightness: 1.0, contrast: 1.2, saturation: 0.8)
            
        case .inkwell:
            outputImage = applyGrayscaleFilter(to: image)
            
        case .lark:
            outputImage = applyFilter(to: image, brightness: 1.1, contrast: 1.0, saturation: 1.1)
            
        case .lofi:
            outputImage = applyFilter(to: image, brightness: 1.2, contrast: 0.9, saturation: 0.9)
            
        case .maven:
            outputImage = applyFilter(to: image, brightness: 1.0, contrast: 1.1, saturation: 1.2)
            
        case .mayfair:
            outputImage = applyFilter(to: image, brightness: 1.1, contrast: 1.0, saturation: 1.1)
            
        case .moon:
            outputImage = applyGrayscaleFilter(to: image, intensity: 1.1)
            
        case .perpetua:
            outputImage = applyFilter(to: image, brightness: 1.0, contrast: 1.1, saturation: 1.0)
            
        case .reyes:
            outputImage = applyFilter(to: image, brightness: 1.2, contrast: 1.0, saturation: 0.9)
            
        case .rise:
            outputImage = applyFilter(to: image, brightness: 1.1, contrast: 1.0, saturation: 1.1)
            
        case .slumber:
            outputImage = applyFilter(to: image, brightness: 0.9, contrast: 1.0, saturation: 1.2)
            
        case .stinson:
            outputImage = applyFilter(to: image, brightness: 1.1, contrast: 1.1, saturation: 1.0)
            
        case .toaster:
            outputImage = applyFilter(to: image, brightness: 1.3, contrast: 0.9, saturation: 0.8)
            
        case .valencia:
            outputImage = applyFilter(to: image, brightness: 1.1, contrast: 1.0, saturation: 1.1)
            
        case .walden:
            outputImage = applyFilter(to: image, brightness: 1.0, contrast: 1.2, saturation: 1.1)
            
        case .willow:
            outputImage = applyGrayscaleFilter(to: image, intensity: 0.9)
            
        case .xpro2:
            outputImage = applyFilter(to: image, brightness: 1.2, contrast: 0.9, saturation: 0.8)
            
        case .crema:
            outputImage = applyFilter(to: image, brightness: 1.1, contrast: 1.0, saturation: 0.9)
            
        case .ludwig:
            outputImage = applyFilter(to: image, brightness: 1.0, contrast: 1.1, saturation: 1.1)
            
        case .sierra:
            outputImage = applyFilter(to: image, brightness: 1.1, contrast: 1.0, saturation: 1.0)
            
        case .skyline:
            outputImage = applyFilter(to: image, brightness: 1.0, contrast: 1.1, saturation: 1.2)
            
        case .dogpatch:
            outputImage = applyFilter(to: image, brightness: 1.2, contrast: 1.0, saturation: 0.9)
            
        case .vesper:
            outputImage = applyFilter(to: image, brightness: 1.1, contrast: 0.9, saturation: 1.1)
            
        case .amaro:
            outputImage = applyFilter(to: image, brightness: 1.1, contrast: 1.2, saturation: 1.1)
        }
        
        guard let output = outputImage,
              let cgImage = context.createCGImage(output, from: output.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    private func applyColorFilter(to image: CIImage, r: CGFloat, g: CGFloat, b: CGFloat) -> CIImage? {
        let filter = CIFilter.colorMatrix()
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIVector(x: r, y: 0, z: 0, w: 0), forKey: "inputRVector")
        filter.setValue(CIVector(x: 0, y: g, z: 0, w: 0), forKey: "inputGVector")
        filter.setValue(CIVector(x: 0, y: 0, z: b, w: 0), forKey: "inputBVector")
        filter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
        return filter.outputImage
    }
    
    private func applyFilter(to image: CIImage, brightness: CGFloat, contrast: CGFloat, saturation: CGFloat) -> CIImage? {
        let brightnessFilter = CIFilter.colorControls()
        brightnessFilter.setValue(image, forKey: kCIInputImageKey)
        brightnessFilter.setValue(brightness - 1, forKey: kCIInputBrightnessKey)
        brightnessFilter.setValue(contrast, forKey: kCIInputContrastKey)
        brightnessFilter.setValue(saturation, forKey: kCIInputSaturationKey)
        return brightnessFilter.outputImage
    }
    
    private func applyGrayscaleFilter(to image: CIImage, intensity: CGFloat = 1.0) -> CIImage? {
        let filter = CIFilter.colorMonochrome()
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIColor(red: 0.7, green: 0.7, blue: 0.7), forKey: kCIInputColorKey)
        filter.setValue(intensity, forKey: kCIInputIntensityKey)
        return filter.outputImage
    }
}
