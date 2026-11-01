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
    var nickname: String?
    var familyId: Int?
    var familyRole: String?
    /// 세션 복원 중 약관 미동의가 확인된 경우 AuthFlowView가 표시할 약관 목록.
    var pendingTerms: [Term]?
    var pendingTermAgreements: [TermAgreement] = []
    var lastSessionError: String?
    private(set) var isLoggingOut = false

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
        nickname = sessionStore.nickname
        familyId = sessionStore.familyId
        familyRole = sessionStore.familyRole

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
        pendingTermAgreements = []

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

    /// 온보딩 첫 단계에서 약관으로 돌아갈 때 서버의 최신 목록과 동의 상태를 다시 읽는다.
    func returnToTerms() async {
        let terms: [Term]
        do {
            terms = try await AuthService.shared.terms()
        } catch {
            #if DEBUG
            print("[KIRI][Router] returnToTerms failed: \(error.localizedDescription)")
            #endif
            // 네트워크/API 실패가 뒤로가기를 막지 않도록 빈 상태로 약관 화면을 연다.
            // 약관 화면의 재시도 버튼으로 최신 목록을 다시 요청할 수 있다.
            pendingTerms = []
            pendingTermAgreements = []
            appState = .authentication
            return
        }

        let agreements: [TermAgreement]
        do {
            agreements = try await AuthService.shared.agreementStatus().agreements
        } catch {
            #if DEBUG
            print("[KIRI][Router] agreement status unavailable: \(error.localizedDescription)")
            #endif
            agreements = []
        }

        pendingTerms = terms
        pendingTermAgreements = agreements
        appState = .authentication
    }

    func enterFamilyMode(familyName: String, inviteCode: String) {
        sessionStore.saveFamily(name: familyName, inviteCode: inviteCode)
        self.familyName = familyName
        self.familyInviteCode = inviteCode
        self.nickname = sessionStore.nickname
        self.familyId = sessionStore.familyId
        self.familyRole = sessionStore.familyRole
        sessionStore.saveOnboardingCompleted(
            userMode: .family
        )

        pendingInvitation = nil
        userMode = .family
        appState = .main
    }

    func enterBrowseMode() {
        self.nickname = sessionStore.nickname
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
                pendingTermAgreements = agreementStatus.agreements
                appState = .authentication
                #if DEBUG
                print("[KIRI][Router] restoreSession: terms required")
                #endif
                return
            }

            pendingTerms = nil
            pendingTermAgreements = []
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
        } catch let error as APIError {
            #if DEBUG
            print("[KIRI][Router] restoreSession: failed \(error.localizedDescription)")
            #endif
            lastSessionError = error.localizedDescription
            // 인증 만료(401)만 세션을 폐기한다. 서버 5xx/네트워크 오류에서는
            // refresh token을 보존해 재시도할 수 있게 한다.
            if case .unauthorized = error {
                do { try tokenStore.clear() } catch {
                    #if DEBUG
                    print("[KIRI][Router] restoreSession: token clear failed")
                    #endif
                }
                sessionStore.clearSession()
                pendingTerms = nil
                pendingTermAgreements = []
            }
            appState = .authentication
        } catch {
            lastSessionError = error.localizedDescription
            appState = .authentication
        }
    }

    func logout() async {
        guard !isLoggingOut else { return }
        isLoggingOut = true
        var serverLogoutFailed = false
        if Self.storedSessionExists(using: tokenStore) {
            do {
                try await AuthService.shared.logout()
            } catch {
                serverLogoutFailed = true
                #if DEBUG
                print("[KIRI][Router] logout: server request failed \(error.localizedDescription)")
                #endif
            }
        }
        do {
            try tokenStore.clear()
        } catch {
            #if DEBUG
            print("[KIRI][Router] logout: local token clear failed")
            #endif
            isLoggingOut = false
            lastSessionError = "기기에서 로그인 정보를 삭제하지 못했습니다."
            return
        }
        sessionStore.clearSession()

        pendingInvitation = nil
        userMode = .browse
        pendingTerms = nil
        pendingTermAgreements = []
        lastSessionError = serverLogoutFailed
            ? "서버 로그아웃에 실패했지만 이 기기에서는 로그아웃했습니다."
            : nil
        appState = .authentication
        isLoggingOut = false
    }
}
