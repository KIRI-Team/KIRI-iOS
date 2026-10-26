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
                        onAuthenticated: {
                            router.completeAuthentication(isNewUser: $0)
                        }
                    )

                case .onboarding:
                    OnboardingFlowView(
                        invitation: router.pendingInvitation,
                        onEnterFamily: { name, code in
                            enterMain(familyName: name, inviteCode: code)
                        },
                        onBrowse: {
                            enterMain(browse: true)
                        },
                        onCancelInvitation: {
                            router.clearInvitation()
                        }
                    )

                case .main:
                    MainTabView(
                        userMode: router.userMode,
                        familyName: router.familyName,
                        familyInviteCode: router.familyInviteCode,
                        onFamilyCreated: { name, code in
                            enterMain(familyName: name, inviteCode: code)
                        },
                        onLogout: {
                            shouldAnimateLoginEntrance = false
                            router.logout()
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
        // 개발·인증 검증 단계에서는 콜드 스타트마다 로그인 화면을 먼저 표시한다.
        // 세션 복원은 서버 기반 검증을 추가한 뒤 별도 경로로 다시 연결한다.
        router.showAuthentication()
        #if DEBUG
        print(
            "[KIRI][RootView] finishSplash: "
                + "forcedAuthentication=true, "
                + "appState=\(Self.stateName(router.appState))"
        )
        #endif
        shouldAnimateLoginEntrance = true
        isSplashPresented = false
    }

    private func enterMain(familyName: String? = nil, inviteCode: String? = nil, browse: Bool = false) {
        if browse {
            router.enterBrowseMode()
        } else if let familyName, let inviteCode {
            router.enterFamilyMode(familyName: familyName, inviteCode: inviteCode)
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
