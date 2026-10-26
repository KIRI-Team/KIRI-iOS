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

    var appState: AppState {
        didSet {
            #if DEBUG
            print(
                "[KIRI][Router] appState changed: "
                    + "\(Self.stateName(oldValue)) -> \(Self.stateName(appState))"
            )
            #endif
        }
    }
    var userMode: UserMode

    var pendingInvitation: FamilyInvitation?
    var familyName: String?
    var familyInviteCode: String?

    private let sessionStore: AppSessionStore
    private let tokenStore: AuthTokenStoring

    var hasPendingInvitation: Bool {
        pendingInvitation != nil
    }

    init(
        sessionStore: AppSessionStore = AppSessionStore(),
        tokenStore: AuthTokenStoring = KeychainAuthTokenStore.shared
    ) {
        self.sessionStore = sessionStore
        self.tokenStore = tokenStore
        familyName = sessionStore.familyName
        familyInviteCode = sessionStore.familyInviteCode

        #if DEBUG
        print(
            "[KIRI][Router] init: "
                + "authenticatedFlag=\(sessionStore.isAuthenticated), "
                + "tokenPresent=\(Self.storedSessionExists(using: tokenStore)), "
                + "onboardingCompleted=\(sessionStore.isOnboardingCompleted), "
                + "storedMode=\(sessionStore.userMode?.rawValue ?? "none")"
        )
        #endif

        // UserDefaults는 로그아웃·앱 삭제·이전 버전 데이터로 인해
        // 토큰과 불일치할 수 있으므로, 실제 Keychain 세션이 있을 때만
        // 인증 완료 상태를 신뢰한다.
        guard sessionStore.isAuthenticated,
              Self.storedSessionExists(using: tokenStore)
        else {
            sessionStore.clearSession()
            appState = .authentication
            userMode = .browse
            #if DEBUG
            print("[KIRI][Router] initial route: authentication")
            #endif
            return
        }

        if !sessionStore.isOnboardingCompleted {
            appState = .onboarding
            userMode = .browse
            #if DEBUG
            print("[KIRI][Router] initial route: onboarding")
            #endif
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
        #if DEBUG
        print("[KIRI][Router] initial route: main")
        #endif
    }

    #if DEBUG
    private static func stateName(_ state: AppState) -> String {
        switch state {
        case .authentication: return "authentication"
        case .onboarding: return "onboarding"
        case .main: return "main"
        }
    }
    #endif

    private static func storedSessionExists(
        using tokenStore: AuthTokenStoring
    ) -> Bool {
        do {
            guard let tokens = try tokenStore.read(),
                  !tokens.accessToken.trimmingCharacters(
                    in: .whitespacesAndNewlines
                  ).isEmpty
            else {
                return false
            }

            return true
        } catch {
            return false
        }
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

    func completeAuthentication(isNewUser: Bool = false) {
        sessionStore.saveAuthenticationCompleted()

        // 신규 회원은 약관 동의 직후 반드시 온보딩을 거친다.
        // 기존 회원은 로컬에 보존된 마지막 온보딩 상태를 복원한다.
        if isNewUser || !sessionStore.isOnboardingCompleted {
            appState = .onboarding
            return
        }

        switch sessionStore.userMode {
        case .family:
            userMode = .family
        case .browse, .none:
            userMode = .browse
        }
        appState = .main
    }

    func showAuthentication() {
        appState = .authentication
    }

    func showOnboarding() {
        appState = .onboarding
    }

    func enterFamilyMode(familyName: String, inviteCode: String) {
        sessionStore.saveFamily(name: familyName, inviteCode: inviteCode)
        self.familyName = familyName
        self.familyInviteCode = inviteCode
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
        // 인증 토큰만 폐기하고, 서버에 저장된 온보딩·가족 연결 상태의
        // 로컬 복원 정보는 다음 로그인에서 사용할 수 있도록 보존한다.
        try? AuthService.shared.clearSession()
        sessionStore.clearSession()

        pendingInvitation = nil
        userMode = .browse
        appState = .authentication
    }
}
