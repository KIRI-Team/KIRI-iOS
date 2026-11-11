//
// MARK: - 파일 가이드
// 파일: Features/Onboarding/RoleSelectionView.swift
// 담당 영역: 기능별 SwiftUI 화면과 상태
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//


import SwiftUI

enum FamilyRole: String, CaseIterable, Hashable {
    case mom
    case dad
    case daughter
    case son

    var apiValue: String {
        switch self {
        case .mom: return "MOTHER"
        case .dad: return "FATHER"
        case .daughter: return "DAUGHTER"
        case .son: return "SON"
        }
    }

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

    var assetName: String {
        switch self {
        case .mom: return "role_mom"
        case .dad: return "role_dad"
        case .daughter: return "role_daughter"
        case .son: return "role_son"
        }
    }
}

struct RoleSelectionView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
            VStack(spacing: 12) {
                Image(role.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    // 역할별 원본 PNG를 유지하면서 선택 상태만 표현합니다.
                    // 선택 해제 시 캐릭터별 실루엣을 보존한 회색 처리,
                    // 선택 시 기존 원본 색상(아빠·엄마·아들은 초록 계열)을 사용합니다.
                    .grayscale(isSelected ? 0 : 1)
                    .colorMultiply(
                        isSelected && role != .daughter
                            ? KIRIColor.Primitive.green500
                            : .white
                    )

                Text(role.koreanName)
                    .font(KIRITypography.roleKorean)
            }
            .foregroundStyle(
                isSelected
                    ? KIRIColor.Text.accent
                    : KIRIColor.Text.disabled
            )
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(
                isSelected
                    ? KIRIColor.Primitive.alphaGreen16
                    : KIRIColor.Background.primary
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: KIRIRadius.xLarge
                )
            )
        }
        .buttonStyle(.plain)
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 0.2),
            value: isSelected
        )
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
