import SwiftUI

enum HomeTutorialTarget: Hashable {
    case answerCollection
    case invite
    case questionMissionCard
    case missionRefresh
    case recommendationTitle
}

struct HomeTutorialFramePreferenceKey: PreferenceKey {
    static let defaultValue: [HomeTutorialTarget: CGRect] = [:]

    static func reduce(
        value: inout [HomeTutorialTarget: CGRect],
        nextValue: () -> [HomeTutorialTarget: CGRect]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

extension View {
    func homeTutorialMeasured(_ target: HomeTutorialTarget) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: HomeTutorialFramePreferenceKey.self,
                    value: [target: proxy.frame(in: .named("homeTutorial"))]
                )
            }
        )
    }
}

/// Figma 튜토리얼 섹션의 홈 화면 위 안내 레이어를 실제 SwiftUI 컴포넌트에 맞춰 표시합니다.
/// 전체 화면 PNG를 사용하지 않으며, 강조 위치는 FamilyHomeView가 측정한 bounds를 사용합니다.
struct HomeTutorialView: View {
    enum Mode: Equatable {
        case browse
        case family
    }

    let mode: Mode
    let frames: [HomeTutorialTarget: CGRect]
    let onComplete: () -> Void
    let onStepChanged: (Int) -> Void

    @State private var stepIndex = 0
    @State private var isAdvancing = false

    var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .topLeading) {
                Color(red: 0.102, green: 0.102, blue: 0.102)
                    .opacity(0.75)
                    .ignoresSafeArea()

                highlights
                guidance
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 24)
                    .onEnded { value in
                        guard value.translation.width < -24 else { return }
                        advance()
                    }
            )
            .onTapGesture {
                advance()
            }
        }
        .ignoresSafeArea()
        .onAppear {
            stepIndex = 0
            onStepChanged(0)
        }
        .onChange(of: mode) { _, _ in
            stepIndex = 0
            onStepChanged(0)
        }
        .animation(.easeInOut(duration: 0.3), value: stepIndex)
    }

    @ViewBuilder
    private var highlights: some View {
        switch stepIndex {
        case 0:
            highlight(.answerCollection, size: CGSize(width: 105, height: 54))
            highlight(.invite, size: CGSize(width: 105, height: 54))
            highlight(.questionMissionCard)
        case 1:
            highlight(.questionMissionCard)
            highlight(.missionRefresh, size: CGSize(width: 33, height: 33))
        default:
            highlight(.recommendationTitle, size: CGSize(width: 160, height: 37))
        }
    }

    @ViewBuilder
    private var guidance: some View {
        switch stepIndex {
        case 0:
            guidanceText("우리 가족들의\n답변을 모아봐요!", anchoredTo: .answerCollection, placement: .below)
            guidanceText("가족을 초대해서\n방을 만들어요!", anchoredTo: .invite, placement: .below)
            guidanceText("질문은 매일 하나씩 발행돼요!", anchoredTo: .questionMissionCard, placement: .below)
        case 1:
            guidanceText("스와이프로 질문카드도 확인할 수 있어요!", anchoredTo: .questionMissionCard, placement: .above)
            guidanceText("우리 가족의 답변을 바탕으로\n매주 한 개의 미션이 발행돼요!", anchoredTo: .questionMissionCard, placement: .below)
        default:
            guidanceText("끼리가 큐레이팅 한 미션 목록!", anchoredTo: .recommendationTitle, placement: .below)
        }
    }

    @ViewBuilder
    private func highlight(
        _ target: HomeTutorialTarget,
        size: CGSize? = nil
    ) -> some View {
        if let rect = frames[target] {
            let highlightRect = size.map {
                CGRect(
                    x: rect.midX - ($0.width / 2),
                    y: rect.midY - ($0.height / 2),
                    width: $0.width,
                    height: $0.height
                )
            } ?? rect

            RoundedRectangle(cornerRadius: target == .missionRefresh ? 100 : 8)
                .fill(KIRIColor.Primary.default.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: target == .missionRefresh ? 100 : 8)
                        .stroke(KIRIColor.Primary.default.opacity(0.7), lineWidth: 1)
                )
                .frame(width: highlightRect.width, height: highlightRect.height)
                .position(x: highlightRect.midX, y: highlightRect.midY)
        }
    }

    @ViewBuilder
    private func guidanceText(
        _ text: String,
        anchoredTo target: HomeTutorialTarget,
        placement: GuidancePlacement
    ) -> some View {
        if let rect = frames[target] {
            Text(text)
                .font(KIRITypography.headingSmall)
                .tracking(-0.72)
                .multilineTextAlignment(target == .invite ? .trailing : .leading)
                .foregroundStyle(KIRIColor.Text.primary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: placement.maxWidth)
                .position(
                    x: rect.midX,
                    y: placement == .above
                        ? rect.minY - placement.verticalGap
                        : rect.maxY + placement.verticalGap
                )
        }
    }

    private enum GuidancePlacement: Equatable {
        case above
        case below

        var maxWidth: CGFloat {
            switch self {
            case .above: return 272
            case .below: return 220
            }
        }

        var verticalGap: CGFloat {
            switch self {
            case .above: return 22
            case .below: return 30
            }
        }
    }

    private func advance() {
        guard !isAdvancing else { return }
        isAdvancing = true

        if stepIndex == 2 {
            onComplete()
        } else {
            stepIndex += 1
            onStepChanged(stepIndex)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isAdvancing = false
            }
        }
    }
}
