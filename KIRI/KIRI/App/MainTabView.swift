import SwiftUI

struct MainTabView: View {

    enum AppTab: Hashable {
        case home
        case mission
        case record
        case myPage
    }

    let userMode: AppRouter.UserMode
    let familyName: String?
    let familyInviteCode: String?
    let onFamilyCreated: (String, String) -> Void
    let onLogout: () -> Void

    @State private var selectedTab: AppTab = .home
    @State private var homeTutorialStore: HomeTutorialStore

    init(
        userMode: AppRouter.UserMode,
        familyName: String?,
        familyInviteCode: String?,
        onFamilyCreated: @escaping (String, String) -> Void,
        onLogout: @escaping () -> Void
    ) {
        self.userMode = userMode
        self.familyName = familyName
        self.familyInviteCode = familyInviteCode
        self.onFamilyCreated = onFamilyCreated
        self.onLogout = onLogout
        _homeTutorialStore = State(
            initialValue: HomeTutorialStore(
                mode: {
                    switch userMode {
                    case .browse:
                        return .browse
                    case .family:
                        return .family
                    }
                }()
            )
        )
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            KIRIColor.Background.base
                .ignoresSafeArea()

            currentContent
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
                .zIndex(homeTutorialStore.isActive ? 2 : 0)

            KIRITabBar(
                selectedTab: $selectedTab
            )
            .padding(.horizontal, 18)
            .padding(.bottom, 8)
            .zIndex(1)

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
                userMode: userMode,
                familyName: familyName,
                familyInviteCode: familyInviteCode,
                tutorialStore: homeTutorialStore,
                onFamilyCreated: onFamilyCreated
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
        familyName: "끼리네 가족",
        familyInviteCode: "KIRI24",
        onFamilyCreated: { _, _ in },
        onLogout: {}
    )
}
