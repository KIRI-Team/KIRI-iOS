import SwiftUI

@Observable
final class AppRouter {
    enum AppState {
        case onboarding
        case main
    }

    var appState: AppState = .onboarding

    func showOnboarding() {
        appState = .onboarding
    }

    func showMain() {
        appState = .main
    }
}
