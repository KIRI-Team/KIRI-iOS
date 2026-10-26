
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

    func saveFamily(name: String, inviteCode: String) {
        defaults.set(name, forKey: Key.familyName)
        defaults.set(inviteCode, forKey: Key.familyInviteCode)
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
        defaults.removeObject(
            forKey: Key.isAuthenticated
        )
    }
}
