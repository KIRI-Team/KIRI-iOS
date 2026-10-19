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
        HStack(spacing: 17) {
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
            minHeight: 127
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
        isRecommended
            ? KIRIColor.Background.tertiary
            : KIRIColor.Background.secondary
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
                .lineLimit(1)
                .frame(
                    maxWidth: .infinity,
                    minHeight: 27,
                    alignment: .leading
                )

            Text("\(placeName) · \(district)")
                .font(KIRITypography.bodySmall)
                .tracking(-0.56)
                .foregroundStyle(KIRIColor.Text.secondary)
                .lineLimit(1)
                .frame(
                    maxWidth: .infinity,
                    minHeight: 21,
                    alignment: .leading
                )
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
    }

    // MARK: - Bookmark

    private var bookmarkButton: some View {
        Button {
            isBookmarked.toggle()
        } label: {
            Image(
                systemName: isBookmarked
                    ? "bookmark.fill"
                    : "bookmark"
            )
            .font(
                .system(
                    size: 20,
                    weight: .medium
                )
            )
            .foregroundStyle(
                isBookmarked
                    ? KIRIColor.Icon.accent
                    : KIRIColor.Icon.secondary
            )
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
            .background(
                isAccent
                    ? KIRIColor.Background.greenSoft
                    : KIRIColor.Background.elevated
            )
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
