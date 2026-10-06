import SwiftUI

struct FamilyHomeView: View {

    private enum HomeRoute {
        case home
        case notification
        case invitationRequest
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
            }
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
                    preferenceBanner
                        .padding(.top, 20)

                    answerCollectionSection
                        .padding(.top, 58)

                    questionSection
                        .padding(.top, 48)

                    placeRecommendationSection
                        .padding(.top, 36)

                    moodRecommendationSection
                        .padding(.top, 36)

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
            Text("끼리네 가족")
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
        HStack {
            VStack(
                alignment: .leading,
                spacing: 5
            ) {
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
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
        .padding(.horizontal, 18)
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
                    // TODO: 가족 초대 화면 연결
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
                    FamilyMemberItem(
                        name: "내 답변",
                        isMe: true,
                        hasAnswered: true
                    )

                    FamilyMemberItem(
                        name: "엄마",
                        isMe: false,
                        hasAnswered: true
                    )

                    FamilyMemberItem(
                        name: "엄마",
                        isMe: false,
                        hasAnswered: true
                    )

                    FamilyMemberItem(
                        name: "엄마",
                        isMe: false,
                        hasAnswered: true
                    )

                    FamilyMemberItem(
                        name: "엄마",
                        isMe: false,
                        hasAnswered: true
                    )
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

            QuestionCard(
                questionNumber: 1,
                question: "내가 가장 좋아하는 음식은?",
                answer: "뚝배기불고기"
            )
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
                    PlaceCard(
                        title: "경복궁에서 사진찍기",
                        location: "경복궁 종로구",
                        rating: 4.6,
                        description: "대중교통이 편리하고, 부모님이랑 가기 좋아요! 추천합니다."
                    )

                    PlaceCard(
                        title: "남산에서 산책하기",
                        location: "서울 중구",
                        rating: 4.5,
                        description: "가볍게 산책하면서 함께 시간을 보내기 좋아요."
                    )
                }
                .padding(.horizontal, 18)
            }
        }
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
                    PlaceCard(
                        title: "경복궁에서 산책하기",
                        location: "경복궁 종로구",
                        rating: 4.6,
                        description: "가족과 함께 가볍게 둘러보기 좋은 장소예요."
                    )

                    PlaceCard(
                        title: "남산에서 야경보기",
                        location: "서울 중구",
                        rating: 4.7,
                        description: "저녁에 가족과 함께 기분전환하기 좋아요."
                    )
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
