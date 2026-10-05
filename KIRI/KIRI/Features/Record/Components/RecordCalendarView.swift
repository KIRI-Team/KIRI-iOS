
import SwiftUI

struct RecordCalendarView: View {

    // MARK: - Domain State

    enum ActivityState {
        /// 일정 생성 후 아직 최종 확정되지 않은 상태
        /// Figma: 연한 시계
        case pendingSchedule

        /// 일정 확정 후 아직 유효 리뷰가 없는 상태
        /// Figma: 밝은 시계
        case confirmedSchedule

        /// 유효 리뷰 작성 완료
        /// Figma: 리뷰 대표사진
        case completed
    }

    struct CalendarActivity: Identifiable {
        let id = UUID()
        let day: Int
        let state: ActivityState

        /// 리뷰 완료 상태에서 서버가 내려줄 대표사진 URL.
        /// 최초 유효 리뷰의 첫 번째 사진이 기본 대표사진.
        let representativePhotoURL: URL?

        /// 같은 날짜에 추가 완료 활동이 있을 경우 +N 표시.
        let additionalCompletedCount: Int
    }

    struct UpcomingSchedule: Identifiable {
        let id = UUID()

        let title: String
        let dateText: String
        let isConfirmed: Bool
    }

    // MARK: - State

    @State private var displayedYear = 2023
    @State private var displayedMonth = 12

    // MARK: - Mock Data

    /// Figma 상태 재현용 mock.
    ///
    /// 9일  = 미확정 일정
    /// 11일 = 리뷰 완료
    /// 12일 = 확정 일정
    private let activities: [CalendarActivity] = [
        CalendarActivity(
            day: 9,
            state: .pendingSchedule,
            representativePhotoURL: nil,
            additionalCompletedCount: 0
        ),
        CalendarActivity(
            day: 11,
            state: .completed,
            representativePhotoURL: nil,
            additionalCompletedCount: 0
        ),
        CalendarActivity(
            day: 12,
            state: .confirmedSchedule,
            representativePhotoURL: nil,
            additionalCompletedCount: 0
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

    // MARK: - Month Header

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
                Button {
                    previousMonth()
                } label: {
                    Image(systemName: "chevron.left")
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
                .accessibilityLabel("이전 달")

                Button {
                    nextMonth()
                } label: {
                    Image(systemName: "chevron.right")
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
                .accessibilityLabel("다음 달")
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
            activityCell(activity)
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

    // MARK: - Pending Schedule

    /// Figma의 연한 시계.
    ///
    /// 일정은 생성됐지만 아직 확정되지 않은 상태.
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

    // MARK: - Confirmed Schedule

    /// Figma의 밝은 시계.
    ///
    /// 일정 확정 완료.
    /// 아직 유효 리뷰가 작성되지 않았으므로 사진으로 전환되지 않는다.
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

    // MARK: - Completed Activity

    /// 유효 리뷰가 등록된 활동.
    ///
    /// 실제 서비스에서는 representativePhotoURL에
    /// 리뷰 대표사진 URL이 들어온다.
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
                // TODO: 일정 상세 연결
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
