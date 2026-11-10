//
// MARK: - 파일 가이드
// 파일: Features/Record/Schedule/ScheduleDetailView.swift
// 담당 영역: 기능별 SwiftUI 화면과 상태
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//

import SwiftUI
struct ScheduleDetailView: View {
    let schedule: RecordCalendarView.ScheduleDetailData
    let onBack: () -> Void
    // 서버에서 검증된 약속 당일 데이터.
    // nil이면 당일 활동 화면을 열지 않는다.
    var todayContent: TodayActivityView.Content? = nil
    var savedReview: ActivityReviewWriteView.Draft? = nil
    var onReviewSaved: ((ActivityReviewWriteView.Draft) -> Void)? = nil
    /// 일정 변경이 서버에 반영된 뒤 캘린더·다가오는 일정 목록을 다시 읽도록 알립니다.
    var onScheduleChanged: (() -> Void)? = nil
    @State private var showingReviewEditor = false
    @State private var localEditedReview: ActivityReviewWriteView.Draft?
    @State private var serverDetail: ScheduleDetailResult?
    @State private var isLoadingServerDetail = false
    @State private var serverDetailError: String?
    @State private var isMutatingSchedule = false
    @State private var scheduleMutationError: String?
    @State private var showingCancelConfirmation = false
    @State private var showingEditSheet = false
    @State private var nearbyMissions: [NearbyMissionResult] = []
    @State private var nearbyLoadError: String?
    @State private var isLoadingNearby = false
    private var currentReview: ActivityReviewWriteView.Draft? {
        localEditedReview ?? savedReview
    }
    @State private var selectedTab: ContentTab = .aiActivity
    private enum ContentTab: String, CaseIterable {
        case aiActivity = "끼리네 AI 활동"
        case familyMemory = "가족 추억"
    }
    private enum DateState {
        case upcoming
        case today
        case past
        case unknown
    }
    private var dateState: DateState {
        guard let scheduledDate = parsedScheduleDate else {
            return .unknown
        }
        let calendar = Calendar.current
        if calendar.isDateInToday(scheduledDate) {
            return .today
        }
        return scheduledDate > Date() ? .upcoming : .past
    }
    private var parsedScheduleDate: Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = .current
        formatter.dateFormat = effectiveDate.contains(".") ? "yyyy.MM.dd" : "yyyy-MM-dd"
        formatter.isLenient = false
        return formatter.date(from: effectiveDate)
    }
    private var effectiveDate: String {
        serverDetail?.date ?? schedule.date
    }
    private var effectiveStartTime: String {
        serverDetail?.time ?? schedule.startTime
    }
    private var effectiveStatus: String {
        serverDetail?.status ?? (schedule.status == .confirmedSchedule ? "CONFIRMED" : "PENDING")
    }
    var body: some View {
        Group {
            if let review = currentReview {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        navigationBar
                        Text(schedule.title)
                            .font(KIRITypography.title)
                            .foregroundStyle(KIRIColor.Text.strong)
                        activityDetail
                        ActivityReviewCompleteView(
                            schedule: schedule,
                            review: review,
                            onBack: onBack,
                            onEdit: { showingReviewEditor = true }
                        )
                    }
                    .padding(.horizontal, 18)
                }
            } else {
                switch dateState {
                case .today:
                    if schedule.status == .confirmedSchedule,
                       let todayContent,
                       todayContent.isCurrentUserConfirmed {
                        TodayActivityView(
                            schedule: schedule,
                            content: todayContent,
                            onBack: onBack,
                            savedReview: currentReview,
                            onReviewSaved: { draft in
                                localEditedReview = draft
                                onReviewSaved?(draft)
                            }
                        )
                    } else {
                        statusView(
                            title: "약속 당일 화면을 확인할 수 없어요",
                            message: "확정된 일정의 최종 참여자만 이용할 수 있어요."
                        )
                    }
                case .upcoming:
                    upcomingContent
                case .past:
                    statusView(
                        title: "지난 약속이에요",
                        message: "활동 완료 여부는 가족이 남긴 기록을 기준으로 확인해요."
                    )
                case .unknown:
                    statusView(
                        title: "일정 날짜를 확인할 수 없어요",
                        message: "일정 정보를 다시 확인해 주세요."
                    )
                }
            }
        }
        .fullScreenCover(isPresented: $showingReviewEditor) {
            ActivityReviewWriteView(
                onBack: { showingReviewEditor = false },
                onSubmit: { draft in
                    localEditedReview = draft
                    onReviewSaved?(draft)
                    showingReviewEditor = false
                },
                onSubmitToServer: schedule.scheduleId.map { scheduleId in
                    { draft in
                        var imageKeys: [String] = []
                        for image in draft.images {
                            guard let data = image.jpegData(compressionQuality: 0.85) else {
                                throw APIError.decodingFailed
                            }
                            let contentType = "image/jpeg"
                            let presigned = try await AuthService.shared.issuePresignedURL(
                                contentType: contentType,
                                contentLength: Int64(data.count)
                            )
                            try await AuthService.shared.uploadImage(data: data, to: presigned.presignedUrl, contentType: contentType)
                            imageKeys.append(presigned.imageKey)
                        }
                        _ = try await AuthService.shared.createReview(
                            scheduleId: scheduleId,
                            request: ReviewCreateRequest(
                                starRating: draft.rating,
                                imageKeys: imageKeys,
                                content: draft.comment,
                                isRejoinIntended: draft.wantsToRepeat
                            )
                        )
                    }
                },
                initialDraft: currentReview
            )
        }
        .sheet(isPresented: $showingEditSheet) {
            if let scheduleId = schedule.scheduleId {
                ScheduleEditSheet(
                    scheduleId: scheduleId,
                    initialDate: effectiveDate,
                    initialTime: effectiveStartTime,
                    onUpdated: {
                        Task {
                            await loadServerDetail()
                            onScheduleChanged?()
                        }
                    }
                )
            }
        }
        .background(KIRIColor.Background.base)
        .task {
            await loadServerDetail()
            await loadNearbyMissions()
        }
    }

    private func loadServerDetail() async {
        guard let scheduleId = schedule.scheduleId, !isLoadingServerDetail else { return }
        isLoadingServerDetail = true
        serverDetailError = nil
        do {
            serverDetail = try await AuthService.shared.scheduleDetail(scheduleId: scheduleId)
        } catch {
            serverDetailError = "일정 최신 정보를 불러오지 못했어요."
            #if DEBUG
            print("[KIRI][Record] schedule detail failed id=\(scheduleId) error=\(error)")
            #endif
        }
        isLoadingServerDetail = false
    }

    private func loadNearbyMissions() async {
        guard let scheduleId = schedule.scheduleId, !isLoadingNearby else { return }
        isLoadingNearby = true
        nearbyLoadError = nil
        defer { isLoadingNearby = false }
        do {
            nearbyMissions = try await AuthService.shared.nearbyMissions(scheduleId: scheduleId)
        } catch {
            nearbyLoadError = "근처 놀거리 추천을 불러오지 못했어요."
        }
    }
    private var upcomingContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                navigationBar
                Text(
                    effectiveStatus == "CONFIRMED"
                        ? "약속 확정"
                        : "약속 예정"
                )
                .font(KIRITypography.bodySmall)
                .foregroundStyle(KIRIColor.Text.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(KIRIColor.Background.elevated)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .padding(.top, 21)
                Text(schedule.title)
                    .font(KIRITypography.title)
                    .foregroundStyle(KIRIColor.Text.strong)
                    .padding(.top, 12)
                activityDetail
                    .padding(.top, 30)
                if let participants = serverDetail?.participants, !participants.isEmpty {
                    participantSummary(participants)
                        .padding(.top, 18)
                }
                if isLoadingServerDetail {
                    ProgressView("일정 정보를 확인하고 있어요")
                        .padding(.top, 16)
                } else if let serverDetailError {
                    Text(serverDetailError)
                        .font(KIRITypography.bodySmall)
                        .foregroundStyle(KIRIColor.Text.secondary)
                        .padding(.top, 16)
                }
                contentSelector
                    .padding(.top, 53)
                selectedContent
                    .padding(.top, 40)
                scheduleActions
                    .padding(.top, 28)
                Color.clear.frame(height: 120)
            }
            .padding(.horizontal, 18)
        }
    }
    private var navigationBar: some View {
        ZStack {
            Text(effectiveDate.replacingOccurrences(of: "-", with: "."))
                .font(KIRITypography.bodySmallMedium)
                .foregroundStyle(KIRIColor.Text.tertiary)
            HStack {
                KIRIBackButton(action: onBack)
                Spacer()
            }
        }
        .frame(height: 62)
    }
    private var activityDetail: some View {
        VStack(alignment: .leading, spacing: 9) {
            detailRow("시작 시간", effectiveStartTime)
            detailRow("장소", schedule.location)
            detailRow("예상 걸음 수", schedule.expectedSteps)
            detailRow("활동 시간", schedule.duration)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KIRIColor.Background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func participantSummary(_ participants: [ScheduleParticipantResult]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("참여 가족")
                .font(KIRITypography.bodySmallMedium)
                .foregroundStyle(KIRIColor.Text.strong)
            ForEach(Array(participants.enumerated()), id: \.offset) { _, participant in
                HStack {
                    Text(participant.nickname)
                    Spacer()
                    Text(participant.accepted ? "참여" : "응답 대기")
                        .foregroundStyle(participant.accepted ? KIRIColor.Primary.default : KIRIColor.Text.secondary)
                }
                .font(KIRITypography.bodySmall)
                .foregroundStyle(KIRIColor.Text.primary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KIRIColor.Background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    private func detailRow(
        _ label: String,
        _ value: String
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(label)
                .foregroundStyle(KIRIColor.Text.secondary)
            Text("|")
                .foregroundStyle(KIRIColor.Text.tertiary)
            Text(value)
                .foregroundStyle(KIRIColor.Text.primary)
        }
        .font(KIRITypography.body)
    }
    private var contentSelector: some View {
        HStack(spacing: 6) {
            ForEach(ContentTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Text(tab.rawValue)
                        .font(KIRITypography.headingSmall)
                        .foregroundStyle(
                            selectedTab == tab
                                ? KIRIColor.Text.strong
                                : KIRIColor.Text.tertiary
                        )
                        .padding(.horizontal, 18)
                        .frame(height: 44)
                        .background(
                            selectedTab == tab
                                ? KIRIColor.Background.tertiary
                                : Color.clear
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(KIRIColor.Background.secondary)
        .clipShape(Capsule())
        .frame(maxWidth: .infinity)
    }

    /// 서버 계약이 확정된 일정 응답·취소 동작만 노출합니다.
    /// 버튼을 누르면 서버 결과를 받은 뒤 상세를 재조회하고 상위 캘린더도 갱신합니다.
    private var scheduleActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let scheduleMutationError {
                Text(scheduleMutationError)
                    .font(KIRITypography.bodySmall)
                    .foregroundStyle(KIRIColor.Text.secondary)
            }

            if effectiveStatus != "CANCELLED" {
                Button("일정 수정") { showingEditSheet = true }
                    .buttonStyle(scheduleActionStyle(isPrimary: false))
                    .disabled(isMutatingSchedule || schedule.scheduleId == nil)

                HStack(spacing: 8) {
                    Button("거절") {
                        Task { await respond(action: "DECLINED") }
                    }
                    .buttonStyle(scheduleActionStyle(isPrimary: false))
                    .disabled(isMutatingSchedule)

                    Button("수락") {
                        Task { await respond(action: "ACCEPTED") }
                    }
                    .buttonStyle(scheduleActionStyle(isPrimary: true))
                    .disabled(isMutatingSchedule)
                }

                Button("약속 취소", role: .destructive) {
                    showingCancelConfirmation = true
                }
                .font(KIRITypography.bodySmallMedium)
                .foregroundStyle(KIRIColor.Text.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .disabled(isMutatingSchedule)
            }
        }
        .confirmationDialog(
            "약속을 취소할까요?",
            isPresented: $showingCancelConfirmation
        ) {
            Button("약속 취소", role: .destructive) {
                Task { await cancelSchedule() }
            }
            Button("돌아가기", role: .cancel) {}
        } message: {
            Text("가족에게 취소 내역이 표시됩니다.")
        }
    }

    private func scheduleActionStyle(isPrimary: Bool) -> some ButtonStyle {
        ScheduleActionButtonStyle(isPrimary: isPrimary)
    }

    private func respond(action: String) async {
        guard let scheduleId = schedule.scheduleId, !isMutatingSchedule else { return }
        isMutatingSchedule = true
        scheduleMutationError = nil
        defer { isMutatingSchedule = false }
        do {
            _ = try await AuthService.shared.respondToSchedule(scheduleId: scheduleId, action: action)
            await loadServerDetail()
            onScheduleChanged?()
        } catch {
            scheduleMutationError = "일정 응답을 저장하지 못했어요. 다시 시도해 주세요."
        }
    }

    private func cancelSchedule() async {
        guard let scheduleId = schedule.scheduleId, !isMutatingSchedule else { return }
        isMutatingSchedule = true
        scheduleMutationError = nil
        defer { isMutatingSchedule = false }
        do {
            _ = try await AuthService.shared.cancelSchedule(scheduleId: scheduleId)
            await loadServerDetail()
            onScheduleChanged?()
        } catch {
            scheduleMutationError = "약속을 취소하지 못했어요. 다시 시도해 주세요."
        }
    }
    private var selectedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(
                selectedTab == .aiActivity
                    ? "끼리네 AI 활동"
                    : "가족 추억"
            )
            .font(KIRITypography.headingSmall)
            .foregroundStyle(KIRIColor.Text.strong)
            if selectedTab == .aiActivity {
                if isLoadingNearby {
                    ProgressView().frame(maxWidth: .infinity, minHeight: 110)
                } else if let nearbyLoadError {
                    VStack(spacing: 8) {
                        Text(nearbyLoadError).font(KIRITypography.bodySmall).foregroundStyle(KIRIColor.Text.secondary)
                        Button("다시 시도") { Task { await loadNearbyMissions() } }
                    }.frame(maxWidth: .infinity, minHeight: 110)
                } else if nearbyMissions.isEmpty {
                    Text("근처에 추천할 놀거리가 없어요.")
                        .font(KIRITypography.bodySmall).foregroundStyle(KIRIColor.Text.secondary)
                        .frame(maxWidth: .infinity, minHeight: 110)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(nearbyMissions) { item in
                                nearbyCard(item)
                            }
                        }
                    }
                }
            } else {
                Text("아직 등록된 가족 추억이 없어요.")
                    .font(KIRITypography.bodySmall)
                    .foregroundStyle(KIRIColor.Text.secondary)
                    .frame(maxWidth: .infinity, minHeight: 110)
                    .background(KIRIColor.Background.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private func nearbyCard(_ item: NearbyMissionResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            KIRIContentImage(imageURL: item.imageUrl, mockAssetName: nil) {
                KIRIColor.Background.tertiary
            }
            .frame(width: 180, height: 120)
            .clipped()
            Text(item.placeName).font(KIRITypography.bodySmallMedium).foregroundStyle(KIRIColor.Text.strong).lineLimit(2)
            Text(item.region).font(KIRITypography.caption).foregroundStyle(KIRIColor.Text.secondary).lineLimit(1)
            Text(item.description).font(KIRITypography.caption).foregroundStyle(KIRIColor.Text.tertiary).lineLimit(2)
        }
        .padding(10)
        .frame(width: 200, alignment: .leading)
        .background(KIRIColor.Background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    private func statusView(
        title: String,
        message: String
    ) -> some View {
        VStack(spacing: 0) {
            navigationBar
                .padding(.horizontal, 18)
            Spacer()
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 36))
                .foregroundStyle(KIRIColor.Text.tertiary)
            Text(title)
                .font(KIRITypography.headingSmall)
                .foregroundStyle(KIRIColor.Text.strong)
                .padding(.top, 20)
            Text(message)
                .font(KIRITypography.bodySmall)
                .foregroundStyle(KIRIColor.Text.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 10)
                .padding(.horizontal, 24)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ScheduleActionButtonStyle: ButtonStyle {
    let isPrimary: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(KIRITypography.button)
            .foregroundStyle(isPrimary ? KIRIColor.Text.onGreen : KIRIColor.Text.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isPrimary ? KIRIColor.Primary.default : KIRIColor.Background.elevated)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}
