import SwiftUI

struct HomeView: View {
    let userMode: AppRouter.UserMode

    var body: some View {
        switch userMode {
        case .family:
            FamilyHomeView()

        case .browse:
            BrowseHomeView()
        }
    }
}

#Preview("Family") {
    HomeView(
        userMode: .family
    )
}

#Preview("Browse") {
    HomeView(
        userMode: .browse
    )
}
