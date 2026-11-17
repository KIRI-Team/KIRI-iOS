//
// MARK: - 파일 가이드
// 파일: Features/Mission/MissionActivityDetailView.swift
// 담당 화면: 미션 상세 (Figma 9901:24342)
// 주요 책임: 상세 API 상태, 히어로 이미지, 활동 정보 카드, 세그먼트와 버킷 저장 CTA를 표시합니다.
// UI 수정 위치: 상단 여백은 detailContent의 padding, 이미지 높이는 heroImage의 frame(height:),
// 카드 행 간격은 ActivityDetailCard의 VStack spacing, 하단 CTA는 bottomBar에서 조정합니다.
// 데이터 흐름: MissionView → missionId → AuthService.missionDetail → MissionDetailResult.
// 주의: 서버에 없는 추천 활동·맞춤템·주변 장소를 임의로 생성하지 않습니다.
// 맞춤템 카드의 우산 아이콘은 Figma 8438:5340 원본 SVG를
// Assets.xcassets/figma_umbrella.imageset에서 사용합니다.
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
    /// 일부 진입점(홈의 가족 배정 미션)은 저장보다 일정 생성을 우선 CTA로
    /// 사용합니다. nil이면 기존 미션 탭의 버킷 저장 CTA를 유지합니다.
    let onSchedule: (() -> Void)?
    private let allowsRecommendationNavigation: Bool

    @State private var detail: MissionDetailResult?
    @State private var isLoadingDetail = false
    @State private var detailError: String?
    @State private var essentials: [MissionDetailItem] = []
    @State private var isLoadingEssentials = false
    @State private var essentialsError: String?
    @State private var isSavingBookmark = false
    @State private var bookmarkError: String?
    @State private var isShowingBucketToast = false
    @State private var bucketToastMessage = "버킷에 저장했어요"
    @State private var isShowingBucketConfirmation = false
    @State private var selectedSegment: DetailSegment = .recommended
    @State private var nearbyMissions: [NearbyMissionResult] = []
    @State private var isLoadingNearby = false
    @State private var nearbyError: String?
    @State private var selectedNearby: NearbyMissionResult?
    @State private var nearbyIsBookmarked = false

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
        onSchedule: (() -> Void)? = nil,
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
        self.onSchedule = onSchedule
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

            if isShowingBucketConfirmation {
                BucketSaveConfirmationModal(
                    title: detail?.title ?? title,
                    onCancel: { isShowingBucketConfirmation = false },
                    onConfirm: {
                        isShowingBucketConfirmation = false
                        guard let missionId else { return }
                        Task { await saveBookmark(missionId: missionId) }
                    }
                )
                .transition(.opacity)
                .zIndex(10)
            }
        }
        // 각 섹션은 서로 다른 API에 의존합니다. 미션 상세가 느리거나
        // 실패해도 essentials 요청이 기다리지 않도록 독립적으로 시작하고,
        // 같은 상세 뷰가 다른 missionId로 재사용될 때도 다시 조회합니다.
        .task(id: missionId) { await loadDetail() }
        .task(id: missionId) { await loadEssentials() }
        .task(id: missionId) { await loadNearbyMissions() }
        .overlay(alignment: .top) {
            if isShowingBucketToast {
                KIRIToast(message: bucketToastMessage)
                    .padding(.horizontal, 18)
                    .safeAreaPadding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .fullScreenCover(item: $selectedNearby) { recommendation in
            MissionActivityDetailView(
                missionId: recommendation.missionId,
                title: recommendation.placeName,
                placeName: recommendation.placeName,
                district: recommendation.region,
                rating: nil,
                tags: [],
                isRecommended: false,
                imageURL: recommendation.imageUrl,
                isBookmarked: $nearbyIsBookmarked,
                allowsRecommendationNavigation: false,
                onBack: { selectedNearby = nil }
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
            // 맞춤템은 일정과 무관하게 별도 essentials 요청으로 조회합니다.
            // 미션 본문이 일시적으로 404/디코딩 실패해도 essentials 응답이
            // 도착했다면 서버가 준 이름·설명을 숨기지 않습니다.
            // 맞춤템은 미션 상세와 독립된 /essentials 응답으로 표시합니다.
            // 상세가 실패해도 빈 상태·오류·재시도 영역을 숨기지 않습니다.
            if missionId != nil || detail != nil {
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
                KIRIBackButton(action: onBack)
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
        VStack(alignment: .leading, spacing: 16) {
            // 추천 활동과 맞춤템은 서로 독립된 API입니다. 미션 상세 응답이
            // 늦거나 실패해도 essentials가 도착하면 맞춤템을 먼저 보여줍니다.
            familyActivitySectionTitle("오늘 끼리네 가족의 맞춤 활동")
                .padding(.bottom, 4)
            if isLoadingDetail && detail == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 96)
            } else if let detail, !detail.steps.isEmpty {
                VStack(spacing: 12) {
                    ForEach(detail.steps) { item in
                        activityCard(item)
                    }
                }
            } else {
                emptyRecommendationMessage("추천 활동이 아직 없어요.")
            }

            familyActivitySectionTitle("오늘 끼리네 가족의 맞춤템")
                .padding(.top, 20)
                .padding(.bottom, 4)
            if isLoadingEssentials {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 96)
            } else if let essentialsError {
                VStack(spacing: 8) {
                    Text(essentialsError)
                        .font(KIRITypography.bodySmall)
                        .foregroundStyle(KIRIColor.Text.secondary)
                    Button("다시 시도") { Task { await loadEssentials() } }
                }
                .frame(maxWidth: .infinity, minHeight: 96)
            } else if !essentials.isEmpty {
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(essentials) { item in
                        customItemCard(item)
                    }
                }
            } else {
                emptyRecommendationMessage("추천 준비물이 아직 없어요.")
            }

            detailSectionTitle("근처 놀거리 추천", accent: false)
                .padding(.top, 20)
                .padding(.bottom, 4)
            if isLoadingNearby {
                ProgressView().frame(maxWidth: .infinity, minHeight: 110)
            } else if let nearbyError {
                VStack(spacing: 8) {
                    Text(nearbyError)
                        .font(KIRITypography.bodySmall)
                        .foregroundStyle(KIRIColor.Text.secondary)
                    Button("다시 시도") { Task { await loadNearbyMissions() } }
                }
                .frame(maxWidth: .infinity, minHeight: 110)
            } else if nearbyMissions.isEmpty {
                unavailableRecommendationCard("근처에 추천할 놀거리가 없어요.")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(nearbyMissions) { item in
                            nearbyCard(item)
                        }
                    }
                }
            }
        }
    }

    private func loadNearbyMissions() async {
        guard let missionId, !isLoadingNearby else { return }
        isLoadingNearby = true
        nearbyError = nil
        defer { isLoadingNearby = false }
        do {
            nearbyMissions = try await AuthService.shared.nearbyMissions(missionId: missionId)
        } catch {
            nearbyMissions = []
            nearbyError = "근처 놀거리를 불러오지 못했어요."
        }
    }

    private func loadEssentials() async {
        guard let missionId, !isLoadingEssentials else { return }
        isLoadingEssentials = true
        essentialsError = nil
        defer { isLoadingEssentials = false }
        do {
            essentials = try await AuthService.shared.missionEssentials(missionId: missionId)
        } catch {
            essentials = []
            essentialsError = essentialsErrorMessage(for: error)
            #if DEBUG
            print("[KIRI][Mission] essentials load failed missionId=\(missionId) error=\(String(describing: error))")
            #endif
        }
    }

    private func essentialsErrorMessage(for error: Error) -> String {
        switch error {
        case APIError.unauthorized:
            return "로그인이 필요해요."
        case APIError.decodingFailed:
            return "맞춤템 응답을 확인하지 못했어요."
        case APIError.networkError(_):
            return "맞춤템을 불러오지 못했어요. 네트워크를 확인해 주세요."
        default:
            return "맞춤템을 불러오지 못했어요. 다시 시도해 주세요."
        }
    }

    @ViewBuilder
    private func nearbyCard(_ item: NearbyMissionResult) -> some View {
        let card = VStack(alignment: .leading, spacing: 0) {
            KIRIContentImage(imageURL: item.imageUrl, mockAssetName: nil) {
                KIRIColor.Background.tertiary
            }
            .frame(width: 251, height: 144)
            .clipped()
            VStack(alignment: .leading, spacing: 4) {
                Text(item.placeName)
                    .font(KIRITypography.bodySmallMedium)
                    .foregroundStyle(KIRIColor.Text.strong)
                    .lineLimit(2)
                Text(item.region)
                    .font(KIRITypography.bodySmall)
                    .foregroundStyle(KIRIColor.Text.secondary)
                    .lineLimit(1)
                if let distance = item.distance {
                    Text(Self.distanceLabel(distance))
                        .font(KIRITypography.caption)
                        .foregroundStyle(KIRIColor.Text.tertiary)
                }
                if !item.description.isEmpty {
                    Text(item.description)
                        .font(KIRITypography.caption)
                        .foregroundStyle(KIRIColor.Text.tertiary)
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, 19)
            .padding(.top, 18)
        }
        .frame(width: 251, height: 284, alignment: .topLeading)
        .background(KIRIColor.Background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))

        if item.missionId != nil {
            Button {
                nearbyIsBookmarked = false
                selectedNearby = item
            } label: { card }
            .buttonStyle(.plain)
        } else {
            card
        }
    }

    private static func distanceLabel(_ value: Double) -> String {
        // 계약의 기본 단위는 km입니다. 큰 값은 m 응답도 안전하게 표시합니다.
        value >= 100 ? String(format: "%.1fkm", value / 1000) : String(format: "%.1fkm", value)
    }

    private func customItemCard(_ item: MissionDetailItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                // 서버가 양산/우산 준비물을 반환할 때만 Figma 원본
                // 우산 리소스를 사용합니다. 다른 항목에 같은 아이콘을
                // 임의로 재사용하지 않습니다.
                if isUmbrellaItem(item) {
                    Image("figma_umbrella")
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
                Text(item.title)
                    .font(KIRITypography.bodySmallMedium)
                    .foregroundStyle(KIRIColor.Text.strong)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !item.description.isEmpty {
                Text(item.description)
                    .font(KIRITypography.caption)
                    .foregroundStyle(KIRIColor.Text.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .background(KIRIColor.Background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    /// Figma의 추천 활동은 항목마다 독립된 카드로 표시합니다. 서버의
    /// steps 배열 순서를 그대로 유지해 제목과 설명이 서로 섞이지 않도록
    /// 하고, 긴 텍스트는 카드 높이를 자연스럽게 확장합니다.
    private func activityCard(_ item: MissionDetailItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // 우산은 추천 활동 아이콘이 아니라 prepareItems의
            // 양산/우산 카드 전용 리소스입니다.
            Text(item.title)
                .font(KIRITypography.bodySmallMedium)
                .foregroundStyle(KIRIColor.Text.strong)
                .fixedSize(horizontal: false, vertical: true)
            if !item.description.isEmpty {
                Text(item.description)
                    .font(KIRITypography.caption)
                    .foregroundStyle(KIRIColor.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KIRIColor.Background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func isUmbrellaItem(_ item: MissionDetailItem) -> Bool {
        let value = item.title.lowercased()
        return value.contains("우산") || value.contains("양산") || value.contains("umbrella")
    }

    private func emptyRecommendationMessage(_ message: String) -> some View {
        Text(message)
            .font(KIRITypography.bodySmall)
            .foregroundStyle(KIRIColor.Text.tertiary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
            .background(KIRIColor.Background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func detailSectionTitle(_ title: String, accent: Bool) -> some View {
        Text(title)
            .font(KIRITypography.headingSmall)
            .foregroundStyle(accent ? KIRIColor.Text.accent : KIRIColor.Text.strong)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func familyActivitySectionTitle(_ title: String) -> some View {
        let parts = title.components(separatedBy: "끼리네 가족")
        return HStack(spacing: 0) {
            Text(parts.first ?? "")
            Text("끼리네 가족")
                .foregroundStyle(KIRIColor.Text.accent)
            Text(parts.dropFirst().joined(separator: "끼리네 가족"))
        }
        .font(KIRITypography.headingSmall)
        .foregroundStyle(KIRIColor.Text.strong)
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
        // Figma 9901:24342에는 별도의 "활동 소개"/"미션 소개" 섹션이 없습니다.
        // 상세 API의 description은 모델에 보존하지만, 존재하지 않는 UI를 만들지
        // 않도록 이 화면에서는 렌더링하지 않습니다.
    }


    private var bottomBar: some View {
        Button {
            if let onSchedule {
                onSchedule()
                return
            }
            guard !isSavingBookmark else { return }
            if isBookmarked {
                guard let missionId else { return }
                Task { await removeBookmark(missionId: missionId) }
            } else {
                withAnimation(.easeOut(duration: 0.2)) {
                    isShowingBucketConfirmation = true
                }
            }
        } label: {
            let saved = isBookmarked
            HStack(spacing: 10) {
                if onSchedule == nil {
                    Image(saved ? "mission_bookmark_active" : "mission_bookmark_disabled")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
                Text(onSchedule == nil ? (saved ? "버킷에 저장됨" : "버킷에 저장") : "일정 잡기")
            }
            .font(KIRITypography.headingSmall)
            .foregroundStyle(onSchedule == nil && saved ? KIRIColor.Text.accent : KIRIColor.Button.FilledAccent.contentDefault)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(onSchedule == nil && !saved ? KIRIColor.Background.secondary : KIRIColor.Button.FilledAccent.backgroundDefault)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(isSavingBookmark)
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
                bucketToastMessage = "버킷에 저장했어요"
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

    private func removeBookmark(missionId: Int) async {
        isSavingBookmark = true
        bookmarkError = nil
        defer { isSavingBookmark = false }
        do {
            try await AuthService.shared.removeMissionFromBucket(missionId: missionId)
            await MainActor.run {
                isBookmarked = false
                bucketToastMessage = "버킷에서 삭제했어요"
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
            await MainActor.run {
                bookmarkError = "버킷 저장 해제에 실패했어요. 다시 시도해 주세요."
            }
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

/// Figma 9901:24278 `플레이스메인/저장 팝업`에 대응하는 저장 확인 모달입니다.
/// Figma 원본에는 별도 이미지 레이어가 없으므로 임의 아이콘이나 이모지를 추가하지 않고,
/// 서버 저장 전 확인·취소 동작만 제공합니다.
struct BucketSaveConfirmationModal: View {
    let title: String
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.58)
                .ignoresSafeArea()
                .onTapGesture { }

            VStack(alignment: .leading, spacing: 0) {
                Text("버킷리스트에 저장하시겠습니까?")
                    .font(KIRITypography.bodyMedium)
                    .foregroundStyle(KIRIColor.Text.strong)
                    .padding(.bottom, 24)

                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(KIRITypography.bodySmallMedium)
                        .foregroundStyle(KIRIColor.Text.strong)
                        .lineLimit(2)
                    Text("이 약속은 버킷리스트에서 확인하실 수 있습니다")
                        .font(KIRITypography.caption)
                        .foregroundStyle(KIRIColor.Text.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .background(KIRIColor.Background.elevated)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                HStack(spacing: 16) {
                    Button("취소", action: onCancel)
                        .font(KIRITypography.bodySmallMedium)
                        .foregroundStyle(KIRIColor.Text.strong)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .buttonStyle(.plain)

                    Button("저장", action: onConfirm)
                        .font(KIRITypography.bodySmallMedium)
                        .foregroundStyle(KIRIColor.Text.inverse)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(KIRIColor.Primary.default)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .buttonStyle(.plain)
                }
                .padding(.top, 24)
            }
            .padding(22)
            .frame(maxWidth: 344)
            .background(KIRIColor.Background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 18)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("버킷리스트 저장 확인")
    }
}

private struct ActivityDetailCard: View {
    let detail: MissionDetailResult?
    let fallbackPlace: String

    private var place: String {
        guard let detailPlace = detail?.place else { return fallbackPlace }
        let name = detailPlace.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let address = detailPlace.address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !address.isEmpty, address != name else { return name.isEmpty ? fallbackPlace : name }
        // 장소명과 전체 주소를 분리해 표시합니다. 주소는 축약하지 않고
        // Text의 자연스러운 줄바꿈으로 카드 안에서 끝까지 보이게 합니다.
        return name.isEmpty ? address : "\(name)\n\(address)"
    }
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
