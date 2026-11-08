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
    private let imageDirectory: URL

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("KIRI/ReviewDraftImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        imageDirectory = support
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
        let imageFileNames: [String]?
        // 이전 버전 마이그레이션 전용. 새 저장값에는 포함하지 않습니다.
        let imageData: [Data]?

        enum CodingKeys: String, CodingKey {
            case rating, comment, wantsToRepeat, imageFileNames, imageData
        }

        init(rating: Int, comment: String, wantsToRepeat: Bool, imageFileNames: [String]) {
            self.rating = rating
            self.comment = comment
            self.wantsToRepeat = wantsToRepeat
            self.imageFileNames = imageFileNames
            self.imageData = nil
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            rating = try c.decode(Int.self, forKey: .rating)
            comment = try c.decode(String.self, forKey: .comment)
            wantsToRepeat = try c.decode(Bool.self, forKey: .wantsToRepeat)
            imageFileNames = try c.decodeIfPresent([String].self, forKey: .imageFileNames)
            imageData = try c.decodeIfPresent([Data].self, forKey: .imageData)
        }
    }

    private func persist() {
        let payload = reviews.reduce(into: [String: PersistedReview]()) { result, entry in
            let imageFileNames = entry.value.images.enumerated().compactMap { index, image in
                guard let data = image.jpegData(compressionQuality: 0.85) else { return nil }
                let fileName = "\(safeFilePrefix(entry.key))-\(index).jpg"
                do {
                    try data.write(to: imageDirectory.appendingPathComponent(fileName), options: .atomic)
                    return fileName
                } catch {
                    return nil
                }
            }
            result[entry.key] = PersistedReview(
                rating: entry.value.rating,
                comment: entry.value.comment,
                wantsToRepeat: entry.value.wantsToRepeat,
                imageFileNames: imageFileNames
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
            let imageURLs = entry.value.imageFileNames?.map { imageDirectory.appendingPathComponent($0) } ?? []
            var images = imageURLs.compactMap { UIImage(contentsOfFile: $0.path) }
            if images.isEmpty, let legacyImageData = entry.value.imageData {
                images = legacyImageData.compactMap(UIImage.init(data:))
                // 다음 저장부터는 이미지 바이트를 UserDefaults에 다시 쓰지 않고 파일로 이전합니다.
                if !images.isEmpty {
                    reviews[entry.key] = ActivityReviewWriteView.Draft(rating: entry.value.rating, images: images, comment: entry.value.comment, wantsToRepeat: entry.value.wantsToRepeat)
                }
            }
            guard !images.isEmpty else { return }
            result[entry.key] = ActivityReviewWriteView.Draft(
                rating: entry.value.rating,
                images: images,
                comment: entry.value.comment,
                wantsToRepeat: entry.value.wantsToRepeat
            )
        }
        // 이전 버전의 대용량 UserDefaults 값을 읽었다면 파일 기반 형식으로 즉시 마이그레이션합니다.
        if !reviews.isEmpty { persist() }
    }

    private func safeFilePrefix(_ key: String) -> String {
        let allowed = key.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) }
        return String(String.UnicodeScalarView(allowed)).prefix(40).description
    }
}
