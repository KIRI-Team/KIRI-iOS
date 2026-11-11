//
// MARK: - 파일 가이드
// 파일: App/RootView.swift
// 담당 영역: 앱 시작·라우팅·탭 구성
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//

import SwiftUI

struct RootView: View {
    @State private var router = AppRouter()
    @State private var isSplashPresented = true
    @State private var shouldAnimateLoginEntrance = false

    var body: some View {
        ZStack {
            KIRIColor.background
                .ignoresSafeArea()

            if isSplashPresented {
                SplashView {
                    finishSplash()
                }
                .zIndex(3)
            } else {
                switch router.appState {
                case .authentication:
                    AuthFlowView(
                        animateLoginEntrance: shouldAnimateLoginEntrance,
                        initialTerms: router.pendingTerms,
                        initialAgreements: router.pendingTermAgreements,
                        onAuthenticated: { isNewUser in
                            Task { await router.completeAuthentication(isNewUser: isNewUser) }
                        }
                    )

                case .onboarding:
                    OnboardingFlowView(
                        invitation: router.pendingInvitation,
                        onEnterFamily: { name, code, familyId in
                            enterMain(familyName: name, inviteCode: code, familyId: familyId)
                        },
                        onBrowse: {
                            enterMain(browse: true)
                        },
                        onCancelInvitation: {
                            router.clearInvitation()
                        },
                        onBackToTerms: {
                            Task { await router.returnToTerms() }
                        }
                    )

                case .main:
                    MainTabView(
                        userMode: router.userMode,
                        familyName: router.familyName,
                        familyInviteCode: router.familyInviteCode,
                        familyId: router.familyId,
                        familyRole: router.familyRole,
                        nickname: router.nickname,
                        tutorialIdentity: router.tutorialIdentity,
                        familyState: router.familyState,
                        onRetryFamilyState: {
                            Task { await router.refreshFamilyState() }
                        },
                        onFamilyCreated: { name, code in
                            enterMain(familyName: name, inviteCode: code)
                        },
                        onLogout: {
                            shouldAnimateLoginEntrance = false
                            Task { await router.logout() }
                        },
                        onDeleteAccount: {
                            await router.deleteAccount()
                        },
                        onUpdateNickname: { value in
                            await router.updateNickname(value)
                        },
                        onUpdateFamilyName: { value in
                            await router.updateFamilyName(value)
                        }
                    )
                }
            }

        }
        .preferredColorScheme(.dark)
        .onAppear {
            #if DEBUG
            print(
                "[KIRI][RootView] onAppear: "
                    + "bundle=\(Bundle.main.bundleIdentifier ?? "unknown"), "
                    + "appState=\(Self.stateName(router.appState)), "
                    + "splash=\(isSplashPresented)"
            )
            #endif
        }
        .onChange(of: router.appState) { oldState, newState in
            #if DEBUG
            print(
                "[KIRI][RootView] appState changed: "
                    + "\(Self.stateName(oldState)) -> \(Self.stateName(newState))"
            )
            #endif
        }
    }

    private func finishSplash() {
        Task { @MainActor in
            await router.restoreSession()
            shouldAnimateLoginEntrance = router.appState == .authentication && router.pendingTerms == nil
            isSplashPresented = false
            #if DEBUG
            print(
                "[KIRI][RootView] finishSplash: "
                    + "appState=\(Self.stateName(router.appState)), "
                    + "termsPending=\(router.pendingTerms != nil)"
            )
            #endif
        }
    }

    private func enterMain(familyName: String? = nil, inviteCode: String? = nil, familyId: Int? = nil, browse: Bool = false) {
        if browse {
            router.enterBrowseMode()
        } else if let familyName, let inviteCode {
            router.enterFamilyMode(familyName: familyName, inviteCode: inviteCode, familyId: familyId)
        }
    }

    #if DEBUG
    private static func stateName(_ state: AppRouter.AppState) -> String {
        switch state {
        case .authentication: return "authentication"
        case .onboarding: return "onboarding"
        case .main: return "main"
        }
    }
    #endif
}

#Preview {
    RootView()
}
