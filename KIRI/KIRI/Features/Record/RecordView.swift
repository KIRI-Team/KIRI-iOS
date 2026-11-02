//
// MARK: - 파일 가이드
// 담당 화면: 기록탭 컨테이너. 캘린더·버킷리스트와 선택된 일정/리뷰를 전환합니다.
// UI 수정 위치: RecordTab, selectedTab, 하위 뷰의 padding/spacing.
// Figma: 기록탭 9898:18872. 하위 API 상태는 각 컴포넌트에서 관리합니다.
//
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

    @State private var editingReview = false
    @State private var showingDeleteConfirmation = false
    @State private var selectedReviewSchedule: RecordCalendarView.ScheduleDetailData?
    @State private var reviewStore = ActivityReviewStore()

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
                    localDraft: selectedReviewSchedule.flatMap { reviewStore.reviews[reviewKey($0)] } ?? review.draft,
                    onBack: { selectedReview = nil; selectedReviewSchedule = nil },
                    onEdit: { editingReview = true },
                    onDelete: { showingDeleteConfirmation = true }
                )
            } else if let schedule = selectedSchedule {

                ScheduleDetailView(

                    schedule: schedule,

                    onBack: {

                        selectedSchedule = nil

                    },

                    // 서버 일정 상세가 제공하는 데이터만 표시합니다.
                    todayContent: nil,

                    savedReview: reviewStore.reviews[reviewKey(schedule)],

                    onReviewSaved: { draft in

                        reviewStore.save(draft, for: reviewKey(schedule))

                    }

                )

            } else {

                recordContent

            }

        }

        .fullScreenCover(isPresented: $editingReview) {
            if let schedule = selectedReviewSchedule,
               let draft = reviewStore.reviews[reviewKey(schedule)] {
                ActivityReviewWriteView(
                    onBack: { editingReview = false },
                    onSubmit: { updated in
                        reviewStore.save(updated, for: reviewKey(schedule))
                        selectedReview = reviewData(for: schedule, draft: updated)
                        editingReview = false
                    },
                    initialDraft: draft
                )
            }
        }
        .confirmationDialog("이 기록을 삭제할까요?", isPresented: $showingDeleteConfirmation) {
            Button("삭제하기", role: .destructive) {
                if let schedule = selectedReviewSchedule {
                    reviewStore.remove(for: reviewKey(schedule))
                }
                selectedReview = nil
                selectedReviewSchedule = nil
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("현재 실행 중인 앱의 임시 기록만 삭제됩니다.")
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

                            selectedReviewSchedule = nil
                            selectedReview = review

                        },

                        savedReviewDrafts: reviewStore.reviews,

                        onSelectSavedReview: { schedule in

                            openSavedReview(schedule)

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

    private func openSavedReview(_ schedule: RecordCalendarView.ScheduleDetailData) {
        guard let draft = reviewStore.reviews[reviewKey(schedule)] else { return }
        selectedReviewSchedule = schedule
        selectedReview = reviewData(for: schedule, draft: draft)
    }

    private func reviewData(for schedule: RecordCalendarView.ScheduleDetailData,
                            draft: ActivityReviewWriteView.Draft) -> RecordCalendarView.ReviewDetailData {
        .init(title: schedule.title, date: schedule.date,
              familyName: "끼리네가족", authorName: "나", isCurrentUser: true,
              review: draft.comment, writtenDate: Date.now.formatted(.dateTime.month().day()),
              representativePhotoURL: nil,
              draft: draft)
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
