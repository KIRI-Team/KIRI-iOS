
import Foundation

@Observable
final class AppSessionStore {
    enum UserMode: String, Codable, Sendable {
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
        static let accountSnapshotPrefix = "kiri.account.snapshot."
    }

    /// Non-token account state retained across a local logout. It is keyed by
    /// the authenticated server identity and is never used without that key.
    struct AccountSnapshot: Codable, Equatable, Sendable {
        let identity: String
        var nickname: String?
        var familyRole: String?
        var familyId: Int?
        var familyName: String?
        var familyInviteCode: String?
        var userMode: UserMode?
        var hasFamily: Bool?
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

    func saveAccountSnapshot(_ snapshot: AccountSnapshot) {
        guard !snapshot.identity.isEmpty,
              let data = try? JSONEncoder().encode(snapshot)
        else { return }
        defaults.set(data, forKey: accountSnapshotKey(for: snapshot.identity))
    }

    func accountSnapshot(for identity: String) -> AccountSnapshot? {
        guard !identity.isEmpty,
              let data = defaults.data(forKey: accountSnapshotKey(for: identity))
        else { return nil }
        return try? JSONDecoder().decode(AccountSnapshot.self, from: data)
    }

    func removeAccountSnapshot(for identity: String) {
        guard !identity.isEmpty else { return }
        defaults.removeObject(forKey: accountSnapshotKey(for: identity))
    }

    /// Applies only a snapshot selected with the current authenticated identity.
    func applyAccountSnapshot(_ snapshot: AccountSnapshot) {
        if let nickname = snapshot.nickname { defaults.set(nickname, forKey: Key.nickname) }
        if let familyRole = snapshot.familyRole { defaults.set(familyRole, forKey: Key.familyRole) }
        if let familyId = snapshot.familyId { defaults.set(familyId, forKey: Key.familyId) }
        if let familyName = snapshot.familyName { defaults.set(familyName, forKey: Key.familyName) }
        if let inviteCode = snapshot.familyInviteCode { defaults.set(inviteCode, forKey: Key.familyInviteCode) }
        if let mode = snapshot.userMode { defaults.set(mode.rawValue, forKey: Key.userMode) }
    }

    /// Clears active-session presentation state without touching account snapshots.
    func clearActiveFamilyState() {
        [Key.familyName, Key.familyInviteCode, Key.familyId, Key.familyRole, Key.userMode]
            .forEach { defaults.removeObject(forKey: $0) }
    }

    private func accountSnapshotKey(for identity: String) -> String {
        let encoded = Data(identity.utf8).base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
        return Key.accountSnapshotPrefix + encoded
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
        // 인증 토큰과 현재 계정의 활성 화면 상태만 제거한다.
        // 계정별 스냅샷은 다음 동일 계정 로그인에서 서버 상태와 대조하기 위해 보존한다.
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
