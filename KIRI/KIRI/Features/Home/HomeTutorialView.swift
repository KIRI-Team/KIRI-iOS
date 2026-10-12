import SwiftUI

/// Figma 9173:13678에 표현된 홈 화면 안내 오버레이.
/// 별도 전체 화면 레이아웃이나 시스템 아이콘을 만들지 않고, 실제 홈의 안내 대상만 강조한다.
struct HomeTutorialView: View {
    enum Mode {
        case browse
        case family
    }

    private struct Step {
        let highlight: CGRect
        let messages: [(text: String, position: CGPoint)]
    }

    let mode: Mode
    let onComplete: () -> Void

    @State private var stepIndex = 0

    private var steps: [Step] {
        switch mode {
        case .browse:
            // Figma annotation 9167:10685. 둘러보기 홈의 가족공간 생성 영역만 안내한다.
            return [
                Step(
                    highlight: CGRect(x: 18, y: 145, width: 354, height: 96),
                    messages: [
                        ("가족을 초대해서\n방을 만들어요!", CGPoint(x: 300, y: 278))
                    ]
                )
            ]

        case .family:
            // Figma annotations 9173:10693, 9173:13144, 9173:12443, 9173:13413.
            return [
                Step(
                    highlight: CGRect(x: 18, y: 145, width: 354, height: 128),
                    messages: [
                        ("우리 가족들의\n답변을 모아봐요!", CGPoint(x: 110, y: 310))
                    ]
                ),
                Step(
                    highlight: CGRect(x: 18, y: 426, width: 354, height: 130),
                    messages: [
                        ("스와이프로 질문카드도 확인할 수 있어요!", CGPoint(x: 230, y: 400)),
                        ("우리 가족의 답변을 바탕으로\n매주 한 개의 미션이 발행돼요!", CGPoint(x: 270, y: 610))
                    ]
                ),
                Step(
                    highlight: CGRect(x: 18, y: 640, width: 354, height: 30),
                    messages: [
                        ("끼리가 큐레이팅 한 미션 목록!", CGPoint(x: 150, y: 700))
                    ]
                )
            ]
        }
    }

    private var currentStep: Step {
        steps[min(stepIndex, steps.count - 1)]
    }

    var body: some View {
        GeometryReader { geometry in
            let scale = geometry.size.width / 390
            let highlight = CGRect(
                x: currentStep.highlight.origin.x * scale,
                y: currentStep.highlight.origin.y * scale,
                width: currentStep.highlight.width * scale,
                height: currentStep.highlight.height * scale
            )

            ZStack {
                TutorialDimMask(hole: highlight)
                    .fill(Color.black.opacity(0.72), style: FillStyle(eoFill: true))
                    .ignoresSafeArea()

                RoundedRectangle(cornerRadius: 8)
                    .stroke(KIRIColor.Primary.default, lineWidth: 1)
                    .frame(width: highlight.width, height: highlight.height)
                    .position(x: highlight.midX, y: highlight.midY)

                ForEach(Array(currentStep.messages.enumerated()), id: \.offset) { _, message in
                    Text(message.text)
                        .font(KIRITypography.body)
                        .foregroundStyle(KIRIColor.Text.strong)
                        .multilineTextAlignment(.center)
                        .position(
                            x: message.position.x * scale,
                            y: message.position.y * scale
                        )
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 24)
                    .onEnded { value in
                        guard value.translation.width < -24 else { return }
                        advance()
                    }
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("홈 튜토리얼")
            .accessibilityHint("왼쪽으로 쓸어 다음 안내를 확인하세요")
        }
        .ignoresSafeArea()
    }

    private func advance() {
        if stepIndex == steps.count - 1 {
            onComplete()
        } else {
            stepIndex += 1
        }
    }
}

private struct TutorialDimMask: Shape {
    let hole: CGRect

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)
        path.addRoundedRect(in: hole, cornerSize: CGSize(width: 8, height: 8))
        return path
    }
}
