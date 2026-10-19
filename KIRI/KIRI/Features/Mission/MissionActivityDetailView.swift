import SwiftUI

/// 미션 목록에서 선택한 활동의 상세 화면.
/// 현재 데이터는 MissionView의 로컬 예시 데이터이며 서버 연동 전 단계입니다.
struct MissionActivityDetailView: View {
    let title: String
    let placeName: String
    let district: String
    let rating: Double?
    let tags: [String]
    let isRecommended: Bool
    let mockAssetName: String? = nil
    let imageURL: URL? = nil
    @Binding var isBookmarked: Bool
    let onBack: () -> Void

    var body: some View {
        ZStack {
            KIRIColor.Background.base.ignoresSafeArea()

            VStack(spacing: 0) {
                navigationBar

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        cover
                        titleSection
                        placeSection
                        tagsSection
                        Color.clear.frame(height: 24)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                }

                bottomBar
            }
        }
    }

    private var navigationBar: some View {
        ZStack {
            Text("활동 상세")
                .font(KIRITypography.headingSmall)
                .foregroundStyle(KIRIColor.Text.strong)

            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(KIRIColor.Text.strong)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("뒤로가기")

                Spacer()
            }
            .padding(.horizontal, 10)
        }
        .frame(height: 62)
    }

    private var cover: some View {
        ZStack {
            KIRIContentImage(imageURL: imageURL, mockAssetName: mockAssetName) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(KIRIColor.Background.elevated)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .frame(height: 240)
        .accessibilityLabel("장소 이미지 미등록")
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isRecommended {
                Text("끼리추천")
                    .font(KIRITypography.captionMedium)
                    .foregroundStyle(KIRIColor.Text.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(KIRIColor.Background.greenSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            Text(title)
                .font(KIRITypography.headingSmall)
                .foregroundStyle(KIRIColor.Text.strong)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(KIRIColor.Icon.secondary)
                Text("\(placeName) · \(district)")
                    .font(KIRITypography.bodySmall)
                    .foregroundStyle(KIRIColor.Text.secondary)
                Spacer(minLength: 0)
                if let rating {
                    Image(systemName: "star.fill")
                        .foregroundStyle(KIRIColor.Text.accent)
                    Text(rating.formatted(.number.precision(.fractionLength(1))))
                        .font(KIRITypography.bodySmall)
                        .foregroundStyle(KIRIColor.Text.secondary)
                }
            }
        }
    }

    private var placeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("장소 정보")
                .font(KIRITypography.headingSmall)
                .foregroundStyle(KIRIColor.Text.strong)

            VStack(alignment: .leading, spacing: 12) {
                informationRow("장소", value: placeName)
                informationRow("지역", value: district)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(KIRIColor.Background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func informationRow(_ label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(label)
                .font(KIRITypography.bodySmall)
                .foregroundStyle(KIRIColor.Text.secondary)
                .frame(width: 44, alignment: .leading)
            Text(value)
                .font(KIRITypography.bodySmall)
                .foregroundStyle(KIRIColor.Text.strong)
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var tagsSection: some View {
        if !tags.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("활동 정보")
                    .font(KIRITypography.headingSmall)
                    .foregroundStyle(KIRIColor.Text.strong)

                HStack(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(KIRITypography.captionMedium)
                            .foregroundStyle(KIRIColor.Text.tertiary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(KIRIColor.Background.elevated)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }
        }
    }

    private var bottomBar: some View {
        Button {
            isBookmarked.toggle()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                Text(isBookmarked ? "버킷에서 제거" : "버킷에 저장")
            }
            .font(KIRITypography.headingSmall)
            .foregroundStyle(KIRIColor.Text.strong)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(KIRIColor.Background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(KIRIColor.Background.base)
    }
}
