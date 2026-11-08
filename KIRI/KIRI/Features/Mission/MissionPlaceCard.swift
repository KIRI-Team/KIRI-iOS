//
// MARK: - 파일 가이드
// 파일: Features/Mission/MissionPlaceCard.swift
// 담당 영역: 기능별 SwiftUI 화면과 상태
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//

import SwiftUI

struct MissionPlaceCard: View {

    let title: String
    let placeName: String
    let district: String
    let rating: Double?
    let tags: [String]
    let isRecommended: Bool
    let mockAssetName: String?
    let imageURL: URL?

    @Binding var isBookmarked: Bool

    init(
        title: String,
        placeName: String,
        district: String,
        rating: Double?,
        tags: [String],
        isRecommended: Bool,
        mockAssetName: String? = nil,
        imageURL: URL? = nil,
        isBookmarked: Binding<Bool>
    ) {
        self.title = title
        self.placeName = placeName
        self.district = district
        self.rating = rating
        self.tags = tags
        self.isRecommended = isRecommended
        self.mockAssetName = mockAssetName
        self.imageURL = imageURL
        self._isBookmarked = isBookmarked
    }

    var body: some View {
        HStack(alignment: .center, spacing: 17) {
            thumbnail

            VStack(
                alignment: .leading,
                spacing: 21
            ) {
                placeInformation

                HStack(spacing: 0) {
                    tagsView

                    Spacer(minLength: 8)

                    bookmarkButton
                }
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 18)
        .frame(
            maxWidth: .infinity,
            minHeight: 136
        )
        .background(cardBackground)
        .clipShape(
            RoundedRectangle(
                cornerRadius: KIRIRadius.small
            )
        )
    }

    // MARK: - Background

    private var cardBackground: Color {
        // Figma KIRI/Place Card의 추천·일반 상태 모두 #252524 계열을 사용합니다.
        // 추천 여부는 태그 색상으로만 구분하고 카드 배경은 동일하게 유지합니다.
        KIRIColor.Background.primary
    }

    // MARK: - Thumbnail

    private var thumbnail: some View {
        ZStack(alignment: .topLeading) {
            KIRIContentImage(imageURL: imageURL, mockAssetName: mockAssetName) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(KIRIColor.Background.elevated)
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))

            if let rating {
                ratingBadge(rating)
                    .padding(7)
            }
        }
        .frame(
            width: 91,
            height: 91
        )
    }

    // MARK: - Rating

    private func ratingBadge(
        _ rating: Double
    ) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(
                    .system(
                        size: 9,
                        weight: .medium
                    )
                )
                .foregroundStyle(KIRIColor.Icon.strong)
                .frame(
                    width: 12,
                    height: 12
                )

            Text(
                rating.formatted(
                    .number.precision(
                        .fractionLength(1)
                    )
                )
            )
            .font(KIRITypography.navigation)
            .tracking(-0.4)
            .foregroundStyle(KIRIColor.Text.tertiary)
            .frame(height: 14)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            KIRIColor.Background.tertiary
        )
        .clipShape(Capsule())
    }

    // MARK: - Information

    private var placeInformation: some View {
        VStack(
            alignment: .leading,
            spacing: 2
        ) {
            Text(title)
                .font(KIRITypography.headingSmall)
                .tracking(-0.72)
                .foregroundStyle(KIRIColor.Text.strong)
                // Figma의 216pt 정보 영역 안에서 긴 제목은 최대 두 줄로 확장합니다.
                // 고정 높이나 offset으로 줄바꿈을 덮지 않아 장소명이 겹치지 않습니다.
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(placeName) · \(district)")
                .font(KIRITypography.bodySmall)
                .tracking(-0.56)
                .foregroundStyle(KIRIColor.Text.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Tags

    private var tagsView: some View {
        HStack(spacing: 8) {
            if isRecommended {
                MissionPlaceTag(
                    title: "끼리추천",
                    isAccent: true
                )
            }

            ForEach(
                Array(
                    tags.prefix(
                        isRecommended ? 1 : 2
                    )
                ),
                id: \.self
            ) { tag in
                MissionPlaceTag(
                    title: tag,
                    isAccent: false
                )
            }
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
    }

    // MARK: - Bookmark

    private var bookmarkButton: some View {
        Button {
            isBookmarked.toggle()
        } label: {
            // Figma KIRI/Icon/Action/Bookmark의 24pt 원본 SVG를 상태별로 사용합니다.
            Image(isBookmarked ? "mission_bookmark_active" : "mission_bookmark_disabled")
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
            .frame(
                width: 24,
                height: 24
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            isBookmarked
                ? "버킷에서 제거"
                : "버킷에 저장"
        )
    }
}

// MARK: - Tag

private struct MissionPlaceTag: View {

    let title: String
    let isAccent: Bool

    var body: some View {
        Text(title)
            .font(KIRITypography.captionMedium)
            .tracking(-0.48)
            .foregroundStyle(
                isAccent
                    ? KIRIColor.Text.accent
                    : KIRIColor.Text.tertiary
            )
            .lineLimit(1)
            .frame(height: 17)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(isAccent ? KIRIColor.Primary.container : KIRIColor.Background.elevated)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 5
                )
            )
    }
}

// MARK: - Preview

#Preview {
    MissionPlaceCardPreview()
}

private struct MissionPlaceCardPreview: View {

    @State private var isBookmarked = true

    var body: some View {
        ZStack {
            KIRIColor.Background.base
                .ignoresSafeArea()

            VStack(spacing: 16) {
                MissionPlaceCard(
                    title: "광장시장에서 시장음식 먹어보기",
                    placeName: "광장시장",
                    district: "종로구",
                    rating: nil,
                    tags: [
                        "혼잡도 높음"
                    ],
                    isRecommended: true,
                    isBookmarked: $isBookmarked
                )

                MissionPlaceCard(
                    title: "광장시장에서 시장음식 먹어보기",
                    placeName: "광장시장",
                    district: "종로구",
                    rating: 4.6,
                    tags: [
                        "대중교통 편리",
                        "혼잡도 높음"
                    ],
                    isRecommended: false,
                    isBookmarked: $isBookmarked
                )
            }
            .padding(.horizontal, 18)
        }
    }
}
