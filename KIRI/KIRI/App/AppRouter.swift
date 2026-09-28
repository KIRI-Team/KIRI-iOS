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

    var appState: AppState
    var userMode: UserMode

    var pendingInvitation: FamilyInvitation?

    private let sessionStore: AppSessionStore

    var hasPendingInvitation: Bool {
        pendingInvitation != nil
    }

    init(
        sessionStore: AppSessionStore = AppSessionStore()
    ) {
        self.sessionStore = sessionStore

        if !sessionStore.isAuthenticated {
            appState = .authentication
            userMode = .browse
            return
        }

        if !sessionStore.isOnboardingCompleted {
            appState = .onboarding
            userMode = .browse
            return
        }

        switch sessionStore.userMode {
        case .family:
            userMode = .family

        case .browse:
            userMode = .browse

        case .none:
            userMode = .browse
        }

        appState = .main
    }

    func receiveInvitation(
        code: String,
        familyName: String? = nil
    ) {
        pendingInvitation = FamilyInvitation(
            code: code,
            familyName: familyName
        )

        if sessionStore.isAuthenticated {
            appState = .onboarding
        } else {
            appState = .authentication
        }
    }

    func completeAuthentication() {
        sessionStore.saveAuthenticationCompleted()
        appState = .onboarding
    }

    func showAuthentication() {
        appState = .authentication
    }

    func showOnboarding() {
        appState = .onboarding
    }

    func enterFamilyMode() {
        sessionStore.saveOnboardingCompleted(
            userMode: .family
        )

        pendingInvitation = nil
        userMode = .family
        appState = .main
    }

    func enterBrowseMode() {
        sessionStore.saveOnboardingCompleted(
            userMode: .browse
        )

        userMode = .browse
        appState = .main
    }

    func clearInvitation() {
        pendingInvitation = nil
    }

    func logout() {
        sessionStore.clearSession()

        pendingInvitation = nil
        userMode = .browse
        appState = .authentication
    }
}
