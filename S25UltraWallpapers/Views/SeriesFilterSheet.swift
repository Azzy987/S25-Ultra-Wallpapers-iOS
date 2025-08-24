import SwiftUI

struct SeriesFilterSheet: View {
    let availableSeries: [String]
    @Binding var selectedSeries: String?
    let onApplyFilter: (String?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @State private var localSelectedSeries: String?
    @State private var searchText: String = ""
    
    private var filteredSeries: [String] {
        if searchText.isEmpty {
            return availableSeries
        } else {
            return availableSeries.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    init(availableSeries: [String], selectedSeries: Binding<String?>, onApplyFilter: @escaping (String?) -> Void) {
        self.availableSeries = availableSeries
        self._selectedSeries = selectedSeries
        self.onApplyFilter = onApplyFilter
        self._localSelectedSeries = State(initialValue: selectedSeries.wrappedValue)
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
                    
                    Text("Filter by Series")
                        .font(.headline)
                        .foregroundColor(theme.onSurface)
                    
                    Spacer()
                    
                    Button("Apply") {
                        onApplyFilter(localSelectedSeries)
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                    .font(.system(size: 16, weight: .semibold))
                }
                .padding()
                .background(theme.surface)
                
                Divider()
                    .background(theme.onSurfaceVariant)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(theme.onSurfaceVariant)
                        .font(.system(size: 16))
                    
                    TextField("Search series...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(theme.onSurface)
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(theme.onSurfaceVariant)
                                .font(.system(size: 16))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.onSurfaceVariant.opacity(0.3), lineWidth: 1)
                        .background(theme.surface)
                )
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Series list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        // "All" option
                        SeriesRow(
                            title: "All Series",
                            isSelected: localSelectedSeries == nil,
                            onTap: {
                                localSelectedSeries = nil
                            }
                        )
                        
                        // Individual series (filtered)
                        ForEach(filteredSeries, id: \.self) { series in
                            SeriesRow(
                                title: series,
                                isSelected: localSelectedSeries == series,
                                onTap: {
                                    localSelectedSeries = series
                                }
                            )
                        }
                    }
                }
                .padding(.top, 8)
                .background(theme.background)
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct SeriesRow: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(title)
                    .font(.body)
                    .foregroundColor(theme.onSurface)
                
                Spacer() // Ensures full width coverage
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(theme.primary)
                        .font(.system(size: 16, weight: .medium))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity) // Ensure button takes full width
            .background(
                Rectangle()
                    .fill(isSelected ? theme.surfaceVariant.opacity(0.5) : Color.clear)
            )
            .contentShape(Rectangle()) // Make entire area tappable
        }
        .buttonStyle(PlainButtonStyle())
        
        Divider()
            .background(theme.onSurfaceVariant.opacity(0.3))
            .padding(.leading, 16)
    }
}