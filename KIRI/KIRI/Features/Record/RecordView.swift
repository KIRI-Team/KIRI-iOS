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
    @State private var selectedInvitation:
        RecordBucketListView.InvitationData?
    @State private var showsInvitationSentBanner = false
    @State private var savedReviews: [String: ActivityReviewWriteView.Draft] = [:]
    private var demoTodaySchedule: RecordCalendarView.ScheduleDetailData {
        let now = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy.MM.dd"
        return .init(day: Calendar.current.component(.day, from: now),
                     month: Calendar.current.component(.month, from: now),
                     status: .confirmedSchedule,
                     title: "한강 뚜벅뚜벅 축제 방문",
                     date: formatter.string(from: now),
                     startTime: "오후 2시 50분", location: "여의도 한강 공원",
                     expectedSteps: "정보 없음", duration: "정보 없음")
    }
    private var mockTodayContent: TodayActivityView.Content {
        .init(isCurrentUserConfirmed: true, participantNames: ["나"],
              requiredActivities: [], requiredItems: [], nearbyRecommendations: [])
    }
    private func reviewKey(_ schedule: RecordCalendarView.ScheduleDetailData) -> String {
        "\(schedule.date)|\(schedule.title)"
    }
    var body: some View {
        ZStack {
            KIRIColor.Background.base
                .ignoresSafeArea()
            if let invitation = selectedInvitation {
                InvitationView(
                    invitation: invitation,
                    onBack: {
                        selectedInvitation = nil
                    },
                    onCancel: {
                        selectedInvitation = nil
                    },
                    onSendInApp: {
                        handleInAppInvitationSent()
                    },
                    onSendKakao: {
                        handleKakaoInvitation()
                    }
                )
            } else if let review = selectedReview {
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
                    },
                    todayContent: schedule.date == demoTodaySchedule.date &&
                        schedule.title == demoTodaySchedule.title ? mockTodayContent : nil,
                    savedReview: savedReviews[reviewKey(schedule)],
                    onReviewSaved: { draft in
                        savedReviews[reviewKey(schedule)] = draft
                    }
                )
            } else {
                recordContent
            }
        }
    }
    // MARK: - Record Content
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
                        },
                        demoTodaySchedule: demoTodaySchedule,
                        savedReviewSchedules: savedReviews.keys.contains(reviewKey(demoTodaySchedule))
                            ? [demoTodaySchedule] : [],
                        onSelectSavedReview: { schedule in
                            selectedSchedule = schedule
                        }
                    )
                case .bucket:
                    RecordBucketListView(
                        showsInvitationSentBanner:
                            showsInvitationSentBanner,
                        onSelectInvitation: { invitation in
                            showsInvitationSentBanner = false
                            selectedInvitation = invitation
                        }
                    )
                }
            }
        }
    }
    // MARK: - Invitation
    private func handleInAppInvitationSent() {
        selectedInvitation = nil
        selectedTab = .bucket
        withAnimation(
            .easeOut(duration: 0.2)
        ) {
            showsInvitationSentBanner = true
        }
        Task {
            try? await Task.sleep(
                for: .seconds(2.5)
            )
            await MainActor.run {
                withAnimation(
                    .easeOut(duration: 0.2)
                ) {
                    showsInvitationSentBanner = false
                }
            }
        }
    }
    private func handleKakaoInvitation() {
        // TODO:
        // 카카오 공유 SDK 또는 공유 링크 정책 확정 후 연결
        selectedInvitation = nil
        selectedTab = .bucket
    }
}
#Preview {
    RecordView()
}
