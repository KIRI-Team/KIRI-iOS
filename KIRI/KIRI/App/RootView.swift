import SwiftUI

struct RootView: View {
    private enum TutorialMode: Equatable {
        case browse
        case family
    }

    @State private var router = AppRouter()
    @State private var isSplashPresented = true
    @State private var tutorialMode: TutorialMode?
    @AppStorage("kiri_browse_tutorial_completed") private var browseTutorialCompleted = false
    // Stable family ID가 제공되기 전까지 Mock의 가족 튜토리얼은 계정 단위로 보관한다.
    // 가족명·초대코드는 식별자로 저장하지 않는다.
    @AppStorage("kiri_family_tutorial_completed") private var familyTutorialCompleted = false

    var body: some View {
        ZStack {
            KIRIColor.background
                .ignoresSafeArea()

            if isSplashPresented {
                SplashView {
                    isSplashPresented = false
                }
                .transition(.opacity)
                .zIndex(3)
            } else {
                switch router.appState {
                case .authentication:
                    AuthFlowView {
                        router.completeAuthentication()
                    }

                case .onboarding:
                    OnboardingFlowView(
                        invitation: router.pendingInvitation,
                        onEnterFamily: { name, code in
                            enterMainAndShowTutorial(familyName: name, inviteCode: code)
                        },
                        onBrowse: {
                            enterMainAndShowTutorial(browse: true)
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
                            enterMainAndShowTutorial(familyName: name, inviteCode: code)
                        },
                        onLogout: {
                            router.logout()
                        }
                    )
                }
            }

            if let tutorialMode {
                HomeTutorialView(
                    mode: tutorialMode == .browse ? .browse : .family,
                    onComplete: { finishTutorial(tutorialMode) }
                )
                .transition(.opacity)
                .zIndex(2)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func finishTutorial(_ mode: TutorialMode) {
        switch mode {
        case .browse:
            browseTutorialCompleted = true

        case .family:
            familyTutorialCompleted = true
        }

        tutorialMode = nil
    }

    private func enterMainAndShowTutorial(familyName: String? = nil, inviteCode: String? = nil, browse: Bool = false) {
        if browse {
            router.enterBrowseMode()
        } else if let familyName, let inviteCode {
            router.enterFamilyMode(familyName: familyName, inviteCode: inviteCode)
        }
        let mode: TutorialMode = browse ? .browse : .family
        if shouldPresentTutorial(for: mode) {
            tutorialMode = mode
        }
    }

    private func shouldPresentTutorial(for mode: TutorialMode) -> Bool {
        switch mode {
        case .browse:
            return !browseTutorialCompleted

        case .family:
            return !familyTutorialCompleted
        }
    }
}

#Preview {
    RootView()
}
