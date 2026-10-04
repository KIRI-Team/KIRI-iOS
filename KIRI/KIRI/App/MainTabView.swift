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
            KIRIColor.Background.base
                .ignoresSafeArea()

            currentContent
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )

            KIRITabBar(
                selectedTab: $selectedTab
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 8)
        }
        .ignoresSafeArea(
            .keyboard,
            edges: .bottom
        )
    }

    // MARK: - Content

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

// MARK: - Preview

#Preview {
    MainTabView(
        userMode: .family,
        onLogout: {}
    )
}
