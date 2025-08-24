import SwiftUI

struct SettingsSectionHeader: View {
    let title: String
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(theme.onBackground)
            
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}