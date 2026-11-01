
import Foundation

@Observable
final class AppSessionStore {
    enum UserMode: String {
        case family
        case browse
    }

    private enum Key {
        static let isAuthenticated = "kiri.isAuthenticated"
        static let isOnboardingCompleted = "kiri.isOnboardingCompleted"
        static let userMode = "kiri.userMode"
        static let familyName = "kiri.familyName"
        static let familyInviteCode = "kiri.familyInviteCode"
        static let familyId = "kiri.familyId"
        static let nickname = "kiri.nickname"
        static let familyRole = "kiri.familyRole"
    }

    private let defaults: UserDefaults

    var isAuthenticated: Bool {
        defaults.bool(forKey: Key.isAuthenticated)
    }

    var isOnboardingCompleted: Bool {
        defaults.bool(forKey: Key.isOnboardingCompleted)
    }

    var userMode: UserMode? {
        guard let rawValue = defaults.string(forKey: Key.userMode) else {
            return nil
        }

        return UserMode(rawValue: rawValue)
    }

    var familyName: String? { defaults.string(forKey: Key.familyName) }
    var familyInviteCode: String? { defaults.string(forKey: Key.familyInviteCode) }
    var familyId: Int? { defaults.object(forKey: Key.familyId) as? Int }
    var nickname: String? { defaults.string(forKey: Key.nickname) }
    var familyRole: String? { defaults.string(forKey: Key.familyRole) }

    func saveNickname(_ nickname: String) {
        defaults.set(nickname, forKey: Key.nickname)
    }

    func saveFamilyRole(_ role: String) {
        defaults.set(role, forKey: Key.familyRole)
    }

    func saveFamily(name: String, inviteCode: String, familyId: Int? = nil) {
        defaults.set(name, forKey: Key.familyName)
        defaults.set(inviteCode, forKey: Key.familyInviteCode)
        if let familyId { defaults.set(familyId, forKey: Key.familyId) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func saveAuthenticationCompleted() {
        defaults.set(
            true,
            forKey: Key.isAuthenticated
        )
    }

    func saveOnboardingCompleted(
        userMode: UserMode
    ) {
        defaults.set(
            true,
            forKey: Key.isOnboardingCompleted
        )

        defaults.set(
            userMode.rawValue,
            forKey: Key.userMode
        )
    }

    func clearSession() {
        // 인증 토큰과 함께 현재 계정에 귀속된 로컬 상태도 제거한다.
        // 서버의 회원·가족 데이터는 삭제하지 않으며, 다음 로그인 때 서버 상태를
        // 다시 조회해 복원해야 한다.
        [
            Key.isAuthenticated,
            Key.isOnboardingCompleted,
            Key.userMode,
            Key.familyName,
            Key.familyInviteCode
            , Key.familyId, Key.nickname, Key.familyRole
        ].forEach { defaults.removeObject(forKey: $0) }
    }
}
