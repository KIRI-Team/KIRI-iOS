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
