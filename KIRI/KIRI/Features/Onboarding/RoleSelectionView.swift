
import SwiftUI

enum FamilyRole: String, CaseIterable, Hashable {
    case mom
    case dad
    case daughter
    case son

    var koreanName: String {
        switch self {
        case .mom:
            return "엄마"
        case .dad:
            return "아빠"
        case .daughter:
            return "딸"
        case .son:
            return "아들"
        }
    }

    var englishName: String {
        switch self {
        case .mom:
            return "Mom"
        case .dad:
            return "Dad"
        case .daughter:
            return "Daughter"
        case .son:
            return "Son"
        }
    }
}

struct RoleSelectionView: View {
    let nickname: String

    @Binding var selectedRole: FamilyRole?

    let onBack: () -> Void
    let onNext: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 0) {
            header

            VStack(alignment: .leading, spacing: 0) {
                Text("\(nickname)님의\n역할을 선택해주세요.")
                    .font(KIRITypography.title)
                    .foregroundStyle(KIRIColor.textPrimary)
                    .lineSpacing(7)

                Text("가족 안에서의 역할을 선택해주세요!")
                    .font(KIRITypography.subtitle)
                    .foregroundStyle(KIRIColor.textSecondary)
                    .padding(.top, 12)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(FamilyRole.allCases, id: \.self) { role in
                        roleCard(role)
                    }
                }
                .padding(.horizontal, 25)
                .padding(.top, 55)

                Spacer()

                if selectedRole != nil {
                    KIRIPrimaryButton(
                        title: "다음",
                        action: onNext
                    )
                }
            }
            .padding(.horizontal, KIRISpacing.horizontal)
            .padding(.bottom, 10)
        }
        .background(KIRIColor.background)
    }

    private var header: some View {
        HStack {
            KIRIBackButton(action: onBack)

            Spacer()
        }
        .padding(.horizontal, 4)
        .frame(height: 70)
    }

    private func roleCard(_ role: FamilyRole) -> some View {
        let isSelected = selectedRole == role

        return Button {
            selectedRole = role
        } label: {
            VStack(spacing: 14) {
                Text(role.koreanName)
                    .font(KIRITypography.roleKorean)

                Text(role.englishName)
                    .font(KIRITypography.roleEnglish)
            }
            .foregroundStyle(
                isSelected
                    ? KIRIColor.selectedText
                    : KIRIColor.textSecondary
            )
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(
                isSelected
                    ? KIRIColor.selectedBackground
                    : KIRIColor.surface
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: KIRIRadius.xLarge
                )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var role: FamilyRole? = .dad

    RoleSelectionView(
        nickname: "주연주",
        selectedRole: $role,
        onBack: {},
        onNext: {}
    )
    .background(KIRIColor.background)
}
