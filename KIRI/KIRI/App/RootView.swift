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
                    onEnterFamily: {
                        router.enterFamilyMode()
                    },
                    onBrowse: {
                        router.enterBrowseMode()
                    }
                )

            case .main:
                MainTabView(
                    userMode: router.userMode
                )
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    RootView()
}
