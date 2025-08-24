import SwiftUI

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    enum ThemeMode: String, CaseIterable {
        case light = "Light"
        case dark = "Dark"
    }
    
    @AppStorage("themeMode") var themeMode: ThemeMode = .dark {
        didSet {
            print("🎨 ThemeMode changed to: \(themeMode.rawValue)")
            updateTheme()
        }
    }
    
    @Published private(set) var theme: AppColorScheme
    private var observer: NSKeyValueObservation?
    
    private init() {
        self.theme = Self.getInitialTheme()
        print("🎨 Initial theme type: \(self.theme.themeType)")
        setupThemeObserver()
    }
    
    private func setupThemeObserver() {
        print("🎨 Setting up theme observers")
        // No system theme observers needed since we only support manual light/dark selection
    }
    
    deinit {
        print("🎨 ThemeManager deinit")
        observer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    func updateTheme() {
        print("🎨 Updating theme")
        print("🎨 Theme mode: \(themeMode.rawValue)")
        
        withAnimation(.easeInOut(duration: 0.3)) {
            switch themeMode {
            case .dark:
                print("🎨 Setting dark theme")
                theme = AppColors.dark
            case .light:
                print("🎨 Setting light theme")
                theme = AppColors.light
            }
        }
        
        print("🎨 Theme updated to: \(theme.themeType)")
    }
    
    private static func getInitialTheme() -> AppColorScheme {
        let themeMode = ThemeMode(rawValue: UserDefaults.standard.string(forKey: "themeMode") ?? "dark") ?? .dark
        print("🎨 Getting initial theme for mode: \(themeMode.rawValue)")
        
        switch themeMode {
        case .dark:
            print("🎨 Initial dark theme")
            return AppColors.dark
        case .light:
            print("🎨 Initial light theme")
            return AppColors.light
        }
    }
}

// Add these at the top of the file or move to a separate Theme file
struct AppColorScheme: Equatable {
    let themeType: ThemeType
    let primary: Color
    let onPrimary: Color
    let primaryContainer: Color
    let onPrimaryContainer: Color
    let secondary: Color
    let onSecondary: Color
    let secondaryContainer: Color
    let onSecondaryContainer: Color
    let background: Color
    let onBackground: Color
    let surface: Color
    let onSurface: Color
    let surfaceVariant: Color
    let onSurfaceVariant: Color
    
    enum ThemeType {
        case light
        case dark
    }
    
    static func == (lhs: AppColorScheme, rhs: AppColorScheme) -> Bool {
        lhs.themeType == rhs.themeType
    }
}

struct AppColors {
    static let light = AppColorScheme(
        themeType: .light,
        primary: Color(hex: "874B6C"),
        onPrimary: .white,
        primaryContainer: Color(hex: "FFD8E9"),
        onPrimaryContainer: Color(hex: "380727"),
        secondary: Color(hex: "715764"),
        onSecondary: .white,
        secondaryContainer: Color(hex: "FCD9E8"),
        onSecondaryContainer: Color(hex: "291520"),
        background: Color(hex: "FFF8F8"),
        onBackground: Color(hex: "211A1D"),
        surface: Color(hex: "FFF8F8"),
        onSurface: Color(hex: "211A1D"),
        surfaceVariant: Color(hex: "F0DEE4"),
        onSurfaceVariant: Color(hex: "504349")
    )
    
    static let dark = AppColorScheme(
        themeType: .dark,
        primary: Color(hex: "FBB0D7"),
        onPrimary: Color(hex: "511D3D"),
        primaryContainer: Color(hex: "6C3454"),
        onPrimaryContainer: Color(hex: "FFD8E9"),
        secondary: Color(hex: "DFBDCC"),
        onSecondary: Color(hex: "402A35"),
        secondaryContainer: Color(hex: "58404C"),
        onSecondaryContainer: Color(hex: "FCD9E8"),
        background: Color(hex: "181115"),
        onBackground: Color(hex: "EDDFE3"),
        surface: Color(hex: "181115"),
        onSurface: Color(hex: "EDDFE3"),
        surfaceVariant: Color(hex: "504349"),
        onSurfaceVariant: Color(hex: "D4C2C8")
    )
} 
