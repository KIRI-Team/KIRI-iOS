//
// MARK: - 파일 가이드
// 파일: Features/Mission/MissionPlaceCard.swift
// 담당 화면: 미션 목록의 장소 카드 (Figma 9901:23876)
// 주요 책임: 서버 미션의 이미지·제목·장소·태그·버킷 상태를 한 카드로 렌더링합니다.
// UI 수정 위치: 이미지 크기는 thumbnail의 frame(width:height:), 정보 여백은 body의 padding,
// 제목/장소 글꼴은 placeInformation, 태그 모양은 MissionPlaceTag에서 조정합니다.
// 데이터 흐름: MissionView → MissionPlaceCard → KIRIContentImage / AuthService 버킷 저장.
// 주의: Figma 9901:23876 기준으로 이미지는 왼쪽의 고정 91×91pt 영역에만 그려지고,
// 오른쪽 정보 열은 남은 너비만 사용합니다. 이미지와 텍스트를 overlay로 겹치지 않습니다.
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
    let onBookmarkTapped: (() -> Void)?

    init(
        title: String,
        placeName: String,
        district: String? = nil,
        rating: Double?,
        tags: [String],
        isRecommended: Bool,
        mockAssetName: String? = nil,
        imageURL: URL? = nil,
        isBookmarked: Binding<Bool>,
        onBookmarkTapped: (() -> Void)? = nil
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
        self.onBookmarkTapped = onBookmarkTapped
    }

    var body: some View {
        HStack(alignment: .top, spacing: 17) {
            // 카드 이미지와 텍스트를 별도 열로 분리합니다. 이 열은 어떤 원본 이미지
            // 비율이 들어와도 91×91pt를 벗어나지 않습니다.
            thumbnail

            VStack(alignment: .leading, spacing: 8) {
                placeInformation

                Spacer(minLength: 4)

                // 태그와 북마크는 정보 열의 하단에 둡니다. 태그가 여러 줄이 되면
                // 정보 열과 카드 높이가 함께 늘어나므로 이미지와 겹치지 않습니다.
                HStack(alignment: .bottom, spacing: 8) {
                    if !tagItems.isEmpty {
                        tagsView
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Spacer(minLength: 0)
                    }
                    bookmarkButton
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 136, alignment: .topLeading)
        .background(cardBackground)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 8
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
            // KIRIContentImage는 공통 컴포넌트라 호출부가 크기를 제약해야 합니다.
            // frame 뒤 clipped를 적용해 AsyncImage가 원본 크기로 카드 밖에 그려지지 않게 합니다.
            KIRIContentImage(imageURL: imageURL, mockAssetName: mockAssetName) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(KIRIColor.Background.elevated)
            }
            .frame(width: 91, height: 91)
            .clipped()
            if let rating {
                ratingBadge(rating)
                    .padding(6)
            }
        }
        .frame(width: 91, height: 91)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .clipped()
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
                .font(.custom("Pretendard-Medium", fixedSize: 16))
                .tracking(-0.64)
                .foregroundStyle(KIRIColor.Text.strong)
                // 정보 영역의 HStack에서 계산된 폭 안에서만 두 줄까지 줄바꿈합니다.
                // fixedSize(width:)나 offset을 사용하지 않아 이미지 영역을 침범하지 않습니다.
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(locationText)
                .font(.custom("Pretendard-Regular", fixedSize: 13))
                .tracking(-0.52)
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
        MissionTagFlow(items: tagItems)
    }

    private var tagItems: [MissionTagItem] {
        var items: [MissionTagItem] = []
        if isRecommended {
            items.append(MissionTagItem(title: "끼리추천", isAccent: true))
        }
        items.append(contentsOf: tags.map { MissionTagItem(title: $0, isAccent: false) })
        return items
    }

    // MARK: - Bookmark

    private var bookmarkButton: some View {
        Button {
            if let onBookmarkTapped {
                onBookmarkTapped()
            } else {
                isBookmarked.toggle()
            }
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

private struct MissionTagItem: Identifiable {
    let title: String
    let isAccent: Bool

    var id: String { "\(isAccent ? "accent" : "tag")-\(title)" }
}

/// 태그가 많아져도 카드 폭을 넘지 않고 다음 줄로 자연스럽게 이동시키는 레이아웃입니다.
private struct MissionTagFlow: View {
    let items: [MissionTagItem]

    var body: some View {
        MissionTagLayout {
            ForEach(items) { item in
                MissionPlaceTag(title: item.title, isAccent: item.isAccent)
            }
        }
    }
}

private struct MissionTagLayout: Layout {

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        layout(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let result = layout(proposal: ProposedViewSize(width: bounds.width, height: bounds.height), subviews: subviews)
        for (index, point) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: result.sizes[index].width, height: result.sizes[index].height)
            )
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint], sizes: [CGSize]) {
        let availableWidth = proposal.width ?? .infinity
        let spacing: CGFloat = 8
        let rowSpacing: CGFloat = 6
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > availableWidth {
                y += rowHeight + rowSpacing
                x = 0
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            sizes.append(size)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return (CGSize(width: proposal.width ?? max(0, x - spacing), height: y + rowHeight), positions, sizes)
    }
}

// MARK: - Tag

private struct MissionPlaceTag: View {

    let title: String
    let isAccent: Bool

    var body: some View {
        Text(title)
            .font(.custom("Pretendard-Medium", fixedSize: 11))
            .tracking(-0.44)
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

/// 실제 API 목록에는 포함되지 않는 UI 검증용 fixture입니다. SwiftUI Preview에서만 사용합니다.
struct MissionPlaceCardPreview: View {

    @State private var bookmarkedIDs: Set<String> = ["0"]

    private let fixtures = [
        ("전통주갤러리 관람하기", "전통주갤러리", "종로구", ["전시·문화"], true),
        ("어메이징거 방문하기", "어메이징거", "마포구", ["체험", "상시 운영"], false),
        ("가족과 우당 이회영 선생 흉상 나들이 가기", "우당 이회영 선생 흉상", "중구", ["산책·야외"], false),
        ("가족과 맥아더 사령관 동상에서 사진 찍기", "맥아더 사령관 동상", "인천 중구", [], false)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(Array(fixtures.enumerated()), id: \.offset) { index, fixture in
                    MissionPlaceCard(
                        title: fixture.0,
                        placeName: fixture.1,
                        district: fixture.2,
                        rating: index == 1 ? 4.6 : nil,
                        tags: fixture.3,
                        isRecommended: fixture.4,
                        mockAssetName: index.isMultiple(of: 2) ? "mission_gyeongbok" : "mission_namsan",
                        isBookmarked: Binding(
                            get: { bookmarkedIDs.contains("\(index)") },
                            set: { value in
                                if value { bookmarkedIDs.insert("\(index)") }
                                else { bookmarkedIDs.remove("\(index)") }
                            }
                        )
                    )
                }
            }
            .padding(18)
        }
        .background {
            KIRIColor.Background.base
                .ignoresSafeArea()
        }
    }
}
