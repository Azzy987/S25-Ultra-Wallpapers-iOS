import SwiftUI

struct ThemeKey: EnvironmentKey {
    static let defaultValue = AppColors.dark
}

extension EnvironmentValues {
    var appTheme: AppColorScheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
} 