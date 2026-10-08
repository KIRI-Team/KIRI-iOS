
import SwiftUI

struct RecordCalendarView: View {

    // MARK: - Models

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

    // API 연동 전, 화면 이동 확인을 위한 내부 데이터.
    var demoTodaySchedule: ScheduleDetailData? = nil
    var savedReviewSchedules: [ScheduleDetailData] = []
    var onSelectSavedReview: (ScheduleDetailData) -> Void = { _ in }

    // MARK: - State

    @State private var displayedMonthDate: Date
    @State private var selectedDate: Date

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

        let calendar = Calendar.current
        let today = Date()

        _displayedMonthDate = State(
            initialValue: calendar.date(
                from: calendar.dateComponents(
                    [.year, .month],
                    from: today
                )
            ) ?? today
        )

        _selectedDate = State(initialValue: today)
    }

    // MARK: - Calendar

    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.locale = Locale(identifier: "ko_KR")
        value.firstWeekday = 2
        return value
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

    private var selectedDay: Int {
        calendar.component(.day, from: selectedDate)
    }

    private let weekDays = [
        "월", "화", "수", "목", "금", "토", "일"
    ]

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 6),
        count: 7
    )

    // MARK: - Data

    private var visibleSchedules: [ScheduleDetailData] {
        var schedules = savedReviewSchedules

        if let demoTodaySchedule,
           !schedules.contains(where: {
               $0.date == demoTodaySchedule.date &&
               $0.title == demoTodaySchedule.title
           }) {
            schedules.append(demoTodaySchedule)
        }

        return schedules
    }

    private var selectedSchedules: [ScheduleDetailData] {
        visibleSchedules.filter { schedule in
            guard let date = parseDate(schedule.date) else {
                return false
            }

            return calendar.isDate(
                date,
                inSameDayAs: selectedDate
            )
        }
    }

    private var selectedReviews: [ReviewDetailData] {
        mockActivities.compactMap { activity in
            guard let review = activity.review,
                  let date = parseDate(review.date),
                  calendar.isDate(
                    date,
                    inSameDayAs: selectedDate
                  ) else {
                return nil
            }

            return review
        }
    }

    // 기존 샘플 일정은 표시 월과 실제 날짜가
    // 일치하지 않아 기본값에서 제외한다.
    private var mockActivities: [CalendarActivity] {
        []
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

    private func dateForDay(_ day: Int) -> Date? {
        calendar.date(
            byAdding: .day,
            value: day - 1,
            to: displayedMonthDate
        )
    }

    private func schedules(for day: Int) -> [ScheduleDetailData] {
        guard let date = dateForDay(day) else {
            return []
        }

        return visibleSchedules.filter { schedule in
            guard let scheduleDate = parseDate(schedule.date) else {
                return false
            }

            return calendar.isDate(
                scheduleDate,
                inSameDayAs: date
            )
        }
    }

    private func hasSavedReview(
        _ schedule: ScheduleDetailData
    ) -> Bool {
        savedReviewSchedules.contains {
            $0.date == schedule.date &&
            $0.title == schedule.title
        }
    }

    private func activityState(
        for day: Int
    ) -> ActivityState? {
        let daySchedules = schedules(for: day)

        if daySchedules.contains(where: hasSavedReview) {
            return .completed
        }

        if daySchedules.contains(where: {
            $0.status == .confirmedSchedule
        }) {
            return .confirmedSchedule
        }

        if !daySchedules.isEmpty {
            return .pendingSchedule
        }

        return nil
    }

    // MARK: - Body

    var body: some View {
        ScrollView(
            .vertical,
            showsIndicators: false
        ) {
            VStack(alignment: .leading, spacing: 0) {
                monthHeader
                    .padding(.top, 28)

                calendarGrid
                    .padding(.top, 18)

                selectedDateSection
                    .padding(.top, 32)

                upcomingSection
                    .padding(.top, 36)

                Color.clear
                    .frame(height: 110)
            }
            .padding(.horizontal, 18)
        }
        .background(KIRIColor.Background.base)
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack(spacing: 0) {
            Text(
                "\(String(displayedYear))년 \(String(displayedMonth))월"
            )
            .font(KIRITypography.headingSmall)
            .tracking(-0.72)
            .foregroundStyle(KIRIColor.Text.strong)

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
        }
        .frame(height: 24)
    }

    private func monthButton(
        systemName: String,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(
                    .system(
                        size: 15,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    KIRIColor.Icon.secondary
                )
                .frame(width: 24, height: 28)
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
                ForEach(
                    0..<leadingEmptyDays,
                    id: \.self
                ) { _ in
                    Color.clear
                        .frame(height: 45)
                }

                ForEach(
                    1...numberOfDays,
                    id: \.self
                ) { day in
                    calendarCell(day)
                }
            }
        }
    }

    private var weekHeader: some View {
        LazyVGrid(
            columns: columns,
            spacing: 6
        ) {
            ForEach(
                weekDays,
                id: \.self
            ) { day in
                Text(day)
                    .font(
                        .system(
                            size: 12,
                            weight: .semibold
                        )
                    )
                    .tracking(-0.48)
                    .foregroundStyle(
                        KIRIColor.Text.tertiary
                    )
                    .frame(height: 16)
            }
        }
    }

    // MARK: - Date Cell

    private func calendarCell(
        _ day: Int
    ) -> some View {
        Button {
            selectDay(day)
        } label: {
            dateCellContent(day)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            "\(String(displayedMonth))월 \(String(day))일"
        )
    }

    private func dateCellContent(
        _ day: Int
    ) -> some View {
        let selected = isSelected(day)
        let state = activityState(for: day)

        return ZStack {
            RoundedRectangle(
                cornerRadius: 12
            )
            .fill(
                selected
                    ? KIRIColor.Background.greenSoft
                    : KIRIColor.Background.tertiary
            )

            if let state {
                stateContent(
                    state,
                    day: day
                )
            } else {
                Text(String(day))
                    .font(KIRITypography.body)
                    .tracking(-0.64)
                    .foregroundStyle(
                        KIRIColor.Text.primary
                    )
            }
        }
        .frame(height: 45)
        .overlay {
            RoundedRectangle(
                cornerRadius: 12
            )
            .stroke(
                selected
                    ? KIRIColor.Primary.default
                    : Color.clear,
                lineWidth: 1
            )
        }
    }

    @ViewBuilder
    private func stateContent(
        _ state: ActivityState,
        day: Int
    ) -> some View {
        switch state {
        case .pendingSchedule:
            VStack(spacing: 2) {
                Image(systemName: "clock")
                    .font(.system(size: 17))
                    .foregroundStyle(
                        KIRIColor.Text.tertiary
                    )

                Text(String(day))
                    .font(KIRITypography.caption)
                    .foregroundStyle(
                        KIRIColor.Text.primary
                    )
            }

        case .confirmedSchedule:
            VStack(spacing: 2) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(
                        KIRIColor.Text.primary
                    )

                Text(String(day))
                    .font(KIRITypography.caption)
                    .foregroundStyle(
                        KIRIColor.Text.primary
                    )
            }

        case .completed:
            VStack(spacing: 2) {
                Image(systemName: "photo.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(
                        KIRIColor.Primary.default
                    )

                Text(String(day))
                    .font(KIRITypography.caption)
                    .foregroundStyle(
                        KIRIColor.Text.primary
                    )
            }
        }
    }

    private func isSelected(
        _ day: Int
    ) -> Bool {
        guard let date = dateForDay(day) else {
            return false
        }

        return calendar.isDate(
            date,
            inSameDayAs: selectedDate
        )
    }

    private func selectDay(
        _ day: Int
    ) {
        guard let date = dateForDay(day) else {
            return
        }

        withAnimation(
            .easeInOut(duration: 0.2)
        ) {
            selectedDate = date
        }
    }

    // MARK: - Selected Date

    private var selectedDateSection: some View {
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            Text(
                "\(String(displayedMonth))월 \(String(selectedDay))일"
            )
            .font(KIRITypography.headingSmall)
            .foregroundStyle(KIRIColor.Text.strong)

            if selectedSchedules.isEmpty &&
                selectedReviews.isEmpty {
                emptyCard(
                    "등록된 일정이나 기록이 없어요."
                )
            } else {
                ForEach(selectedSchedules) { schedule in
                    scheduleCard(schedule)
                }

                ForEach(selectedReviews) { review in
                    Button {
                        onSelectReview(review)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "photo.fill")
                                .foregroundStyle(
                                    KIRIColor.Primary.default
                                )

                            Text(review.title)
                                .font(KIRITypography.bodyMedium)
                                .foregroundStyle(
                                    KIRIColor.Text.strong
                                )

                            Spacer()

                            Image(
                                systemName: "chevron.right"
                            )
                            .foregroundStyle(
                                KIRIColor.Text.tertiary
                            )
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
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func scheduleCard(
        _ schedule: ScheduleDetailData
    ) -> some View {
        Button {
            if hasSavedReview(schedule) {
                onSelectSavedReview(schedule)
            } else {
                onSelectSchedule(schedule)
            }
        } label: {
            HStack(spacing: 12) {
                VStack(
                    alignment: .leading,
                    spacing: 8
                ) {
                    Text(schedule.title)
                        .font(
                            KIRITypography.bodyMedium
                        )
                        .foregroundStyle(
                            KIRIColor.Text.strong
                        )
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 8) {
                        Text(
                            statusTitle(for: schedule)
                        )
                        .foregroundStyle(
                            hasSavedReview(schedule)
                                ? KIRIColor.Primary.default
                                : KIRIColor.Text.secondary
                        )

                        Text(schedule.startTime)
                            .foregroundStyle(
                                KIRIColor.Text.tertiary
                            )
                    }
                    .font(KIRITypography.bodySmall)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundStyle(
                        KIRIColor.Text.tertiary
                    )
            }
            .padding(18)
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
        .buttonStyle(.plain)
    }

    private func statusTitle(
        for schedule: ScheduleDetailData
    ) -> String {
        if hasSavedReview(schedule) {
            return "기록 완료"
        }

        switch schedule.status {
        case .pendingSchedule:
            return "약속 예정"

        case .confirmedSchedule:
            return "약속 확정"

        case .completed:
            return "기록 완료"
        }
    }

    // MARK: - Upcoming

    private var upcomingSchedules: [ScheduleDetailData] {
        visibleSchedules.filter { schedule in
            guard let date = parseDate(schedule.date) else {
                return false
            }

            return calendar.startOfDay(for: date) >=
                calendar.startOfDay(for: Date()) &&
                !hasSavedReview(schedule)
        }
        .sorted {
            (parseDate($0.date) ?? .distantFuture) <
            (parseDate($1.date) ?? .distantFuture)
        }
    }

    private var upcomingSection: some View {
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            Text("다가오는 약속")
                .font(KIRITypography.headingSmall)
                .foregroundStyle(
                    KIRIColor.Text.strong
                )

            if upcomingSchedules.isEmpty {
                emptyCard(
                    "다가오는 약속이 없어요."
                )
            } else {
                ForEach(upcomingSchedules) { schedule in
                    scheduleCard(schedule)
                }
            }
        }
    }

    // MARK: - Shared

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
                minHeight: 110
            )
            .background(
                KIRIColor.Background.secondary
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 8)
            )
    }

    // MARK: - Navigation

    private func moveMonth(
        by amount: Int
    ) {
        guard let nextMonth = calendar.date(
            byAdding: .month,
            value: amount,
            to: displayedMonthDate
        ) else {
            return
        }

        withAnimation(
            .easeInOut(duration: 0.2)
        ) {
            displayedMonthDate = nextMonth

            // 월을 이동하면 해당 월의 1일을 선택한다.
            selectedDate = nextMonth
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
