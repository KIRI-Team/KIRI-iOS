import SwiftUI

struct RecordView: View {

    enum RecordTab: Hashable {
        case calendar
        case bucket

        var title: String {
            switch self {
            case .calendar:
                return "캘린더"

            case .bucket:
                return "버킷리스트"
            }
        }
    }

    @State private var selectedTab: RecordTab = .calendar

    @State private var selectedSchedule:
        RecordCalendarView.ScheduleDetailData?

    @State private var selectedReview:
        RecordCalendarView.ReviewDetailData?

    var body: some View {
        ZStack {
            KIRIColor.Background.base
                .ignoresSafeArea()

            if let review = selectedReview {
                ReviewDetailView(
                    review: review,
                    onBack: {
                        selectedReview = nil
                    },
                    onEdit: {
                        // TODO: 리뷰 수정 화면 연결
                    },
                    onDelete: {
                        // TODO: 리뷰 삭제 API 연결
                        selectedReview = nil
                    }
                )

            } else if let schedule = selectedSchedule {
                ScheduleDetailView(
                    schedule: schedule,
                    onBack: {
                        selectedSchedule = nil
                    }
                )

            } else {
                recordContent
            }
        }
    }

    private var recordContent: some View {
        VStack(spacing: 0) {
            KIRITopTab(
                items: [
                    RecordTab.calendar,
                    RecordTab.bucket
                ],
                selection: $selectedTab
            ) { tab in
                tab.title
            }
            .padding(.horizontal, 18)
            .padding(.top, 40)

            Group {
                switch selectedTab {
                case .calendar:
                    RecordCalendarView(
                        onSelectSchedule: { schedule in
                            selectedSchedule = schedule
                        },
                        onSelectReview: { review in
                            selectedReview = review
                        }
                    )

                case .bucket:
                    RecordBucketListView()
                }
            }
        }
    }
}

#Preview {
    RecordView()
}
