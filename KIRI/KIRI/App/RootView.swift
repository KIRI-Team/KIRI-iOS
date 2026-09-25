import SwiftUI

struct RootView: View {
    @State private var router = AppRouter()

    var body: some View {
        ZStack {
            KIRIColor.background
                .ignoresSafeArea()

            switch router.appState {
            case .onboarding:
                OnboardingFlowView {
                    router.showMain()
                }

            case .main:
                MainTabView()
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    RootView()
}
