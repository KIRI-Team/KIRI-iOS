//
// MARK: - 파일 가이드
// 파일: Features/Mission/MissionActivityDetailView.swift
// 담당 화면: 미션 상세 (Figma 9901:24342)
// 주요 책임: 상세 API 상태, 히어로 이미지, 활동 정보 카드, 세그먼트와 버킷 저장 CTA를 표시합니다.
// UI 수정 위치: 상단 여백은 detailContent의 padding, 이미지 높이는 heroImage의 frame(height:),
// 카드 행 간격은 ActivityDetailCard의 VStack spacing, 하단 CTA는 bottomBar에서 조정합니다.
// 데이터 흐름: MissionView → missionId → AuthService.missionDetail → MissionDetailResult.
// 주의: 서버에 없는 추천 활동·맞춤템·주변 장소를 임의로 생성하지 않습니다.
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
    private let allowsRecommendationNavigation: Bool

    @State private var detail: MissionDetailResult?
    @State private var isLoadingDetail = false
    @State private var detailError: String?
    @State private var isSavingBookmark = false
    @State private var bookmarkError: String?
    @State private var isShowingBucketToast = false
    @State private var selectedSegment: DetailSegment = .recommended
    @State private var familyRecommendation: FamilyRecommendationResult?
    @State private var recommendationError: String?
    @State private var isLoadingRecommendation = false
    @State private var selectedRecommendation: FamilyRecommendationResult?
    @State private var recommendationIsBookmarked = false

    fileprivate enum DetailSegment: String, CaseIterable, Hashable {
        case recommended = "추천 활동"
        case reviews = "리뷰"
    }

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
        previewDetail: MissionDetailResult? = nil,
        isBookmarked: Binding<Bool>,
        allowsRecommendationNavigation: Bool = true,
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
        self._detail = State(initialValue: previewDetail)
        self._isBookmarked = isBookmarked
        self.allowsRecommendationNavigation = allowsRecommendationNavigation
        self.onBack = onBack
    }

    var body: some View {
        ZStack {
            KIRIColor.Background.base.ignoresSafeArea()
            VStack(spacing: 0) {
                navigationBar
                ScrollView(showsIndicators: false) {
                    detailContent
                }
                .safeAreaInset(edge: .bottom, spacing: 0) { Color.clear.frame(height: 86) }
                bottomBar
            }
        }
        .task {
            await loadDetail()
            await loadFamilyRecommendation()
        }
        .fullScreenCover(item: $selectedRecommendation) { recommendation in
            MissionActivityDetailView(
                missionId: recommendation.missionId,
                title: recommendation.title,
                placeName: "",
                district: MissionDisplayLabel.category(recommendation.category) ?? "",
                rating: nil,
                tags: [MissionDisplayLabel.category(recommendation.category)].compactMap { $0 },
                isRecommended: false,
                imageURL: recommendation.imageUrl,
                isBookmarked: $recommendationIsBookmarked,
                allowsRecommendationNavigation: false,
                onBack: { selectedRecommendation = nil }
            )
        }
    }

    private var detailContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            heroImage

            if isLoadingDetail && detail == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else if let detailError {
                VStack(alignment: .leading, spacing: 8) {
                    Text(detailError)
                        .font(KIRITypography.bodySmall)
                        .foregroundStyle(KIRIColor.Text.secondary)
                    Button("다시 시도") { Task { await loadDetail() } }
                        .font(KIRITypography.captionMedium)
                        .foregroundStyle(KIRIColor.Text.accent)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
            }

            // 상세 조회가 실패한 경우 목록 응답의 제목·장소를 성공 데이터처럼
            // 보여주지 않습니다. 재시도 상태와 실제 상세 응답을 분리해야
            // 누락된 필드나 서버 오류를 사용자가 정상 데이터로 오해하지 않습니다.
            if detailError == nil || detail != nil {
                VStack(alignment: .leading, spacing: 0) {
                    if isRecommended {
                        Text("끼리추천")
                            .font(KIRITypography.captionMedium)
                            .foregroundStyle(KIRIColor.Text.accent)
                            .frame(width: 63, height: 33)
                            .background(KIRIColor.Background.greenSoft)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .padding(.bottom, 12)
                    }

                    Text(detail?.title ?? title)
                        .font(KIRITypography.headingSmall)
                        .foregroundStyle(KIRIColor.Text.strong)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(minHeight: 40, alignment: .leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 23)

                    ActivityDetailCard(detail: detail, fallbackPlace: placeName)
                }
                .padding(.horizontal, 18)
                .padding(.top, 20)
                .padding(.bottom, 34)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(KIRIColor.Background.primary)

                VStack(spacing: 0) {
                    DetailSegmentedControl(selection: $selectedSegment)
                        .padding(.top, 36)
                        .padding(.bottom, 34)

                    if selectedSegment == .recommended {
                        recommendationContent
                    } else {
                        Text("아직 등록된 리뷰가 없어요")
                            .font(KIRITypography.bodySmall)
                            .foregroundStyle(KIRIColor.Text.tertiary)
                            .frame(maxWidth: .infinity, minHeight: 140)
                    }

                    detailSections
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var navigationBar: some View {
        ZStack {
            Text("플레이스")
                .font(KIRITypography.headingSmall)
                .foregroundStyle(KIRIColor.Text.strong)
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(KIRIColor.Text.strong)
                        .frame(width: 52, height: 52)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("뒤로가기")
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 62)
        .background(KIRIColor.Background.secondary)
    }

    @ViewBuilder
    private var heroImage: some View {
        if (detail?.imageUrl ?? imageURL) != nil {
            KIRIContentImage(imageURL: detail?.imageUrl ?? imageURL, mockAssetName: mockAssetName) {
                KIRIColor.Background.secondary
            }
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .clipped()
            .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var recommendationContent: some View {
        if isLoadingDetail {
            ProgressView().frame(maxWidth: .infinity, minHeight: 140)
        } else {
            VStack(alignment: .leading, spacing: 16) {
                detailSectionTitle("오늘의 끼리 추천 활동", accent: true)
                unavailableRecommendationCard("추천 활동 데이터가 아직 없어요.")

                detailSectionTitle("오늘의 끼리 맞춤템", accent: false)
                if isLoadingRecommendation {
                    ProgressView().frame(maxWidth: .infinity, minHeight: 100)
                } else if let recommendationError {
                    VStack(spacing: 8) {
                        Text(recommendationError).font(KIRITypography.bodySmall).foregroundStyle(KIRIColor.Text.secondary)
                        Button("다시 시도") { Task { await loadFamilyRecommendation() } }
                    }.frame(maxWidth: .infinity, minHeight: 100)
                } else if let recommendation = familyRecommendation {
                    recommendationCard(recommendation)
                } else {
                    unavailableRecommendationCard("오늘의 맞춤 활동이 없어요.")
                }
            }
        }
    }

    private func loadFamilyRecommendation() async {
        guard !isLoadingRecommendation else { return }
        isLoadingRecommendation = true
        recommendationError = nil
        defer { isLoadingRecommendation = false }
        do {
            familyRecommendation = try await AuthService.shared.familyRecommendation()
        } catch {
            recommendationError = "맞춤 활동을 불러오지 못했어요."
        }
    }

    private func recommendationCard(_ recommendation: FamilyRecommendationResult) -> some View {
        Group {
            if allowsRecommendationNavigation {
                Button {
                    recommendationIsBookmarked = false
                    selectedRecommendation = recommendation
                } label: {
                    recommendationCardLabel(recommendation)
                }
                .buttonStyle(.plain)
            } else {
                recommendationCardLabel(recommendation)
            }
        }
    }

    private func recommendationCardLabel(_ recommendation: FamilyRecommendationResult) -> some View {
            HStack(spacing: 8) {
            KIRIContentImage(imageURL: recommendation.imageUrl, mockAssetName: nil) {
                KIRIColor.Background.tertiary
            }
            .frame(width: 52, height: 52)
            .clipped()
            VStack(alignment: .leading, spacing: 6) {
                Text(recommendation.title).font(KIRITypography.bodySmallMedium).foregroundStyle(KIRIColor.Text.strong).lineLimit(2)
                Text(recommendation.description).font(KIRITypography.caption).foregroundStyle(KIRIColor.Text.secondary).lineLimit(2)
                if !recommendation.recommendationReason.isEmpty {
                    Text(recommendation.recommendationReason).font(KIRITypography.caption).foregroundStyle(KIRIColor.Text.tertiary).lineLimit(2)
                }
            }
            Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .frame(width: 171, height: 110, alignment: .topLeading)
        .background(KIRIColor.Background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func detailSectionTitle(_ title: String, accent: Bool) -> some View {
        Text(title)
            .font(KIRITypography.headingSmall)
            .foregroundStyle(accent ? KIRIColor.Text.accent : KIRIColor.Text.strong)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func unavailableRecommendationCard(_ message: String) -> some View {
        Text(message)
            .font(KIRITypography.bodySmall)
            .foregroundStyle(KIRIColor.Text.tertiary)
            .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
            .padding(.horizontal, 18)
            .background(KIRIColor.Background.primary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var detailSections: some View {
        if let detail, !detail.prepareItems.isEmpty {
            VStack(alignment: .leading, spacing: 24) {
                // Figma 상세 화면에는 준비물 정보만 존재합니다.
                // API 응답의 steps는 보존하되, Figma에 없는 활동 단계 UI는 노출하지 않습니다.
                detailList(title: "준비물", items: detail.prepareItems)
            }
            .padding(.top, 28)
        }

        if let detail, let description = detail.description, !description.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("미션 소개")
                    .font(KIRITypography.headingSmall)
                    .foregroundStyle(KIRIColor.Text.strong)
                Text(description.replacingOccurrences(of: "\\n", with: "\n"))
                    .font(KIRITypography.bodySmall)
                    .foregroundStyle(KIRIColor.Text.secondary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 28)
        }
    }

    private func detailList(title: String, items: [MissionDetailItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(KIRITypography.headingSmall).foregroundStyle(KIRIColor.Text.strong)
            VStack(alignment: .leading, spacing: 12) {
                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title).font(KIRITypography.bodySmall).foregroundStyle(KIRIColor.Text.strong)
                        Text(item.description)
                            .font(KIRITypography.captionMedium)
                            .foregroundStyle(KIRIColor.Text.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(KIRIColor.Background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var bottomBar: some View {
        Button {
            guard !isBookmarked, detail?.bucketSaved != true, !isSavingBookmark, let missionId else { return }
            Task { await saveBookmark(missionId: missionId) }
        } label: {
            let saved = isBookmarked || detail?.bucketSaved == true
            HStack(spacing: 10) {
                Image(saved ? "mission_bookmark_active" : "mission_bookmark_disabled")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                Text(saved ? "버킷에 저장됨" : "버킷에 저장")
            }
            .font(KIRITypography.headingSmall)
            .foregroundStyle(saved ? KIRIColor.Text.accent : KIRIColor.Text.strong)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(saved ? KIRIColor.Primary.container : KIRIColor.Background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(isSavingBookmark || isBookmarked || detail?.bucketSaved == true)
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(KIRIColor.Background.base)
        .overlay(alignment: .top) {
            if let bookmarkError {
                Text(bookmarkError)
                    .font(KIRITypography.captionMedium)
                    .foregroundStyle(KIRIColor.Text.secondary)
                    .padding(.bottom, 4)
                    .offset(y: -22)
            }
            if isShowingBucketToast {
                Text("버킷에 저장했어요")
                    .font(KIRITypography.bodySmallMedium)
                    .foregroundStyle(KIRIColor.Text.onGreen)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(KIRIColor.Primary.default)
                    .clipShape(Capsule())
                    .offset(y: -58)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func saveBookmark(missionId: Int) async {
        isSavingBookmark = true
        bookmarkError = nil
        defer { isSavingBookmark = false }
        do {
            _ = try await AuthService.shared.saveMissionToBucket(missionId: missionId)
            isBookmarked = true
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    isShowingBucketToast = true
                }
            }
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) {
                    isShowingBucketToast = false
                }
            }
        } catch {
            bookmarkError = "버킷 저장에 실패했어요. 다시 시도해 주세요."
        }
    }

    private func loadDetail() async {
        guard let missionId else { return }
        await MainActor.run { isLoadingDetail = true; detailError = nil }
        do {
            let result = try await AuthService.shared.missionDetail(missionId: missionId)
            await MainActor.run {
                detail = result
                isBookmarked = result.bucketSaved
                isLoadingDetail = false
            }
        } catch {
            await MainActor.run { detailError = error.localizedDescription; isLoadingDetail = false }
        }
    }
}

private struct ActivityDetailCard: View {
    let detail: MissionDetailResult?
    let fallbackPlace: String

    private var place: String { detail?.place.name ?? fallbackPlace }
    private var openingTime: String? {
        guard let value = detail?.openingTime, !value.isEmpty else { return nil }
        return value
    }
    private var estimatedSteps: String? {
        guard let min = detail?.estimatedStepsMin else { return nil }
        if let max = detail?.estimatedStepsMax, max != min { return "\(min)~\(max)보" }
        return "\(min)보"
    }
    private var durationText: String? {
        guard let min = detail?.durationMinMinutes else { return nil }
        if let max = detail?.durationMaxMinutes, max != min { return "\(min)~\(max)분" }
        return "\(min)분"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let openingTime { row("시작 시간", openingTime) }
            row("장소", place)
            if let estimatedSteps, let durationText {
                HStack(alignment: .top, spacing: 14) {
                    compactRow("예상 걸음수", estimatedSteps)
                    compactRow("활동시간", durationText)
                }
            } else {
                if let estimatedSteps { row("예상 걸음수", estimatedSteps) }
                if let durationText { row("활동시간", durationText) }
            }
        }
        // Figma Activity Detail은 Pretendard Regular 16/26을 사용합니다.
        // 행이 늘어날 때 카드 높이도 함께 늘어나도록 고정 높이를 두지 않습니다.
        .font(KIRITypography.body)
        .foregroundStyle(KIRIColor.Text.primary)
        .padding(.horizontal, 26)
        .padding(.vertical, 17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 127, alignment: .leading)
        .background(KIRIColor.Background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(label).fixedSize(horizontal: true, vertical: false)
            Text("|")
            Text(value).fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func compactRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(label).fixedSize(horizontal: true, vertical: false)
            Text("|")
            Text(value).fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct DetailSegmentedControl: View {
    @Binding var selection: MissionActivityDetailView.DetailSegment

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MissionActivityDetailView.DetailSegment.allCases, id: \.self) { segment in
                Button(segment.rawValue) {
                    withAnimation(.easeInOut(duration: 0.2)) { selection = segment }
                }
                .font(KIRITypography.bodySmall)
                .foregroundStyle(selection == segment ? KIRIColor.Text.strong : KIRIColor.Text.tertiary)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(selection == segment ? KIRIColor.Background.elevated : .clear)
                .clipShape(Capsule())
            }
        }
        .padding(6)
        .frame(width: 223, height: 52)
        .background(KIRIColor.Background.secondary)
        .clipShape(Capsule())
    }
}

#Preview {
    MissionActivityDetailPreview()
}

struct MissionActivityDetailPreview: View {
    @State private var saved = false

    var body: some View {
        MissionActivityDetailView(
            title: "한강 뚜벅뚜벅 축제 가보기",
            placeName: "여의도 한강 공원",
            district: "영등포구",
            rating: nil,
            tags: [],
            isRecommended: true,
            mockAssetName: nil,
            previewDetail: MissionDetailResult(
                missionId: 1,
                title: "한강 뚜벅뚜벅 축제 가보기",
                description: "차 없는 잠수교를 천천히 걸으며 한강 풍경과 축제 분위기를 즐길 수 있어요!",
                category: "OUTDOOR",
                missionType: "PERMANENT",
                status: "ACTIVE",
                indoorOutdoor: "OUTDOOR",
                imageUrl: nil,
                imageSource: nil,
                startDate: nil,
                endDate: nil,
                openingTime: "오후 2시 50분",
                closingTime: nil,
                price: 0,
                durationMinMinutes: 120,
                durationMaxMinutes: nil,
                estimatedStepsMin: 20000,
                estimatedStepsMax: nil,
                sourceUrl: nil,
                place: MissionDetailPlace(placeId: 1, name: "여의도 한강 공원", address: "서울 영등포구", latitude: nil, longitude: nil),
                prepareItems: [],
                steps: [],
                bucketSaved: false,
                bucketState: "NOT_SAVED",
                averageRating: nil,
                reviewCount: 0
            ),
            isBookmarked: $saved,
            onBack: {}
        )
    }
}
