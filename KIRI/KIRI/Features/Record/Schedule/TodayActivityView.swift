//
// MARK: - 파일 가이드
// 파일: Features/Record/Schedule/TodayActivityView.swift
// 담당 영역: 기능별 SwiftUI 화면과 상태
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//

import SwiftUI
struct TodayActivityView: View {
    struct Recommendation: Identifiable {
        let id: String
        let title: String
        let location: String
        let description: String
        let distanceMeters: Double?
        let isRestPlace: Bool
        let price: Int?
        let crowdLevel: Int?
        let imageURL: URL?
    }
    struct ParticipantStatus: Identifiable {
        let id: Int
        let nickname: String
        let isAccepted: Bool
    }
    struct SuggestedItem: Identifiable {
        let id: String
        let title: String
        let reason: String
    }
    struct ReviewMemory: Identifiable {
        let id: Int
        let authorName: String
        let familyRole: String?
        let content: String
        let imageURL: URL?
        let isMine: Bool
    }
    struct Content {
        let isCurrentUserConfirmed: Bool
        let participantNames: [String]
        let participantStatuses: [ParticipantStatus]
        let requiredActivities: [String]
        let requiredItems: [SuggestedItem]
        let nearbyRecommendations: [Recommendation]
        let reviewMemories: [ReviewMemory]
        let currentUserNickname: String
        let currentUserRole: String

        init(
            isCurrentUserConfirmed: Bool,
            participantNames: [String],
            participantStatuses: [ParticipantStatus] = [],
            requiredActivities: [String],
            requiredItems: [SuggestedItem],
            nearbyRecommendations: [Recommendation],
            reviewMemories: [ReviewMemory] = [],
            currentUserNickname: String = "",
            currentUserRole: String = ""
        ) {
            self.isCurrentUserConfirmed = isCurrentUserConfirmed
            self.participantNames = participantNames
            self.participantStatuses = participantStatuses
            self.requiredActivities = requiredActivities
            self.requiredItems = requiredItems
            self.nearbyRecommendations = nearbyRecommendations
            self.reviewMemories = reviewMemories
            self.currentUserNickname = currentUserNickname
            self.currentUserRole = currentUserRole
        }
    }
    let schedule: RecordCalendarView.ScheduleDetailData
    let content: Content
    let onBack: () -> Void
    var missionTitle: String? = nil
    var missionDescription: String? = nil
    var requestMessage: String? = nil
    @State private var selectedTab = 0
    @State private var showingConditionScreen = false
    @State private var showingReviewEditor = false
    @State private var selectedConditions:
        Set<ConditionAdjustmentSheet.Condition> = []
    @State private var conditionsLoadError: String?
    @State private var refreshedRecommendations: [Recommendation]?
    @State private var isDescriptionExpanded = false
    var savedReview: ActivityReviewWriteView.Draft? = nil
    var onReviewSaved: ((ActivityReviewWriteView.Draft) -> Void)? = nil
    @State private var localReview: ActivityReviewWriteView.Draft?
    private var submittedReview: ActivityReviewWriteView.Draft? {
        savedReview ?? localReview
    }
    private var sortedRecommendations: [Recommendation] {
        (refreshedRecommendations ?? content.nearbyRecommendations).sorted {
            score($0) < score($1)
        }
    }
    private func score(
        _ item: Recommendation
    ) -> Double {
        var value = item.distanceMeters ?? 100_000
        if selectedConditions.contains(.lessWalking) {
            value *= 3
        }
        if selectedConditions.contains(.moreRest),
           item.isRestPlace {
            value -= 10_000
        }
        if selectedConditions.contains(.lowerBudget),
           let price = item.price {
            value += Double(price)
        }
        if selectedConditions.contains(.avoidCrowds),
           let crowdLevel = item.crowdLevel {
            value += Double(crowdLevel) * 5_000
        }
        return value
    }
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(
                alignment: .leading,
                spacing: 0
            ) {
                navigationBar
                statusBadge
                    .padding(.top, 21)
                Text(missionTitle?.isEmpty == false ? missionTitle! : schedule.title)
                    .font(KIRITypography.title)
                    .foregroundStyle(
                        KIRIColor.Text.strong
                    )
                    .padding(.top, 12)
                participantSection
                    .padding(.top, 10)
                activityDetail
                    .padding(.top, 30)
                eventDescriptionSection
                    .padding(.top, 18)
                actionButtons
                    .padding(.top, 18)
                contentSelector
                    .padding(.top, 46)
                if selectedTab == 0 {
                    aiActivityContent
                        .padding(.top, 40)
                } else {
                    familyMemoryContent
                        .padding(.top, 40)
                }
                Color.clear.frame(height: 120)
            }
            .padding(.horizontal, 18)
        }
        .background(
            KIRIColor.Background.base
        )
        .fullScreenCover(
            isPresented: $showingConditionScreen
        ) {
            ConditionAdjustmentSheet(
                selectedConditions: selectedConditions,
                onApply: { conditions in
                    selectedConditions = conditions
                },
                onApplyToServer: schedule.scheduleId.map { scheduleId in
                    { conditions in
                        try await AuthService.shared.updateScheduleConditions(
                            scheduleId: scheduleId,
                            conditions: conditions.map(\.serverValue)
                        )
                        // 조건 저장 직후 서버가 계산한 최신 추천을 다시 읽어
                        // 상세 화면에 즉시 반영합니다. 조회에 실패해도
                        // 저장 성공 상태와 기존 추천은 유지합니다.
                        if let nearby = try? await AuthService.shared.nearbyMissions(scheduleId: scheduleId) {
                            await MainActor.run {
                                refreshedRecommendations = nearby.map { item in
                                    Recommendation(
                                        id: item.id,
                                        title: item.placeName,
                                        location: item.region,
                                        description: item.description,
                                        distanceMeters: item.distance,
                                        isRestPlace: false,
                                        price: item.price,
                                        crowdLevel: nil,
                                        imageURL: item.imageUrl
                                    )
                                }
                            }
                        }
                    }
                },
                activityTitle: schedule.title,
                expectedSteps: schedule.expectedSteps,
                activityDuration: schedule.duration
            )
        }
        .fullScreenCover(
            isPresented: $showingReviewEditor
        ) {
            ActivityReviewWriteView(
                onBack: {
                    showingReviewEditor = false
                },
                onSubmit: { draft in
                    localReview = draft
                    onReviewSaved?(draft)
                    showingReviewEditor = false
                    selectedTab = 1
                },
                onSubmitToServer: schedule.scheduleId.map { scheduleId in
                    { draft in
                        // 당일 화면은 서버 리뷰를 별도로 주입받지 않을 수 있으므로
                        // 저장 직전에 최신 목록에서 내 리뷰 ID를 확인합니다.
                        let existingReviewId: Int?
                        if let reviews = try? await AuthService.shared.scheduleReviews(scheduleId: scheduleId) {
                            existingReviewId = reviews.reviews.first(where: { $0.isMine })?.reviewId
                        } else {
                            existingReviewId = nil
                        }
                        let imageData = try draft.images.map { image in
                            guard let data = image.jpegData(compressionQuality: 0.85) else {
                                throw APIError.decodingFailed
                            }
                            return data
                        }
                        _ = try await AuthService.shared.saveReview(
                            scheduleId: scheduleId,
                            rating: draft.rating,
                            images: imageData,
                            comment: draft.comment,
                            wantsToRepeat: draft.wantsToRepeat,
                            existingReviewId: existingReviewId
                        )
                    }
                },
                initialDraft: submittedReview
            )
        }
        .task {
            guard let scheduleId = schedule.scheduleId else { return }
            do {
                let result = try await AuthService.shared.scheduleConditions(scheduleId: scheduleId)
                selectedConditions = Set(result.conditions.compactMap(ConditionAdjustmentSheet.Condition.from(serverValue:)))
                conditionsLoadError = nil
            } catch {
                conditionsLoadError = "컨디션을 불러오지 못했어요."
            }
        }
    }
    // MARK: - Navigation
    private var navigationBar: some View {
        ZStack {
            Text(
                "\(schedule.month)월 \(schedule.day)일"
            )
            .font(KIRITypography.headingSmall)
            .foregroundStyle(
                KIRIColor.Text.strong
            )
            HStack {
                KIRIBackButton(action: onBack)
                Spacer()
            }
        }
        .frame(height: 62)
    }
    // MARK: - Schedule Information
    private var statusBadge: some View {
        Text("약속 당일이에요!")
            .font(KIRITypography.bodySmall)
            .foregroundStyle(
                KIRIColor.Text.primary
            )
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                KIRIColor.Background.elevated
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 5)
            )
    }
    private var participantSection: some View {
        HStack(
            alignment: .top,
            spacing: 8
        ) {
            Text("참여상태")
            Text("|")
            if content.participantStatuses.isEmpty {
                Text(content.participantNames.isEmpty ? "참여자 정보 없음" : content.participantNames.joined(separator: ", "))
            } else {
                ForEach(Array(content.participantStatuses.enumerated()), id: \.element.id) { index, participant in
                    if index > 0 { Text(" ") }
                    HStack(spacing: 3) {
                        Text(participant.nickname)
                        if participant.isAccepted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(KIRIColor.Primary.default)
                        }
                    }
                }
            }
        }
        .font(KIRITypography.body)
        .foregroundStyle(
            KIRIColor.Text.primary
        )
    }
    private var eventDescriptionSection: some View {
        Group {
            if let missionDescription, !missionDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("행사설명")
                        .font(KIRITypography.bodySmallMedium)
                        .foregroundStyle(KIRIColor.Text.strong)
                    Text(missionDescription)
                        .font(KIRITypography.bodySmall)
                        .foregroundStyle(KIRIColor.Text.secondary)
                        .lineLimit(isDescriptionExpanded ? nil : 3)
                        .fixedSize(horizontal: false, vertical: true)
                    if missionDescription.count > 120 {
                        Button(isDescriptionExpanded ? "접기" : "더 보기") {
                            isDescriptionExpanded.toggle()
                        }
                        .font(KIRITypography.caption)
                        .foregroundStyle(KIRIColor.Text.accent)
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    private var actionButtons: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                conditionActionButton
                reviewActionButton
            }
            VStack(spacing: 10) {
                conditionActionButton
                reviewActionButton
            }
        }
    }

    private var conditionActionButton: some View {
        Button { showingConditionScreen = true } label: {
            Text("컨디션 조정")
                .font(KIRITypography.bodySmallMedium)
                .foregroundStyle(KIRIColor.Primary.default)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(KIRIColor.Background.green)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private var reviewActionButton: some View {
        Button { showingReviewEditor = true } label: {
            Text(submittedReview == nil ? "추억 기록" : "추억 기록 수정")
                .font(KIRITypography.bodySmallMedium)
                .foregroundStyle(KIRIColor.Text.onGreen)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(KIRIColor.Primary.default)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
    private var activityDetail: some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            detailRow(
                "시작 시간",
                schedule.startTime
            )
            detailRow(
                "장소",
                schedule.location
            )
            detailRow(
                "예상 걸음 수",
                schedule.expectedSteps
            )
            detailRow(
                "활동 시간",
                schedule.duration
            )
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 17)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            KIRIColor.Background.secondary
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 8)
        )
    }
    private func detailRow(
        _ title: String,
        _ value: String
    ) -> some View {
        HStack(
            alignment: .top,
            spacing: 10
        ) {
            Text(title)
            Text("|")
            Text(value)
        }
        .font(KIRITypography.body)
        .foregroundStyle(
            KIRIColor.Text.primary
        )
    }
    // MARK: - Review Navigation
    private var reviewButton: some View {
        Button {
            showingReviewEditor = true
        } label: {
            Text(
                submittedReview == nil
                    ? "오늘의 추억 기록하러가기"
                    : "내 기록 수정하기"
            )
            .font(KIRITypography.headingSmall)
            .foregroundStyle(
                KIRIColor.Text.onGreen
            )
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                KIRIColor.Primary.default
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 8)
            )
        }
        .buttonStyle(.plain)
    }
    // MARK: - Tabs
    private var contentSelector: some View {
        HStack(spacing: 6) {
            tabButton(
                "끼리네 AI 활동",
                index: 0
            )
            tabButton(
                "가족 추억",
                index: 1
            )
        }
        .padding(4)
        .background(
            KIRIColor.Background.secondary
        )
        .clipShape(Capsule())
        .frame(maxWidth: .infinity)
    }
    private func tabButton(
        _ title: String,
        index: Int
    ) -> some View {
        Button {
            selectedTab = index
        } label: {
            Text(title)
                .font(KIRITypography.headingSmall)
                .foregroundStyle(
                    selectedTab == index
                        ? KIRIColor.Text.strong
                        : KIRIColor.Text.tertiary
                )
                .padding(.horizontal, 18)
                .frame(height: 44)
                .background(
                    selectedTab == index
                        ? KIRIColor.Background.tertiary
                        : Color.clear
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
    // MARK: - AI Activity
    private var aiActivityContent: some View {
        VStack(
            alignment: .leading,
            spacing: 36
        ) {
            requiredActivitySection
            requiredItemSection
            nearbySection
        }
    }
    private var requiredActivitySection: some View {
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            sectionTitle(
                    "추천 활동"
            )
            if content.requiredActivities.isEmpty {
                emptyCard(
                    "추천 활동이 아직 없어요."
                )
            } else {
                ForEach(
                    Array(
                        content.requiredActivities
                            .prefix(3)
                            .enumerated()
                    ),
                    id: \.offset
                ) { _, title in
                    HStack(
                        alignment: .top,
                        spacing: 12
                    ) {
                        Image(
                            systemName: "checkmark.circle"
                        )
                        .foregroundStyle(
                            KIRIColor.Primary.default
                        )
                        Text(title)
                            .font(
                                KIRITypography.bodyMedium
                            )
                            .foregroundStyle(
                                KIRIColor.Text.strong
                            )
                        Spacer()
                    }
                    .padding(18)
                    .background(
                        KIRIColor.Background.secondary
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 8
                        )
                    )
                }
            }
        }
    }
    private var requiredItemSection: some View {
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            sectionTitle("끼리 맞춤템")
            if content.requiredItems.isEmpty {
                emptyCard(
                    "추천 준비물이 아직 없어요."
                )
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: 12
                ) {
                    ForEach(
                        content.requiredItems.prefix(4)
                    ) { item in
                        VStack(
                            alignment: .leading,
                            spacing: 8
                        ) {
                            Image(
                                systemName: "bag"
                            )
                            .foregroundStyle(
                                KIRIColor.Primary.default
                            )
                            Text(item.title)
                                .font(
                                    KIRITypography.headingSmall
                                )
                                .foregroundStyle(
                                    KIRIColor.Text.strong
                                )
                            Text(item.reason)
                                .font(
                                    KIRITypography.bodySmall
                                )
                                .foregroundStyle(
                                    KIRIColor.Text.secondary
                                )
                        }
                        .frame(
                            maxWidth: .infinity,
                            minHeight: 112,
                            alignment: .topLeading
                        )
                        .padding(16)
                        .background(
                            KIRIColor.Background.secondary
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 8
                            )
                        )
                    }
                }
            }
        }
    }
    // MARK: - Nearby Recommendations
    private var nearbySection: some View {
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            HStack(alignment: .top) {
                VStack(
                    alignment: .leading,
                    spacing: 5
                ) {
                    sectionTitle(
                        "근처 놀거리 추천"
                    )
                    Text(
                        "일정 장소를 기준으로 추천해요."
                    )
                    .font(
                        KIRITypography.bodySmall
                    )
                    .foregroundStyle(
                        KIRIColor.Text.secondary
                    )
                }
                Spacer()
                Button {
                    showingConditionScreen = true
                } label: {
                    Label(
                        "컨디션 조정하러가기",
                        systemImage: "slider.horizontal.3"
                    )
                    .font(
                        KIRITypography.bodySmallMedium
                    )
                    .foregroundStyle(
                        KIRIColor.Primary.default
                    )
                }
                .buttonStyle(.plain)
            }
            if sortedRecommendations.isEmpty {
                emptyCard(
                    "추천할 수 있는 주변 장소가 없어요."
                )
            } else {
                ForEach(
                    sortedRecommendations
                ) { place in
                    VStack(
                        alignment: .leading,
                        spacing: 9
                    ) {
                        KIRIContentImage(imageURL: place.imageURL, mockAssetName: nil) {
                            KIRIColor.Background.tertiary
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 144)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        Text(place.title)
                            .font(
                                KIRITypography.headingSmall
                            )
                            .foregroundStyle(
                                KIRIColor.Text.strong
                            )
                        Text(place.location)
                            .font(
                                KIRITypography.bodySmall
                            )
                            .foregroundStyle(
                                KIRIColor.Text.secondary
                            )
                        Text(place.description)
                            .font(
                                KIRITypography.bodySmall
                            )
                            .foregroundStyle(
                                KIRIColor.Text.tertiary
                            )
                    }
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding(18)
                    .background(
                        KIRIColor.Background.secondary
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 8
                        )
                    )
                }
            }
        }
    }
    // MARK: - Family Memory
    private var familyMemoryContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("나의 한 줄")
            if let submittedReview {
                reviewMemoryCard(
                    ReviewMemory(
                        id: -1,
                        authorName: content.currentUserNickname.isEmpty ? "나" : content.currentUserNickname,
                        familyRole: content.currentUserRole,
                        content: submittedReview.comment,
                        imageURL: nil,
                        isMine: true
                    ),
                    localDraft: submittedReview
                )
            } else if let serverReview = content.reviewMemories.first(where: { $0.isMine }) {
                reviewMemoryCard(serverReview)
            } else {
                emptyMemoryCard("아직 나의 기록이 없어요.")
            }

            sectionTitle("다른 가족의 기록")
            let otherReviews = content.reviewMemories.filter { !$0.isMine }
            if otherReviews.isEmpty {
                emptyMemoryCard("아직 다른 가족이 남긴 기록이 없어요.")
            } else {
                VStack(spacing: 12) {
                    ForEach(otherReviews) { review in
                        reviewMemoryCard(review)
                    }
                }
            }
        }
    }

    private func reviewMemoryCard(
        _ review: ReviewMemory,
        localDraft: ActivityReviewWriteView.Draft? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                avatar(for: review.familyRole)
                Text(review.authorName)
                    .font(KIRITypography.bodySmallMedium)
                    .foregroundStyle(KIRIColor.Text.primary)
                if review.isMine {
                    Text("나")
                        .font(KIRITypography.captionMedium)
                        .foregroundStyle(KIRIColor.Text.accent)
                }
                Spacer()
                if review.isMine {
                    Button("수정하기") { showingReviewEditor = true }
                        .font(KIRITypography.captionMedium)
                        .foregroundStyle(KIRIColor.Text.secondary)
                        .buttonStyle(.plain)
                }
            }
            if let localDraft, let firstImage = localDraft.images.first {
                Image(uiImage: firstImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if let imageURL = review.imageURL {
                KIRIContentImage(imageURL: imageURL, mockAssetName: nil) { KIRIColor.Background.tertiary }
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            Text(review.content)
                .font(KIRITypography.bodySmall)
                .foregroundStyle(KIRIColor.Text.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KIRIColor.Background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func avatar(for role: String?) -> some View {
        let assetName: String
        switch role?.uppercased() {
        case "MOTHER": assetName = "role_mom_active"
        case "FATHER": assetName = "role_dad_active"
        case "DAUGHTER": assetName = "role_daughter_active"
        case "SON": assetName = "role_son_active"
        default: assetName = "kiri_character"
        }
        return Image(assetName)
            .resizable()
            .scaledToFit()
            .frame(width: 36, height: 36)
    }
    // MARK: - Shared Components
    private func sectionTitle(
        _ title: String
    ) -> some View {
        Text(title)
            .font(KIRITypography.headingSmall)
            .foregroundStyle(
                KIRIColor.Text.strong
            )
    }
    private func emptyMemoryCard(_ message: String) -> some View {
        VStack(spacing: 10) {
            Image("kiri_app_icon")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
            Text(message)
                .font(KIRITypography.bodySmall)
                .foregroundStyle(KIRIColor.Text.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .background(KIRIColor.Background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func emptyCard(_ message: String) -> some View {
        Text(message)
            .font(KIRITypography.bodySmall)
            .foregroundStyle(KIRIColor.Text.secondary)
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(KIRIColor.Background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
