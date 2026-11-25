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

    /// 각 단계의 실제 홈 컴포넌트가 측정된 뒤에만 오버레이를 그립니다.
    /// 측정 중에는 홈을 그대로 보여 주어 다음 강조 위치를 계산하는 동안
    /// 검은 화면만 남는 순간이 생기지 않게 합니다.
    private var requiredTargets: [HomeTutorialTarget] {
        switch stepIndex {
        case 0:
            return [.answerCollection, .invite, .questionMissionCard]
        case 1:
            return [.questionMissionCard, .missionRefresh]
        default:
            return [.recommendationTitle]
        }
    }

    private var isReadyForStep: Bool {
        requiredTargets.allSatisfy { frames[$0] != nil }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // 실제 FamilyHomeView를 그대로 뒤에 두고, 튜토리얼 요소만 오버레이합니다.
            // Figma 화면 전체를 이미지로 덮지 않으므로 구성원 수·기기 높이에 맞춰
            // PreferenceKey로 측정한 실제 컴포넌트 위치를 사용합니다.
            if isReadyForStep {
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
            } else {
                // 홈 콘텐츠가 이미 렌더링된 상태를 유지하고, 프레임 측정이
                // 끝날 때까지 투명한 레이어만 둡니다.
                Color.clear.ignoresSafeArea()
            }
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
            highlight(.invite)
            highlight(.questionMissionCard)
        case 1:
            highlight(.questionMissionCard)
            highlight(.missionRefresh)
        default:
            highlight(.recommendationTitle, size: CGSize(width: 160, height: 37))
        }
    }

    @ViewBuilder
    private var guidance: some View {
        switch stepIndex {
        case 0:
            guidanceText("우리 가족들의\n답변을 모아봐요!", anchoredTo: .answerCollection, placement: .below)
            guidanceText("가족을 초대해서\n방을 만들어요!", anchoredTo: .invite, placement: .above)
            guidanceText("질문은 매일 하나씩 발행돼요!", anchoredTo: .questionMissionCard, placement: .below)
        case 1:
            guidanceText(
                "스와이프로 질문카드도 확인할 수 있어요!",
                anchoredTo: .missionRefresh,
                placement: .above
            )
            guidanceText(
                "우리 가족의 답변을 바탕으로\n매주 한 개의 미션이 발행돼요!",
                anchoredTo: .questionMissionCard,
                placement: .below
            )
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
            ZStack {
                Text(text)
                    .kiriTextStyle(KIRITypography.titleLarge)
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

                // 실제 홈 프레임을 기준으로 안내 방향을 표시합니다. 화면 전체를
                // 이미지로 덮지 않고 대상 컴포넌트가 움직이면 함께 이동합니다.
                Image(systemName: placement == .above ? "arrow.down" : "arrow.up")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(KIRIColor.Primary.default)
                    .position(
                        x: rect.midX,
                        y: placement == .above
                            ? rect.minY - 12
                            : rect.maxY + 12
                    )
            }
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
