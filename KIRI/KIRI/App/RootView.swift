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
    }

    private func finishSplash() {
        shouldAnimateLoginEntrance = router.appState == .authentication
        isSplashPresented = false
    }

    private func enterMain(familyName: String? = nil, inviteCode: String? = nil, browse: Bool = false) {
        if browse {
            router.enterBrowseMode()
        } else if let familyName, let inviteCode {
            router.enterFamilyMode(familyName: familyName, inviteCode: inviteCode)
        }
    }
}

#Preview {
    RootView()
}
