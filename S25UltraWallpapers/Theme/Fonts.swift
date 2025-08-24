import SwiftUI

struct AppFonts {
    static func body(_ size: CGFloat = 16) -> Font {
        .custom("Nunito-Regular", size: size)
    }
    
    static func bodyBold(_ size: CGFloat = 16) -> Font {
        .custom("Nunito-Bold", size: size)
    }
    
    static func display(_ size: CGFloat = 24) -> Font {
        .custom("ABeeZee-Regular", size: size)
    }
} 