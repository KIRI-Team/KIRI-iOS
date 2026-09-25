
import SwiftUI

struct MyPageView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("마이")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("마이")
        }
    }
}

#Preview {
    MyPageView()
}
