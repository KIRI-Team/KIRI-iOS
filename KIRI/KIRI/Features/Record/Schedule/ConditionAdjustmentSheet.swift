

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
                return "걸음 수 낮추기"
            case .moreRest:
                return "휴식 시간 늘리기"
            case .lowerBudget:
                return "예산 낮추기"
            case .avoidCrowds:
                return "사람 많은 곳 피하기"
            }
        }

        var description: String {
            switch self {
            case .lessWalking:
                return "가까운 장소를 우선 추천해요."
            case .moreRest:
                return "카페나 공원처럼 쉴 수 있는 장소를 우선해요."
            case .lowerBudget:
                return "무료 또는 저비용 장소를 우선해요."
            case .avoidCrowds:
                return "혼잡 정보가 확인된 장소만 비교해요."
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
                return "person.2.slash"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss

    let selectedConditions: Set<Condition>
    let onApply: (Set<Condition>) -> Void

    @State private var selection: Set<Condition> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("오늘의 컨디션 조정")
                .font(KIRITypography.headingLarge)
                .foregroundStyle(KIRIColor.Text.strong)
                .padding(.top, 32)

            Text("우리 가족에게 맞게 근처 놀거리 추천을 조정해요.")
                .font(KIRITypography.bodySmall)
                .foregroundStyle(KIRIColor.Text.secondary)
                .padding(.top, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(Condition.allCases, id: \.self) { condition in
                        conditionCard(condition)
                    }
                }
                .padding(.top, 26)
            }

            Button {
                onApply(selection)
                dismiss()
            } label: {
                Text("적용하기")
                    .font(KIRITypography.button)
                    .foregroundStyle(KIRIColor.Text.onGreen)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(KIRIColor.Primary.default)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .padding(.horizontal, 18)
        .background(
            KIRIColor.Background.base.ignoresSafeArea()
        )
        .onAppear {
            selection = selectedConditions
        }
    }

    private func conditionCard(
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
            HStack(spacing: 14) {
                Image(systemName: condition.icon)
                    .font(.system(size: 21))
                    .foregroundStyle(
                        isSelected
                            ? KIRIColor.Primary.default
                            : KIRIColor.Text.secondary
                    )
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 6) {
                    Text(condition.title)
                        .font(KIRITypography.bodyMedium)
                        .foregroundStyle(KIRIColor.Text.strong)

                    Text(condition.description)
                        .font(KIRITypography.bodySmall)
                        .foregroundStyle(KIRIColor.Text.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 4)

                Image(
                    systemName: isSelected
                        ? "checkmark.circle.fill"
                        : "circle"
                )
                .font(.system(size: 22))
                .foregroundStyle(
                    isSelected
                        ? KIRIColor.Primary.default
                        : KIRIColor.Icon.secondary
                )
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(KIRIColor.Background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected
                            ? KIRIColor.Primary.default
                            : Color.clear,
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
    }
}
