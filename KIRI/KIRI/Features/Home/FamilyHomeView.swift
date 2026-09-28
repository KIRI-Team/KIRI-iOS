import SwiftUI

struct FamilyHomeView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                familyTitle

                preferenceBanner
                    .padding(.top, 32)

                answerCollectionSection
                    .padding(.top, 58)

                questionSection
                    .padding(.top, 48)

                placeRecommendationSection
                    .padding(.top, 36)

                moodRecommendationSection
                    .padding(.top, 36)

                Spacer()
                    .frame(height: 32)
            }
            .padding(.top, 20)
        }
        .background(KIRIColor.background)
    }

    private var familyTitle: some View {
        Text("끼리네 가족")
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(KIRIColor.textPrimary)
            .frame(maxWidth: .infinity)
    }

    private var preferenceBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("주연님의")
                Text("취향을 더 알고싶어요!")
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(KIRIColor.textPrimary)

            Spacer()

            Text("취향테스트 참여하러가기")
                .font(.system(size: 12))
                .foregroundStyle(KIRIColor.textSecondary)
        }
        .padding(.horizontal, 20)
        .frame(height: 84)
        .background(KIRIColor.surface)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
        .padding(.horizontal, 18)
    }

    private var answerCollectionSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("답변 모아보기")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(KIRIColor.textPrimary)

                Spacer()

                Button {
                    // TODO: 가족 초대 화면 연결
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "plus")
                            .font(.system(size: 12))

                        Text("가족 초대하기")
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(KIRIColor.textSecondary)
                    .padding(.horizontal, 12)
                    .frame(height: 31)
                    .background(Color.white.opacity(0.12))
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

    private var questionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("오늘 나의 질문카드")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(KIRIColor.textPrimary)

                Spacer()

                Text("다른 가족들의 답변을 기다려요!")
                    .font(.system(size: 12))
                    .foregroundStyle(KIRIColor.textSecondary)
            }

            QuestionCard(
                questionNumber: 1,
                question: "내가 가장 좋아하는 음식은?",
                answer: "뚝배기불고기"
            )
        }
        .padding(.horizontal, 18)
    }

    private var placeRecommendationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("엄마와 함께라면 여기!")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(KIRIColor.textPrimary)
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

    private var moodRecommendationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("오늘 기분전환을 느끼고 싶다면")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(KIRIColor.textPrimary)
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
}

#Preview {
    FamilyHomeView()
}
