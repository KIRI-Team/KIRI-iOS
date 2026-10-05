
import SwiftUI

struct ScheduleDetailView: View {

    let schedule: RecordCalendarView.ScheduleDetailData
    let onBack: () -> Void

    @State private var isParticipantTooltipVisible = false
    @State private var selectedContentTab: ContentTab = .aiActivity

    private enum ContentTab: Hashable {
        case aiActivity
        case familyMemory
    }

    var body: some View {
        ZStack {
            KIRIColor.Background.base
                .ignoresSafeArea()

            ScrollView(
                .vertical,
                showsIndicators: false
            ) {
                VStack(
                    alignment: .leading,
                    spacing: 0
                ) {
                    navigationBar

                    statusBadge
                        .padding(.top, 21)

                    titleSection
                        .padding(.top, 12)

                    activityDetail
                        .padding(.top, 30)

                    contentSelector
                        .padding(.top, 53)

                    aiActivitySection
                        .padding(.top, 48)

                    essentialItemSection
                        .padding(.top, 48)

                    nearbySection
                        .padding(.top, 48)

                    Color.clear
                        .frame(height: 80)
                }
                .padding(.horizontal, 18)
            }

            if isParticipantTooltipVisible {
                tooltipOverlay
            }
        }
    }

    // MARK: - Navigation

    private var navigationBar: some View {
        ZStack {
            Text("\(schedule.day)월 \(schedule.day)일")
                .font(KIRITypography.bodySmallMedium)
                .tracking(-0.56)
                .foregroundStyle(KIRIColor.Text.tertiary)

            HStack {
                KIRIBackButton {
                    onBack()
                }

                Spacer()
            }
        }
        .frame(height: 62)
    }

    // MARK: - Status

    private var statusBadge: some View {
        Text(
            schedule.status == .confirmedSchedule
                ? "약속 확정"
                : "약속 예정"
        )
        .font(KIRITypography.bodySmallMedium)
        .tracking(-0.56)
        .foregroundStyle(
            schedule.status == .confirmedSchedule
                ? KIRIColor.Text.accent
                : KIRIColor.Text.secondary
        )
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            schedule.status == .confirmedSchedule
                ? KIRIColor.Background.greenSoft
                : KIRIColor.Background.elevated
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 5
            )
        )
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            Text(schedule.title)
                .font(KIRITypography.title)
                .tracking(-1.12)
                .foregroundStyle(KIRIColor.Text.strong)

            HStack(spacing: 6) {
                Button {
                    isParticipantTooltipVisible = true
                } label: {
                    Text("인원확인")
                        .font(KIRITypography.body)
                        .tracking(-0.64)
                        .foregroundStyle(KIRIColor.Text.primary)
                        .underline()
                }
                .buttonStyle(.plain)

                Text("I")
                    .font(KIRITypography.body)
                    .foregroundStyle(KIRIColor.Text.primary)

                Text(schedule.date)
                    .font(KIRITypography.body)
                    .tracking(-0.64)
                    .foregroundStyle(KIRIColor.Text.primary)
            }
        }
    }

    // MARK: - Activity Detail

    private var activityDetail: some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            detailRow(
                title: "시작 시간",
                value: schedule.startTime
            )

            detailRow(
                title: "장소",
                value: schedule.location
            )

            HStack(spacing: 14) {
                detailInline(
                    title: "예상 걸음수",
                    value: schedule.expectedSteps
                )

                detailInline(
                    title: "활동시간",
                    value: schedule.duration
                )
            }
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 16)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(
            KIRIColor.Background.secondary
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 8
            )
        )
    }

    private func detailRow(
        title: String,
        value: String
    ) -> some View {
        HStack(spacing: 10) {
            Text(title)

            Text("I")

            Text(value)
        }
        .font(KIRITypography.body)
        .tracking(-0.64)
        .foregroundStyle(KIRIColor.Text.primary)
    }

    private func detailInline(
        title: String,
        value: String
    ) -> some View {
        HStack(spacing: 6) {
            Text(title)

            Text("I")

            Text(value)
        }
        .font(KIRITypography.body)
        .tracking(-0.64)
        .foregroundStyle(KIRIColor.Text.primary)
    }

    // MARK: - Content Selector

    private var contentSelector: some View {
        HStack(spacing: 7) {
            selectorButton(
                title: "끼리네 AI 활동",
                tab: .aiActivity
            )

            selectorButton(
                title: "가족 추억",
                tab: .familyMemory
            )
        }
        .padding(4)
        .background(
            KIRIColor.Background.secondary
        )
        .clipShape(Capsule())
        .frame(
            maxWidth: .infinity,
            alignment: .center
        )
    }

    private func selectorButton(
        title: String,
        tab: ContentTab
    ) -> some View {
        Button {
            selectedContentTab = tab
        } label: {
            Text(title)
                .font(KIRITypography.headingSmall)
                .tracking(-0.72)
                .foregroundStyle(KIRIColor.Text.strong)
                .padding(.horizontal, 20)
                .frame(height: 44)
                .background(
                    selectedContentTab == tab
                        ? KIRIColor.Background.tertiary
                        : KIRIColor.Background.secondary
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - AI Activities

    private var aiActivitySection: some View {
        VStack(
            alignment: .leading,
            spacing: 18
        ) {
            sectionTitle(
                prefix: "오늘 ",
                accent: "끼리네 가족",
                suffix: "의 필수 활동"
            )

            recommendationCard(
                title: "잠수교 위에서 한강 보며 걷기",
                description: "차 없는 잠수교를 천천히 걸으며 한강 풍경과 축제 분위기를 즐길 수 있어요!"
            )

            recommendationCard(
                title: "야외 취식존에서 한강 보며 식사하기",
                description: "한강을 바라보며 푸드트럭에서 산 음식을 여유롭게 먹을 수 있어요!"
            )
        }
    }

    private func recommendationCard(
        title: String,
        description: String
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            HStack(spacing: 4) {
                Image(systemName: "umbrella.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(KIRIColor.Icon.primary)

                Text(title)
                    .font(KIRITypography.headingSmall)
                    .tracking(-0.72)
                    .foregroundStyle(KIRIColor.Text.strong)
            }

            Text(description)
                .font(KIRITypography.bodySmall)
                .tracking(-0.56)
                .foregroundStyle(KIRIColor.Text.secondary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 18)
        .frame(
            maxWidth: .infinity,
            minHeight: 110,
            alignment: .leading
        )
        .background(
            KIRIColor.Background.secondary
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 8
            )
        )
    }

    // MARK: - Essential Items

    private var essentialItemSection: some View {
        VStack(
            alignment: .leading,
            spacing: 18
        ) {
            sectionTitle(
                prefix: "오늘 ",
                accent: "끼리네 가족",
                suffix: "의 필수템"
            )

            HStack(spacing: 12) {
                essentialItemCard
                essentialItemCard
            }
        }
    }

    private var essentialItemCard: some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            HStack(spacing: 4) {
                Image(systemName: "umbrella.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(KIRIColor.Icon.primary)

                Text("양산")
                    .font(KIRITypography.headingSmall)
                    .tracking(-0.72)
                    .foregroundStyle(KIRIColor.Text.strong)
            }

            Text("오늘 자외선 농도가 많이 높아요! 피부 조심하세요~")
                .font(KIRITypography.bodySmall)
                .tracking(-0.56)
                .foregroundStyle(KIRIColor.Text.secondary)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
        }
        .padding(18)
        .frame(
            maxWidth: .infinity,
            minHeight: 130,
            alignment: .topLeading
        )
        .background(
            KIRIColor.Background.secondary
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 8
            )
        )
    }

    // MARK: - Nearby

    private var nearbySection: some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            Text("한강뚜벅뚜벅축제 근처 놀거리추천")
                .font(KIRITypography.headingSmall)
                .tracking(-0.72)
                .foregroundStyle(KIRIColor.Text.strong)

            HStack(spacing: 0) {
                Text("끼리네 가족")
                    .foregroundStyle(KIRIColor.Text.accent)

                Text("한테 맞는 놀거리를 추천해드려요!")
                    .foregroundStyle(KIRIColor.Text.disabled)
            }
            .font(KIRITypography.bodySmall)
            .tracking(-0.56)

            ScrollView(
                .horizontal,
                showsIndicators: false
            ) {
                HStack(spacing: 16) {
                    nearbyCard(
                        title: "세빛섬",
                        location: "서울시 반포구"
                    )

                    nearbyCard(
                        title: "반포대교 달빛무지개분수",
                        location: "서울시 반포구"
                    )
                }
            }
            .padding(.top, 12)
        }
    }

    private func nearbyCard(
        title: String,
        location: String
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 0
        ) {
            ZStack {
                KIRIColor.Background.elevated

                Image(systemName: "photo")
                    .font(.system(size: 24))
                    .foregroundStyle(KIRIColor.Icon.secondary)
            }
            .frame(
                width: 251,
                height: 144
            )

            VStack(
                alignment: .leading,
                spacing: 3
            ) {
                Text(title)
                    .font(KIRITypography.headingSmall)
                    .tracking(-0.72)
                    .foregroundStyle(KIRIColor.Text.strong)
                    .lineLimit(1)

                Text(location)
                    .font(KIRITypography.bodySmallMedium)
                    .tracking(-0.56)
                    .foregroundStyle(KIRIColor.Text.secondary)
            }
            .padding(.horizontal, 19)
            .padding(.top, 20)

            Spacer()
        }
        .frame(
            width: 251,
            height: 284
        )
        .background(
            KIRIColor.Background.elevated
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
    }

    // MARK: - Section Title

    private func sectionTitle(
        prefix: String,
        accent: String,
        suffix: String
    ) -> some View {
        HStack(spacing: 0) {
            Text(prefix)
                .foregroundStyle(KIRIColor.Text.strong)

            Text(accent)
                .foregroundStyle(KIRIColor.Text.accent)

            Text(suffix)
                .foregroundStyle(KIRIColor.Text.primary)
        }
        .font(KIRITypography.headingSmall)
        .tracking(-0.72)
    }

    // MARK: - Tooltip

    private var tooltipOverlay: some View {
        ZStack {
            KIRIColor.Background.base
                .opacity(0.70)
                .ignoresSafeArea()
                .onTapGesture {
                    isParticipantTooltipVisible = false
                }

            VStack {
                ScheduleParticipantTooltip()
                    .padding(.top, 241)

                Spacer()
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .topLeading
            )
            .padding(.leading, 20)
        }
    }
}

#Preview {
    ScheduleDetailView(
        schedule: .init(
            day: 3,
            status: .pendingSchedule,
            title: "한강 뚜벅뚜벅 축제 가보기",
            date: "2026.06.13",
            startTime: "오후 2시 50분",
            location: "여의도 한강 공원",
            expectedSteps: "20000보",
            duration: "8시간"
        ),
        onBack: {}
    )
}
