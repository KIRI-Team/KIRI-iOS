
import SwiftUI

struct RootView: View {
    @State private var router = AppRouter()

    var body: some View {
        switch router.appState {
        case .main:
            MainTabView()
        }
    }
}

#Preview {
    RootView()
}
