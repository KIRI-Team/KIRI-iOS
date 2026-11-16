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
    /// 주변 추천 카드에서 선택한 미션을 기록 탭 라우터가 엽니다.
    var onMissionSelected: ((NearbyMissionResult) -> Void)? = nil
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
    @State private var toastMessage: String?
    @State private var toastGeneration = 0
    @State private var showingCancelConfirmation = false
    @State private var showingEditSheet = false
    @State private var nearbyMissions: [NearbyMissionResult] = []
    @State private var nearbyLoadError: String?
    @State private var isLoadingNearby = false
    @State private var serverReviews: [ReviewItemResult] = []
    @State private var representativePhotoId: Int?
    @State private var showingRepresentativePicker = false
    @State private var isChangingRepresentativePhoto = false
    @State private var reviewsLoadError: String?
    @State private var isLoadingReviews = false
    @State private var reviewMutationError: String?
    @State private var reviewToDelete: ReviewItemResult?
    @State private var isDeletingReview = false
    @State private var currentUserNickname = ""
    @State private var currentUserRole = ""
    @State private var familyMembers: [FamilyMemberInfoResult] = []
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
    private var parsedScheduleDateTime: Date? {
        let dateValue = effectiveDate.replacingOccurrences(of: ".", with: "-")
        let timeValue = effectiveStartTime.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !dateValue.isEmpty, !timeValue.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.isLenient = false
        for format in ["yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd HH:mm"] {
            formatter.dateFormat = format
            if let value = formatter.date(from: "\(dateValue) \(timeValue)") { return value }
        }
        return nil
    }
    private var isAppointmentPast: Bool {
        guard let scheduledAt = parsedScheduleDateTime else {
            return parsedScheduleDate.map { $0 < Calendar.current.startOfDay(for: Date()) } ?? false
        }
        return scheduledAt <= Date()
    }
    private var canWriteReview: Bool {
        guard let detail = serverDetail else { return false }
        let status = detail.status?.uppercased() ?? ""
        let isConfirmedStatus = ["CONFIRMED", "COMPLETED", "TODAY"].contains(status)
        return isConfirmedStatus && detail.myStatus?.uppercased() == "ACCEPTED" && isAppointmentPast
    }
    private var reviewEligibilityMessage: String {
        guard let detail = serverDetail else { return "일정 정보를 확인한 뒤 리뷰를 작성할 수 있어요." }
        let status = detail.status?.uppercased() ?? ""
        if status == "SCHEDULED" || status == "PENDING" {
            return "아직 확정되지 않은 약속은 리뷰를 작성할 수 없어요."
        }
        if detail.myStatus?.uppercased() != "ACCEPTED" {
            return "참여가 확정된 가족만 리뷰를 작성할 수 있어요."
        }
        if !isAppointmentPast { return "약속 시간이 지난 뒤 리뷰를 작성할 수 있어요." }
        return "현재 일정 상태에서는 리뷰를 작성할 수 없어요."
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
    private var displayTitle: String {
        let value = serverDetail?.missionTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? schedule.title : value
    }
    private var displayDescription: String? {
        guard let value = serverDetail?.missionDescription?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        return value
    }
    private var isReconfirmationRequired: Bool { serverDetail?.myStatus == "RECONFIRM_REQUIRED" }
    private func hasChanged(_ field: String) -> Bool { serverDetail?.changedFields.contains(field) == true }
    private func changedBadge(_ field: String) -> some View {
        Group {
            if isReconfirmationRequired && hasChanged(field) {
                Text("변경되었어요!")
                    .font(KIRITypography.caption)
                    .foregroundStyle(KIRIColor.Primary.default)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(KIRIColor.Primary.default.opacity(0.14))
                    .clipShape(Capsule())
            }
        }
    }
    var body: some View {
        Group {
            if let review = currentReview {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        navigationBar
                        Text(displayTitle)
                            .font(KIRITypography.title)
                            .foregroundStyle(KIRIColor.Text.strong)
                        activityDetail
                        ActivityReviewCompleteView(
                            schedule: schedule,
                            review: review,
                            onBack: onBack,
                            onEdit: { showingReviewEditor = true },
                            userName: currentUserNickname,
                            familyRole: currentUserRole
                        )
                    }
                    .padding(.horizontal, 18)
                }
            } else {
                if isAppointmentPast {
                    pastContent
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
                            missionTitle: displayTitle,
                            missionDescription: displayDescription,
                            requestMessage: serverDetail?.requestMessage,
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
                    pastContent
                case .unknown:
                    statusView(
                        title: "일정 날짜를 확인할 수 없어요",
                        message: "일정 정보를 다시 확인해 주세요."
                    )
                }
                }
            }
        }
        .fullScreenCover(isPresented: $showingReviewEditor) {
            ActivityReviewWriteView(
                onBack: { showingReviewEditor = false },
                onSubmit: { draft in
                    localEditedReview = draft
                    onReviewSaved?(draft)
                    onScheduleChanged?()
                    showingReviewEditor = false
                },
                onSubmitToServer: schedule.scheduleId.map { scheduleId in
                    { draft in
                        var imageKeys: [String] = []
                        for image in draft.images {
                            guard let data = image.jpegData(compressionQuality: 0.85) else {
                                throw APIError.decodingFailed
                            }
#if DEBUG
                            print("[KIRI][Review] image presign start bytes=\(data.count)")
#endif
                            let contentType = "image/jpeg"
                            let presigned = try await AuthService.shared.issuePresignedURL(
                                contentType: contentType,
                                contentLength: Int64(data.count)
                            )
                            try await AuthService.shared.uploadImage(data: data, to: presigned.presignedUrl, contentType: contentType)
                            imageKeys.append(presigned.imageKey)
#if DEBUG
                            print("[KIRI][Review] image upload completed")
#endif
                        }
                        let request = ReviewCreateRequest(
                            starRating: draft.rating,
                            imageKeys: imageKeys,
                            content: draft.comment,
                            isRejoinIntended: draft.wantsToRepeat
                        )
                        if let mine = serverReviews.first(where: { $0.isMine }) {
#if DEBUG
                            print("[KIRI][Review] request stage=update scheduleId=\(scheduleId) reviewId=\(mine.reviewId) images=\(imageKeys.count) rating=\(draft.rating)")
#endif
                            _ = try await AuthService.shared.updateReview(
                                scheduleId: scheduleId,
                                reviewId: mine.reviewId,
                                request: request
                            )
                        } else {
#if DEBUG
                            print("[KIRI][Review] request stage=create scheduleId=\(scheduleId) images=\(imageKeys.count) rating=\(draft.rating)")
#endif
                            _ = try await AuthService.shared.createReview(
                                scheduleId: scheduleId,
                                request: request
                            )
                        }
#if DEBUG
                        print("[KIRI][Review] request completed scheduleId=\(scheduleId)")
#endif
                        // 리뷰 생성만으로 대표사진이 자동 지정되지 않는 서버 계약을
                        // 보완합니다. 실패해도 리뷰 저장 성공을 실패로 바꾸지 않습니다.
                        if !imageKeys.isEmpty,
                           let latest = try? await AuthService.shared.scheduleReviews(scheduleId: scheduleId),
                           latest.representativePhotoId == nil,
                           let firstPhoto = latest.reviews.first(where: { $0.isMine })?.photos.first {
                            _ = try? await AuthService.shared.changeRepresentativePhoto(
                                scheduleId: scheduleId,
                                reviewPhotoId: firstPhoto.reviewPhotoId
                            )
                        }
#if DEBUG
                        print("[KIRI][Review] refresh completed scheduleId=\(scheduleId)")
#endif
                    }
                },
                initialDraft: currentReview,
                userName: currentUserNickname,
                familyRole: currentUserRole
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
                            await loadNearbyMissions()
                            onScheduleChanged?()
                            showToast("일정을 변경했어요.")
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showingRepresentativePicker) {
            RepresentativePhotoPicker(
                reviews: serverReviews,
                selectedPhotoId: representativePhotoId,
                isSaving: isChangingRepresentativePhoto,
                onSelect: { photo in
                    guard let scheduleId = schedule.scheduleId, !isChangingRepresentativePhoto else { return }
                    isChangingRepresentativePhoto = true
                    Task { @MainActor in
                        defer { isChangingRepresentativePhoto = false }
                        do {
                            let result = try await AuthService.shared.changeRepresentativePhoto(
                                scheduleId: scheduleId,
                                reviewPhotoId: photo.reviewPhotoId
                            )
                            representativePhotoId = result.representativePhotoId
                            showingRepresentativePicker = false
                            await loadReviews()
                            showToast("대표사진을 변경했어요.")
                        } catch {
                            showToast("대표사진을 변경하지 못했어요.")
                        }
                    }
                }
            )
        }
        .background(KIRIColor.Background.base)
        .alert("리뷰 삭제", isPresented: Binding(
            get: { reviewToDelete != nil },
            set: { if !$0 { reviewToDelete = nil } }
        )) {
            Button("삭제", role: .destructive) {
                guard let review = reviewToDelete else { return }
                Task { await deleteReview(review) }
            }
            Button("취소", role: .cancel) { reviewToDelete = nil }
        } message: {
            Text("작성한 리뷰를 삭제할까요?")
        }
        .alert("리뷰 처리 실패", isPresented: Binding(
            get: { reviewMutationError != nil },
            set: { if !$0 { reviewMutationError = nil } }
        )) {
            Button("확인", role: .cancel) { reviewMutationError = nil }
        } message: {
            Text(reviewMutationError ?? "")
        }
        .task {
            await loadReviewIdentity()
            await loadServerDetail()
            await loadNearbyMissions()
            await loadReviews()
        }
        .overlay(alignment: .top) {
            if let toastMessage {
                KIRIToast(message: toastMessage)
                    .padding(.horizontal, 18)
                    .safeAreaPadding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private func loadReviewIdentity() async {
        do {
            let info = try await AuthService.shared.myInfo()
            currentUserNickname = info.nickname
            currentUserRole = info.familyRole ?? ""
            if let familyIdResult = try? await AuthService.shared.familyIdForCurrentMember() {
                familyMembers = (try? await AuthService.shared.familyInfo(familyId: familyIdResult.familyId).members) ?? []
            }
        } catch {
            // 리뷰 화면에서는 임의의 작성자 정보를 표시하지 않습니다.
        }
    }

    private func loadServerDetail() async {
        guard let scheduleId = schedule.scheduleId, !isLoadingServerDetail else { return }
        isLoadingServerDetail = true
        serverDetailError = nil
        do {
            serverDetail = try await AuthService.shared.scheduleDetail(scheduleId: scheduleId)
#if DEBUG
            if let detail = serverDetail {
                let acceptedCount = detail.participants.filter { $0.status.uppercased() == "ACCEPTED" }.count
                print("[KIRI][Review] eligibility scheduleId=\(scheduleId) status=\(detail.status ?? "nil") myStatus=\(detail.myStatus ?? "nil") acceptedParticipants=\(acceptedCount) date=\(detail.date) time=\(detail.time ?? "nil")")
            }
#endif
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

    private func loadReviews() async {
        guard let scheduleId = schedule.scheduleId, !isLoadingReviews else { return }
        isLoadingReviews = true
        reviewsLoadError = nil
        defer { isLoadingReviews = false }
        do {
            let result = try await AuthService.shared.scheduleReviews(scheduleId: scheduleId)
            representativePhotoId = result.representativePhotoId
            serverReviews = result.reviews
        } catch {
            reviewsLoadError = "가족 추억을 불러오지 못했어요."
        }
    }

    private func deleteReview(_ review: ReviewItemResult) async {
        guard !isDeletingReview, let scheduleId = schedule.scheduleId else { return }
        isDeletingReview = true
        reviewMutationError = nil
        defer { isDeletingReview = false }
        do {
            try await AuthService.shared.deleteReview(scheduleId: scheduleId, reviewId: review.reviewId)
            await loadReviews()
            await MainActor.run { reviewToDelete = nil }
        } catch {
            await MainActor.run { reviewMutationError = "리뷰를 삭제하지 못했어요. 다시 시도해 주세요." }
        }
    }
    private var upcomingContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                navigationBar
                Text(statusBadgeTitle)
                .font(KIRITypography.bodySmall)
                .foregroundStyle(KIRIColor.Text.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(KIRIColor.Background.elevated)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .padding(.top, 21)
                Text(displayTitle)
                    .font(KIRITypography.title)
                    .foregroundStyle(KIRIColor.Text.strong)
                    .padding(.top, 12)
                scheduleContext
                    .padding(.top, 10)
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

    @ViewBuilder
    private var pastContent: some View {
        if isLoadingServerDetail {
            VStack(spacing: 16) {
                navigationBar
                ProgressView("일정 상태를 확인하고 있어요")
                    .frame(maxWidth: .infinity, minHeight: 180)
            }
            .padding(.horizontal, 18)
        } else if let serverDetailError {
            VStack(spacing: 16) {
                navigationBar
                Text(serverDetailError)
                    .font(KIRITypography.bodySmall)
                    .foregroundStyle(KIRIColor.Text.secondary)
                Button("다시 시도") {
                    Task {
                        await loadServerDetail()
                        await loadReviews()
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 220)
            .padding(.horizontal, 18)
        } else if isLoadingReviews {
            VStack(spacing: 16) {
                navigationBar
                ProgressView("리뷰 기록을 확인하고 있어요")
                    .frame(maxWidth: .infinity, minHeight: 180)
            }
            .padding(.horizontal, 18)
        } else if let reviewsLoadError {
            VStack(spacing: 16) {
                navigationBar
                Text(reviewsLoadError)
                    .font(KIRITypography.bodySmall)
                    .foregroundStyle(KIRIColor.Text.secondary)
                Button("다시 시도") { Task { await loadReviews() } }
            }
            .frame(maxWidth: .infinity, minHeight: 220)
            .padding(.horizontal, 18)
        } else if let review = serverReviews.first(where: { $0.isMine }) {
            ReviewDetailView(
                review: reviewDetailData(review),
                localDraft: nil,
                onBack: onBack,
                onEdit: { showingReviewEditor = true },
                onDelete: { reviewToDelete = review }
            )
        } else if canWriteReview {
            VStack(alignment: .leading, spacing: 18) {
                navigationBar
                Text("지난 약속이에요")
                    .font(KIRITypography.title)
                    .foregroundStyle(KIRIColor.Text.strong)
                Text("아직 내 리뷰가 없어요. 활동을 기록해 보세요.")
                    .font(KIRITypography.bodySmall)
                    .foregroundStyle(KIRIColor.Text.secondary)
                Button {
                    showingReviewEditor = true
                } label: {
                    Text("리뷰 작성하기")
                        .font(KIRITypography.bodyMedium)
                        .foregroundStyle(KIRIColor.Text.strong)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(KIRIColor.Primary.default)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
        } else {
            VStack(alignment: .leading, spacing: 18) {
                navigationBar
                Text("지난 약속이에요")
                    .font(KIRITypography.title)
                    .foregroundStyle(KIRIColor.Text.strong)
                Text(reviewEligibilityMessage)
                    .font(KIRITypography.bodySmall)
                    .foregroundStyle(KIRIColor.Text.secondary)
                Button("일정 상태 다시 확인") {
                    Task {
                        await loadServerDetail()
                        await loadReviews()
                    }
                }
                .font(KIRITypography.bodySmallMedium)
                .foregroundStyle(KIRIColor.Text.strong)
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
        }
    }

    private func reviewDetailData(_ review: ReviewItemResult) -> RecordCalendarView.ReviewDetailData {
        RecordCalendarView.ReviewDetailData(
            title: schedule.title,
            date: effectiveDate,
            familyName: "가족",
            authorName: reviewWriterName(review),
            isCurrentUser: review.isMine,
            review: review.content,
            writtenDate: review.createdAt,
            representativePhotoURL: review.photos.first?.imageUrl
        )
    }

    private func reviewWriterName(_ review: ReviewItemResult) -> String {
        let nickname = review.writer.nickname?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !nickname.isEmpty { return nickname }
        return familyMembers.first(where: { $0.memberId == review.writer.memberId })?.nickname ?? "가족 구성원"
    }
    private var navigationBar: some View {
        ZStack {
            HStack(spacing: 6) {
                Text(effectiveDate.replacingOccurrences(of: "-", with: "."))
                    .font(KIRITypography.bodySmallMedium)
                    .foregroundStyle(KIRIColor.Text.tertiary)
                changedBadge("DATE")
            }
            HStack {
                KIRIBackButton(action: onBack)
                Spacer()
            }
        }
        .frame(height: 62)
    }
    private var activityDetail: some View {
        VStack(alignment: .leading, spacing: 9) {
            detailRow("시작 시간", effectiveStartTime, changedField: "TIME")
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

    private var scheduleContext: some View {
        VStack(alignment: .leading, spacing: 7) {
            if let description = displayDescription {
                Text(description)
                    .font(KIRITypography.bodySmall)
                    .foregroundStyle(KIRIColor.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let message = serverDetail?.requestMessage?.trimmingCharacters(in: .whitespacesAndNewlines), !message.isEmpty {
                Text("\"\(message)\"")
                    .font(KIRITypography.bodySmall)
                    .foregroundStyle(KIRIColor.Text.secondary)
            }
            if let proposer = serverDetail?.proposer?.nickname?.trimmingCharacters(in: .whitespacesAndNewlines), !proposer.isEmpty {
                Text("\(proposer)님이 제안했어요")
                    .font(KIRITypography.bodySmall)
                    .foregroundStyle(KIRIColor.Text.tertiary)
            }
        }
    }

    private var statusBadgeTitle: String {
        if serverDetail?.myStatus == "PENDING", serverDetail?.canRespond == true { return "일정 요청" }
        if serverDetail?.myStatus == "RECONFIRM_REQUIRED" { return "일정 재확인" }
        return effectiveStatus == "CONFIRMED" ? "약속 확정" : "약속 예정"
    }

    private func participantSummary(_ participants: [ScheduleParticipantResult]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("참여 가족")
                .font(KIRITypography.bodySmallMedium)
                .foregroundStyle(KIRIColor.Text.strong)
            changedBadge("PARTICIPANTS")
            ForEach(Array(participants.enumerated()), id: \.offset) { _, participant in
                HStack {
                    if let url = participant.characterImageUrl {
                        AsyncImage(url: url) { phase in
                            if case .success(let image) = phase {
                                image.resizable().scaledToFill()
                            } else {
                                Image("figma_family_member_default").resizable().scaledToFit()
                            }
                        }
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                    } else {
                        Image("figma_family_member_default")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                    }
                    Text(participant.nickname)
                    Spacer()
                    Text(participant.status == "ACCEPTED" ? "참여" : participant.status == "DECLINED" ? "거절" : "응답 대기")
                        .foregroundStyle(participant.status == "ACCEPTED" ? KIRIColor.Primary.default : KIRIColor.Text.secondary)
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
        _ value: String,
        changedField: String? = nil
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(label)
                .foregroundStyle(KIRIColor.Text.secondary)
            Text("|")
                .foregroundStyle(KIRIColor.Text.tertiary)
            Text(value)
                .foregroundStyle(KIRIColor.Text.primary)
            if let changedField { changedBadge(changedField) }
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
                if isReconfirmationRequired && serverDetail?.canRespond == true {
                    Text("일정이 변경되었어요. 다시 확인해 주세요.")
                        .font(KIRITypography.bodySmallMedium)
                        .foregroundStyle(KIRIColor.Text.strong)
                }

                if serverDetail?.canEdit == true {
                Button("일정 수정") { showingEditSheet = true }
                    .buttonStyle(scheduleActionStyle(isPrimary: false))
                    .disabled(isMutatingSchedule || schedule.scheduleId == nil)
                }

                if serverDetail?.canRespond == true {
                    HStack(spacing: 8) {
                    Button(serverDetail?.myStatus == "RECONFIRM_REQUIRED" ? "취소" : "거절") {
                        Task { await respond(action: "DECLINED") }
                    }
                    .buttonStyle(scheduleActionStyle(isPrimary: false))
                    .disabled(isMutatingSchedule)

                    Button(serverDetail?.myStatus == "RECONFIRM_REQUIRED" ? "약속 확정하기" : "수락") {
                        Task { await respond(action: "ACCEPTED") }
                    }
                    .buttonStyle(scheduleActionStyle(isPrimary: true))
                    .disabled(isMutatingSchedule)
                    }
                }

                if serverDetail?.canCancel == true {
                    Button("약속 취소", role: .destructive) {
                        showingCancelConfirmation = true
                    }
                    .font(KIRITypography.bodySmallMedium)
                    .foregroundStyle(KIRIColor.Text.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .disabled(isMutatingSchedule)
                }
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
        guard serverDetail?.canRespond == true else { return }
        isMutatingSchedule = true
        scheduleMutationError = nil
        defer { isMutatingSchedule = false }
        do {
            _ = try await AuthService.shared.respondToSchedule(scheduleId: scheduleId, action: action)
            await loadServerDetail()
            await loadNearbyMissions()
            onScheduleChanged?()
            showToast(action == "ACCEPTED" ? "일정 참여를 수락했어요." : "일정 참여를 거절했어요.")
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
            await loadNearbyMissions()
            onScheduleChanged?()
            showToast("약속을 취소했어요.")
        } catch {
            scheduleMutationError = "약속을 취소하지 못했어요. 다시 시도해 주세요."
        }
    }
    private func showToast(_ message: String) {
        toastGeneration += 1
        let generation = toastGeneration
        toastMessage = message
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.2))
            guard generation == toastGeneration else { return }
            withAnimation(.easeOut(duration: 0.2)) { toastMessage = nil }
        }
    }
    private var selectedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(selectedTab == .aiActivity ? "근처 놀거리 추천" : "가족 추억")
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
                if isLoadingReviews {
                    ProgressView().frame(maxWidth: .infinity, minHeight: 110)
                } else if let reviewsLoadError {
                    VStack(spacing: 8) {
                        Text(reviewsLoadError).font(KIRITypography.bodySmall).foregroundStyle(KIRIColor.Text.secondary)
                        Button("다시 시도") { Task { await loadReviews() } }
                    }.frame(maxWidth: .infinity, minHeight: 110)
                } else if serverReviews.isEmpty {
                    Text("아직 등록된 가족 추억이 없어요.")
                        .font(KIRITypography.bodySmall)
                        .foregroundStyle(KIRIColor.Text.secondary)
                        .frame(maxWidth: .infinity, minHeight: 110)
                        .background(KIRIColor.Background.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(serverReviews) { review in
                            serverReviewCard(review)
                        }
                    }
                }
            }
        }
    }

    private func serverReviewCard(_ review: ReviewItemResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(reviewWriterName(review)).font(KIRITypography.bodySmallMedium).foregroundStyle(KIRIColor.Text.strong)
                Spacer()
                Text("★ \(review.starRating)").font(KIRITypography.captionMedium).foregroundStyle(KIRIColor.Text.accent)
                if review.isMine {
                    Menu {
                        Button("수정하기") { showingReviewEditor = true }
                        Button("삭제하기", role: .destructive) { reviewToDelete = review }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(KIRIColor.Icon.secondary)
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                    .disabled(isDeletingReview)
                }
            }
            Text(review.content).font(KIRITypography.bodySmall).foregroundStyle(KIRIColor.Text.primary)
            if !review.photos.isEmpty {
                HStack(spacing: 8) {
                    ForEach(review.photos) { photo in
                        AsyncImage(url: photo.imageUrl) { phase in
                            phase.image?
                                .resizable()
                                .scaledToFill()
                        }
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay {
                            if representativePhotoId == photo.reviewPhotoId {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(KIRIColor.Primary.default, lineWidth: 2)
                            }
                        }
                    }
                    Spacer(minLength: 0)
                    if schedule.scheduleId != nil {
                        Button("대표사진 선택") { showingRepresentativePicker = true }
                            .font(KIRITypography.captionMedium)
                            .foregroundStyle(KIRIColor.Text.accent)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KIRIColor.Background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func nearbyCard(_ item: NearbyMissionResult) -> some View {
        let card = VStack(alignment: .leading, spacing: 0) {
            KIRIContentImage(imageURL: item.imageUrl, mockAssetName: nil) {
                KIRIColor.Background.tertiary
            }
            .frame(width: 251, height: 144)
            .clipped()
            VStack(alignment: .leading, spacing: 3) {
                Text(item.placeName).font(KIRITypography.bodySmallMedium).foregroundStyle(KIRIColor.Text.strong).lineLimit(2)
                Text(item.region).font(KIRITypography.bodySmall).foregroundStyle(KIRIColor.Text.secondary).lineLimit(1)
                if let distance = item.distance {
                    Text(Self.distanceLabel(distance)).font(KIRITypography.caption).foregroundStyle(KIRIColor.Text.tertiary)
                }
                Text(item.description).font(KIRITypography.caption).foregroundStyle(KIRIColor.Text.tertiary).lineLimit(3)
            }
            .padding(.horizontal, 19)
            .padding(.top, 18)
        }
        .frame(width: 251, height: 284, alignment: .topLeading)
        .background(KIRIColor.Background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))

        if item.missionId != nil, let onMissionSelected {
            Button { onMissionSelected(item) } label: { card }
                .buttonStyle(.plain)
        } else {
            card
        }
    }

    private static func distanceLabel(_ value: Double) -> String {
        value >= 100 ? String(format: "%.1fkm", value / 1000) : String(format: "%.1fkm", value)
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

private struct RepresentativePhotoPicker: View {
    let reviews: [ReviewItemResult]
    let selectedPhotoId: Int?
    let isSaving: Bool
    let onSelect: (ReviewPhotoResult) -> Void

    private var photos: [ReviewPhotoResult] {
        reviews.flatMap(\.photos)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(photos) { photo in
                        Button { onSelect(photo) } label: {
                            VStack(spacing: 6) {
                                AsyncImage(url: photo.imageUrl) { phase in
                                    phase.image?.resizable().scaledToFill()
                                }
                                .frame(height: 150)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                Text(selectedPhotoId == photo.reviewPhotoId ? "대표사진" : "대표사진으로 설정")
                                    .font(KIRITypography.captionMedium)
                                    .foregroundStyle(selectedPhotoId == photo.reviewPhotoId ? KIRIColor.Text.accent : KIRIColor.Text.primary)
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(isSaving || selectedPhotoId == photo.reviewPhotoId)
                    }
                }
                .padding(18)
            }
            .background(KIRIColor.Background.base)
            .navigationTitle("대표사진 선택")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
