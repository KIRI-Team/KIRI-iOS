import SwiftUI

struct FamilyHomeView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    // 기존 가족공간 데이터가 준비되면 실제 값을 전달합니다.
    var familyName: String?
    var familyId: Int? = nil
    var familyInviteCode: String? = nil
    var nickname: String? = nil
    var familyRole: String? = nil
    var tutorialStep: Int? = nil
    var loadsServerQuestion: Bool = true
    var onExploreMission: () -> Void = {}

    @State private var isInvitePresented = false
    @State private var isInviteUnavailableAlertPresented = false
    @State private var selectedMission: MissionFeedItem?
    @State private var selectedMember: HomeMember?
    @State private var isPlaceBookmarked = false
    @State private var showsMissionFace = false
    @State private var didLoadTodayQuestion = false
    @State private var todayQuestionError: String?
    @State private var serverQuestion: TodayQuestionResult?
    @State private var familyAnswers: [FamilyAnswer] = []
    @State private var isLoadingFamilyAnswers = false
    @State private var familyAnswersError: String?
    @State private var recommendedMissions: [MissionFeedItem] = []
    @State private var isLoadingRecommendations = false
    @State private var recommendationError: String?


    private enum HomeRoute {
        case home
        case notification
        case invitationRequest
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
                    onSelectInvitation: {
                        route = .invitationRequest
                    }
                )

            case .invitationRequest:
                InvitationRequestView(
                    request: invitationRequest,
                    onBack: {
                        route = .notification
                    },
                    onCancel: {
                        route = .notification
                    },
                    onConfirmSchedule: {
                        handleScheduleConfirmed()
                    }
                )

            case .placeDetail:
                if let selectedMission {
                    MissionActivityDetailView(
                        title: selectedMission.title,
                        placeName: selectedMission.placeName,
                        district: selectedMission.category,
                        rating: nil,
                        tags: [selectedMission.missionType],
                        isRecommended: true,
                        mockAssetName: nil,
                        imageURL: selectedMission.imageUrl,
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
                    onBack: { route = .home }
                ) { savedAnswer in
                    guard let questionId = serverQuestion?.questionId else { return }
                    Task { @MainActor in
                        do {
                            try await AuthService.shared.writeAnswer(questionId: questionId, answer: savedAnswer)
                            await loadTodayQuestion()
                            route = .home
                        } catch {
                            todayQuestionError = error.localizedDescription
                        }
                    }
                }

            case .missionDetail:
                HomeMissionDetailView(onBack: { route = .home }) {
                    route = .home
                }

            case .memberDetail:
                ZStack {
                    homeContent.allowsHitTesting(false)
                    Color.black.opacity(0.56).ignoresSafeArea()
                    if let selectedMember {
                        HomeMemberQuestionView(member: selectedMember, onBack: { route = .home })
                    }
                }
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
        .alert("초대코드를 불러올 수 없어요", isPresented: $isInviteUnavailableAlertPresented) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("가족공간의 초대코드가 연결되지 않았습니다.")
        }
        .onAppear {
            if let tutorialStep {
                showsMissionFace = tutorialStep >= 1
            }
        }
        .onChange(of: tutorialStep) { _, newStep in
            if let newStep {
                showsMissionFace = newStep >= 1
            }
        }
        .task {
            guard loadsServerQuestion else {
                didLoadTodayQuestion = true
                return
            }
            await loadTodayQuestion()
        }
        .task {
            await loadRecommendations()
        }
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
                        answerCollectionSection
                            .id("tutorial-top")
                            .padding(.top, 23)

                        questionMissionSection
                            .id("tutorial-question-card")
                            .padding(.top, 48)

                        placeRecommendationSection
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
        guard step == 1 else {
            if animated && !reduceMotion {
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo("tutorial-top", anchor: .top)
                }
            } else {
                proxy.scrollTo("tutorial-top", anchor: .top)
            }
            return
        }

        if animated && !reduceMotion {
            withAnimation(.easeInOut(duration: 0.25)) {
                proxy.scrollTo("tutorial-question-card", anchor: .top)
            }
        } else {
            proxy.scrollTo("tutorial-question-card", anchor: .top)
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

                        Circle()
                            .fill(KIRIColor.Primary.default)
                            .frame(
                                width: 6,
                                height: 6
                            )
                            .offset(
                                x: 1,
                                y: -1
                            )
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

            if isLoadingFamilyAnswers && displayedMembers.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .leading)
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
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(displayedMembers) { member in
                            Button {
                                selectedMember = member
                                route = member.isMe ? .questionAnswer : .memberDetail
                            } label: {
                                FamilyMemberItem(name: member.name, role: member.role, isMe: member.isMe, hasAnswered: member.hasAnswered)
                            }
                            .buttonStyle(.plain)
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
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 136)
            } else if let todayQuestionError {
                VStack(spacing: 10) {
                    Text(todayQuestionError)
                        .font(KIRITypography.bodyMedium)
                        .foregroundStyle(KIRIColor.Text.secondary)
                    Button("다시 시도") {
                        Task { await loadTodayQuestion() }
                    }
                    .font(KIRITypography.bodySmallMedium)
                    .foregroundStyle(KIRIColor.Text.accent)
                }
                .frame(maxWidth: .infinity, minHeight: 136)
            } else if let serverQuestion, let questionId = serverQuestion.questionId {
                QuestionMissionFlipCard(
                    questionNumber: questionId,
                    question: serverQuestion.question ?? "오늘의 질문",
                    answer: serverQuestion.answer,
                    mission: tutorialMission,
                    showsMission: $showsMissionFace,
                    onQuestionAnswer: { route = .questionAnswer },
                    onMissionDetail: { route = .missionDetail },
                    onMissionExplore: onExploreMission
                )
                .homeTutorialMeasured(.questionMissionCard)
            } else {
                Text("오늘의 질문이 아직 없어요")
                    .font(KIRITypography.bodyMedium)
                    .foregroundStyle(KIRIColor.Text.tertiary)
                    .frame(maxWidth: .infinity, minHeight: 136)
            }
        }
        .padding(.horizontal, 18)
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
        if !familyAnswers.isEmpty {
            return familyAnswers.map { member in
                HomeMember(
                    id: String(member.memberId),
                    memberId: member.memberId,
                    name: member.nickname,
                    role: member.isMe ? (member.familyRole ?? familyRole) : member.familyRole,
                    hasAnswered: member.isAnswered,
                    answer: member.answer,
                    isMe: member.isMe
                )
            }
        }

        // The server response identifies the authenticated user through the
        // question payload even when the family answer list is empty. Do not
        // invent other family members, but keep the authenticated member
        // visible when the family itself is known.
        guard familyId != nil else { return [] }
        return [HomeMember(
            id: "me",
            memberId: nil,
            name: (nickname?.isEmpty == false ? nickname! : "나"),
            role: familyRole,
            hasAnswered: serverQuestion?.isAnswered ?? false,
            answer: serverQuestion?.answer,
            isMe: true
        )]
    }

    private var tutorialMission: HomeMockMission? {
        guard let mission = recommendedMissions.first else { return nil }
        var tags = [mission.category]
        if let distance = mission.distance {
            tags.append(String(format: "%.1fkm", distance))
        }
        return HomeMockMission(
            title: mission.title,
            location: mission.placeName,
            tags: tags,
            isComplete: false
        )
    }

    // MARK: - Mood Recommendation

    private var moodRecommendationSection: some View {
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            Text("오늘 기분전환을 느끼고 싶다면")
                .font(KIRITypography.headingSmall)
                .tracking(-0.72)
                .foregroundStyle(KIRIColor.Text.strong)
                .padding(.horizontal, 18)

            Text("추천 콘텐츠가 아직 없어요")
                .font(KIRITypography.bodySmall)
                .foregroundStyle(KIRIColor.Text.tertiary)
                .frame(maxWidth: .infinity, minHeight: 144, alignment: .center)
        }
    }

    @ViewBuilder
    private var recommendationCards: some View {
        if isLoadingRecommendations {
            ProgressView().frame(maxWidth: .infinity, minHeight: 144)
        } else if let recommendationError {
            Text(recommendationError)
                .font(KIRITypography.bodySmall)
                .foregroundStyle(KIRIColor.Text.tertiary)
                .frame(maxWidth: .infinity, minHeight: 144, alignment: .center)
        } else if recommendedMissions.isEmpty {
            Text("추천할 미션이 아직 없어요")
                .font(KIRITypography.bodySmall)
                .foregroundStyle(KIRIColor.Text.tertiary)
                .frame(maxWidth: .infinity, minHeight: 144, alignment: .center)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    ForEach(recommendedMissions) { mission in
                        Button {
                            selectedMission = mission
                            route = .placeDetail
                        } label: {
                            PlaceCard(
                                title: mission.title,
                                location: mission.placeName,
                                rating: nil,
                                description: mission.category,
                                imageURL: mission.imageUrl
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
            }
        }
    }

    // MARK: - Request Mock Data

    private var invitationRequest:
        InvitationRequestView.RequestData {
        InvitationRequestView.RequestData(
            senderRole: "딸",
            title: "한강 뚜벅뚜벅 축제",
            date: "26.06.23",
            participants: "엄마, 아빠, 나",
            description: """
            2026 한강 뚜벅뚜벅 축제는 잠수교를 보행교로 전환해 시민이 직접 걸으며 공연·체험·미식 등 다양한 문화·여가 프로그램을 즐기는 서울 대표 한강 축제입니다.
            """,
            familyMessage:
                "엄마, 아빠 나 여기 가고싶은데 우리 10월 초에 갈래요??"
        )
    }

    // MARK: - Actions

    private func handleScheduleConfirmed() {
        // TODO:
        // 수락 API 연결 후 실제 RecordCalendarView 일정 갱신
        route = .home
    }

    private func loadTodayQuestion() async {
        #if DEBUG
        print("[KIRI][Question] request started")
        #endif
        do {
            let result = try await AuthService.shared.todayQuestion()
            await MainActor.run {
                serverQuestion = result
                familyAnswers = []
                didLoadTodayQuestion = true
                todayQuestionError = nil
            }
            #if DEBUG
            print("[KIRI][Question] response hasFamily=\(result.hasFamily) questionIdPresent=\(result.questionId != nil) questionPresent=\(result.question?.isEmpty == false) isAnswered=\(result.isAnswered)")
            #endif
            if let questionId = result.questionId {
                await loadFamilyAnswers(questionId: questionId)
            }
        } catch let APIError.serverError(code, _) where code == "QUESTION404_1" {
            // A family can temporarily have no question assigned. Keep the
            // family home visible and render its empty state instead of an
            // API error or a fake question.
            await MainActor.run {
                serverQuestion = nil
                familyAnswers = []
                familyAnswersError = nil
                todayQuestionError = nil
                didLoadTodayQuestion = true
            }
            #if DEBUG
            print("[KIRI][Question] no question assigned")
            #endif
        } catch {
            await MainActor.run {
                familyAnswers = []
                todayQuestionError = error.localizedDescription
                didLoadTodayQuestion = true
            }
            #if DEBUG
            print("[KIRI][Question] load failed: \(error.localizedDescription)")
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
                isLoadingFamilyAnswers = false
            }
        } catch {
            await MainActor.run {
                familyAnswers = []
                familyAnswersError = error.localizedDescription
                isLoadingFamilyAnswers = false
            }
            #if DEBUG
            print("[KIRI][Question] family answers load failed: \(error.localizedDescription)")
            #endif
        }
    }

    private func loadRecommendations() async {
        await MainActor.run {
            isLoadingRecommendations = true
            recommendationError = nil
        }
        do {
            let result = try await AuthService.shared.missionFeed()
            await MainActor.run {
                recommendedMissions = result.missions
                isLoadingRecommendations = false
            }
            #if DEBUG
            print("[KIRI][Recommendation] response count=\(result.missions.count) hasNext=\(result.hasNext)")
            #endif
        } catch {
            await MainActor.run {
                recommendationError = error.localizedDescription
                isLoadingRecommendations = false
            }
            #if DEBUG
            print("[KIRI][Recommendation] load failed: \(error.localizedDescription)")
            #endif
        }
    }
}

#Preview {
    FamilyHomeView()
}
