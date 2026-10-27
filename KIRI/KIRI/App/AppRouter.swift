import SwiftUI

@MainActor
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
    /// 세션 복원 중 약관 미동의가 확인된 경우 AuthFlowView가 표시할 약관 목록.
    var pendingTerms: [Term]?

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
        pendingTerms = nil

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

    /// 스플래시 이후 저장된 세션을 서버에서 재검증한다.
    /// refresh token 재발급과 약관 상태 조회가 모두 성공한 경우에만 기존 화면을 복원한다.
    func restoreSession() async {
        #if DEBUG
        print("[KIRI][Router] restoreSession: started")
        #endif

        guard Self.storedSessionExists(using: tokenStore) else {
            sessionStore.clearSession()
            pendingTerms = nil
            appState = .authentication
            return
        }

        do {
            _ = try await AuthService.shared.reissue()
            sessionStore.saveAuthenticationCompleted()

            let agreementStatus = try await AuthService.shared.agreementStatus()
            if !agreementStatus.termsAgreed {
                pendingTerms = try await AuthService.shared.terms()
                appState = .authentication
                #if DEBUG
                print("[KIRI][Router] restoreSession: terms required")
                #endif
                return
            }

            pendingTerms = nil
            if !sessionStore.isOnboardingCompleted {
                appState = .onboarding
                userMode = .browse
            } else {
                userMode = sessionStore.userMode == .family ? .family : .browse
                appState = .main
            }
            #if DEBUG
            print("[KIRI][Router] restoreSession: restored \(Self.stateName(appState))")
            #endif
        } catch {
            #if DEBUG
            print("[KIRI][Router] restoreSession: failed \(error.localizedDescription)")
            #endif
            do {
                try tokenStore.clear()
            } catch {
                #if DEBUG
                print("[KIRI][Router] restoreSession: token clear failed")
                #endif
            }
            sessionStore.clearSession()
            pendingTerms = nil
            appState = .authentication
        }
    }

    func logout() {
        do {
            try AuthService.shared.clearSession()
        } catch {
            #if DEBUG
            print("[KIRI][Router] logout: local token clear failed")
            #endif
            // 토큰 삭제에 실패한 경우 인증 화면으로 이동하지 않는다.
            // 남아 있는 자격 증명을 숨긴 채 세션을 전환하면 계정 혼동이 생길 수 있다.
            return
        }
        sessionStore.clearSession()

        pendingInvitation = nil
        userMode = .browse
        pendingTerms = nil
        appState = .authentication
    }
}
