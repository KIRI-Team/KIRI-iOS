import SwiftUI

struct RootView: View {
    @State private var router = AppRouter()

    var body: some View {
        ZStack {
            KIRIColor.background
                .ignoresSafeArea()

            switch router.appState {
            case .authentication:
                AuthFlowView {
                    router.completeAuthentication()
                }

            case .onboarding:
                OnboardingFlowView(
                    invitation: router.pendingInvitation,
                    onEnterFamily: { name, code in
                        router.enterFamilyMode(familyName: name, inviteCode: code)
                    },
                    onBrowse: {
                        router.enterBrowseMode()
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
                        router.enterFamilyMode(familyName: name, inviteCode: code)
                    },
                    onLogout: {
                        router.logout()
                    }
                )
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    RootView()
}
