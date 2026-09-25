
import SwiftUI

struct MissionView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("미션")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("미션")
        }
    }
}

#Preview {
    MissionView()
}
