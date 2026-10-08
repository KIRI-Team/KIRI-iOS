

import SwiftUI

struct ScheduleScreenPreview: View {

    @State private var selectedScreen: PreviewScreen = .today
    @State private var selectedConditions:
        Set<ConditionAdjustmentSheet.Condition> = []

    private enum PreviewScreen: String, CaseIterable {
        case today = "약속 당일"
        case condition = "컨디션 조정"
        case schedule = "일정 상세"
    }

    private var todayDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: Date())
    }

    private var todaySchedule: RecordCalendarView.ScheduleDetailData {
        let calendar = Calendar.current
        let now = Date()

        return .init(
            day: calendar.component(.day, from: now),
            month: calendar.component(.month, from: now),
            status: .confirmedSchedule,
            title: "한강 뚜벅뚜벅 축제 가보기",
            date: todayDate,
            startTime: "오후 2시 50분",
            location: "여의도 한강 공원",
            expectedSteps: "20000보",
            duration: "8시간"
        )
    }

    private var mockContent: TodayActivityView.Content {
        .init(
            isCurrentUserConfirmed: true,
            participantNames: [
                "김주연",
                "엄마",
                "아빠"
            ],
            requiredActivities: [
                "잠수교 위에서 한강 보며 걷기",
                "야외 취식존에서 한강 보며 식사하기"
            ],
            requiredItems: [
                .init(
                    id: "umbrella",
                    title: "양산",
                    reason: "오늘은 햇빛이 강할 수 있어요."
                ),
                .init(
                    id: "water",
                    title: "생수",
                    reason: "걷는 동안 수분을 보충해요."
                ),
                .init(
                    id: "shoes",
                    title: "편한 신발",
                    reason: "오래 걸을 때 발의 부담을 줄여요."
                )
            ],
            nearbyRecommendations: [
                .init(
                    id: "sevit",
                    title: "세빛섬",
                    location: "서울 서초구 반포동",
                    description: "한강 위에서 풍경을 즐길 수 있는 공간",
                    distanceMeters: 850,
                    isRestPlace: true,
                    price: 0,
                    crowdLevel: nil
                ),
                .init(
                    id: "bridge",
                    title: "반포대교 달빛무지개분수",
                    location: "서울 서초구 반포동",
                    description: "한강 주변에서 즐기는 야외 볼거리",
                    distanceMeters: 1200,
                    isRestPlace: false,
                    price: 0,
                    crowdLevel: nil
                )
            ]
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            previewSelector

            Divider()
                .overlay(KIRIColor.Border.subtle)

            Group {
                switch selectedScreen {
                case .today:
                    TodayActivityView(
                        schedule: todaySchedule,
                        content: mockContent,
                        onBack: {}
                    )

                case .condition:
                    ConditionAdjustmentSheet(
                        selectedConditions: selectedConditions
                    ) { conditions in
                        selectedConditions = conditions
                    }

                case .schedule:
                    ScheduleDetailView(
                        schedule: todaySchedule,
                        onBack: {},
                        todayContent: mockContent
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(
            KIRIColor.Background.base.ignoresSafeArea()
        )
    }

    private var previewSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("KIRI · 화면 테스트")
                    .font(KIRITypography.bodySmallMedium)
                    .foregroundStyle(KIRIColor.Text.strong)

                Spacer()

                Text("MOCK")
                    .font(KIRITypography.captionMedium)
                    .foregroundStyle(KIRIColor.Primary.default)
            }

            HStack(spacing: 8) {
                ForEach(PreviewScreen.allCases, id: \.self) { screen in
                    Button {
                        selectedScreen = screen
                    } label: {
                        Text(screen.rawValue)
                            .font(KIRITypography.bodySmallMedium)
                            .foregroundStyle(
                                selectedScreen == screen
                                    ? KIRIColor.Text.onGreen
                                    : KIRIColor.Text.secondary
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(
                                selectedScreen == screen
                                    ? KIRIColor.Primary.default
                                    : KIRIColor.Background.secondary
                            )
                            .clipShape(
                                RoundedRectangle(cornerRadius: 8)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 14)
    }
}

#Preview("KIRI 일정 화면 테스트") {
    ScheduleScreenPreview()
}
