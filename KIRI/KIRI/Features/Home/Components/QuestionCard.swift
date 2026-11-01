
import SwiftUI

struct QuestionCard: View {
    let questionNumber: Int
    let question: String
    let answer: String?
    var onCardTap: (() -> Void)? = nil
    var onFlip: (() -> Void)? = nil

    var body: some View {
        ZStack(alignment: .topTrailing) {
            questionContent
                .contentShape(RoundedRectangle(cornerRadius: 8))
                .onTapGesture {
                    onCardTap?()
                }

            if let onFlip {
                Button(action: onFlip) {
                    Image("figma_refresh")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .frame(width: 33, height: 33)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("가족 미션 카드로 뒤집기")
                .padding(.top, 10)
                .padding(.trailing, 12)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 136)
        .background(KIRIColor.Background.primary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var questionContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(answer == nil ? "답변하기" : "답변완료")
                .font(KIRITypography.bodySmall)
                .foregroundStyle(KIRIColor.Text.secondary)

            Text("Q\(questionNumber). \(question)")
                .font(KIRITypography.headingSmall)
                .foregroundStyle(KIRIColor.Text.strong)
                .padding(.top, 11)

            HStack {
                Spacer()

                Text(answer.map { "A. \($0)" } ?? "오늘의 질문에 답해보세요")
                    .font(KIRITypography.headingSmall)
                    .foregroundStyle(answer == nil ? KIRIColor.Text.secondary : KIRIColor.Text.accent)
            }
            .padding(.top, 11)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 25)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

/// HOME-05: 오늘의 질문과 이번 주 가족 미션을 한 카드의 앞뒤로 표현합니다.
/// 카드 전환은 화면 표시 상태만 바꾸며 질문 답변/미션 완료 데이터에는 영향을 주지 않습니다.
struct QuestionMissionFlipCard: View {
    let questionNumber: Int
    let question: String
    let answer: String?
    let mission: HomeMockMission?
    @Binding var showsMission: Bool
    let onQuestionAnswer: () -> Void
    let onMissionDetail: () -> Void
    let onMissionExplore: () -> Void

    @State private var isAnimating = false
    @State private var suppressMissionBodyTap = false
    @State private var rotationAngle: Double = 0

    var body: some View {
        ZStack {
            questionFace
                .opacity(rotationAngle < 90 ? 1 : 0)
                .allowsHitTesting(rotationAngle < 90)
                .zIndex(rotationAngle < 90 ? 1 : 0)

            missionFace
                // The back face is authored in the opposite direction. The container
                // rotation below brings it back to a readable 360° orientation.
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(rotationAngle >= 90 ? 1 : 0)
                .allowsHitTesting(rotationAngle >= 90)
                .zIndex(rotationAngle >= 90 ? 1 : 0)
        }
        .rotation3DEffect(.degrees(rotationAngle), axis: (x: 0, y: 1, z: 0))
        .frame(maxWidth: .infinity)
        .frame(height: 136)
        .gesture(
            DragGesture(minimumDistance: 24)
                .onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height),
                          abs(value.translation.width) >= 24 else { return }
                    flip()
                }
        )
        .onAppear {
            rotationAngle = showsMission ? 180 : 0
        }
        .onChange(of: showsMission) { _, newValue in
            withAnimation(.easeInOut(duration: 0.35)) {
                rotationAngle = newValue ? 180 : 0
            }
        }
    }

    private var questionFace: some View {
        QuestionCard(
            questionNumber: questionNumber,
            question: question,
            answer: answer,
            onCardTap: onQuestionAnswer,
            onFlip: { flip() }
        )
    }

    @ViewBuilder
    private var missionFace: some View {
        if let mission {
            missionContent(mission)
        } else {
            ZStack(alignment: .topTrailing) {
                Button(action: onMissionExplore) {
                    VStack(spacing: 6) {
                        Text("공개된 미션을 둘러보세요 →")
                            .font(KIRITypography.bodyMedium)
                            .foregroundStyle(KIRIColor.Text.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 136)
                    .background(KIRIColor.Background.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                Button(action: { flip() }) {
                    Image("figma_refresh")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .frame(width: 33, height: 33)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("오늘의 질문 카드로 뒤집기")
                .padding(.top, 10)
                .padding(.trailing, 12)
            }
        }
    }

    private func missionContent(_ mission: HomeMockMission) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    if mission.isComplete {
                        Text("이미 미션을 완료하셨군요!")
                            .font(KIRITypography.bodySmall)
                            .foregroundStyle(KIRIColor.Text.accent)
                            .lineLimit(1)
                    }
                    Text(mission.title)
                        .font(KIRITypography.headingSmall)
                        .foregroundStyle(KIRIColor.Text.strong)
                        .lineLimit(1)
                    Text(mission.location)
                        .font(KIRITypography.bodySmall)
                        .foregroundStyle(KIRIColor.Text.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Button {
                    flip(suppressMissionBodyTap: true)
                } label: {
                    Image("figma_refresh")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(KIRIColor.Text.secondary)
                        .frame(width: 33, height: 33)
                }
                .buttonStyle(.plain)
                .homeTutorialMeasured(.missionRefresh)
            }

            if mission.isComplete {
                Button {
                    onMissionDetail()
                } label: {
                    Text("오늘의 추억 기록하러가기")
                        .font(KIRITypography.bodyMedium)
                        .foregroundStyle(KIRIColor.Text.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(KIRIColor.Background.elevated)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            } else {
                HStack(spacing: 8) {
                    ForEach(mission.tags, id: \.self) { tag in
                        Text(tag)
                            .font(KIRITypography.caption)
                            .foregroundStyle(KIRIColor.Text.tertiary)
                            .padding(.horizontal, 8)
                            .frame(height: 29)
                            .background(KIRIColor.Background.elevated)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: 136)
        .background(KIRIColor.Background.primary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture {
            guard !suppressMissionBodyTap else {
                suppressMissionBodyTap = false
                return
            }
            onMissionDetail()
        }
    }

    private func flip(suppressMissionBodyTap: Bool = false) {
        guard !isAnimating else { return }
        if suppressMissionBodyTap {
            self.suppressMissionBodyTap = true
            DispatchQueue.main.async {
                self.suppressMissionBodyTap = false
            }
        }
        isAnimating = true
        showsMission.toggle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            isAnimating = false
        }
    }
}

#Preview {
    QuestionCard(
        questionNumber: 1,
        question: "내가 가장 좋아하는 음식은?",
        answer: "뚝배기불고기"
    )
    .padding()
    .background(KIRIColor.background)
}
