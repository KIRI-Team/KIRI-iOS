//
// MARK: - 파일 가이드
// 담당 화면: 기록탭 컨테이너. 캘린더·버킷리스트와 선택된 일정/리뷰를 전환합니다.
// UI 수정 위치: RecordTab, selectedTab, 하위 뷰의 padding/spacing.
// Figma: 기록탭 9898:18872. 하위 API 상태는 각 컴포넌트에서 관리합니다.
//
import SwiftUI

struct RecordView: View {

    // 가족 상태가 확인된 뒤에만 기록 API를 조회합니다.
    // 둘러보기와 상태 확인 실패를 서버 빈 목록으로 오인하지 않도록 라우터 상태를 받습니다.
    let userMode: AppRouter.UserMode
    let familyState: AppRouter.FamilyState

    init(
        userMode: AppRouter.UserMode = .family,
        familyState: AppRouter.FamilyState = .hasFamily
    ) {
        self.userMode = userMode
        self.familyState = familyState
    }

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

                    // 서버 리뷰 조회/등록 API가 실제 화면에 연결되기 전까지
                    // UserDefaults의 임시 Draft를 일정 상세에 표시하지 않습니다.
                    savedReview: nil,
                    onReviewSaved: nil

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

    @ViewBuilder
    private var recordContent: some View {

        if userMode == .browse || familyState == .noFamily {
            RecordFamilyRequiredView()
        } else if familyState == .loading || familyState == .unknown {
            RecordFamilyStateView(state: familyState)
        } else {

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

                        // 리뷰 조회 API가 연결되기 전까지 로컬 Draft는 운영 화면에 표시하지 않습니다.
                        // Preview와 테스트에서만 ActivityReviewStore를 사용할 수 있습니다.
                        savedReviewDrafts: [:],
                        onSelectSavedReview: { _ in }

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

// MARK: - 가족공간 접근 상태

private struct RecordFamilyRequiredView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 30))
                .foregroundStyle(KIRIColor.Icon.secondary)
            Text("가족공간에 참여하면 기록을 볼 수 있어요")
                .font(KIRITypography.headingSmall)
                .foregroundStyle(KIRIColor.Text.strong)
            Text("가족공간을 만들거나 초대를 받아 기록을 시작해 보세요.")
                .font(KIRITypography.bodySmall)
                .foregroundStyle(KIRIColor.Text.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }
}

private struct RecordFamilyStateView: View {
    let state: AppRouter.FamilyState

    var body: some View {
        VStack(spacing: 14) {
            if state == .loading {
                ProgressView()
            } else {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 28))
                    .foregroundStyle(KIRIColor.Icon.secondary)
                Text("가족공간 상태를 확인하고 있어요")
                    .font(KIRITypography.headingSmall)
                    .foregroundStyle(KIRIColor.Text.strong)
                Text("잠시 후 다시 시도해 주세요.")
                    .font(KIRITypography.bodySmall)
                    .foregroundStyle(KIRIColor.Text.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
