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

    var pendingInvitation: FamilyInvitation?

    var hasPendingInvitation: Bool {
        pendingInvitation != nil
    }

    func receiveInvitation(
        code: String,
        familyName: String? = nil
    ) {
        pendingInvitation = FamilyInvitation(
            code: code,
            familyName: familyName
        )

        appState = .authentication
    }

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
        pendingInvitation = nil
        userMode = .family
        appState = .main
    }

    func enterBrowseMode() {
        userMode = .browse
        appState = .main
    }

    func clearInvitation() {
        pendingInvitation = nil
    }
}
