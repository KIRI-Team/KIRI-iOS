import Foundation

enum AppEventTracker {
    static func record(_ name: String, properties: [String: String]? = nil) {
        let event = AppEventRequest(
            eventId: UUID().uuidString,
            eventName: name,
            properties: properties,
            platform: "IOS",
            appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            occurredAt: timestamp()
        )
        Task { _ = try? await AuthService.shared.recordAppEvent(event) }
    }

    private static func timestamp() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: Date())
    }
}
