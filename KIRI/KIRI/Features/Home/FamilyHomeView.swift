import SwiftUI

struct FamilyHomeView: View {
    // 기존 가족공간 데이터가 준비되면 실제 값을 전달합니다.
    var familyName: String = "끼리네 가족"
    var familyInviteCode: String? = nil
    var tutorialStep: Int? = nil

    @State private var isInvitePresented = false
    @State private var isInviteUnavailableAlertPresented = false
    @State private var mockData = HomeMockData()
    @State private var selectedPlace: HomeMockPlace?
    @State private var selectedMember: HomeMockMember?
    @State private var isPlaceBookmarked = false


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
                if let selectedPlace {
                    MissionActivityDetailView(
                        title: selectedPlace.title,
                        placeName: selectedPlace.title,
                        district: selectedPlace.location,
                        rating: selectedPlace.rating,
                        tags: selectedPlace.tags,
                        isRecommended: true,
                        isBookmarked: $isPlaceBookmarked,
                        onBack: { route = .home }
                    )
                }

            case .taste:
                TasteTestView()

            case .questionAnswer:
                HomeQuestionAnswerView(question: mockData.question.text, existingAnswer: mockData.question.answer, onBack: { route = .home }) { savedAnswer in
                    mockData.question.answer = savedAnswer
                    if let index = mockData.members.firstIndex(where: { $0.isMe }) { mockData.members[index].hasAnswered = true }
                    route = .home
                }

            case .missionDetail:
                HomeMissionDetailView(onBack: { route = .home }) {
                    mockData.hasSchedule = true
                    route = .home
                }

            case .memberDetail:
                if let selectedMember {
                    HomeMemberQuestionView(member: selectedMember, onBack: { route = .home })
                }
            }
        }
        .fullScreenCover(isPresented: $isInvitePresented) {
            if let code = familyInviteCode, !code.isEmpty {
                FamilyCodeView(
                    familyName: familyName,
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
    }

    // MARK: - Home

    private var homeContent: some View {
        VStack(spacing: 0) {
            homeNavigationBar

            ScrollView(showsIndicators: false) {
                VStack(
                    alignment: .leading,
                    spacing: 0
                ) {
                    if tutorialStep == nil {
                        preferenceBanner
                            .padding(.top, 20)
                    }

                    answerCollectionSection
                        .padding(.top, 58)

                    if showsQuestionForTutorial {
                        questionSection
                            .padding(.top, 48)
                    }

                    if showsMissionForTutorial {
                        if tutorialStep == nil {
                            weeklyMissionSection
                                .padding(.top, 36)
                        } else {
                            tutorialMissionSection
                                .padding(.top, 36)
                        }
                    }

                    placeRecommendationSection
                        .padding(.top, 36)

                    if tutorialStep == nil {
                        moodRecommendationSection
                            .padding(.top, 36)
                    }

                    Spacer()
                        .frame(height: 120)
                }
            }
        }
        .background(KIRIColor.Background.base)
    }

    // MARK: - Navigation Bar

    private var homeNavigationBar: some View {
        ZStack {
            Text(familyName)
                .font(KIRITypography.headingSmall)
                .tracking(-0.72)
                .foregroundStyle(KIRIColor.Text.strong)

            HStack {
                Spacer()

                Button {
                    route = .notification
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell")
                            .font(
                                .system(
                                    size: 20,
                                    weight: .regular
                                )
                            )
                            .foregroundStyle(
                                KIRIColor.Icon.primary
                            )
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

    // MARK: - Preference Banner

    private var preferenceBanner: some View {
        Button { route = .taste } label: {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("주연님의")
                    Text("취향을 더 알고싶어요!")
                }
                .font(KIRITypography.bodyMedium)
                .tracking(-0.64)
                .foregroundStyle(KIRIColor.Text.primary)
                Spacer()
                Text("취향테스트 참여하러가기")
                    .font(KIRITypography.caption)
                    .tracking(-0.48)
                    .foregroundStyle(KIRIColor.Text.secondary)
            }
            .padding(.horizontal, 20)
            .frame(height: 84)
            .background(KIRIColor.Background.tertiary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 18)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Answer Collection

    private var answerCollectionSection: some View {
        VStack(
            alignment: .leading,
            spacing: 20
        ) {
            HStack {
                Text("답변 모아보기")
                    .font(KIRITypography.headingSmall)
                    .tracking(-0.72)
                    .foregroundStyle(KIRIColor.Text.strong)

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
            }

            ScrollView(
                .horizontal,
                showsIndicators: false
            ) {
                HStack(spacing: 18) {
                    ForEach(displayedMembers) { member in
                        Button {
                            selectedMember = member
                            route = member.isMe ? .questionAnswer : .memberDetail
                        } label: {
                            FamilyMemberItem(name: member.name, isMe: member.isMe, hasAnswered: member.hasAnswered)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 18)
    }

    // MARK: - Question

    private var questionSection: some View {
        VStack(
            alignment: .leading,
            spacing: 14
        ) {
            HStack {
                Text("오늘 나의 질문카드")
                    .font(KIRITypography.headingSmall)
                    .tracking(-0.72)
                    .foregroundStyle(KIRIColor.Text.strong)

                Spacer()

                Text("다른 가족들의 답변을 기다려요!")
                    .font(KIRITypography.caption)
                    .tracking(-0.48)
                    .foregroundStyle(KIRIColor.Text.secondary)
            }

            Button { route = .questionAnswer } label: {
                QuestionCard(questionNumber: mockData.question.number, question: mockData.question.text, answer: mockData.question.answer)
            }
            .buttonStyle(.plain)
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

            ScrollView(
                .horizontal,
                showsIndicators: false
            ) {
                HStack(spacing: 24) {
                    ForEach(mockData.places) { place in
                        Button { selectedPlace = place; route = .placeDetail } label: {
                            PlaceCard(title: place.title, location: place.location, rating: place.rating, description: place.description)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
            }
        }
    }

    private var weeklyMissionSection: some View {
        Button { route = .missionDetail } label: {
            HStack(spacing: 14) {
                Image(systemName: mockData.hasSchedule ? "calendar.badge.checkmark" : "circle.dashed")
                    .font(.system(size: 26))
                    .foregroundStyle(mockData.hasSchedule ? KIRIColor.Primary.default : KIRIColor.Icon.secondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text(mockData.hasSchedule ? "이번 주 미션 일정을 확인해보세요" : "이번 주 가족 미션")
                        .font(KIRITypography.bodyMedium).foregroundStyle(KIRIColor.Text.primary)
                    Text(mockData.hasSchedule ? "활동 기록을 남기면 미션이 완료됩니다" : "가족과 함께 작은 추억을 만들어보세요")
                        .font(KIRITypography.caption).foregroundStyle(KIRIColor.Text.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(KIRIColor.Icon.secondary)
            }
            .padding(16)
            .background(KIRIColor.Background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 18)
    }

    private var tutorialMissionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .bottom) {
                Text("이번주 미션이에요!")
                    .font(KIRITypography.headingSmall)
                    .tracking(-0.72)
                    .foregroundStyle(KIRIColor.Text.strong)

                Spacer()

                Text("다른 가족들의 답변을 기다려요!")
                    .font(KIRITypography.caption)
                    .tracking(-0.48)
                    .foregroundStyle(KIRIColor.Text.secondary)
            }

            Button { route = .missionDetail } label: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("광장시장에서 시장음식 먹어보기")
                                .font(.system(size: 18, weight: .medium))
                                .tracking(-0.72)
                                .foregroundStyle(KIRIColor.Text.strong)
                                .lineLimit(1)

                            Text("광장시장 · 종로구")
                                .font(.system(size: 14))
                                .tracking(-0.56)
                                .foregroundStyle(KIRIColor.Text.secondary)
                        }

                        Spacer()

                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundStyle(KIRIColor.Text.secondary)
                            .frame(width: 33, height: 33)
                    }

                    HStack(spacing: 8) {
                        tutorialMissionTag("대중교통 편리")
                        tutorialMissionTag("혼잡도 높음")
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
                .background(KIRIColor.Background.primary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 18)
        }
    }

    private func tutorialMissionTag(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12))
            .tracking(-0.48)
            .foregroundStyle(KIRIColor.Text.secondary)
            .padding(.horizontal, 8)
            .frame(height: 29)
            .background(KIRIColor.Background.tertiary)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var displayedMembers: [HomeMockMember] {
        guard tutorialStep != nil else { return mockData.members }
        return [
            HomeMockMember(id: "me", name: "내 답변", role: "딸", hasAnswered: true, isMe: true),
            HomeMockMember(id: "mama", name: "마마", role: "엄마", hasAnswered: true, isMe: false),
            HomeMockMember(id: "papa", name: "빠빠", role: "아빠", hasAnswered: false, isMe: false),
            HomeMockMember(id: "doldoli", name: "돌돌이", role: "아들", hasAnswered: true, isMe: false),
            HomeMockMember(id: "daughter", name: "딸", role: "딸", hasAnswered: true, isMe: false)
        ]
    }

    private var showsQuestionForTutorial: Bool {
        guard let tutorialStep else { return true }
        return tutorialStep == 0
    }

    private var showsMissionForTutorial: Bool {
        guard let tutorialStep else { return true }
        return tutorialStep >= 1
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

            ScrollView(
                .horizontal,
                showsIndicators: false
            ) {
                HStack(spacing: 24) {
                    ForEach(mockData.places.reversed()) { place in
                        Button { selectedPlace = place; route = .placeDetail } label: {
                            PlaceCard(title: place.title, location: place.location, rating: place.rating, description: place.description)
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
}

#Preview {
    FamilyHomeView()
}
