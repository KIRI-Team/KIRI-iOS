import SwiftUI

@Observable
final class AppRouter {
    enum AppState {
        case onboarding
        case main
    }

    enum UserMode {
        case family
        case browse
    }

    var appState: AppState = .onboarding
    var userMode: UserMode = .browse

    func showOnboarding() {
        appState = .onboarding
    }

    func enterFamilyMode() {
        userMode = .family
        appState = .main
    }

    func enterBrowseMode() {
        userMode = .browse
        appState = .main
    }
}
