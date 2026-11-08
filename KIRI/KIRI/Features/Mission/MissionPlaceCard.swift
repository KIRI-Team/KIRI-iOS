//
// MARK: - 파일 가이드
// 파일: Features/Mission/MissionPlaceCard.swift
// 담당 화면: 미션 목록의 장소 카드 (Figma 9901:23876)
// 주요 책임: 서버 미션의 이미지·제목·장소·태그·버킷 상태를 한 카드로 렌더링합니다.
// UI 수정 위치: 카드 여백은 padding, 정보 폭은 216pt frame, 이미지 크기는 thumbnail frame,
// 제목/장소 글꼴은 placeInformation, 태그 모양은 MissionPlaceTag에서 조정합니다.
// 데이터 흐름: MissionView → MissionPlaceCard → KIRIContentImage / AuthService 버킷 저장.
// 주의: 정보 폭과 이미지 폭의 합은 390pt Figma 프레임에서 카드가 겹치지 않도록 유지해야 합니다.
//

import SwiftUI

struct MissionPlaceCard: View {

    let title: String
    let placeName: String
    let district: String?
    let rating: Double?
    let tags: [String]
    let isRecommended: Bool
    let mockAssetName: String?
    let imageURL: URL?

    @Binding var isBookmarked: Bool

    init(
        title: String,
        placeName: String,
        district: String? = nil,
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
        HStack(alignment: .top, spacing: 17) {
            // 이미지는 고정 프레임을 유지하고, 정보 영역은 남은 폭만 사용합니다.
            // 두 영역을 같은 HStack의 독립 자식으로 두어 텍스트가 이미지 위로 그려질 수 없게 합니다.
            thumbnail
                .layoutPriority(0)

            VStack(alignment: .leading, spacing: 12) {
                placeInformation

                HStack(alignment: .center, spacing: 8) {
                    tagsView
                        .layoutPriority(0)
                    bookmarkButton
                        .layoutPriority(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
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
                // 부모 HStack에서 계산된 남은 폭 안에서만 두 줄까지 줄바꿈합니다.
                // fixedSize(width:)나 offset을 사용하지 않아 이미지 영역을 침범하지 않습니다.
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .layoutPriority(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(locationText)
                .font(KIRITypography.bodySmall)
                .tracking(-0.56)
                .foregroundStyle(KIRIColor.Text.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var locationText: String {
        guard let district, !district.isEmpty else { return placeName }
        return "\(placeName) · \(district)"
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
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
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
