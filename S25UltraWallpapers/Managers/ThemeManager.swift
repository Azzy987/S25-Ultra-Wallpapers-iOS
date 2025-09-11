import SwiftUI

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    enum ThemeMode: String, CaseIterable {
        case system = "System"
        case light = "Light"
        case dark = "Dark"
    }
    
    @AppStorage("themeMode") var themeMode: ThemeMode = .system {
        didSet {
            updateTheme()
        }
    }
    
    @Published private(set) var theme: AppColorScheme
    private var observer: NSKeyValueObservation?
    
    private init() {
        self.theme = Self.getInitialTheme()
        setupThemeObserver()
    }
    
    private func setupThemeObserver() {
        // Observer for system theme changes when using system mode
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(systemThemeChanged),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // Observer for trait collection changes
        if #available(iOS 13.0, *) {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(systemThemeChanged),
                name: NSNotification.Name("UIApplicationDidChangeStatusBarOrientationNotification"),
                object: nil
            )
        }
    }
    
    @objc private func systemThemeChanged() {
        if themeMode == .system {
            updateTheme()
        }
    }
    
    deinit {
        observer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    func updateTheme() {
        withAnimation(.easeInOut(duration: 0.3)) {
            let newTheme: AppColorScheme
            
            switch themeMode {
            case .system:
                // Follow system appearance
                if #available(iOS 13.0, *) {
                    let userInterfaceStyle = UIScreen.main.traitCollection.userInterfaceStyle
                    newTheme = (userInterfaceStyle == .dark) ? AppColors.dark : AppColors.light
                } else {
                    newTheme = AppColors.light // Fallback for older iOS versions
                }
            case .dark:
                newTheme = AppColors.dark
            case .light:
                newTheme = AppColors.light
            }
            
            theme = newTheme
        }
    }
    
    private static func getInitialTheme() -> AppColorScheme {
        let themeMode = ThemeMode(rawValue: UserDefaults.standard.string(forKey: "themeMode") ?? "system") ?? .system
        
        switch themeMode {
        case .system:
            // Follow system appearance
            if #available(iOS 13.0, *) {
                let userInterfaceStyle = UIScreen.main.traitCollection.userInterfaceStyle
                return (userInterfaceStyle == .dark) ? AppColors.dark : AppColors.light
            } else {
                return AppColors.light // Fallback for older iOS versions
            }
        case .dark:
            return AppColors.dark
        case .light:
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
