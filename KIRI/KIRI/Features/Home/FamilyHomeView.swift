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
    @State private var selectedRecommendation: FamilyRecommendationResult?
    @State private var selectedMember: HomeMember?
    @State private var isPlaceBookmarked = false
    @State private var showsMissionFace = false
    @State private var didLoadTodayQuestion = false
    @State private var todayQuestionError: String?
    @State private var serverQuestion: TodayQuestionResult?
    @State private var familyAnswers: [FamilyAnswer] = []
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
    @State private var familyRecommendation: FamilyRecommendationResult?
    @State private var isLoadingRecommendations = false
    @State private var recommendationError: String?


    private enum HomeRoute {
        case home
        case notification
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
                        // 알림 목록 API가 제공되기 전에는 샘플 요청서를 열지 않습니다.
                    }
                )


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
                                    try await AuthService.shared.pokeMember(memberId: memberId)
                                    if let questionId = serverQuestion?.questionId {
                                        await loadFamilyAnswers(questionId: questionId)
                                    }
                                    await MainActor.run {
                                        pokedMemberIDs.insert(memberId)
                                        showPokeToast("\(selectedMember.name)님을 콕 찔렀어요!", isError: false)
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
                            }
                        )
                        .zIndex(1)
                    }
                    if let pokeToastMessage {
                        KIRIToast(message: pokeToastMessage, isError: pokeToastIsError)
                            .padding(.horizontal, 18)
                            .safeAreaPadding(.top, 8)
                            // 말풍선·dim과 같은 ZStack 안에서도 토스트는 화면 최상단에 고정합니다.
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .zIndex(2)
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
        }
        .onDisappear {
            tabBarVisibility.wrappedValue = true
        }
        .coordinateSpace(name: "familyHome")
        .onPreferenceChange(FamilyMemberFramePreferenceKey.self) { frames in
            memberFrames = frames
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
        // QUESTION404_3은 현재 확인 가능한 계약상 중복 전송 코드가 아니므로
        // 이미 전송된 상태로 처리하지 않고 질문 상태 확인 실패로 안내합니다.
        if code.uppercased() == "QUESTION404_3" {
            return "오늘 질문 상태를 확인할 수 없어 콕을 보내지 못했어요. 다시 시도해 주세요."
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
            Text("추천 미션")
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

    private var tutorialMission: MissionFeedItem? {
        recommendedMissions.first
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
            VStack(spacing: 8) {
                Text("추천 미션을 불러오지 못했어요")
                    .font(KIRITypography.bodySmall)
                    .foregroundStyle(KIRIColor.Text.tertiary)
                Button("다시 시도") {
                    Task { await loadRecommendations() }
                }
                .font(KIRITypography.bodySmallMedium)
                .foregroundStyle(KIRIColor.Text.accent)
                .accessibilityHint(recommendationError)
            }
            .frame(maxWidth: .infinity, minHeight: 144, alignment: .center)
        } else if let recommendation = familyRecommendation {
            Button {
                selectedRecommendation = recommendation
                selectedMission = nil
                isPlaceBookmarked = false
                route = .placeDetail
            } label: {
                PlaceCard(
                    title: recommendation.title,
                    location: "",
                    rating: recommendation.score,
                    description: recommendation.recommendationReason,
                    imageURL: recommendation.imageUrl
                )
            }
            .buttonStyle(.plain)
        } else {
            Text("추천할 미션이 아직 없어요")
                .font(KIRITypography.bodySmall)
                .foregroundStyle(KIRIColor.Text.tertiary)
                .frame(maxWidth: .infinity, minHeight: 144, alignment: .center)
        }
    }

    // MARK: - Actions


    private func loadTodayQuestion() async {
        #if DEBUG
        print("[KIRI][Question] request started")
        #endif
        do {
            let result = try await AuthService.shared.todayQuestion()
            await MainActor.run {
                serverQuestion = result
                familyAnswers = []
                familyAnswersQuestion = nil
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
                familyAnswersQuestion = nil
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
                familyAnswersQuestion = nil
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
                familyAnswersQuestion = result.question
                isLoadingFamilyAnswers = false
            }
        } catch {
            await MainActor.run {
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

    private func loadRecommendations() async {
        await MainActor.run {
            isLoadingRecommendations = true
            recommendationError = nil
            familyRecommendation = nil
        }

        // 플립 카드의 실제 미션과 가족 맞춤 추천은 각각 계약된 API에서 읽습니다.
        do {
            let feed = try await AuthService.shared.missionFeed()
            await MainActor.run { recommendedMissions = feed.missions }
        } catch {
            // 추천 섹션과 독립된 플립 카드 데이터 실패는 추천 카드 오류로 덮어쓰지 않습니다.
            await MainActor.run { recommendedMissions = [] }
        }

        do {
            let recommendation = try await AuthService.shared.familyRecommendation()
            await MainActor.run {
                familyRecommendation = recommendation
                isLoadingRecommendations = false
            }
        } catch {
            await MainActor.run {
                recommendationError = error.localizedDescription
                isLoadingRecommendations = false
            }
            #if DEBUG
            print("[KIRI][Recommendation] family recommendation load failed")
            #endif
        }
    }

}

#Preview {
    FamilyHomeView()
}
