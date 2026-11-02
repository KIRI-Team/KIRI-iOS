//
// MARK: - 파일 가이드
// 파일: Features/Mission/MissionActivityDetailView.swift
// 담당 영역: 기능별 SwiftUI 화면과 상태
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//

import SwiftUI

struct MissionActivityDetailView: View {
    let missionId: Int?
    let title: String
    let placeName: String
    let district: String
    let rating: Double?
    let tags: [String]
    let isRecommended: Bool
    let mockAssetName: String?
    let imageURL: URL?
    @Binding var isBookmarked: Bool
    let onBack: () -> Void
    @State private var detail: MissionDetailResult?
    @State private var isLoadingDetail = false
    @State private var detailError: String?

    init(
        missionId: Int? = nil,
        title: String,
        placeName: String,
        district: String,
        rating: Double?,
        tags: [String],
        isRecommended: Bool,
        mockAssetName: String? = nil,
        imageURL: URL? = nil,
        isBookmarked: Binding<Bool>,
        onBack: @escaping () -> Void
    ) {
        self.missionId = missionId
        self.title = title
        self.placeName = placeName
        self.district = district
        self.rating = rating
        self.tags = tags
        self.isRecommended = isRecommended
        self.mockAssetName = mockAssetName
        self.imageURL = imageURL
        self._isBookmarked = isBookmarked
        self.onBack = onBack
    }

    var body: some View {
        ZStack {
            KIRIColor.Background.base.ignoresSafeArea()

            VStack(spacing: 0) {
                navigationBar

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        detailStatus
                        cover
                        titleSection
                        descriptionSection
                        placeSection
                        scheduleSection
                        activityStepsSection
                        tagsSection
                        Color.clear.frame(height: 24)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                }

                bottomBar
            }
        }
        .task { await loadDetail() }
    }

    @ViewBuilder
    private var detailStatus: some View {
        if isLoadingDetail && detail == nil {
            HStack(spacing: 8) {
                ProgressView()
                Text("미션 상세 정보를 불러오는 중이에요")
                    .font(KIRITypography.captionMedium)
                    .foregroundStyle(KIRIColor.Text.secondary)
            }
        } else if let detailError {
            VStack(alignment: .leading, spacing: 8) {
                Text(detailError)
                    .font(KIRITypography.bodySmall)
                    .foregroundStyle(KIRIColor.Text.secondary)
                Button("다시 시도") {
                    Task { await loadDetail() }
                }
                .font(KIRITypography.captionMedium)
                .foregroundStyle(KIRIColor.Text.accent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(KIRIColor.Background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
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
            KIRIContentImage(imageURL: detail?.imageUrl ?? imageURL, mockAssetName: mockAssetName) {
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

            Text(detail?.title ?? title)
                .font(KIRITypography.headingSmall)
                .foregroundStyle(KIRIColor.Text.strong)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(KIRIColor.Icon.secondary)
                Text("\(detail?.place.name ?? placeName) · \(detail?.district ?? district)")
                    .font(KIRITypography.bodySmall)
                    .foregroundStyle(KIRIColor.Text.secondary)
                Spacer(minLength: 0)
                if let rating = detail?.averageRating ?? rating {
                    Image(systemName: "star.fill")
                        .foregroundStyle(KIRIColor.Text.accent)
                    Text(rating.formatted(.number.precision(.fractionLength(1))))
                        .font(KIRITypography.bodySmall)
                        .foregroundStyle(KIRIColor.Text.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var descriptionSection: some View {
        if let description = detail?.description, !description.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("미션 소개")
                    .font(KIRITypography.headingSmall)
                    .foregroundStyle(KIRIColor.Text.strong)
                Text(description)
                    .font(KIRITypography.bodySmall)
                    .foregroundStyle(KIRIColor.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var placeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("장소 정보")
                .font(KIRITypography.headingSmall)
                .foregroundStyle(KIRIColor.Text.strong)

            VStack(alignment: .leading, spacing: 12) {
                informationRow("장소", value: detail?.place.name ?? placeName)
                informationRow("주소", value: detail?.place.address ?? district)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(KIRIColor.Background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    @ViewBuilder
    private var scheduleSection: some View {
        if let detail {
            let time = [detail.openingTime, detail.closingTime]
                .compactMap { $0 }
                .joined(separator: " - ")
            let price = detail.price.map { $0 == 0 ? "무료" : "\($0)원" }
            if !time.isEmpty || price != nil {
                VStack(alignment: .leading, spacing: 12) {
                    Text("이용 정보")
                        .font(KIRITypography.headingSmall)
                        .foregroundStyle(KIRIColor.Text.strong)
                    VStack(alignment: .leading, spacing: 12) {
                        if !time.isEmpty { informationRow("운영시간", value: time) }
                        if let price { informationRow("이용요금", value: price) }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(KIRIColor.Background.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    @ViewBuilder
    private var activityStepsSection: some View {
        if let detail, !detail.prepareItems.isEmpty || !detail.steps.isEmpty {
            VStack(alignment: .leading, spacing: 18) {
                if !detail.prepareItems.isEmpty {
                    detailList(title: "준비물", items: detail.prepareItems)
                }
                if !detail.steps.isEmpty {
                    detailList(title: "활동 단계", items: detail.steps)
                }
            }
        }
    }

    private func detailList(title: String, items: [MissionDetailItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(KIRITypography.headingSmall)
                .foregroundStyle(KIRIColor.Text.strong)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(KIRITypography.bodySmall)
                            .foregroundStyle(KIRIColor.Text.strong)
                        Text(item.description)
                            .font(KIRITypography.captionMedium)
                            .foregroundStyle(KIRIColor.Text.secondary)
                    }
                }
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
                    ForEach(detail?.tags ?? tags, id: \.self) { tag in
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
            guard !isBookmarked, detail?.bucketSaved != true else { return }
            isBookmarked = true
        } label: {
            HStack(spacing: 10) {
                let saved = isBookmarked || detail?.bucketSaved == true
                Image(systemName: saved ? "bookmark.fill" : "bookmark")
                Text(saved ? "저장됨" : "버킷에 저장")
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

    private func loadDetail() async {
        guard let missionId else { return }
        await MainActor.run {
            isLoadingDetail = true
            detailError = nil
        }
        do {
            let result = try await AuthService.shared.missionDetail(missionId: missionId)
            await MainActor.run {
                detail = result
                isLoadingDetail = false
            }
        } catch {
            await MainActor.run {
                detailError = error.localizedDescription
                isLoadingDetail = false
            }
            #if DEBUG
            print("[KIRI][Mission] detail load failed: missionId=\(missionId), error=\(error.localizedDescription)")
            #endif
        }
    }
}
