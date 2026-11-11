//
// MARK: - 파일 가이드
// 파일: Features/Home/HomeTutorialView.swift
// 담당 영역: 기능별 SwiftUI 화면과 상태
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//

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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
        ZStack(alignment: .topLeading) {
            // 실제 FamilyHomeView를 그대로 뒤에 두고, 튜토리얼 요소만 오버레이합니다.
            // Figma 화면 전체를 이미지로 덮지 않으므로 구성원 수·기기 높이에 맞춰
            // PreferenceKey로 측정한 실제 컴포넌트 위치를 사용합니다.
            KIRIColor.Primitive.neutral1000.opacity(0.68)
                .ignoresSafeArea()

            highlights
            guidance

            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 24)
                        .onEnded { value in
                            guard value.translation.width < -24 else { return }
                            advance()
                        }
                )
                .onTapGesture { advance() }
                .ignoresSafeArea()
        }
        .onAppear {
            stepIndex = 0
            onStepChanged(0)
        }
        .onChange(of: mode) { _, _ in
            stepIndex = 0
            onStepChanged(0)
        }
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 0.3),
            value: stepIndex
        )
    }

    @ViewBuilder
    private var highlights: some View {
        switch stepIndex {
        case 0:
            highlight(.answerCollection)
        case 1:
            highlight(.questionMissionCard)
        default:
            highlight(.recommendationTitle, size: CGSize(width: 160, height: 37))
        }
    }

    @ViewBuilder
    private var guidance: some View {
        switch stepIndex {
        case 0:
            guidanceText("우리 가족들의\n답변을 모아봐요!", anchoredTo: .answerCollection, placement: .below)
        case 1:
            guidanceText("질문은 매일 하나씩 발행돼요!", anchoredTo: .questionMissionCard, placement: .below)
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
