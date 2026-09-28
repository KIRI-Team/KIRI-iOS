import SwiftUI

@Observable
final class AppRouter {
    enum AppState {
        case authentication
        case onboarding
        case main
    }

    enum UserMode {
        case family
        case browse
    }

    var appState: AppState = .authentication
    var userMode: UserMode = .browse

    func completeAuthentication() {
        appState = .onboarding
    }

    func showAuthentication() {
        appState = .authentication
    }

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
