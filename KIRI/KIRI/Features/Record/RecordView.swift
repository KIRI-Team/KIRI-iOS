
import SwiftUI

struct RecordView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("기록")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("기록")
        }
    }
}

#Preview {
    RecordView()
}
