
import SwiftUI

struct RecordCalendarView: View {

    // MARK: - Domain

    enum ActivityState {
        case pendingSchedule
        case confirmedSchedule
        case completed
    }

    struct ScheduleDetailData: Identifiable {
        let id = UUID()

        let day: Int
        let month: Int
        let status: ActivityState

        let title: String
        let date: String
        let startTime: String
        let location: String
        let expectedSteps: String
        let duration: String
    }

    struct ReviewDetailData: Identifiable {
        let id = UUID()

        let title: String
        let date: String
        let familyName: String
        let authorName: String
        let isCurrentUser: Bool
        let review: String
        let writtenDate: String
        let representativePhotoURL: URL?
    }

    struct CalendarActivity: Identifiable {
        let id = UUID()

        let day: Int
        let state: ActivityState
        let representativePhotoURL: URL?
        let additionalCompletedCount: Int
        let schedule: ScheduleDetailData?
        let review: ReviewDetailData?
    }

    struct UpcomingSchedule: Identifiable {
        let id = UUID()

        let title: String
        let dateText: String
        let isConfirmed: Bool
    }

    // MARK: - Properties

    let onSelectSchedule: (ScheduleDetailData) -> Void
    let onSelectReview: (ReviewDetailData) -> Void

    var demoTodaySchedule: ScheduleDetailData? = nil
    var savedReviewSchedules: [ScheduleDetailData] = []
    var onSelectSavedReview: (ScheduleDetailData) -> Void = { _ in }

    // MARK: - State

    @State private var displayedMonthDate = Calendar.current.date(
        from: Calendar.current.dateComponents(
            [.year, .month],
            from: Date()
        )
    ) ?? Date()

    // MARK: - Init

    init(
        onSelectSchedule: @escaping (ScheduleDetailData) -> Void = { _ in },
        onSelectReview: @escaping (ReviewDetailData) -> Void = { _ in },
        demoTodaySchedule: ScheduleDetailData? = nil,
        savedReviewSchedules: [ScheduleDetailData] = [],
        onSelectSavedReview: @escaping (ScheduleDetailData) -> Void = { _ in }
    ) {
        self.onSelectSchedule = onSelectSchedule
        self.onSelectReview = onSelectReview
        self.demoTodaySchedule = demoTodaySchedule
        self.savedReviewSchedules = savedReviewSchedules
        self.onSelectSavedReview = onSelectSavedReview
    }

    // MARK: - Calendar Data

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ko_KR")
        calendar.firstWeekday = 2
        return calendar
    }

    private var displayedYear: Int {
        calendar.component(.year, from: displayedMonthDate)
    }

    private var displayedMonth: Int {
        calendar.component(.month, from: displayedMonthDate)
    }

    private var numberOfDays: Int {
        calendar.range(
            of: .day,
            in: .month,
            for: displayedMonthDate
        )?.count ?? 30
    }

    private var leadingEmptyDays: Int {
        let weekday = calendar.component(
            .weekday,
            from: displayedMonthDate
        )

        return (weekday + 5) % 7
    }

    private var weekDays: [String] {
        ["월", "화", "수", "목", "금", "토", "일"]
    }

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 6),
        count: 7
    )

    private var todayDay: Int? {
        guard calendar.isDate(
            displayedMonthDate,
            equalTo: Date(),
            toGranularity: .month
        ) else {
            return nil
        }

        return calendar.component(.day, from: Date())
    }

    // MARK: - Mock Data

    // 실제 서버 일정이 아닌 화면 확인용 데이터.
    // 기존 샘플의 날짜와 표시 월이 일치하지 않아
    // 잘못된 완료 상태가 표시되는 문제를 방지한다.

    private var mockActivities: [CalendarActivity] {
        []
    }

    private var currentMonthSavedReviews: [ScheduleDetailData] {
        savedReviewSchedules.filter { schedule in
            guard let date = parseDate(schedule.date) else {
                return false
            }

            return calendar.isDate(
                date,
                equalTo: displayedMonthDate,
                toGranularity: .month
            )
        }
    }

    private var currentMonthDemoSchedule: ScheduleDetailData? {
        guard let demoTodaySchedule,
              let date = parseDate(demoTodaySchedule.date),
              calendar.isDate(
                date,
                equalTo: displayedMonthDate,
                toGranularity: .month
              ) else {
            return nil
        }

        return demoTodaySchedule
    }

    private func parseDate(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.calendar = calendar
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy.MM.dd"
        formatter.isLenient = false

        return formatter.date(from: value)
    }

    private func dayOfMonth(_ schedule: ScheduleDetailData) -> Int? {
        guard let date = parseDate(schedule.date) else {
            return nil
        }

        return calendar.component(.day, from: date)
    }

    private func savedReview(for day: Int) -> ScheduleDetailData? {
        currentMonthSavedReviews.first {
            dayOfMonth($0) == day
        }
    }

    private func mockActivity(for day: Int) -> CalendarActivity? {
        mockActivities.first { $0.day == day }
    }

    // MARK: - Body

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                monthHeader
                    .padding(.top, 28)

                calendarGrid
                    .padding(.top, 18)

                demoSection
                    .padding(.top, 30)

                upcomingSection
                    .padding(.top, 36)

                Color.clear.frame(height: 110)
            }
            .padding(.horizontal, 18)
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack(spacing: 0) {
            HStack(spacing: 8) {
                Text("\(displayedYear)년 \(displayedMonth)월")
                    .font(KIRITypography.headingSmall)
                    .tracking(-0.72)
                    .foregroundStyle(KIRIColor.Text.strong)
            }

            Spacer()

            HStack(spacing: 24) {
                monthButton(
                    systemName: "chevron.left",
                    label: "이전 달"
                ) {
                    moveMonth(by: -1)
                }

                monthButton(
                    systemName: "chevron.right",
                    label: "다음 달"
                ) {
                    moveMonth(by: 1)
                }
            }
            .padding(.trailing, 3)
        }
        .frame(height: 22)
    }

    private func monthButton(
        systemName: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(KIRIColor.Icon.secondary)
                .frame(width: 20, height: 24)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        VStack(spacing: 16) {
            weekHeader

            LazyVGrid(
                columns: columns,
                spacing: 8
            ) {
                ForEach(0..<leadingEmptyDays, id: \.self) { _ in
                    Color.clear
                        .frame(height: 45)
                }

                ForEach(1...numberOfDays, id: \.self) { day in
                    calendarCell(day)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var weekHeader: some View {
        LazyVGrid(
            columns: columns,
            spacing: 6
        ) {
            ForEach(weekDays, id: \.self) { day in
                Text(day)
                    .font(KIRITypography.navigation)
                    .tracking(-0.4)
                    .foregroundStyle(KIRIColor.Text.tertiary)
                    .frame(height: 14)
            }
        }
    }

    // MARK: - Calendar Cell

    @ViewBuilder
    private func calendarCell(_ day: Int) -> some View {
        if let saved = savedReview(for: day) {
            Button {
                onSelectSavedReview(saved)
            } label: {
                completedCell()
            }
            .buttonStyle(.plain)

        } else if let demo = currentMonthDemoSchedule,
                  dayOfMonth(demo) == day {
            Button {
                onSelectSchedule(demo)
            } label: {
                confirmedScheduleCell()
            }
            .buttonStyle(.plain)

        } else if let activity = mockActivity(for: day) {
            if let schedule = activity.schedule {
                Button {
                    onSelectSchedule(schedule)
                } label: {
                    activityCell(activity)
                }
                .buttonStyle(.plain)

            } else if let review = activity.review {
                Button {
                    onSelectReview(review)
                } label: {
                    activityCell(activity)
                }
                .buttonStyle(.plain)

            } else {
                activityCell(activity)
            }

        } else {
            normalCell(day)
        }
    }

    private func normalCell(_ day: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(KIRIColor.Background.tertiary)

            Text("\(day)")
                .font(KIRITypography.body)
                .tracking(-0.64)
                .foregroundStyle(
                    todayDay == day
                        ? KIRIColor.Text.accent
                        : KIRIColor.Text.primary
                )
        }
        .frame(height: 45)
        .overlay {
            if todayDay == day {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        KIRIColor.Primary.default,
                        lineWidth: 1.5
                    )
            }
        }
        .accessibilityLabel("\(day)일")
    }

    @ViewBuilder
    private func activityCell(
        _ activity: CalendarActivity
    ) -> some View {
        switch activity.state {
        case .pendingSchedule:
            pendingScheduleCell()

        case .confirmedSchedule:
            confirmedScheduleCell()

        case .completed:
            completedCell()
        }
    }

    private func pendingScheduleCell() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(KIRIColor.Background.elevated)

            Image(systemName: "clock")
                .font(.system(size: 24))
                .foregroundStyle(KIRIColor.Text.tertiary)
        }
        .frame(height: 45)
        .accessibilityLabel("확정 대기 중인 일정")
    }

    private func confirmedScheduleCell() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(KIRIColor.Background.elevated)

            Image(systemName: "clock")
                .font(.system(size: 25, weight: .medium))
                .foregroundStyle(KIRIColor.Text.primary)
        }
        .frame(height: 45)
        .accessibilityLabel("확정된 일정")
    }

    private func completedCell() -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(KIRIColor.Background.elevated)

            Image(systemName: "photo.fill")
                .font(.system(size: 19))
                .foregroundStyle(KIRIColor.Primary.default)
        }
        .frame(height: 45)
        .accessibilityLabel("기록을 작성한 활동")
    }

    // MARK: - Demo Section

    private var demoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let demoTodaySchedule {
                Text("화면 테스트 · MOCK")
                    .font(KIRITypography.bodySmallMedium)
                    .foregroundStyle(KIRIColor.Text.secondary)

                Button {
                    onSelectSchedule(demoTodaySchedule)
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("오늘의 약속 화면")
                                .font(KIRITypography.headingSmall)

                            Text(demoTodaySchedule.title)
                                .font(KIRITypography.bodySmall)
                                .foregroundStyle(
                                    KIRIColor.Text.secondary
                                )
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                    }
                    .foregroundStyle(KIRIColor.Text.strong)
                    .padding(18)
                    .background(KIRIColor.Background.secondary)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 8)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Upcoming

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("다가오는 약속")
                .font(KIRITypography.headingSmall)
                .tracking(-0.72)
                .foregroundStyle(KIRIColor.Text.strong)

            Text("예정된 약속이 없어요.")
                .font(KIRITypography.bodySmall)
                .foregroundStyle(KIRIColor.Text.secondary)
                .frame(
                    maxWidth: .infinity,
                    minHeight: 110
                )
                .background(KIRIColor.Background.tertiary)
                .clipShape(
                    RoundedRectangle(cornerRadius: 8)
                )
        }
    }

    // MARK: - Month Navigation

    private func moveMonth(by amount: Int) {
        guard let nextMonth = calendar.date(
            byAdding: .month,
            value: amount,
            to: displayedMonthDate
        ) else {
            return
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            displayedMonthDate = nextMonth
        }
    }
}

#Preview {
    ZStack {
        KIRIColor.Background.base
            .ignoresSafeArea()

        RecordCalendarView()
    }
}
