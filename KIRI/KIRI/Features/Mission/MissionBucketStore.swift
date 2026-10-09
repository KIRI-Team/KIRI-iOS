import Foundation
import Combine

/// Shared, local-only bucket storage until the server API is connected.
final class MissionBucketStore: ObservableObject {
    static let shared = MissionBucketStore()
    private let storageKey = "kiri.mission.savedActivities.v1"

    struct SavedActivity: Codable, Identifiable, Equatable {
        var id: String { key }
        let key: String
        let title: String
        let placeName: String
    }

    @Published private(set) var activities: [SavedActivity] {
        didSet { persist() }
    }

    private init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([SavedActivity].self, from: data) {
            activities = saved
        } else {
            activities = []
        }
    }

    static func key(title: String, placeName: String) -> String {
        "\(title)|\(placeName)"
    }

    func contains(title: String, placeName: String) -> Bool {
        activities.contains { $0.key == Self.key(title: title, placeName: placeName) }
    }

    func setSaved(_ saved: Bool, title: String, placeName: String) {
        let key = Self.key(title: title, placeName: placeName)
        if saved {
            guard !activities.contains(where: { $0.key == key }) else { return }
            activities.insert(SavedActivity(key: key, title: title, placeName: placeName), at: 0)
        } else {
            activities.removeAll { $0.key == key }
        }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(activities) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
