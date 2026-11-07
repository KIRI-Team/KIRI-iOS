//
// MARK: - 파일 가이드
// 파일: App/MainTabView.swift
// 담당 영역: 앱 시작·라우팅·탭 구성
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//

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
    let familyId: Int?
    let familyRole: String?
    let nickname: String?
    let tutorialIdentity: String?
    let familyState: AppRouter.FamilyState
    let onRetryFamilyState: () -> Void
    let onFamilyCreated: (String, String) -> Void
    let onLogout: () -> Void
    let onDeleteAccount: () async -> String?
    let onUpdateNickname: (String) async -> String?
    let onUpdateFamilyName: (String) async -> String?

    @State private var selectedTab: AppTab = .home
    @State private var homeTutorialStore: HomeTutorialStore

    init(
        userMode: AppRouter.UserMode,
        familyName: String?,
        familyInviteCode: String?,
        familyId: Int? = nil,
        familyRole: String? = nil,
        nickname: String? = nil,
        tutorialIdentity: String? = nil,
        familyState: AppRouter.FamilyState = .unknown,
        onRetryFamilyState: @escaping () -> Void = {},
        onFamilyCreated: @escaping (String, String) -> Void,
        onLogout: @escaping () -> Void
        , onDeleteAccount: @escaping () async -> String? = { nil },
        onUpdateNickname: @escaping (String) async -> String? = { _ in nil },
        onUpdateFamilyName: @escaping (String) async -> String? = { _ in nil }
    ) {
        self.userMode = userMode
        self.familyName = familyName
        self.familyInviteCode = familyInviteCode
        self.familyId = familyId
        self.familyRole = familyRole
        self.nickname = nickname
        self.tutorialIdentity = tutorialIdentity
        self.familyState = familyState
        self.onRetryFamilyState = onRetryFamilyState
        self.onFamilyCreated = onFamilyCreated
        self.onLogout = onLogout
        self.onDeleteAccount = onDeleteAccount
        self.onUpdateNickname = onUpdateNickname
        self.onUpdateFamilyName = onUpdateFamilyName
        _homeTutorialStore = State(
            initialValue: HomeTutorialStore(
                mode: {
                    switch userMode {
                    case .browse:
                        return .browse
                    case .family:
                        return .family
                    }
            }(), familyId: familyId, identity: tutorialIdentity
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
                familyId: familyId,
                nickname: nickname,
                familyRole: familyRole,
                familyState: familyState,
                onRetryFamilyState: onRetryFamilyState,
                tutorialStore: homeTutorialStore,
                onFamilyCreated: onFamilyCreated,
                onExploreMission: { selectedTab = .mission }
            )

        case .mission:
            MissionView()

        case .record:
            RecordView(userMode: userMode, familyState: familyState)

        case .myPage:
            MyPageView(
                onLogout: onLogout,
                onDeleteAccount: onDeleteAccount,
                nickname: nickname,
                familyName: familyName,
                familyId: familyId,
                familyRole: familyRole,
                onUpdateNickname: onUpdateNickname,
                onUpdateFamilyName: onUpdateFamilyName
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
