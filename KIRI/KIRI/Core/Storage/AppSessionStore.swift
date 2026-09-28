
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

        defaults.removeObject(
            forKey: Key.isOnboardingCompleted
        )

        defaults.removeObject(
            forKey: Key.userMode
        )
    }
}
