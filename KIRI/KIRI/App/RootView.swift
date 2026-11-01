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
                        onEnterFamily: { name, code in
                            enterMain(familyName: name, inviteCode: code)
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
