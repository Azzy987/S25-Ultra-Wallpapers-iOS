import SwiftUI

struct SectionHeader: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                
            
            Spacer()
            
            Button(action: action) {
                Text("More")
                    .font(.subheadline)
            }
        }
    }
} 
