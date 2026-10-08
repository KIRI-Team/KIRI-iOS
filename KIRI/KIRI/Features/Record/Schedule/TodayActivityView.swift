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
    }
    struct SuggestedItem: Identifiable {
        let id: String
        let title: String
        let reason: String
    }
    struct Content {
        let isCurrentUserConfirmed: Bool
        let participantNames: [String]
        let requiredActivities: [String]
        let requiredItems: [SuggestedItem]
        let nearbyRecommendations: [Recommendation]
    }
    let schedule: RecordCalendarView.ScheduleDetailData
    let content: Content
    let onBack: () -> Void
    @State private var selectedTab = 0
    @State private var showingConditionScreen = false
    @State private var showingReviewEditor = false
    @State private var selectedConditions:
        Set<ConditionAdjustmentSheet.Condition> = []
    var savedReview: ActivityReviewWriteView.Draft? = nil
    var onReviewSaved: ((ActivityReviewWriteView.Draft) -> Void)? = nil
    @State private var localReview: ActivityReviewWriteView.Draft?
    private var submittedReview: ActivityReviewWriteView.Draft? {
        savedReview ?? localReview
    }
    private var sortedRecommendations: [Recommendation] {
        content.nearbyRecommendations.sorted {
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
                Text(schedule.title)
                    .font(KIRITypography.title)
                    .foregroundStyle(
                        KIRIColor.Text.strong
                    )
                    .padding(.top, 12)
                participantSection
                    .padding(.top, 10)
                activityDetail
                    .padding(.top, 30)
                reviewButton
                    .padding(.top, 24)
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
                initialDraft: submittedReview
            )
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
            Text(
                content.participantNames.isEmpty
                    ? "참여자 정보 없음"
                    : content.participantNames.joined(
                        separator: ", "
                    )
            )
        }
        .font(KIRITypography.body)
        .foregroundStyle(
            KIRIColor.Text.primary
        )
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
                "오늘 끼리네 필수 활동"
            )
            if content.requiredActivities.isEmpty {
                emptyCard(
                    "등록된 필수 활동이 없어요."
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
            sectionTitle("오늘의 필수템")
            if content.requiredItems.isEmpty {
                emptyCard(
                    "확인된 준비물 정보가 없어요."
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
                        "컨디션 조정",
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
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            sectionTitle("가족 추억")
            if let submittedReview {
                ActivityReviewCompleteView(
                    schedule: schedule,
                    review: submittedReview,
                    onBack: {
                        selectedTab = 0
                    },
                    onEdit: {
                        showingReviewEditor = true
                    }
                )
            } else {
                emptyCard(
                    "아직 등록된 가족 추억이 없어요."
                )
            }
        }
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
    private func emptyCard(
        _ message: String
    ) -> some View {
        Text(message)
            .font(KIRITypography.bodySmall)
            .foregroundStyle(
                KIRIColor.Text.secondary
            )
            .frame(
                maxWidth: .infinity,
                minHeight: 100
            )
            .background(
                KIRIColor.Background.secondary
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 8)
            )
    }
}
