import SwiftUI

/// Figma 9173:13678의 홈 튜토리얼 오버레이.
/// 실제 홈 화면 위에 단계별 dim 처리와 강조 영역을 표시한다.
struct HomeTutorialView: View {
    enum Mode {
        case browse
        case family
    }

    private struct Highlight {
        let rect: CGRect
        let isCircle: Bool
    }

    private struct Callout {
        let text: String
        let rect: CGRect
    }

    private struct Step {
        let highlights: [Highlight]
        let callouts: [Callout]
    }

    let mode: Mode
    let onComplete: () -> Void

    @State private var stepIndex = 0

    // Figma uses the same three visual steps for both entry modes. Mode stays
    // in the API so RootView can persist browse and family completion separately.
    private let steps: [Step] = [
        Step(
            // 9167:10656, 9173:12347, 9173:12349
            highlights: [
                Highlight(rect: CGRect(x: 14, y: 140, width: 105, height: 54), isCircle: false),
                Highlight(rect: CGRect(x: 267, y: 139, width: 105, height: 54), isCircle: false),
                Highlight(rect: CGRect(x: 14, y: 347, width: 358, height: 130), isCircle: false)
            ],
            callouts: [
                Callout(text: "우리 가족들의\n답변을 모아봐요!", rect: CGRect(x: 14, y: 203, width: 113, height: 54)),
                Callout(text: "가족을 초대해서\n방을 만들어요!", rect: CGRect(x: 260, y: 203, width: 112, height: 54)),
                Callout(text: "질문은 매일 하나씩 발행돼요!", rect: CGRect(x: 178, y: 493, width: 194, height: 27))
            ]
        ),
        Step(
            // 9173:12439, 9173:13145
            highlights: [
                Highlight(rect: CGRect(x: 14, y: 347, width: 358, height: 130), isCircle: false),
                Highlight(rect: CGRect(x: 332, y: 359, width: 33, height: 33), isCircle: true)
            ],
            callouts: [
                Callout(text: "스와이프로 질문카드도 확인할 수 있어요!", rect: CGRect(x: 100, y: 302, width: 272, height: 27)),
                Callout(text: "우리 가족의 답변을 바탕으로\n매주 한 개의 미션이 발행돼요!", rect: CGRect(x: 174, y: 493, width: 198, height: 54))
            ]
        ),
        Step(
            // 9173:13412
            highlights: [
                Highlight(rect: CGRect(x: 14, y: 520, width: 160, height: 37), isCircle: false)
            ],
            callouts: [
                Callout(text: "끼리가 큐레이팅 한 미션 목록!", rect: CGRect(x: 14, y: 574, width: 198, height: 27))
            ]
        )
    ]

    var body: some View {
        GeometryReader { geometry in
            let scale = geometry.size.width / 390
            let currentStep = steps[stepIndex]
            let holes = currentStep.highlights.map { scaleRect($0.rect, by: scale) }

            ZStack {
                TutorialDimMask(holes: holes)
                    .fill(
                        Color.black.opacity(0.72),
                        style: FillStyle(eoFill: true)
                    )
                    .ignoresSafeArea()

                ForEach(Array(currentStep.highlights.enumerated()), id: \.offset) { _, highlight in
                    let rect = scaleRect(highlight.rect, by: scale)

                    if highlight.isCircle {
                        Circle()
                            .stroke(KIRIColor.Primary.default, lineWidth: 1)
                            .frame(width: rect.width, height: rect.height)
                            .position(x: rect.midX, y: rect.midY)
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(KIRIColor.Primary.default, lineWidth: 1)
                            .frame(width: rect.width, height: rect.height)
                            .position(x: rect.midX, y: rect.midY)
                    }
                }

                ForEach(Array(currentStep.callouts.enumerated()), id: \.offset) { _, callout in
                    let rect = scaleRect(callout.rect, by: scale)

                    Text(callout.text)
                        .font(KIRITypography.headingSmall)
                        .foregroundStyle(KIRIColor.Text.strong)
                        .multilineTextAlignment(.center)
                        .lineSpacing(0)
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
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
            .accessibilityLabel("홈 튜토리얼 단계 \(stepIndex + 1) / \(steps.count)")
            .accessibilityHint("왼쪽으로 쓸어 다음 안내를 확인하세요")
        }
        .ignoresSafeArea()
    }

    private func scaleRect(_ rect: CGRect, by scale: CGFloat) -> CGRect {
        CGRect(
            x: rect.origin.x * scale,
            y: rect.origin.y * scale,
            width: rect.width * scale,
            height: rect.height * scale
        )
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
    let holes: [CGRect]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)

        for hole in holes {
            path.addRoundedRect(
                in: hole,
                cornerSize: CGSize(width: 8, height: 8)
            )
        }

        return path
    }
}
