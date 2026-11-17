//
// MARK: - 파일 가이드
// 파일: Features/Home/FamilyHomeView.swift
// 담당 영역: 기능별 SwiftUI 화면과 상태
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//

import SwiftUI

private struct FamilyMemberFramePreferenceKey: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]

    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

struct FamilyHomeView: View {
    @Environment(\.kiriTabBarVisibility) private var tabBarVisibility
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    // 기존 가족공간 데이터가 준비되면 실제 값을 전달합니다.
    var familyName: String?
    var familyId: Int? = nil
    var familyInviteCode: String? = nil
    var nickname: String? = nil
    var familyRole: String? = nil
    var tutorialStep: Int? = nil
    var loadsServerQuestion: Bool = true
    var onExploreMission: () -> Void = {}
    var onSelectNotification: (NotificationDestination) -> Void = { _ in }

    @State private var isInvitePresented = false
    @State private var isInviteUnavailableAlertPresented = false
    @State private var selectedMission: MissionFeedItem?
    @State private var selectedRecommendation: FamilyRecommendationResult?
    @State private var selectedMember: HomeMember?
    @State private var isPlaceBookmarked = false
    @State private var isFamilyMissionSchedulePresented = false
    @State private var showsMissionFace = false
    @State private var didLoadTodayQuestion = false
    @State private var isLoadingTodayQuestion = false
    @State private var todayQuestionError: String?
    @State private var todayQuestionUnavailable = false
    @State private var questionLoadedDay: Date?
    @State private var serverQuestion: TodayQuestionResult?
    @State private var familyAnswers: [FamilyAnswer] = []
    @State private var familyMembers: [FamilyMemberInfoResult] = []
    @State private var familyMembersError: String?
    @State private var isLoadingFamilyMembers = false
    // 답변 목록 응답의 질문을 함께 보존해 선택한 구성원의 상태와 같은 질문을 표시합니다.
    @State private var familyAnswersQuestion: String?
    @State private var isLoadingFamilyAnswers = false
    @State private var familyAnswersError: String?
    @State private var memberFrames: [Int: CGRect] = [:]
    // 콕 찌르기 성공 상태는 말풍선을 닫았다 다시 열어도 유지해야 합니다.
    // 서버 응답이 성공 또는 중복 전송으로 확인된 memberId만 저장합니다.
    @State private var pokedMemberIDs: Set<Int> = []
    @State private var pokeToastMessage: String?
    @State private var pokeToastIsError = false
    @State private var recommendedMissions: [MissionFeedItem] = []
    @State private var isLoadingRecommendations = false
    @State private var missionFeedError: String?
    @State private var notificationMission: MissionDetailResult?
    @State private var notificationScheduleDetail: ScheduleDetailResult?
    @State private var notificationScheduleID: Int?
    @State private var isRespondingToNotification = false
    @State private var unreadNotificationCount = 0
    @State private var todayScheduleDetail: ScheduleDetailResult?
    @State private var todayScheduleData: RecordCalendarView.ScheduleDetailData?
    @State private var todayNearbyMissions: [NearbyMissionResult] = []
    @State private var todayMissionDetail: MissionDetailResult?
    @State private var todayReviews: [ReviewItemResult] = []


    private enum HomeRoute {
        case home
        case notification
        case notificationMission
        case notificationInvitation
        case todayActivity
        case placeDetail
        case taste
        case questionAnswer
        case missionDetail
        case memberDetail
    }

    @State private var route: HomeRoute = .home

    var body: some View {
        ZStack {
            KIRIColor.Background.base
                .ignoresSafeArea()

            switch route {
            case .home:
                homeContent

            case .notification:
                NotificationView(
                    onBack: {
                        route = .home
                    },
                    onSelect: { destination in
                        switch destination {
                        case .mission(let missionId):
                            Task { await openNotificationMission(missionId) }
                        case .question(let questionId):
                            Task { await openNotificationQuestion(questionId) }
                        case .schedule(let scheduleId):
                            Task { await openNotificationSchedule(scheduleId) }
                        case .unavailable:
                            showPokeToast("이 알림의 화면을 열 수 없어요.", isError: true)
                        }
                    }
                )

            case .notificationMission:
                if let notificationMission {
                    MissionActivityDetailView(
                        missionId: notificationMission.missionId,
                        title: notificationMission.title,
                        placeName: notificationMission.place?.name ?? "",
                        district: notificationMission.district,
                        rating: notificationMission.averageRating,
                        tags: notificationMission.tags,
                        isRecommended: false,
                        mockAssetName: nil,
                        imageURL: notificationMission.imageUrl,
                        isBookmarked: .constant(notificationMission.bucketSaved),
                        onBack: { route = .notification }
                    )
                }

            case .notificationInvitation:
                if let detail = notificationScheduleDetail {
                    InvitationRequestView(
                        request: invitationRequestData(from: detail),
                        onBack: { route = .notification },
                        onCancel: { respondToNotificationSchedule(detail, action: .decline) },
                        onConfirmSchedule: { respondToNotificationSchedule(detail, action: .accept) },
                        onMissionDetail: detail.missionId.map { missionID in
                            { Task { await openNotificationMission(missionID) } }
                        },
                        respondsDirectly: true,
                        isScheduleChange: detail.myStatus?.uppercased() == "RECONFIRM_REQUIRED"
                    )
                }

            case .todayActivity:
                if let detail = todayScheduleDetail, let schedule = todayScheduleData {
                    TodayActivityView(
                        schedule: schedule,
                        content: todayActivityContent(detail),
                        onBack: { route = .home },
                        missionTitle: detail.missionTitle,
                        missionDescription: detail.missionDescription,
                        requestMessage: detail.requestMessage,
                        onReviewSaved: { _ in
                            // 당일 상세에서 서버 저장이 끝난 뒤 홈의 일정·기억 데이터를
                            // 다시 읽어 캘린더/추억 진입 시에도 서버 상태를 사용합니다.
                            Task { await loadTodayAppointment() }
                        }
                    )
                }


            case .placeDetail:
                if let selectedMission {
                    MissionActivityDetailView(
                        missionId: selectedMission.missionId,
                        title: selectedMission.title,
                        placeName: selectedMission.placeName,
                        district: MissionDisplayLabel.category(selectedMission.category) ?? "",
                        rating: nil,
                        tags: selectedMission.displayTags,
                        isRecommended: true,
                        mockAssetName: nil,
                        imageURL: selectedMission.imageUrl,
                        isBookmarked: $isPlaceBookmarked,
                        onBack: { route = .home }
                    )
                } else if let selectedRecommendation {
                    MissionActivityDetailView(
                        missionId: selectedRecommendation.missionId,
                        title: selectedRecommendation.title,
                        placeName: "",
                        district: MissionDisplayLabel.category(selectedRecommendation.category) ?? "",
                        rating: selectedRecommendation.score,
                        tags: [MissionDisplayLabel.category(selectedRecommendation.category)].compactMap { $0 },
                        isRecommended: true,
                        mockAssetName: nil,
                        imageURL: selectedRecommendation.imageUrl,
                        isBookmarked: $isPlaceBookmarked,
                        onBack: { route = .home }
                    )
                }

            case .taste:
                TasteTestView()

            case .questionAnswer:
                HomeQuestionAnswerView(
                    question: serverQuestion?.question ?? "오늘의 질문",
                    existingAnswer: serverQuestion?.answer,
                    familyMembers: displayedMembers,
                    currentMemberId: currentAuthenticatedMemberId,
                    familyMembersError: familyAnswersError,
                    onRetryFamilyMembers: {
                        if let questionId = serverQuestion?.questionId {
                            Task { await loadFamilyAnswers(questionId: questionId) }
                        }
                    },
                    onBack: { route = .home }
                ) { selectedMemberId, savedAnswer in
                    guard let questionId = serverQuestion?.questionId,
                          let authenticatedMemberId = currentAuthenticatedMemberId,
                          selectedMemberId == authenticatedMemberId else {
                        #if DEBUG
                        print("[KIRI][Question] save blocked: selected member is not authenticated member")
                        #endif
                        return false
                    }
                    #if DEBUG
                    print("[KIRI][Question] save start questionId=\(questionId) answerLength=\(savedAnswer.count)")
                    #endif
                    do {
                        try await AuthService.shared.writeAnswer(questionId: questionId, answer: savedAnswer)
                        #if DEBUG
                        print("[KIRI][Question] save success questionId=\(questionId)")
                        #endif
                        await loadTodayQuestion()
                        return true
                    } catch {
                        await MainActor.run { todayQuestionError = error.localizedDescription }
                        return false
                    }
                }

            case .missionDetail:
                if let mission = tutorialMission {
                    MissionActivityDetailView(
                        missionId: mission.missionId,
                        title: mission.title,
                        placeName: mission.placeName,
                        district: MissionDisplayLabel.category(mission.category) ?? "",
                        rating: nil,
                        tags: mission.displayTags,
                        isRecommended: false,
                        imageURL: mission.imageUrl,
                        isBookmarked: $isPlaceBookmarked,
                        onSchedule: { isFamilyMissionSchedulePresented = true },
                        onBack: { route = .home }
                    )
                }

            case .memberDetail:
                ZStack {
                    homeContent.allowsHitTesting(false)
                    Color.black.opacity(0.56)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture { route = .home }
                    if let selectedMember {
                        HomeMemberQuestionView(
                            member: selectedMember,
                            question: familyAnswersQuestion ?? serverQuestion?.question ?? "오늘의 질문",
                            anchorFrame: selectedMember.memberId.flatMap { memberFrames[$0] },
                            initiallyPoked: selectedMember.memberId.map { pokedMemberIDs.contains($0) } ?? false,
                            onBack: { route = .home },
                            onPoke: { memberId in
                                do {
                                    try await AuthService.shared.pokeMember(
                                        memberId: memberId,
                                        familyId: familyId,
                                        nickname: selectedMember.name
                                    )
                                    if let questionId = serverQuestion?.questionId {
                                        await loadFamilyAnswers(questionId: questionId)
                                    }
                                    await MainActor.run {
                                        pokedMemberIDs.insert(memberId)
                                        showPokeToast("\(selectedMember.name)님을 콕 찔렀어요!", isError: false)
                                        // 전송이 끝난 뒤에는 질문 모아보기 경로를 남기지
                                        // 않고 가족 홈으로 돌아갑니다. 토스트는 루트 오버레이에서
                                        // 계속 표시됩니다.
                                        route = .home
                                    }
                                    return true
                                } catch let error as APIError {
                                    #if DEBUG
                                    if case let .serverError(code, _) = error {
                                        print("[KIRI][Home] poke failed code=\(code)")
                                    }
                                    #endif
                                    if isAlreadyPokeError(error) {
                                        await MainActor.run {
                                            pokedMemberIDs.insert(memberId)
                                            showPokeToast("이미 \(selectedMember.name)님을 콕 찔렀어요!", isError: false)
                                            route = .home
                                        }
                                        return true
                                    }
                                    await MainActor.run {
                                        showPokeToast(pokeFailureMessage(for: error), isError: true)
                                    }
                                    return false
                                } catch {
                                    await MainActor.run {
                                        showPokeToast("콕 찌르기에 실패했어요. 다시 시도해 주세요.", isError: true)
                                    }
                                    return false
                                }
                            },
                            onAlreadyPoked: {
                                showPokeToast("이미 \(selectedMember.name)님을 콕 찔렀어요!", isError: false)
                                route = .home
                            }
                        )
                        .zIndex(1)
                    }
                }
            }

            // 답변/콕 화면을 닫거나 전송을 완료해 홈으로 돌아와도
            // 결과 토스트가 최상위 safe area에서 보이도록 합니다.
            if let pokeToastMessage {
                KIRIToast(message: pokeToastMessage, isError: pokeToastIsError)
                    .padding(.horizontal, 18)
                    .safeAreaPadding(.top, 8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(20)
            }
        }
        .fullScreenCover(isPresented: $isInvitePresented) {
            if let code = familyInviteCode, !code.isEmpty {
                FamilyCodeView(
                    familyName: familyName ?? "가족공간",
                    familyCode: code,
                    onBack: { isInvitePresented = false },
                    onComplete: { isInvitePresented = false }
                )
                .preferredColorScheme(.dark)
            }
        }
        .fullScreenCover(isPresented: $isFamilyMissionSchedulePresented) {
            if let mission = tutorialMission {
                ScheduleCreationSheet(
                    missionId: mission.missionId,
                    missionTitle: mission.title,
                    onCreated: {
                        isFamilyMissionSchedulePresented = false
                        route = .home
                    }
                )
            }
        }
        .alert("초대코드를 불러올 수 없어요", isPresented: $isInviteUnavailableAlertPresented) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("가족공간의 초대코드가 연결되지 않았습니다.")
        }
        .onAppear {
            tabBarVisibility.wrappedValue = route == .home
            if let tutorialStep {
                showsMissionFace = tutorialStep >= 1
            }
        }
        .onChange(of: tutorialStep) { _, newStep in
            if let newStep {
                showsMissionFace = newStep >= 1
            }
        }
        .onChange(of: route) { _, newRoute in
            tabBarVisibility.wrappedValue = newRoute == .home
            if newRoute == .home {
                Task {
                    await refreshUnreadNotifications()
                    await loadTodayAppointment()
                }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task {
                await loadTodayAppointment()
                if loadsServerQuestion {
                    let today = Calendar.current.startOfDay(for: Date())
                    if questionLoadedDay != today { await loadTodayQuestion() }
                }
            }
        }
        .onDisappear {
            tabBarVisibility.wrappedValue = true
        }
        .coordinateSpace(name: "familyHome")
        .onPreferenceChange(FamilyMemberFramePreferenceKey.self) { frames in
            memberFrames = frames
        }
        .task { await loadInitialHomeData() }
    }

    /// 독립적인 홈 섹션은 각 응답이 도착하는 즉시 화면을 갱신합니다.
    private func loadInitialHomeData() async {
        let startedAt = Date()
        async let question: Void = loadsServerQuestion ? loadTodayQuestion() : markQuestionUnavailable()
        async let members: Void = loadFamilyMembers()
        async let recommendations: Void = loadRecommendations()
        async let notifications: Void = refreshUnreadNotifications()
        async let appointment: Void = loadTodayAppointment()
        _ = await (question, members, recommendations, notifications, appointment)
        #if DEBUG
        print("[KIRI][HomePerf] initial complete elapsedMs=\(Int(Date().timeIntervalSince(startedAt) * 1000))")
        #endif
    }

    private func markQuestionUnavailable() async {
        await MainActor.run { didLoadTodayQuestion = true }
    }

    private var todayAppointmentCard: some View {
        Button {
            route = .todayActivity
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    (
                        Text("오늘 ")
                            .foregroundStyle(KIRIColor.Text.strong)
                        + Text("약속 당일")
                            .foregroundStyle(KIRIColor.Text.accent)
                        + Text("이에요!")
                            .foregroundStyle(KIRIColor.Text.strong)
                    )
                    .font(KIRITypography.bodySmallMedium)

                    Text("코스를 확인하세요")
                        .font(KIRITypography.bodySmall)
                        .foregroundStyle(KIRIColor.Text.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(KIRIColor.Text.secondary)
            }
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(KIRIColor.Background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func todayActivityContent(_ detail: ScheduleDetailResult) -> TodayActivityView.Content {
        TodayActivityView.Content(
            isCurrentUserConfirmed: detail.myStatus?.uppercased() == "ACCEPTED",
            participantNames: detail.participants.filter { $0.status.uppercased() == "ACCEPTED" }.map(\.nickname),
            participantStatuses: familyMembers.map { member in
                TodayActivityView.ParticipantStatus(
                    id: member.memberId,
                    nickname: member.nickname,
                    isAccepted: detail.participants.first(where: { $0.memberId == member.memberId })?.status.uppercased() == "ACCEPTED"
                )
            },
            requiredActivities: todayMissionDetail?.steps.map(\.title) ?? [],
            requiredItems: todayMissionDetail?.prepareItems.map {
                TodayActivityView.SuggestedItem(id: $0.id, title: $0.title, reason: $0.description)
            } ?? [],
            nearbyRecommendations: todayNearbyMissions.map { item in
                TodayActivityView.Recommendation(
                    id: item.id,
                    title: item.placeName,
                    location: item.region,
                    description: item.description,
                    distanceMeters: item.distance,
                    isRestPlace: false,
                    price: item.price,
                    crowdLevel: nil,
                    imageURL: item.imageUrl
                )
            },
            reviewMemories: todayReviews.map { review in
                TodayActivityView.ReviewMemory(
                    id: review.reviewId,
                    authorName: review.writer.nickname
                        ?? familyMembers.first(where: { $0.memberId == review.writer.memberId })?.nickname
                        ?? (review.isMine ? (nickname ?? "나") : "가족 구성원"),
                    familyRole: review.writer.familyRole
                        ?? familyMembers.first(where: { $0.memberId == review.writer.memberId })?.familyRole,
                    content: review.content,
                    imageURL: review.photos.first?.imageUrl,
                    isMine: review.isMine
                )
            },
            currentUserNickname: nickname ?? ""
        )
    }

    private func loadTodayAppointment() async {
        do {
            let upcoming = try await AuthService.shared.upcomingSchedules()
            struct TodayCandidate {
                let scheduleId: Int
                let title: String
                let time: String
            }
            var candidate = [upcoming.upcoming, upcoming.responseRequired]
                .compactMap { $0 }
                .first { $0.type.uppercased() == "TODAY" && $0.myStatus.uppercased() == "ACCEPTED" }
                .map { TodayCandidate(scheduleId: $0.scheduleId, title: $0.title, time: $0.time) }
            // 리뷰가 저장된 당일 일정은 upcoming 응답에서 빠질 수 있습니다.
            // 캘린더의 현재 월 일정은 완료된 오늘 일정도 포함하므로 보조 조회로 사용합니다.
            if candidate == nil {
                let now = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                if let year = now.year, let month = now.month, let day = now.day,
                   let calendar = try? await AuthService.shared.calendar(year: year, month: month),
                   let item = calendar.schedules.first(where: {
                       Int($0.date.split(separator: "-").last ?? "") == day &&
                       $0.myStatus.uppercased() == "ACCEPTED"
                   }) {
                    candidate = TodayCandidate(scheduleId: item.scheduleId, title: "오늘의 약속", time: item.time)
                }
            }
            guard let candidate else {
                let isViewingToday = await MainActor.run {
                    route == .todayActivity && todayScheduleDetail != nil
                }
                // 리뷰 저장 직후 완료된 일정이 upcoming 목록에서 빠질 수 있습니다.
                // 당일 상세를 보고 있는 동안에는 목록 갱신이 현재 라우트를 지우지 않습니다.
                if isViewingToday { return }
                await MainActor.run {
                    todayScheduleDetail = nil
                    todayScheduleData = nil
                    todayNearbyMissions = []
                    todayMissionDetail = nil
                    todayReviews = []
                }
                return
            }
            let detail = try await AuthService.shared.scheduleDetail(scheduleId: candidate.scheduleId)
            guard ["TODAY", "SCHEDULED", "CONFIRMED", "COMPLETED"].contains((detail.status ?? "").uppercased()),
                  detail.myStatus?.uppercased() == "ACCEPTED" else {
                let isViewingToday = await MainActor.run {
                    route == .todayActivity && todayScheduleDetail != nil
                }
                if isViewingToday { return }
                await MainActor.run {
                    todayScheduleDetail = nil
                    todayScheduleData = nil
                    todayNearbyMissions = []
                    todayMissionDetail = nil
                    todayReviews = []
                }
                return
            }
            let components = detail.date.split(separator: "-").compactMap { Int($0) }
            let schedule = RecordCalendarView.ScheduleDetailData(
                scheduleId: candidate.scheduleId,
                day: components.last ?? 1,
                month: components.dropLast().last ?? Calendar.current.component(.month, from: Date()),
                status: .confirmedSchedule,
                title: detail.missionTitle ?? candidate.title,
                date: detail.date,
                startTime: detail.time ?? candidate.time,
                location: "",
                expectedSteps: "",
                duration: ""
            )
            await MainActor.run {
                todayScheduleDetail = detail
                todayScheduleData = schedule
                todayNearbyMissions = []
                todayMissionDetail = nil
                todayReviews = []
            }

            // 배너와 당일 상세는 일정 상세 응답만으로 즉시 열고, 부가 데이터는
            // 각 섹션에서 독립적으로 보강합니다.
            let nearby = (try? await AuthService.shared.nearbyMissions(scheduleId: candidate.scheduleId)) ?? []
            let reviews = (try? await AuthService.shared.scheduleReviews(scheduleId: candidate.scheduleId))?.reviews ?? []
            let mission: MissionDetailResult?
            if let missionID = detail.missionId {
                mission = try? await AuthService.shared.missionDetail(missionId: missionID)
            } else {
                mission = nil
            }
            await MainActor.run {
                todayNearbyMissions = nearby
                todayMissionDetail = mission
                todayReviews = reviews
                if let mission {
                    let steps = if let min = mission.estimatedStepsMin {
                        if let max = mission.estimatedStepsMax, max != min { "\(min)~\(max)보" } else { "\(min)보" }
                    } else { "" }
                    let duration = if let min = mission.durationMinMinutes {
                        if let max = mission.durationMaxMinutes, max != min { "\(min)~\(max)분" } else { "\(min)분" }
                    } else { "" }
                    todayScheduleData = RecordCalendarView.ScheduleDetailData(
                        scheduleId: candidate.scheduleId,
                        day: components.last ?? 1,
                        month: components.dropLast().last ?? Calendar.current.component(.month, from: Date()),
                        status: .confirmedSchedule,
                        title: detail.missionTitle ?? candidate.title,
                        date: detail.date,
                        startTime: detail.time ?? candidate.time,
                        location: mission.place?.address ?? "",
                        expectedSteps: steps,
                        duration: duration
                    )
                }
            }
        } catch {
            await MainActor.run {
                todayScheduleDetail = nil
                todayScheduleData = nil
                todayNearbyMissions = []
                todayMissionDetail = nil
                todayReviews = []
            }
        }
    }

    private func showPokeToast(_ message: String, isError: Bool) {
        pokeToastMessage = message
        pokeToastIsError = isError
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.4))
            guard pokeToastMessage == message else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                pokeToastMessage = nil
            }
        }
    }

    private func refreshUnreadNotifications() async {
        guard familyId != nil else { return }
        do {
            let count = try await AuthService.shared.unreadNotificationsCount()
            await MainActor.run { unreadNotificationCount = count }
        } catch {
            // 알림 조회 실패는 홈 전체를 오류 상태로 만들지 않습니다. 서버
            // unread-count 계약이 없는 동안에는 점을 보수적으로 숨깁니다.
            await MainActor.run { unreadNotificationCount = 0 }
        }
    }

    private func isAlreadyPokeError(_ error: APIError) -> Bool {
        guard case let .serverError(code, _) = error else { return false }
        let normalizedCode = code.uppercased()
        return normalizedCode.contains("409")
            || normalizedCode.contains("ALREADY")
            || normalizedCode.contains("DUPLICATE")
    }

    private func pokeFailureMessage(for error: APIError) -> String {
        guard case let .serverError(code, message) = error else {
            return "콕 찌르기에 실패했어요. 다시 시도해 주세요."
        }

        let normalized = "\(code) \(message)".uppercased()
        // QUESTION404_3은 질문 상태나 중복 전송이 아니라 대상 memberId가
        // 존재하지 않거나 현재 가족에 속하지 않을 때 반환됩니다.
        if code.uppercased() == "QUESTION404_3" {
            return "가족 구성원을 확인하지 못해 콕을 보내지 못했어요. 다시 시도해 주세요."
        }
        if normalized.contains("ANSWERED") || normalized.contains("ALREADY_ANSWER") {
            return "이 가족에게는 지금 콕을 보낼 수 없어요."
        }
        return "콕 찌르기에 실패했어요. 다시 시도해 주세요."
    }

    // MARK: - Home

    private var homeContent: some View {
        VStack(spacing: 0) {
            homeNavigationBar

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(
                        alignment: .leading,
                        spacing: 0
                    ) {
                        if todayScheduleDetail != nil {
                            todayAppointmentCard
                                .padding(.horizontal, 18)
                                .padding(.top, 16)
                        }
                        answerCollectionSection
                            .id("tutorial-top")
                            .padding(.top, 23)

                        questionMissionSection
                            .id("tutorial-question-card")
                            .padding(.top, 48)

                        placeRecommendationSection
                            .id("tutorial-recommendation-title")
                            .padding(.top, 48)

                        moodRecommendationSection
                            .padding(.top, 36)

                        Spacer()
                            .frame(height: 120)
                    }
                }
                .onAppear {
                    scrollTutorial(to: tutorialStep, using: proxy, animated: false)
                }
                .onChange(of: tutorialStep) { _, newStep in
                    scrollTutorial(to: newStep, using: proxy, animated: true)
                }
            }
        }
        .background(KIRIColor.Background.base)
    }

    private func scrollTutorial(
        to step: Int?,
        using proxy: ScrollViewProxy,
        animated: Bool
    ) {
        guard let step else {
            proxy.scrollTo("tutorial-top", anchor: .top)
            return
        }

        let targetID: String
        switch step {
        case 0:
            targetID = "tutorial-top"
        case 1:
            targetID = "tutorial-question-card"
        default:
            targetID = "tutorial-recommendation-title"
        }

        if animated && !reduceMotion {
            withAnimation(.easeInOut(duration: 0.25)) {
                proxy.scrollTo(targetID, anchor: .top)
            }
        } else {
            proxy.scrollTo(targetID, anchor: .top)
        }
    }

    // MARK: - Navigation Bar

    private var homeNavigationBar: some View {
        ZStack {
                Text(familyName ?? "가족공간")
                .font(KIRITypography.headingSmall)
                .tracking(-0.72)
                .foregroundStyle(KIRIColor.Text.strong)

            HStack {
                Spacer()

                Button {
                    route = .notification
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image("figma_notification")
                            .resizable()
                            .scaledToFit()
                            .frame(
                                width: 24,
                                height: 24
                            )

                        if unreadNotificationCount > 0 {
                            Circle()
                                .fill(KIRIColor.Primary.default)
                                .frame(width: 6, height: 6)
                                .offset(x: 1, y: -1)
                        }
                    }
                    .frame(
                        width: 52,
                        height: 52
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("알림함")
            }
            .padding(.horizontal, 8)
        }
        .frame(height: 62)
    }

    // MARK: - Answer Collection

    private var answerCollectionSection: some View {
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            HStack {
                Text("답변 모아보기")
                    .font(KIRITypography.headingSmall)
                    .tracking(-0.72)
                    .foregroundStyle(KIRIColor.Text.strong)
                    .homeTutorialMeasured(.answerCollection)

                Spacer()

                Button {
                    if let code = familyInviteCode, !code.isEmpty {
                        isInvitePresented = true
                    } else {
                        isInviteUnavailableAlertPresented = true
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "plus")
                            .font(
                                .system(
                                    size: 12,
                                    weight: .regular
                                )
                            )

                        Text("가족 초대하기")
                            .font(KIRITypography.caption)
                            .tracking(-0.48)
                    }
                    .foregroundStyle(KIRIColor.Text.secondary)
                    .padding(.horizontal, 12)
                    .frame(height: 31)
                    .background(
                        KIRIColor.Background.tertiary
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 8
                        )
                    )
                }
                .buttonStyle(.plain)
                .homeTutorialMeasured(.invite)
            }

            if (isLoadingFamilyMembers || isLoadingFamilyAnswers) && displayedMembers.isEmpty {
                homeSkeletonMemberRow
            } else if let familyMembersError, displayedMembers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("가족 구성원을 불러오지 못했어요")
                        .font(KIRITypography.bodySmall)
                        .foregroundStyle(KIRIColor.Text.tertiary)
                    Button("다시 시도") { Task { await loadFamilyMembers() } }
                        .font(KIRITypography.bodySmallMedium)
                        .foregroundStyle(KIRIColor.Text.accent)
                        .accessibilityHint(familyMembersError)
                }
            } else if let familyAnswersError, displayedMembers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("가족 답변을 불러오지 못했어요")
                        .font(KIRITypography.bodySmall)
                        .foregroundStyle(KIRIColor.Text.tertiary)
                    Button("다시 시도") {
                        guard let questionId = serverQuestion?.questionId else { return }
                        Task { await loadFamilyAnswers(questionId: questionId) }
                    }
                    .font(KIRITypography.bodySmallMedium)
                    .foregroundStyle(KIRIColor.Text.accent)
                    .accessibilityHint(familyAnswersError)
                }
            } else if displayedMembers.isEmpty {
                Text("가족을 초대하면 답변을 함께 볼 수 있어요")
                    .font(KIRITypography.bodySmall)
                    .foregroundStyle(KIRIColor.Text.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                if let familyAnswersError, let questionId = serverQuestion?.questionId {
                    HStack(spacing: 8) {
                        Text("답변 상태를 확인하지 못했어요")
                            .font(KIRITypography.caption)
                            .foregroundStyle(KIRIColor.Text.tertiary)
                        Button("다시 시도") {
                            Task { await loadFamilyAnswers(questionId: questionId) }
                        }
                        .font(KIRITypography.captionMedium)
                        .foregroundStyle(KIRIColor.Text.accent)
                        .accessibilityHint(familyAnswersError)
                    }
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(displayedMembers) { member in
                            Button {
                                guard member.answerStatusKnown else {
                                    showPokeToast("답변 상태를 확인할 수 없어요. 다시 시도해 주세요.", isError: true)
                                    return
                                }
                                selectedMember = member
                                // 서버가 내려주는 isMe는 오래된 응답이나
                                // 다른 질문의 매핑에서 틀릴 수 있으므로, 현재
                                // 세션의 실제 memberId를 화면 전환 기준으로 사용합니다.
                                route = isCurrentMember(member) ? .questionAnswer : .memberDetail
                            } label: {
                                FamilyMemberItem(name: member.name, role: member.role, isMe: member.isMe, hasAnswered: member.hasAnswered, answerStatusKnown: member.answerStatusKnown)
                            }
                            .buttonStyle(.plain)
                            .background(
                                GeometryReader { proxy in
                                    Color.clear.preference(
                                        key: FamilyMemberFramePreferenceKey.self,
                                        value: member.memberId.map { [$0: proxy.frame(in: .global)] } ?? [:]
                                    )
                                }
                            )
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 18)
    }

    // MARK: - Question / Mission Flip Card

    /// HOME-05: 질문과 가족 미션은 별도 카드로 나열하지 않고 하나의 카드 앞뒤로 제공합니다.
    private var questionMissionSection: some View {
        VStack(
            alignment: .leading,
            spacing: 14
        ) {
            HStack {
                Text(showsMissionFace ? "이번주 미션이에요!" : "오늘 나의 질문카드")
                    .font(KIRITypography.headingSmall)
                    .tracking(-0.72)
                    .foregroundStyle(KIRIColor.Text.strong)

                Spacer()

                Text("다른 가족들의 답변을 기다려요!")
                    .font(KIRITypography.caption)
                    .tracking(-0.48)
                    .foregroundStyle(KIRIColor.Text.secondary)
            }

            if !didLoadTodayQuestion {
                homeSkeletonCard
            } else if let serverQuestion, let questionId = serverQuestion.questionId,
                      !(serverQuestion.question ?? "").isEmpty {
                QuestionMissionFlipCard(
                    questionNumber: questionId,
                    question: serverQuestion.question ?? "오늘의 질문",
                    answer: serverQuestion.answer,
                    mission: tutorialMission,
                    showsMission: $showsMissionFace,
                    onQuestionAnswer: { route = .questionAnswer },
                    onMissionDetail: { route = .missionDetail },
                    onMissionExplore: onExploreMission,
                    canAnswer: true
                )
                .homeTutorialMeasured(.questionMissionCard)
            } else if let todayQuestionError {
                VStack(spacing: 8) {
                    unavailableQuestionFlipCard
                    HStack(spacing: 8) {
                        Text(todayQuestionError)
                            .font(KIRITypography.caption)
                            .foregroundStyle(KIRIColor.Text.secondary)
                        Button("다시 시도") { Task { await loadTodayQuestion() } }
                            .font(KIRITypography.captionMedium)
                            .foregroundStyle(KIRIColor.Text.accent)
                    }
                }
            } else if todayQuestionUnavailable {
                unavailableQuestionFlipCard
            }
        }
        .padding(.horizontal, 18)
    }

    private var unavailableQuestionFlipCard: some View {
        QuestionMissionFlipCard(
            questionNumber: 0,
            question: "오늘 배정된 질문이 없어요",
            answer: nil,
            mission: tutorialMission,
            showsMission: $showsMissionFace,
            onQuestionAnswer: {},
            onMissionDetail: { route = .missionDetail },
            onMissionExplore: onExploreMission,
            canAnswer: false
        )
        .homeTutorialMeasured(.questionMissionCard)
    }

    // MARK: - Place Recommendation

    private var placeRecommendationSection: some View {
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            Text("엄마와 함께라면 여기!")
                .font(KIRITypography.headingSmall)
                .tracking(-0.72)
                .foregroundStyle(KIRIColor.Text.strong)
                .padding(.horizontal, 18)
                .homeTutorialMeasured(.recommendationTitle)

            recommendationCards
        }
    }

    private var displayedMembers: [HomeMember] {
        let currentMemberId = currentAuthenticatedMemberId
        let answersByMemberId = Dictionary(uniqueKeysWithValues: familyAnswers.map { ($0.memberId, $0) })
        if !familyMembers.isEmpty {
            var members = familyMembers.map { member in
                let answer = answersByMemberId[member.memberId]
                let isMe = member.memberId == currentMemberId
                return HomeMember(
                    id: String(member.memberId), memberId: member.memberId,
                    name: member.nickname,
                    role: member.familyRole ?? (isMe ? familyRole : nil),
                    hasAnswered: answer?.isAnswered ?? false,
                    answerStatusKnown: answer != nil,
                    answer: answer?.answer, isMe: isMe
                )
            }
            // 가족 생성 직후에는 구성원 조회 응답이 세션보다 늦게 도착할 수
            // 있습니다. 인증된 본인을 응답에서 놓치더라도 오늘 질문이 있으면
            // 세션의 memberId로 본인 카드를 유지해 답변을 작성할 수 있어야 합니다.
            if let authenticatedMember = authenticatedHomeMember(currentMemberId: currentMemberId),
               !members.contains(where: { $0.memberId == authenticatedMember.memberId }) {
                members.insert(authenticatedMember, at: 0)
            }
            return members
        }
        // 가족 구성원 조회가 완료되기 전에도 답변 응답에 포함된 실제 구성원을
        // 표시하되, 답변 목록이 비어 있는 1인 가족은 인증 세션의 본인을
        // 추가합니다. 이는 임의 구성원이 아니라 현재 로그인한 계정입니다.
        var members = familyAnswers.map { member in
            let isMe = member.memberId == currentMemberId || member.isMe
            return HomeMember(
                id: String(member.memberId), memberId: member.memberId,
                name: member.nickname, role: member.familyRole,
                hasAnswered: member.isAnswered, answerStatusKnown: true,
                answer: member.answer, isMe: isMe
            )
        }
        if let authenticatedMember = authenticatedHomeMember(currentMemberId: currentMemberId),
           !members.contains(where: { $0.memberId == authenticatedMember.memberId }) {
            members.insert(authenticatedMember, at: 0)
        }
        return members
    }

    private func authenticatedHomeMember(currentMemberId: Int?) -> HomeMember? {
        guard let currentMemberId else { return nil }
        let answer = familyAnswers.first(where: { $0.memberId == currentMemberId || $0.isMe })
        return HomeMember(
            id: String(currentMemberId),
            memberId: currentMemberId,
            name: nickname ?? "나",
            role: familyRole,
            hasAnswered: answer?.isAnswered ?? serverQuestion?.isAnswered ?? false,
            answerStatusKnown: answer != nil || serverQuestion != nil,
            answer: answer?.answer ?? serverQuestion?.answer,
            isMe: true
        )
    }

    private var currentAuthenticatedMemberId: Int? {
        if let memberId = try? AuthService.shared.currentMemberId() {
            return memberId
        }
        if let memberId = AppSessionStore().memberId {
            return memberId
        }
        return familyAnswers.first(where: { $0.isMe })?.memberId
    }

    private func isCurrentMember(_ member: HomeMember) -> Bool {
        guard let memberId = member.memberId,
              let currentMemberId = try? AuthService.shared.currentMemberId() else {
            return false
        }
        return memberId == currentMemberId
    }

    private var tutorialMission: MissionFeedItem? {
        recommendedMissions.first
    }

    // MARK: - Mood Recommendation

    private var moodRecommendationSection: some View {
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            Text("오늘 가을분위기를 느끼고 싶다면")
                .font(KIRITypography.headingSmall)
                .tracking(-0.72)
                .foregroundStyle(KIRIColor.Text.strong)
                .padding(.horizontal, 18)

            if let missionFeedError {
                VStack(spacing: 8) {
                    Text("가을 미션을 불러오지 못했어요")
                        .font(KIRITypography.bodySmall)
                        .foregroundStyle(KIRIColor.Text.tertiary)
                    Button("다시 시도") { Task { await loadRecommendations() } }
                        .font(KIRITypography.bodySmallMedium)
                        .foregroundStyle(KIRIColor.Text.accent)
                        .accessibilityHint(missionFeedError)
                }
                .frame(maxWidth: .infinity, minHeight: 144, alignment: .center)
            } else if outdoorMissions.isEmpty {
                Text("가을 미션이 아직 없어요")
                    .font(KIRITypography.bodySmall)
                    .foregroundStyle(KIRIColor.Text.tertiary)
                    .frame(maxWidth: .infinity, minHeight: 144, alignment: .center)
            } else {
                missionCards(outdoorMissions)
            }
        }
    }

    @ViewBuilder
    private var recommendationCards: some View {
        if isLoadingRecommendations {
            homeSkeletonCard
        } else if missionFeedError != nil {
            VStack(spacing: 8) {
                Text("미션을 불러오지 못했어요")
                    .font(KIRITypography.bodySmall)
                    .foregroundStyle(KIRIColor.Text.tertiary)
                Button("다시 시도") { Task { await loadRecommendations() } }
                    .font(KIRITypography.bodySmallMedium)
                    .foregroundStyle(KIRIColor.Text.accent)
            }
            .frame(maxWidth: .infinity, minHeight: 144, alignment: .center)
        } else if recommendedMissions.isEmpty {
            Text("추천 미션이 아직 없어요")
                .font(KIRITypography.bodySmall)
                .foregroundStyle(KIRIColor.Text.tertiary)
                .frame(maxWidth: .infinity, minHeight: 144, alignment: .center)
        } else {
            missionCards(allPublicMissions)
        }
    }

    private var homeSkeletonCard: some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(KIRIColor.Background.secondary)
            .frame(maxWidth: .infinity, minHeight: 136)
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 12) {
                    RoundedRectangle(cornerRadius: 4).fill(KIRIColor.Background.tertiary).frame(width: 92, height: 14)
                    RoundedRectangle(cornerRadius: 4).fill(KIRIColor.Background.tertiary).frame(width: 210, height: 18)
                    RoundedRectangle(cornerRadius: 4).fill(KIRIColor.Background.tertiary).frame(width: 150, height: 14)
                }
                .padding(20)
            }
            .accessibilityLabel("홈 콘텐츠를 불러오는 중")
    }

    private var homeSkeletonMemberRow: some View {
        HStack(spacing: 12) {
            ForEach(0..<4, id: \.self) { _ in
                VStack(spacing: 8) {
                    Circle().fill(KIRIColor.Background.secondary).frame(width: 58, height: 58)
                    RoundedRectangle(cornerRadius: 4).fill(KIRIColor.Background.tertiary).frame(width: 44, height: 12)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityLabel("가족 구성원을 불러오는 중")
    }

    private var allPublicMissions: [MissionFeedItem] {
        recommendedMissions
    }

    private var outdoorMissions: [MissionFeedItem] {
        // 계절 키워드가 아니라 서버의 미션 카테고리만 신뢰합니다.
        recommendedMissions.filter { $0.category.caseInsensitiveCompare("OUTDOOR") == .orderedSame }
    }

    @ViewBuilder
    private func missionCards(_ missions: [MissionFeedItem]) -> some View {
        if missions.isEmpty {
            EmptyView()
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(missions) { mission in
                        Button {
                            selectedMission = mission
                            selectedRecommendation = nil
                            isPlaceBookmarked = false
                            route = .placeDetail
                        } label: {
                            PlaceCard(title: mission.title, location: mission.placeName, rating: nil, description: nil, imageURL: mission.imageUrl)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
            }
        }
    }

    // MARK: - Actions


    private func loadTodayQuestion() async {
        guard !isLoadingTodayQuestion else { return }
        isLoadingTodayQuestion = true
        defer { isLoadingTodayQuestion = false }
        let startedAt = Date()
        #if DEBUG
        print("[KIRI][Question] request started")
        #endif
        do {
            let result = try await AuthService.shared.todayQuestion()
            await MainActor.run {
                serverQuestion = result
                todayQuestionUnavailable = !result.hasFamily || result.questionId == nil || (result.question ?? "").isEmpty
                questionLoadedDay = Calendar.current.startOfDay(for: Date())
                familyAnswers = []
                familyAnswersQuestion = nil
                familyAnswersError = nil
                didLoadTodayQuestion = true
                todayQuestionError = nil
            }
            #if DEBUG
            print("[KIRI][Question] response elapsedMs=\(Int(Date().timeIntervalSince(startedAt) * 1000)) hasFamily=\(result.hasFamily) questionIdPresent=\(result.questionId != nil) questionPresent=\(result.question?.isEmpty == false) isAnswered=\(result.isAnswered)")
            #endif
            if let questionId = result.questionId {
                await loadFamilyAnswers(questionId: questionId)
            }
        } catch let APIError.serverError(code, _) where code == "QUESTION404_1" {
            // A family can temporarily have no question assigned. Keep the
            // family home visible and render its empty state instead of an
            // API error or a fake question.
            await MainActor.run {
                // Keep a question already received today visible through a
                // transient refresh failure. Only the initial 404 is an
                // authoritative unassigned state.
                let isSameDay = questionLoadedDay == Calendar.current.startOfDay(for: Date())
                if serverQuestion == nil || !isSameDay {
                    serverQuestion = nil
                    todayQuestionUnavailable = true
                    familyAnswers = []
                    familyAnswersQuestion = nil
                    familyAnswersError = nil
                    todayQuestionError = nil
                }
                didLoadTodayQuestion = true
            }
            #if DEBUG
            print("[KIRI][Question] no question assigned elapsedMs=\(Int(Date().timeIntervalSince(startedAt) * 1000))")
            #endif
        } catch {
            await MainActor.run {
                let isSameDay = questionLoadedDay == Calendar.current.startOfDay(for: Date())
                if serverQuestion == nil || !isSameDay {
                    serverQuestion = nil
                    todayQuestionUnavailable = false
                    todayQuestionError = "오늘의 질문을 불러오지 못했어요"
                }
                didLoadTodayQuestion = true
            }
            #if DEBUG
            print("[KIRI][Question] load failed elapsedMs=\(Int(Date().timeIntervalSince(startedAt) * 1000)) error=\(error.localizedDescription)")
            #endif
        }
    }

    private func loadFamilyAnswers(questionId: Int) async {
        await MainActor.run {
            isLoadingFamilyAnswers = true
            familyAnswersError = nil
        }
        do {
            let result = try await AuthService.shared.familyAnswers(questionId: questionId)
            await MainActor.run {
                familyAnswers = result.answers
                familyAnswersQuestion = result.question
                isLoadingFamilyAnswers = false
            }
        } catch {
            await MainActor.run {
                // 구성원 목록은 유지하고 답변 상태를 미확인으로 둡니다.
                // 이전 질문의 답변을 남겨 미답변으로 오인하지 않도록 비웁니다.
                familyAnswers = []
                familyAnswersQuestion = nil
                familyAnswersError = error.localizedDescription
                isLoadingFamilyAnswers = false
            }
            #if DEBUG
            print("[KIRI][Question] family answers load failed: \(error.localizedDescription)")
            #endif
        }
    }

    private func loadFamilyMembers() async {
        guard let familyId else { return }
        guard !isLoadingFamilyMembers else { return }
        let startedAt = Date()
        await MainActor.run {
            isLoadingFamilyMembers = true
            familyMembersError = nil
        }
        do {
            let result = try await AuthService.shared.familyInfo(familyId: familyId)
            await MainActor.run {
                familyMembers = result.members
                isLoadingFamilyMembers = false
            }
            #if DEBUG
            print("[KIRI][HomePerf] family members elapsedMs=\(Int(Date().timeIntervalSince(startedAt) * 1000)) count=\(result.members.count)")
            #endif
        } catch {
            await MainActor.run {
                familyMembersError = error.localizedDescription
                isLoadingFamilyMembers = false
            }
            #if DEBUG
            print("[KIRI][HomePerf] family members failed elapsedMs=\(Int(Date().timeIntervalSince(startedAt) * 1000))")
            #endif
        }
    }

    private func openNotificationMission(_ missionId: Int) async {
        do {
            let result = try await AuthService.shared.missionDetail(missionId: missionId)
            await MainActor.run {
                notificationMission = result
                route = .notificationMission
            }
        } catch {
            await MainActor.run {
                route = .home
                showPokeToast("미션을 불러오지 못했어요. 다시 시도해 주세요.", isError: true)
            }
        }
    }

    private func openNotificationQuestion(_ notificationQuestionId: Int) async {
        do {
            let today = try await AuthService.shared.todayQuestion()
            guard let todayQuestionId = today.questionId else {
                showPokeToast("오늘 배정된 질문이 없어요.", isError: true)
                return
            }
            guard todayQuestionId == notificationQuestionId else {
                showPokeToast("지난 질문에 대한 알림이에요.", isError: true)
                return
            }

            let answers = try await AuthService.shared.familyAnswers(questionId: todayQuestionId)
            await MainActor.run {
                familyAnswers = answers.answers
                familyAnswersQuestion = answers.question
                familyAnswersError = nil
                serverQuestion = TodayQuestionResult(
                    hasFamily: true,
                    questionId: todayQuestionId,
                    question: answers.question,
                    isAnswered: answers.answers.first(where: { $0.isMe || $0.memberId == currentAuthenticatedMemberId })?.isAnswered ?? today.isAnswered,
                    answer: answers.answers.first(where: { $0.isMe || $0.memberId == currentAuthenticatedMemberId })?.answer ?? today.answer
                )
                didLoadTodayQuestion = true
                todayQuestionUnavailable = false
                todayQuestionError = nil
                route = .questionAnswer
            }
        } catch let APIError.serverError(code, _) where code == "QUESTION404_1" {
            showPokeToast("오늘 배정된 질문이 없어요.", isError: true)
        } catch {
            showPokeToast("오늘 질문을 확인하지 못했어요. 다시 시도해 주세요.", isError: true)
        }
    }

    private func openNotificationSchedule(_ scheduleId: Int) async {
        do {
            let detail = try await AuthService.shared.scheduleDetail(scheduleId: scheduleId)
            let myStatus = detail.myStatus?.uppercased()
            if detail.canRespond && ["PENDING", "RECONFIRM_REQUIRED"].contains(myStatus ?? "") {
                await MainActor.run {
                    notificationScheduleDetail = detail
                    notificationScheduleID = scheduleId
                    route = .notificationInvitation
                }
                return
            }
            let values = detail.date.split(separator: "-").compactMap { Int($0) }
            let today = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            let isToday = values.count >= 3
                && today.year == values[0]
                && today.month == values[1]
                && today.day == values[2]
            guard isToday,
                  ["SCHEDULED", "CONFIRMED"].contains((detail.status ?? "").uppercased()),
                  detail.myStatus?.uppercased() == "ACCEPTED" else {
                onSelectNotification(.schedule(scheduleId))
                return
            }
            let schedule = RecordCalendarView.ScheduleDetailData(
                scheduleId: scheduleId,
                day: values.last ?? 1,
                month: values.dropLast().last ?? Calendar.current.component(.month, from: Date()),
                status: .confirmedSchedule,
                title: detail.missionTitle ?? "오늘의 약속",
                date: detail.date,
                startTime: detail.time ?? "",
                location: "",
                expectedSteps: "",
                duration: ""
            )
            await MainActor.run {
                todayScheduleDetail = detail
                todayScheduleData = schedule
                route = .todayActivity
            }
        } catch {
            await MainActor.run { showPokeToast("일정 정보를 불러오지 못했어요. 다시 시도해 주세요.", isError: true) }
        }
    }

    private func invitationRequestData(from detail: ScheduleDetailResult) -> InvitationRequestView.RequestData {
        let participantNames = detail.participants.map(\.nickname).joined(separator: ", ")
        return InvitationRequestView.RequestData(
            senderRole: localizedFamilyRole(detail.proposer?.familyRole).isEmpty ? "가족" : localizedFamilyRole(detail.proposer?.familyRole),
            title: detail.missionTitle ?? "가족 활동",
            date: [detail.date, detail.time].compactMap { $0 }.joined(separator: " "),
            participants: participantNames.isEmpty ? "가족 구성원" : participantNames,
            participantDetails: detail.participants.enumerated().map { index, participant in
                InvitationRequestView.RequestData.Participant(
                    id: participant.memberId ?? -(index + 1),
                    nickname: participant.nickname,
                    familyRole: participant.familyRole,
                    status: participant.status,
                    characterImageURL: participant.characterImageUrl
                )
            },
            description: detail.missionDescription ?? "",
            familyMessage: detail.requestMessage ?? "",
            changedFields: detail.changedFields
        )
    }

    private func respondToNotificationSchedule(_ detail: ScheduleDetailResult, action: ScheduleResponseAction) {
        guard detail.canRespond, let scheduleId = notificationScheduleID, !isRespondingToNotification else { return }
        isRespondingToNotification = true
        Task {
            do {
                _ = try await AuthService.shared.respondToSchedule(
                    scheduleId: scheduleId,
                    action: action
                )
                let refreshed = try await AuthService.shared.scheduleDetail(scheduleId: scheduleId)
                await MainActor.run {
                    notificationScheduleDetail = refreshed
                    isRespondingToNotification = false
                    route = .home
                    showPokeToast(action == .accept ? "약속을 확정했어요." : "초대를 거절했어요.", isError: false)
                }
            } catch {
                await MainActor.run {
                    isRespondingToNotification = false
                    showPokeToast("일정 응답을 저장하지 못했어요. 다시 시도해 주세요.", isError: true)
                }
            }
        }
    }


    private func loadRecommendations() async {
        guard !isLoadingRecommendations else { return }
        let startedAt = Date()
        await MainActor.run {
            isLoadingRecommendations = true
            missionFeedError = nil
        }

        // 가족 홈의 두 섹션은 모두 공개 미션 목록을 사용합니다. 추천/계절
        // 전용 API의 결과로 목록을 제한하지 않고, 커서가 있는 모든 페이지를
        // 읽어 둡니다. OUTDOOR 필터는 화면에서만 적용합니다.
        do {
            var cursor: Int?
            var allMissions: [MissionFeedItem] = []
            var seen = Set<Int>()
            var page = try await AuthService.shared.missionFeed(cursor: cursor)
            let firstPage = page.missions.filter { seen.insert($0.missionId).inserted }
            allMissions.append(contentsOf: firstPage)
            await MainActor.run {
                recommendedMissions = allMissions
                isLoadingRecommendations = false
            }
            #if DEBUG
            print("[KIRI][HomePerf] missions first page elapsedMs=\(Int(Date().timeIntervalSince(startedAt) * 1000)) count=\(firstPage.count)")
            #endif

            // 이후 페이지는 첫 페이지 표시를 막지 않고 도착할 때마다 추가합니다.
            while page.hasNext, let nextCursor = page.nextCursor, nextCursor != cursor {
                cursor = nextCursor
                page = try await AuthService.shared.missionFeed(cursor: cursor)
                let nextPage = page.missions.filter { seen.insert($0.missionId).inserted }
                allMissions.append(contentsOf: nextPage)
                await MainActor.run { recommendedMissions = allMissions }
            }
            #if DEBUG
            print("[KIRI][HomePerf] missions complete elapsedMs=\(Int(Date().timeIntervalSince(startedAt) * 1000)) count=\(allMissions.count)")
            #endif
        } catch {
            await MainActor.run {
                // 첫 페이지가 이미 표시된 뒤 다음 페이지가 실패해도
                // 기존 콘텐츠를 비우지 않고 현재 목록을 유지합니다.
                if recommendedMissions.isEmpty {
                    missionFeedError = "mission-feed"
                }
                isLoadingRecommendations = false
            }
            #if DEBUG
            print("[KIRI][HomePerf] missions failed elapsedMs=\(Int(Date().timeIntervalSince(startedAt) * 1000))")
            #endif
        }
    }

}

#Preview {
    FamilyHomeView()
}
