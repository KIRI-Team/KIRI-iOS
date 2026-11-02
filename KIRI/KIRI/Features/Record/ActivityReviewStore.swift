//
// MARK: - 파일 가이드
// 파일: Features/Record/ActivityReviewStore.swift
// 담당 영역: 기능별 SwiftUI 화면과 상태
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//

import Foundation
import UIKit

@Observable
final class ActivityReviewStore {
    private(set) var reviews: [String: ActivityReviewWriteView.Draft] = [:]

    private let storageKey = "kiri.activityReviews.v1"

    init() {
        load()
    }

    func save(
        _ draft: ActivityReviewWriteView.Draft,
        for key: String
    ) {
        reviews[key] = draft
        persist()
    }

    func remove(for key: String) {
        reviews.removeValue(forKey: key)
        persist()
    }

    private struct PersistedReview: Codable {
        let rating: Int
        let comment: String
        let wantsToRepeat: Bool
        let imageData: [Data]
    }

    private func persist() {
        let payload = reviews.reduce(into: [String: PersistedReview]()) { result, entry in
            let images = entry.value.images.compactMap {
                $0.jpegData(compressionQuality: 0.85)
            }
            result[entry.key] = PersistedReview(
                rating: entry.value.rating,
                comment: entry.value.comment,
                wantsToRepeat: entry.value.wantsToRepeat,
                imageData: images
            )
        }

        guard let data = try? JSONEncoder().encode(payload) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let payload = try? JSONDecoder().decode(
                [String: PersistedReview].self,
                from: data
              ) else {
            return
        }

        reviews = payload.reduce(into: [:]) { result, entry in
            let images = entry.value.imageData.compactMap(UIImage.init(data:))
            guard !images.isEmpty else { return }
            result[entry.key] = ActivityReviewWriteView.Draft(
                rating: entry.value.rating,
                images: images,
                comment: entry.value.comment,
                wantsToRepeat: entry.value.wantsToRepeat
            )
        }
    }
}
