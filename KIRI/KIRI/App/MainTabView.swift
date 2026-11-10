//
// MARK: - 파일 가이드
// 파일: App/MainTabView.swift
// 담당 화면: 인증 이후 메인 탭 컨테이너
// 주요 책임: 현재 탭 콘텐츠와 공통 KIRITabBar의 배치, 가족/세션 상태 전달을 담당합니다.
// UI 수정 위치: 탭바 좌우·하단 위치는 body의 padding, 화면 콘텐츠는 currentContent에서 조정합니다.
// 데이터 흐름: AppRouter → MainTabView → HomeView/MissionView/RecordView/MyPageView.
// 주의: 탭바 여백을 바꾸면 네 화면의 Safe Area와 마지막 콘텐츠 가시성이 함께 변합니다.
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
    @State private var isTabBarVisible = true

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
            // Figma outer navigation 영역은 390×97pt이며, 내부 352×65pt 바를
            // 좌우 19pt·하단 16pt 띄워 배치합니다.
            .padding(.horizontal, 19)
            .padding(.bottom, 16)
            .opacity(isTabBarVisible ? 1 : 0)
            .allowsHitTesting(isTabBarVisible)
            .zIndex(1)

        }
        .environment(\.kiriTabBarVisibility, $isTabBarVisible)
        .onChange(of: selectedTab) { _, _ in
            // 탭을 전환하면 각 탭의 루트 화면에서 탭바를 다시 표시합니다.
            isTabBarVisible = true
        }
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
