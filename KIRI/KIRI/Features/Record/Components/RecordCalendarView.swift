
import SwiftUI
import UIKit

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
        let draft: ActivityReviewWriteView.Draft?

        init(title: String, date: String, familyName: String, authorName: String, isCurrentUser: Bool, review: String, writtenDate: String, representativePhotoURL: URL? = nil, draft: ActivityReviewWriteView.Draft? = nil) {
            self.title = title
            self.date = date
            self.familyName = familyName
            self.authorName = authorName
            self.isCurrentUser = isCurrentUser
            self.review = review
            self.writtenDate = writtenDate
            self.representativePhotoURL = representativePhotoURL
            self.draft = draft
        }
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

    // API 연동 전 화면 연결을 위한 내부 데이터
    var demoTodaySchedule: ScheduleDetailData? = nil
    var savedReviewSchedules: [ScheduleDetailData] = []
    var savedReviewDrafts: [String: ActivityReviewWriteView.Draft] = [:]
    var onSelectSavedReview: (ScheduleDetailData) -> Void = { _ in }

    // MARK: - State

    @State private var displayedMonthDate: Date
    @State private var selectedDate: Date

    // MARK: - Initializer

    init(
        onSelectSchedule: @escaping (ScheduleDetailData) -> Void = { _ in },
        onSelectReview: @escaping (ReviewDetailData) -> Void = { _ in },
        demoTodaySchedule: ScheduleDetailData? = nil,
        savedReviewSchedules: [ScheduleDetailData] = [],
        savedReviewDrafts: [String: ActivityReviewWriteView.Draft] = [:],
        onSelectSavedReview: @escaping (ScheduleDetailData) -> Void = { _ in }
    ) {
        self.onSelectSchedule = onSelectSchedule
        self.onSelectReview = onSelectReview
        self.demoTodaySchedule = demoTodaySchedule
        self.savedReviewSchedules = savedReviewSchedules
        self.savedReviewDrafts = savedReviewDrafts
        self.onSelectSavedReview = onSelectSavedReview

        let today = Date()
        let calendar = Calendar.current

        let monthStart = calendar.date(
            from: calendar.dateComponents(
                [.year, .month],
                from: today
            )
        ) ?? today

        _displayedMonthDate = State(initialValue: monthStart)
        _selectedDate = State(initialValue: today)
    }

    // MARK: - Calendar Properties

    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.locale = Locale(identifier: "ko_KR")
        value.timeZone = .current
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
        let weekday = calendar.component(.weekday, from: displayedMonthDate)
        // Calendar.weekday is 1-based (Sunday = 1). Convert it to the
        // configured firstWeekday instead of relying on a fixed Sunday offset.
        return (weekday - calendar.firstWeekday + 7) % 7
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

    private func reviewKey(_ schedule: ScheduleDetailData) -> String {
        "\(schedule.date)|\(schedule.title)"
    }

    private var calendarActivities: [CalendarActivity] {
        savedReviewSchedules.compactMap { schedule in
            guard let draft = savedReviewDrafts[reviewKey(schedule)] else { return nil }
            let review = ReviewDetailData(
                title: schedule.title, date: schedule.date,
                familyName: "끼리네가족", authorName: "나",
                isCurrentUser: true, review: draft.comment,
                writtenDate: Date.now.formatted(.dateTime.month().day()),
                representativePhotoURL: nil, draft: draft
            )
            return CalendarActivity(
                day: schedule.day, state: .completed,
                representativePhotoURL: nil, additionalCompletedCount: 0,
                schedule: schedule, review: review
            )
        }
    }

    private var upcomingSchedules: [ScheduleDetailData] {
        visibleSchedules
            .filter { schedule in
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

    private func reviews(for day: Int) -> [ReviewDetailData] {
        guard let date = dateForDay(day) else {
            return []
        }

        return calendarActivities.compactMap { activity in
            guard let review = activity.review,
                  let reviewDate = parseDate(review.date),
                  calendar.isDate(
                      reviewDate,
                      inSameDayAs: date
                  ) else {
                return nil
            }

            return review
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

        if !reviews(for: day).isEmpty ||
            daySchedules.contains(where: hasSavedReview) {
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
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                monthHeader
                    .padding(.top, 28)

                calendarGrid
                    .padding(.top, 18)

                upcomingSection
                    .padding(.top, 32)

                Color.clear
                    .frame(height: 110)
            }
            .padding(.horizontal, 18)
        }
        .background(KIRIColor.Background.base)
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack(spacing: 8) {
            Text(
                "\(String(displayedYear))년 \(String(displayedMonth))월"
            )
            .font(KIRITypography.headingSmall)
            .tracking(-0.72)
            .foregroundStyle(KIRIColor.Text.strong)

            Spacer()

            HStack(spacing: 16) {
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
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(KIRIColor.Icon.secondary)
                .frame(width: 24, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: - Calendar

    private var calendarGrid: some View {
        VStack(spacing: 16) {
            weekHeader

            LazyVGrid(columns: columns, spacing: 8) {
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
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(weekDays, id: \.self) { day in
                Text(day)
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(-0.48)
                    .foregroundStyle(KIRIColor.Text.tertiary)
                    .frame(height: 16)
            }
        }
    }

    private func calendarCell(_ day: Int) -> some View {
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

    private func dateCellContent(_ day: Int) -> some View {
        let selected = isSelected(day)
        let state = activityState(for: day)

        return ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    selected
                        ? KIRIColor.Background.greenSoft
                        : KIRIColor.Background.tertiary
                )

            if let state {
                stateContent(state, day: day)
            } else {
                Text(String(day))
                    .font(KIRITypography.body)
                    .tracking(-0.64)
                    .foregroundStyle(KIRIColor.Text.primary)
            }
        }
        .frame(height: 45)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
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
                    .foregroundStyle(KIRIColor.Text.tertiary)

                Text(String(day))
                    .font(KIRITypography.caption)
                    .foregroundStyle(KIRIColor.Text.primary)
            }

        case .confirmedSchedule:
            VStack(spacing: 2) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 17))
                    .foregroundStyle(KIRIColor.Text.primary)

                Text(String(day))
                    .font(KIRITypography.caption)
                    .foregroundStyle(KIRIColor.Text.primary)
            }

        case .completed:
            if let image = reviews(for: day).first?.draft?.images.first {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 45, height: 45)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(alignment: .bottom) {
                        Text(String(day))
                            .font(KIRITypography.caption)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .background(Color.black.opacity(0.35))
                    }
                    .clipped()
            } else {
                VStack(spacing: 2) {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(KIRIColor.Primary.default)
                    Text(String(day))
                        .font(KIRITypography.caption)
                        .foregroundStyle(KIRIColor.Text.primary)
                }
            }
        }
    }

    private func isSelected(_ day: Int) -> Bool {
        guard let date = dateForDay(day) else {
            return false
        }

        return calendar.isDate(
            date,
            inSameDayAs: selectedDate
        )
    }

    private func selectDay(_ day: Int) {
        guard let date = dateForDay(day) else {
            return
        }

        // 날짜 선택에는 별도 이동 애니메이션을 적용하지 않는다.
        selectedDate = date

        // Figma에 별도 선택 날짜 목록이 없으므로
        // 일정이나 기록이 있는 날짜는 상세 화면으로 이동한다.
        if let review = reviews(for: day).first {
            onSelectReview(review)
            return
        }

        if let schedule = schedules(for: day).first {
            openSchedule(schedule)
        }
    }

    // MARK: - Upcoming Section

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("다가오는 약속")
                .font(KIRITypography.headingSmall)
                .tracking(-0.72)
                .foregroundStyle(KIRIColor.Text.strong)

            if upcomingSchedules.isEmpty {
                emptyCard("다가오는 약속이 없어요.")
            } else {
                VStack(spacing: 18) {
                    ForEach(upcomingSchedules) { schedule in
                        scheduleCard(schedule)
                    }
                }
            }
        }
    }

    // MARK: - Schedule Card

    private func scheduleCard(
        _ schedule: ScheduleDetailData
    ) -> some View {
        Button {
            openSchedule(schedule)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    statusBadge(for: schedule)

                    VStack(alignment: .leading, spacing: 0) {
                        Text(schedule.title)
                            .font(KIRITypography.headingSmall)
                            .tracking(-0.72)
                            .foregroundStyle(KIRIColor.Text.strong)
                            .lineLimit(1)

                        Text("일시 | \(shortDate(schedule.date))")
                            .font(KIRITypography.bodySmall)
                            .tracking(-0.56)
                            .foregroundStyle(KIRIColor.Text.secondary)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(KIRIColor.Icon.secondary)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 110)
            .background(KIRIColor.Background.tertiary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func statusBadge(
        for schedule: ScheduleDetailData
    ) -> some View {
        let confirmed = schedule.status == .confirmedSchedule
        let completed = hasSavedReview(schedule) ||
            schedule.status == .completed

        let title: String = {
            if completed {
                return "기록 완료"
            }

            return confirmed ? "약속 확정" : "약속 예정"
        }()

        Text(title)
            .font(KIRITypography.bodySmallMedium)
            .tracking(-0.56)
            .foregroundStyle(
                confirmed || completed
                    ? KIRIColor.Primary.default
                    : KIRIColor.Text.secondary
            )
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                confirmed || completed
                    ? KIRIColor.Background.greenSoft
                    : KIRIColor.Background.elevated
            )
            .clipShape(RoundedRectangle(cornerRadius: 5))
    }

    private func shortDate(_ dateString: String) -> String {
        guard let date = parseDate(dateString) else {
            return dateString
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.calendar = calendar
        formatter.dateFormat = "yy.MM.dd"

        return formatter.string(from: date)
    }

    // MARK: - Empty State

    private func emptyCard(_ message: String) -> some View {
        Text(message)
            .font(KIRITypography.bodySmall)
            .foregroundStyle(KIRIColor.Text.secondary)
            .frame(maxWidth: .infinity, minHeight: 110)
            .background(KIRIColor.Background.tertiary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Navigation

    private func openSchedule(
        _ schedule: ScheduleDetailData
    ) {
        if hasSavedReview(schedule) {
            onSelectSavedReview(schedule)
        } else {
            onSelectSchedule(schedule)
        }
    }

    private func moveMonth(by amount: Int) {
        guard let nextMonth = calendar.date(
            byAdding: .month,
            value: amount,
            to: displayedMonthDate
        ) else {
            return
        }

        // 월 전환 시 날짜 블록이 개별적으로 이동하지 않도록
        // 해당 상태 변경에 대한 애니메이션을 비활성화한다.
        var transaction = Transaction()
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            displayedMonthDate = nextMonth
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
