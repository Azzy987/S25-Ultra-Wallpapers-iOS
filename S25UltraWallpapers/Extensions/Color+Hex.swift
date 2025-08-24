import SwiftUI

extension Color {
    // This is a custom initializer, so we need to make it public
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        
        // Handle "0xFF" format
        let hexString = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
        Scanner(string: hexString).scanHexInt64(&int)
        
        let r = Double((int & 0xFF0000) >> 16) / 255.0
        let g = Double((int & 0x00FF00) >> 8) / 255.0
        let b = Double(int & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}

// Add this protocol
protocol ColorHexInitializable {
    init(hex: String)
} 
