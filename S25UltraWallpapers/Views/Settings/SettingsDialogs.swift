import SwiftUI

// MARK: - Content Dialog (Privacy Policy, Terms, About)
struct ContentDialog: View {
    let title: String
    let content: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(content)
                        .font(.system(size: 14))
                        .foregroundColor(theme.onBackground)
                        .multilineTextAlignment(.leading)
                }
                .padding()
            }
            .background(theme.background)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    dismiss()
                }
                .foregroundColor(theme.primary)
            )
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Feature Request Dialog
struct FeatureRequestDialog: View {
    @StateObject private var settingsViewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @State private var featureTitle = ""
    @State private var featureDescription = ""
    @State private var showingEmptyFieldsAlert = false
    
    init(settingsViewModel: SettingsViewModel) {
        self._settingsViewModel = StateObject(wrappedValue: settingsViewModel)
    }
    
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
                    
                    Text("Feature Request")
                        .font(.headline)
                        .foregroundColor(theme.onSurface)
                    
                    Spacer()
                    
                    Button("Send") {
                        if featureTitle.isEmpty || featureDescription.isEmpty {
                            showingEmptyFieldsAlert = true
                        } else {
                            settingsViewModel.sendFeatureRequest(title: featureTitle, description: featureDescription)
                            dismiss()
                        }
                    }
                    .foregroundColor(theme.primary)
                    .font(.system(size: 16, weight: .semibold))
                    .disabled(featureTitle.isEmpty || featureDescription.isEmpty)
                }
                .padding()
                .background(theme.surface)
                
                Divider()
                    .background(theme.onSurfaceVariant)
                
                // Form Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Feature Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Feature Title")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(theme.onBackground)
                            
                            TextField("Enter a brief title for your feature request", text: $featureTitle)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        // Feature Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(theme.onBackground)
                            
                            TextField("Describe your feature request in detail...", text: $featureDescription)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        // Guidelines
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Guidelines")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(theme.onBackground)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                BulletPoint(text: "Be specific about what you'd like to see")
                                BulletPoint(text: "Explain how it would improve your experience")
                                BulletPoint(text: "Consider if it benefits other users too")
                            }
                        }
                    }
                    .padding()
                }
                .background(theme.background)
            }
        }
        .navigationViewStyle(.stack)
        .alert("Missing Information", isPresented: $showingEmptyFieldsAlert) {
            Button("OK") { }
        } message: {
            Text("Please fill in both the title and description fields.")
        }
    }
}

struct BulletPoint: View {
    let text: String
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(theme.onSurfaceVariant)
                .font(.system(size: 14))
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(theme.onSurfaceVariant)
                .multilineTextAlignment(.leading)
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    @Environment(\.appTheme) private var theme
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(theme.onSurfaceVariant.opacity(0.3), lineWidth: 1)
                    .background(theme.surface)
            )
            .foregroundColor(theme.onSurface)
    }
}

// MARK: - Version Info View
struct VersionInfoView: View {
    @StateObject private var settingsViewModel: SettingsViewModel
    @Environment(\.appTheme) private var theme
    
    init(settingsViewModel: SettingsViewModel) {
        self._settingsViewModel = StateObject(wrappedValue: settingsViewModel)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(settingsViewModel.fullVersionString)
                .font(.system(size: 14))
                .foregroundColor(theme.onSurfaceVariant)
            
            Button(action: {
                settingsViewModel.showingChangelog = true
            }) {
                Text("Tap to see what's new")
                    .font(.system(size: 12))
                    .foregroundColor(theme.primary)
                    .underline()
            }
        }
        .padding(.vertical, 20)
        .sheet(isPresented: $settingsViewModel.showingChangelog) {
            ContentDialog(
                title: "What's New",
                content: settingsViewModel.changelogText
            )
        }
    }
}

// MARK: - Settings Row Component
struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void
    let isLast: Bool
    
    @Environment(\.appTheme) private var theme
    
    init(icon: String, iconColor: Color, title: String, subtitle: String, action: @escaping () -> Void, isLast: Bool = false) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.isLast = isLast
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 20))
                    .frame(width: 24)
                
                // Text Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.onSurface)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(theme.onSurfaceVariant)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer() // Push chevron to the right
                
                // Chevron
                Image(systemName: "chevron.right")
                    .foregroundColor(theme.onSurfaceVariant)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity) // Ensure full width
            .background(Color.clear)
            .contentShape(Rectangle()) // Make entire area tappable
        }
        .buttonStyle(PlainButtonStyle())
        
        if !isLast {
            Divider()
                .background(theme.onSurfaceVariant.opacity(0.3))
                .padding(.leading, 60)
        }
    }
}