
import SwiftUI

struct QuestionCard: View {
    let questionNumber: Int
    let question: String
    let answer: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("답변완료")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.green)

            Text("Q\(questionNumber). \(question)")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(KIRIColor.textPrimary)
                .padding(.top, 8)

            HStack {
                Spacer()

                Text("A. \(answer)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(KIRIColor.textSecondary)
            }
            .padding(.top, 16)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(KIRIColor.surface)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
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
