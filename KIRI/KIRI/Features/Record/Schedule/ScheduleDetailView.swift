import SwiftUI
struct ScheduleDetailView: View {
    let schedule: RecordCalendarView.ScheduleDetailData
    let onBack: () -> Void
    // 서버에서 검증된 약속 당일 데이터.
    // nil이면 당일 활동 화면을 열지 않는다.
    var todayContent: TodayActivityView.Content? = nil
    var savedReview: ActivityReviewWriteView.Draft? = nil
    var onReviewSaved: ((ActivityReviewWriteView.Draft) -> Void)? = nil
    @State private var showingReviewEditor = false
    @State private var localEditedReview: ActivityReviewWriteView.Draft?
    private var currentReview: ActivityReviewWriteView.Draft? {
        localEditedReview ?? savedReview
    }
    @State private var selectedTab: ContentTab = .aiActivity
    private enum ContentTab: String, CaseIterable {
        case aiActivity = "끼리네 AI 활동"
        case familyMemory = "가족 추억"
    }
    private enum DateState {
        case upcoming
        case today
        case past
        case unknown
    }
    private var dateState: DateState {
        guard let scheduledDate = parsedScheduleDate else {
            return .unknown
        }
        let calendar = Calendar.current
        if calendar.isDateInToday(scheduledDate) {
            return .today
        }
        return scheduledDate > Date() ? .upcoming : .past
    }
    private var parsedScheduleDate: Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy.MM.dd"
        formatter.isLenient = false
        return formatter.date(from: schedule.date)
    }
    var body: some View {
        Group {
            if let review = currentReview {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        navigationBar
                        Text(schedule.title)
                            .font(KIRITypography.title)
                            .foregroundStyle(KIRIColor.Text.strong)
                        activityDetail
                        ActivityReviewCompleteView(
                            schedule: schedule,
                            review: review,
                            onBack: onBack,
                            onEdit: { showingReviewEditor = true }
                        )
                    }
                    .padding(.horizontal, 18)
                }
            } else {
                switch dateState {
                case .today:
                    if schedule.status == .confirmedSchedule,
                       let todayContent,
                       todayContent.isCurrentUserConfirmed {
                        TodayActivityView(
                            schedule: schedule,
                            content: todayContent,
                            onBack: onBack,
                            savedReview: currentReview,
                            onReviewSaved: { draft in
                                localEditedReview = draft
                                onReviewSaved?(draft)
                            }
                        )
                    } else {
                        statusView(
                            title: "약속 당일 화면을 확인할 수 없어요",
                            message: "확정된 일정의 최종 참여자만 이용할 수 있어요."
                        )
                    }
                case .upcoming:
                    upcomingContent
                case .past:
                    statusView(
                        title: "지난 약속이에요",
                        message: "활동 완료 여부는 가족이 남긴 기록을 기준으로 확인해요."
                    )
                case .unknown:
                    statusView(
                        title: "일정 날짜를 확인할 수 없어요",
                        message: "일정 정보를 다시 확인해 주세요."
                    )
                }
            }
        }
        .fullScreenCover(isPresented: $showingReviewEditor) {
            ActivityReviewWriteView(
                onBack: { showingReviewEditor = false },
                onSubmit: { draft in
                    localEditedReview = draft
                    onReviewSaved?(draft)
                    showingReviewEditor = false
                },
                initialDraft: currentReview
            )
        }
        .background(KIRIColor.Background.base)
    }
    private var upcomingContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                navigationBar
                Text(
                    schedule.status == .confirmedSchedule
                        ? "약속 확정"
                        : "약속 예정"
                )
                .font(KIRITypography.bodySmall)
                .foregroundStyle(KIRIColor.Text.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(KIRIColor.Background.elevated)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .padding(.top, 21)
                Text(schedule.title)
                    .font(KIRITypography.title)
                    .foregroundStyle(KIRIColor.Text.strong)
                    .padding(.top, 12)
                activityDetail
                    .padding(.top, 30)
                contentSelector
                    .padding(.top, 53)
                selectedContent
                    .padding(.top, 40)
                Color.clear.frame(height: 120)
            }
            .padding(.horizontal, 18)
        }
    }
    private var navigationBar: some View {
        ZStack {
            Text("\(schedule.month)월 \(schedule.day)일")
                .font(KIRITypography.bodySmallMedium)
                .foregroundStyle(KIRIColor.Text.tertiary)
            HStack {
                KIRIBackButton(action: onBack)
                Spacer()
            }
        }
        .frame(height: 62)
    }
    private var activityDetail: some View {
        VStack(alignment: .leading, spacing: 9) {
            detailRow("시작 시간", schedule.startTime)
            detailRow("장소", schedule.location)
            detailRow("예상 걸음 수", schedule.expectedSteps)
            detailRow("활동 시간", schedule.duration)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KIRIColor.Background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    private func detailRow(
        _ label: String,
        _ value: String
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(label)
                .foregroundStyle(KIRIColor.Text.secondary)
            Text("|")
                .foregroundStyle(KIRIColor.Text.tertiary)
            Text(value)
                .foregroundStyle(KIRIColor.Text.primary)
        }
        .font(KIRITypography.body)
    }
    private var contentSelector: some View {
        HStack(spacing: 6) {
            ForEach(ContentTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Text(tab.rawValue)
                        .font(KIRITypography.headingSmall)
                        .foregroundStyle(
                            selectedTab == tab
                                ? KIRIColor.Text.strong
                                : KIRIColor.Text.tertiary
                        )
                        .padding(.horizontal, 18)
                        .frame(height: 44)
                        .background(
                            selectedTab == tab
                                ? KIRIColor.Background.tertiary
                                : Color.clear
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(KIRIColor.Background.secondary)
        .clipShape(Capsule())
        .frame(maxWidth: .infinity)
    }
    private var selectedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(
                selectedTab == .aiActivity
                    ? "끼리네 AI 활동"
                    : "가족 추억"
            )
            .font(KIRITypography.headingSmall)
            .foregroundStyle(KIRIColor.Text.strong)
            Text(
                selectedTab == .aiActivity
                    ? "추천 활동 정보를 준비하고 있어요."
                    : "아직 등록된 가족 추억이 없어요."
            )
            .font(KIRITypography.bodySmall)
            .foregroundStyle(KIRIColor.Text.secondary)
            .frame(maxWidth: .infinity, minHeight: 110)
            .background(KIRIColor.Background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    private func statusView(
        title: String,
        message: String
    ) -> some View {
        VStack(spacing: 0) {
            navigationBar
                .padding(.horizontal, 18)
            Spacer()
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 36))
                .foregroundStyle(KIRIColor.Text.tertiary)
            Text(title)
                .font(KIRITypography.headingSmall)
                .foregroundStyle(KIRIColor.Text.strong)
                .padding(.top, 20)
            Text(message)
                .font(KIRITypography.bodySmall)
                .foregroundStyle(KIRIColor.Text.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 10)
                .padding(.horizontal, 24)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
