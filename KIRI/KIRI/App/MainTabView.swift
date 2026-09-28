import SwiftUI

struct MainTabView: View {
    enum AppTab: Hashable {
        case home
        case mission
        case record
        case myPage
    }

    let userMode: AppRouter.UserMode
    let onLogout: () -> Void

    @State private var selectedTab: AppTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            KIRIColor.background
                .ignoresSafeArea()

            currentContent
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )

            KIRITabBar(
                selectedTab: $selectedTab
            )
            .padding(.horizontal, 18)
            .padding(.bottom, 8)
        }
        .ignoresSafeArea(
            .keyboard,
            edges: .bottom
        )
    }

    @ViewBuilder
    private var currentContent: some View {
        switch selectedTab {
        case .home:
            HomeView(
                userMode: userMode
            )

        case .mission:
            MissionView()

        case .record:
            RecordView()

        case .myPage:
            MyPageView(
                onLogout: onLogout
            )
        }
    }
}

#Preview {
    MainTabView(
        userMode: .family,
        onLogout: {}
    )
}
