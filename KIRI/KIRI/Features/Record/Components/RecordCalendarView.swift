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
        let status: ActivityState

        let title: String
        let date: String

        let startTime: String
        let location: String
        let expectedSteps: String
        let duration: String
    }

    struct CalendarActivity: Identifiable {
        let id = UUID()

        let day: Int
        let state: ActivityState

        let representativePhotoURL: URL?
        let additionalCompletedCount: Int

        let schedule: ScheduleDetailData?
    }

    struct UpcomingSchedule: Identifiable {
        let id = UUID()

        let title: String
        let dateText: String
        let isConfirmed: Bool
    }

    // MARK: - Properties

    let onSelectSchedule: (ScheduleDetailData) -> Void

    // MARK: - State

    @State private var displayedYear = 2023
    @State private var displayedMonth = 12

    // MARK: - Init

    init(
        onSelectSchedule: @escaping (ScheduleDetailData) -> Void = { _ in }
    ) {
        self.onSelectSchedule = onSelectSchedule
    }

    // MARK: - Data

    private let activities: [CalendarActivity] = [
        CalendarActivity(
            day: 9,
            state: .pendingSchedule,
            representativePhotoURL: nil,
            additionalCompletedCount: 0,
            schedule: ScheduleDetailData(
                day: 9,
                status: .pendingSchedule,
                title: "한강 뚜벅뚜벅 축제 가보기",
                date: "2026.06.13",
                startTime: "오후 2시 50분",
                location: "여의도 한강 공원",
                expectedSteps: "20000보",
                duration: "8시간"
            )
        ),

        CalendarActivity(
            day: 11,
            state: .completed,
            representativePhotoURL: nil,
            additionalCompletedCount: 0,
            schedule: nil
        ),

        CalendarActivity(
            day: 12,
            state: .confirmedSchedule,
            representativePhotoURL: nil,
            additionalCompletedCount: 0,
            schedule: ScheduleDetailData(
                day: 12,
                status: .confirmedSchedule,
                title: "한강 뚜벅뚜벅 축제 가보기",
                date: "2026.06.13",
                startTime: "오후 2시 50분",
                location: "여의도 한강 공원",
                expectedSteps: "20000보",
                duration: "8시간"
            )
        )
    ]

    private let upcomingSchedules: [UpcomingSchedule] = [
        UpcomingSchedule(
            title: "한강 뚜벅뚜벅 축제 방문",
            dateText: "26.06.23",
            isConfirmed: false
        ),

        UpcomingSchedule(
            title: "한강 뚜벅뚜벅 축제 방문",
            dateText: "26.06.23",
            isConfirmed: true
        ),

        UpcomingSchedule(
            title: "한강 뚜벅뚜벅 축제 방문",
            dateText: "26.06.23",
            isConfirmed: true
        )
    ]

    private let weekDays = [
        "월",
        "화",
        "수",
        "목",
        "금",
        "토",
        "일"
    ]

    private let columns = Array(
        repeating: GridItem(
            .fixed(45),
            spacing: 6
        ),
        count: 7
    )

    // MARK: - Body

    var body: some View {
        ScrollView(
            .vertical,
            showsIndicators: false
        ) {
            VStack(spacing: 0) {
                monthHeader
                    .padding(.top, 28)

                calendar
                    .padding(.top, 18)

                upcomingSection
                    .padding(.top, 36)

                Color.clear
                    .frame(height: 110)
            }
            .padding(.horizontal, 18)
        }
    }

    // MARK: - Header

    private var monthHeader: some View {
        HStack(spacing: 0) {
            HStack(spacing: 8) {
                Text("\(displayedYear)년 \(displayedMonth)월")
                    .font(KIRITypography.headingSmall)
                    .tracking(-0.72)
                    .foregroundStyle(KIRIColor.Text.strong)

                notificationBadge
            }

            Spacer()

            HStack(spacing: 24) {
                monthButton(
                    systemName: "chevron.left",
                    label: "이전 달"
                ) {
                    previousMonth()
                }

                monthButton(
                    systemName: "chevron.right",
                    label: "다음 달"
                ) {
                    nextMonth()
                }
            }
            .padding(.trailing, 3)
        }
        .frame(height: 22)
    }

    private var notificationBadge: some View {
        HStack(spacing: 6) {
            Text("알림")
                .font(KIRITypography.navigation)
                .tracking(-0.4)
                .foregroundStyle(KIRIColor.Text.accent)

            Circle()
                .fill(KIRIColor.Primary.default)
                .frame(
                    width: 6,
                    height: 6
                )
        }
        .padding(.horizontal, 6)
        .frame(height: 22)
        .background(
            KIRIColor.Background.greenSoft
        )
        .clipShape(Capsule())
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
                .foregroundStyle(KIRIColor.Icon.secondary)
                .frame(
                    width: 8,
                    height: 16
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: - Calendar

    private var calendar: some View {
        VStack(spacing: 16) {
            weekHeader

            LazyVGrid(
                columns: columns,
                alignment: .center,
                spacing: 8
            ) {
                ForEach(1...28, id: \.self) { day in
                    calendarCell(day)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var weekHeader: some View {
        HStack(spacing: 6) {
            ForEach(weekDays, id: \.self) { day in
                Text(day)
                    .font(KIRITypography.navigation)
                    .tracking(-0.4)
                    .foregroundStyle(KIRIColor.Text.tertiary)
                    .frame(
                        width: 45,
                        height: 14
                    )
            }
        }
    }

    // MARK: - Calendar Cell

    @ViewBuilder
    private func calendarCell(
        _ day: Int
    ) -> some View {
        if let activity = activities.first(
            where: { $0.day == day }
        ) {
            if let schedule = activity.schedule {
                Button {
                    onSelectSchedule(schedule)
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

    private func normalCell(
        _ day: Int
    ) -> some View {
        ZStack {
            RoundedRectangle(
                cornerRadius: 12
            )
            .fill(KIRIColor.Background.tertiary)

            Text("\(day)")
                .font(KIRITypography.body)
                .tracking(-0.64)
                .foregroundStyle(KIRIColor.Text.primary)
        }
        .frame(
            width: 45,
            height: 45
        )
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
            completedActivityCell(activity)
        }
    }

    // MARK: - Pending

    private func pendingScheduleCell() -> some View {
        ZStack {
            RoundedRectangle(
                cornerRadius: 12
            )
            .fill(KIRIColor.Background.elevated)

            Image(systemName: "clock")
                .font(
                    .system(
                        size: 25,
                        weight: .regular
                    )
                )
                .foregroundStyle(KIRIColor.Icon.disabled)
        }
        .frame(
            width: 45,
            height: 45
        )
        .accessibilityLabel("확정 대기 중인 일정")
    }

    // MARK: - Confirmed

    private func confirmedScheduleCell() -> some View {
        ZStack {
            RoundedRectangle(
                cornerRadius: 12
            )
            .fill(KIRIColor.Background.elevated)

            Image(systemName: "clock")
                .font(
                    .system(
                        size: 27,
                        weight: .medium
                    )
                )
                .foregroundStyle(KIRIColor.Text.primary)
        }
        .frame(
            width: 45,
            height: 45
        )
        .accessibilityLabel("확정된 일정")
    }

    // MARK: - Completed

    private func completedActivityCell(
        _ activity: CalendarActivity
    ) -> some View {
        ZStack {
            if let url = activity.representativePhotoURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()

                    case .empty:
                        completedPhotoPlaceholder

                    case .failure:
                        completedPhotoPlaceholder

                    @unknown default:
                        completedPhotoPlaceholder
                    }
                }
            } else {
                completedPhotoPlaceholder
            }

            Color.black
                .opacity(0.56)

            if activity.additionalCompletedCount > 0 {
                VStack {
                    Spacer()

                    HStack {
                        Spacer()

                        Text(
                            "+\(activity.additionalCompletedCount)"
                        )
                        .font(KIRITypography.captionMedium)
                        .foregroundStyle(KIRIColor.Text.strong)
                        .padding(5)
                    }
                }
            }
        }
        .frame(
            width: 45,
            height: 45
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 12
            )
        )
        .accessibilityLabel("완료한 활동")
    }

    private var completedPhotoPlaceholder: some View {
        ZStack {
            KIRIColor.Background.elevated

            Image(systemName: "photo")
                .font(
                    .system(
                        size: 17,
                        weight: .medium
                    )
                )
                .foregroundStyle(KIRIColor.Icon.secondary)
        }
    }

    // MARK: - Upcoming

    private var upcomingSection: some View {
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            Text("다가오는 약속")
                .font(KIRITypography.headingSmall)
                .tracking(-0.72)
                .foregroundStyle(KIRIColor.Text.strong)
                .frame(height: 22)

            LazyVStack(spacing: 18) {
                ForEach(upcomingSchedules) { schedule in
                    upcomingScheduleCard(schedule)
                }
            }
        }
    }

    private func upcomingScheduleCard(
        _ schedule: UpcomingSchedule
    ) -> some View {
        HStack(
            alignment: .top,
            spacing: 0
        ) {
            VStack(
                alignment: .leading,
                spacing: 8
            ) {
                scheduleBadge(schedule)

                VStack(
                    alignment: .leading,
                    spacing: 0
                ) {
                    Text(schedule.title)
                        .font(KIRITypography.headingSmall)
                        .tracking(-0.72)
                        .foregroundStyle(KIRIColor.Text.strong)
                        .lineLimit(1)

                    Text("일시 I \(schedule.dateText)")
                        .font(KIRITypography.bodySmall)
                        .tracking(-0.56)
                        .foregroundStyle(KIRIColor.Text.secondary)
                }
            }

            Spacer()

            Button {
                // TODO: 일정 메뉴
            } label: {
                Image(systemName: "ellipsis")
                    .font(
                        .system(
                            size: 13,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(KIRIColor.Icon.disabled)
                    .frame(
                        width: 24,
                        height: 24
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .frame(
            maxWidth: .infinity,
            minHeight: 110,
            alignment: .leading
        )
        .background(
            KIRIColor.Background.tertiary
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 8
            )
        )
    }

    private func scheduleBadge(
        _ schedule: UpcomingSchedule
    ) -> some View {
        Text(
            schedule.isConfirmed
                ? "약속 확정"
                : "약속 예정"
        )
        .font(KIRITypography.bodySmallMedium)
        .tracking(-0.56)
        .foregroundStyle(
            schedule.isConfirmed
                ? KIRIColor.Text.accent
                : KIRIColor.Text.secondary
        )
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            schedule.isConfirmed
                ? KIRIColor.Background.greenSoft
                : KIRIColor.Background.elevated
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 5
            )
        )
    }

    // MARK: - Month

    private func previousMonth() {
        if displayedMonth == 1 {
            displayedMonth = 12
            displayedYear -= 1
        } else {
            displayedMonth -= 1
        }
    }

    private func nextMonth() {
        if displayedMonth == 12 {
            displayedMonth = 1
            displayedYear += 1
        } else {
            displayedMonth += 1
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
