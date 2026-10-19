import SwiftUI
import UIKit

/// Figma에서 내보낸 390×844 튜토리얼 화면을 그대로 표시한다.
/// 강조, 딤, 안내 문구는 이미지에 포함되어 있으므로 SwiftUI에서 다시 그리지 않는다.
struct HomeTutorialView: View {
    enum Mode: Equatable {
        case browse
        case family
    }

    let mode: Mode
    let onComplete: () -> Void
    let onStepChanged: (Int) -> Void

    @State private var stepIndex = 0
    @State private var isAdvancing = false

    private let imageNames = [
        "홈 튜토리얼 1",
        "홈 튜토리얼 2",
        "홈 튜토리얼 3"
    ]

    var body: some View {
        ZStack {
            KIRIColor.Background.base
                .ignoresSafeArea()

            if let image = tutorialImage(for: stepIndex) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .id(stepIndex)
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        )
                    )
            }
        }
        .overlay(alignment: .bottom) {
            tutorialControls
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
        .animation(.easeOut(duration: 0.3), value: stepIndex)
        .onAppear {
            #if DEBUG
            print(
                "[KIRI TutorialDebug][ImageTutorial] onAppear " +
                "mode=\(String(describing: mode)) " +
                "step=\(stepIndex + 1) " +
                "image=\(imageNames[stepIndex]) " +
                "loaded=\(tutorialImage(for: stepIndex) != nil)"
            )
            #endif
        }
        .ignoresSafeArea()
        .onAppear {
            onStepChanged(stepIndex)
        }
    }

    /// PNG에 포함된 홈 콘텐츠와 안내 레이어는 그대로 보존하고,
    /// 단계 진행에 필요한 컨트롤만 화면 하단에 추가한다.
    private var tutorialControls: some View {
        VStack(spacing: 10) {
            Text("\(stepIndex + 1) / 3")
                .font(KIRITypography.caption)
                .foregroundStyle(KIRIColor.Text.secondary)

            KIRIPrimaryButton(
                title: stepIndex == imageNames.count - 1 ? "시작하기" : "다음",
                action: advance
            )
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .safeAreaPadding(.bottom, 8)
        .background(
            KIRIColor.Background.base.opacity(0.94)
        )
    }

    private func tutorialImage(for index: Int) -> UIImage? {
        guard imageNames.indices.contains(index) else { return nil }
        let name = imageNames[index]

        // Xcode의 파일 시스템 동기화 그룹에서 복사된 원본 PNG를 우선 읽고,
        // 이미지 이름 조회를 보조 경로로 사용한다. 파일명은 한글과 공백을 보존한다.
        if let path = Bundle.main.path(forResource: name, ofType: "png"),
           let image = UIImage(contentsOfFile: path) {
            return image
        }
        return UIImage(named: name)
    }

    private func advance() {
        guard !isAdvancing else { return }
        isAdvancing = true

        if stepIndex == imageNames.count - 1 {
            onComplete()
        } else {
            stepIndex += 1
            onStepChanged(stepIndex)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                isAdvancing = false
            }
        }
    }
}
