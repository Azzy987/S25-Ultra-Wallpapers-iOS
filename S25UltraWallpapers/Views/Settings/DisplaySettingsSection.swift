import SwiftUI

struct DisplaySettingsSection: View {
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var settingsViewModel: SettingsViewModel
    @Environment(\.appTheme) private var theme
    
    init(settingsViewModel: SettingsViewModel) {
        self._settingsViewModel = StateObject(wrappedValue: settingsViewModel)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            SettingsSectionHeader(title: "Display Settings")
            
            VStack(spacing: 16) {
                // Theme Selection with Segmented Control
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "moon.circle.fill")
                            .foregroundColor(.indigo)
                            .font(.system(size: 20))
                            .frame(width: 24)
                        
                        Text("Theme")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(theme.onSurface)
                        
                        Spacer()
                    }
                    
                    Picker("Theme", selection: $themeManager.themeMode) {
                        Text("Light").tag(ThemeManager.ThemeMode.light)
                        Text("Dark").tag(ThemeManager.ThemeMode.dark)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.leading, 40) // Align with text
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.surface)
                    .shadow(color: theme.onSurface.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
    }
}

struct ThemeSelectionSheet: View {
    @StateObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(theme.onSurface)
                    
                    Spacer()
                    
                    Text("Select Theme")
                        .font(.headline)
                        .foregroundColor(theme.onSurface)
                    
                    Spacer()
                    
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                    .font(.system(size: 16, weight: .semibold))
                }
                .padding()
                .background(theme.surface)
                
                Divider()
                    .background(theme.onSurfaceVariant)
                
                // Theme options
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(ThemeManager.ThemeMode.allCases, id: \.self) { mode in
                            ThemeRow(
                                mode: mode,
                                isSelected: themeManager.themeMode == mode,
                                onTap: {
                                    themeManager.themeMode = mode
                                }
                            )
                        }
                    }
                }
                .background(theme.background)
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct ThemeRow: View {
    let mode: ThemeManager.ThemeMode
    let isSelected: Bool
    let onTap: () -> Void
    
    @Environment(\.appTheme) private var theme
    
    private var themeIcon: String {
        switch mode {
        case .light:
            return "sun.max"
        case .dark:
            return "moon"
        }
    }
    
    private var themeDescription: String {
        switch mode {
        case .light:
            return "Light appearance"
        case .dark:
            return "Dark appearance"
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: themeIcon)
                    .foregroundColor(theme.primary)
                    .font(.system(size: 20))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.rawValue)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.onSurface)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(themeDescription)
                        .font(.system(size: 14))
                        .foregroundColor(theme.onSurfaceVariant)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(theme.primary)
                        .font(.system(size: 16, weight: .medium))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Rectangle()
                    .fill(isSelected ? theme.surfaceVariant.opacity(0.5) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        
        Divider()
            .background(theme.onSurfaceVariant.opacity(0.3))
            .padding(.leading, 56)
    }
}

struct RefreshRateSelectionSheet: View {
    @StateObject var settingsViewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(theme.onSurface)
                    
                    Spacer()
                    
                    Text("Refresh Rate")
                        .font(.headline)
                        .foregroundColor(theme.onSurface)
                    
                    Spacer()
                    
                    Button("Apply") {
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                    .font(.system(size: 16, weight: .semibold))
                }
                .padding()
                .background(theme.surface)
                
                Divider()
                    .background(theme.onSurfaceVariant)
                
                // Refresh rate options
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(SettingsViewModel.RefreshRate.allCases, id: \.self) { rate in
                            RefreshRateRow(
                                rate: rate,
                                isSelected: settingsViewModel.selectedRefreshRate == rate,
                                onTap: {
                                    settingsViewModel.updateRefreshRate(rate)
                                }
                            )
                        }
                    }
                }
                .background(theme.background)
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct RefreshRateRow: View {
    let rate: SettingsViewModel.RefreshRate
    let isSelected: Bool
    let onTap: () -> Void
    
    @Environment(\.appTheme) private var theme
    
    private var rateDescription: String {
        switch rate {
        case .auto:
            return "Automatically adjust based on content"
        case .hz60:
            return "Standard refresh rate for all devices"
        case .hz90:
            return "Smoother scrolling and animations"
        case .hz120:
            return "Ultra-smooth experience (ProMotion)"
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: "display")
                    .foregroundColor(theme.primary)
                    .font(.system(size: 20))
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(rate.displayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.onSurface)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(rateDescription)
                        .font(.system(size: 14))
                        .foregroundColor(theme.onSurfaceVariant)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(theme.primary)
                        .font(.system(size: 16, weight: .medium))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Rectangle()
                    .fill(isSelected ? theme.surfaceVariant.opacity(0.5) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
        
        Divider()
            .background(theme.onSurfaceVariant.opacity(0.3))
            .padding(.leading, 56)
    }
}