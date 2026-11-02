//
// MARK: - 파일 가이드
// 파일: Features/Mission/MissionBucketStore.swift
// 담당 영역: 기능별 SwiftUI 화면과 상태
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//

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
