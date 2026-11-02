//
// MARK: - 파일 가이드
// 파일: Features/Record/Schedule/ConditionAdjustmentSheet.swift
// 담당 영역: 기능별 SwiftUI 화면과 상태
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//


import SwiftUI

struct ConditionAdjustmentSheet: View {

    enum Condition: String, CaseIterable, Hashable {
        case lessWalking
        case moreRest
        case lowerBudget
        case avoidCrowds

        var title: String {
            switch self {
            case .lessWalking:
                return "걸음수를\n낮춰주세요"
            case .moreRest:
                return "휴식 시간을\n늘려주세요"
            case .lowerBudget:
                return "예산을\n낮춰주세요"
            case .avoidCrowds:
                return "사람 많은 곳은\n피해주세요"
            }
        }

        var icon: String {
            switch self {
            case .lessWalking:
                return "figure.walk"
            case .moreRest:
                return "cup.and.saucer"
            case .lowerBudget:
                return "wallet.pass"
            case .avoidCrowds:
                return "person.2"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss

    let selectedConditions: Set<Condition>
    let onApply: (Set<Condition>) -> Void

    var activityTitle: String = "한강 뚜벅뚜벅 축제 방문"
    var expectedSteps: String = "8000보"
    var activityDuration: String = "8시간"

    @State private var selection: Set<Condition> = []

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                navigationBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        titleSection
                            .padding(.top, 28)

                        conditionSection
                            .padding(.top, 57)
                    }
                    .frame(maxWidth: .infinity)
                }

                applyButton
                    .padding(.horizontal, 18)
                    .padding(.bottom, 24)
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
            .background(KIRIColor.Background.base)
        }
        .onAppear {
            selection = selectedConditions
        }
    }

    // MARK: - Navigation

    private var navigationBar: some View {
        ZStack {
            Text("컨디션 커스텀")
                .font(KIRITypography.headingSmall)
                .tracking(-0.72)
                .foregroundStyle(KIRIColor.Text.strong)

            HStack {
                KIRIBackButton {
                    dismiss()
                }

                Spacer()
            }
        }
        .frame(height: 62)
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(spacing: 5) {
            Text("컨디션 조정이 필요하신가요?")
                .font(KIRITypography.body)
                .tracking(-0.64)
                .foregroundStyle(KIRIColor.Text.secondary)

            Text(activityTitle)
                .font(KIRITypography.title)
                .tracking(-0.56)
                .foregroundStyle(KIRIColor.Text.strong)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 30)
    }

    // MARK: - Conditions

    private var conditionSection: some View {
        VStack(spacing: 21) {
            activityInformation

            LazyVGrid(
                columns: columns,
                spacing: 16
            ) {
                ForEach(Condition.allCases, id: \.self) { condition in
                    selectionCard(condition)
                }
            }
        }
        .padding(.horizontal, 36)
    }

    private var activityInformation: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                Text("예상 걸음수")
                Text(expectedSteps)
            }

            Text("·")

            HStack(spacing: 4) {
                Text("활동시간")
                Text(activityDuration)
            }
        }
        .font(KIRITypography.body)
        .tracking(-0.64)
        .foregroundStyle(KIRIColor.Text.primary)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }

    private func selectionCard(
        _ condition: Condition
    ) -> some View {
        let isSelected = selection.contains(condition)

        return Button {
            if isSelected {
                selection.remove(condition)
            } else {
                selection.insert(condition)
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: condition.icon)
                    .font(.system(size: 29, weight: .light))
                    .foregroundStyle(
                        isSelected
                            ? KIRIColor.Primary.default
                            : KIRIColor.Text.secondary
                    )
                    .frame(width: 44, height: 44)

                Text(condition.title)
                    .font(KIRITypography.bodyMedium)
                    .tracking(-0.64)
                    .foregroundStyle(
                        isSelected
                            ? KIRIColor.Text.strong
                            : KIRIColor.Text.primary
                    )
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }
            .frame(maxWidth: .infinity)
            .frame(height: 149.5)
            .background(
                isSelected
                    ? KIRIColor.Background.tertiary
                    : KIRIColor.Background.secondary
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 8)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected
                            ? KIRIColor.Primary.default
                            : Color.clear,
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(
            isSelected ? .isSelected : []
        )
    }

    // MARK: - Apply

    private var applyButton: some View {
        Button {
            onApply(selection)
            dismiss()
        } label: {
            Text("커스텀 적용하기")
                .font(KIRITypography.headingSmall)
                .tracking(-0.72)
                .foregroundStyle(KIRIColor.Text.strong)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    KIRIColor.Background.secondary
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 8)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview("컨디션 커스텀") {
    ConditionAdjustmentSheet(
        selectedConditions: []
    ) { _ in }
}
