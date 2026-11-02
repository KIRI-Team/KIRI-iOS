
import SwiftUI

struct FamilySettingsView: View {
    @Environment(\.dismiss) private var dismiss

    let familyId: Int?
    let initialFamilyName: String?
    let initialNickname: String?
    let familyRole: String?
    let onUpdateFamilyName: (String) async -> String?

    @State private var familyName: String
    @State private var nickname: String
    @State private var isLeaveAlertPresented = false

    init(
        familyId: Int? = nil,
        familyName: String? = nil,
        nickname: String? = nil,
        familyRole: String? = nil,
        onUpdateFamilyName: @escaping (String) async -> String? = { _ in nil }
    ) {
        self.familyId = familyId
        self.initialFamilyName = familyName
        self.initialNickname = nickname
        self.familyRole = familyRole
        self.onUpdateFamilyName = onUpdateFamilyName
        _familyName = State(initialValue: familyName ?? "")
        _nickname = State(initialValue: nickname ?? "")
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            KIRIColor.background
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    header

                    familyNameSection
                        .padding(.top, 36)

                    familyMemberSection
                        .padding(.top, 52)

                    Button {
                        isLeaveAlertPresented = true
                    } label: {
                        Text("가족공간 나가기")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(KIRIColor.Status.error)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 28)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 18)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert("가족공간을 나갈까요?", isPresented: $isLeaveAlertPresented) {
            Button("취소", role: .cancel) {}
            Button("나가기", role: .destructive) {}
        } message: {
            Text("가족과 함께한 기록은 유지될 수 있습니다.")
        }
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            Text("가족 기본 설정")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(KIRIColor.textPrimary)

            HStack {
                KIRIBackButton {
                    dismiss()
                }

                Spacer()
            }
        }
        .frame(height: 52)
    }

    // MARK: - Family Name

    private var familyNameSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("가족 닉네임 관리")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(KIRIColor.textPrimary)

            HStack {
                Text("현재 가족 이름")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(KIRIColor.Text.primary)

                Spacer()

                Text(familyName)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(KIRIColor.Text.strong)

                Group {
                    if familyId != nil {
                        NavigationLink {
                            FamilyNameEditView(familyName: $familyName, onSave: onUpdateFamilyName)
                        } label: {
                            editIcon
                        }
                    } else {
                        editIcon.opacity(0.35)
                    }
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 60)
            .background(
                RoundedRectangle(
                    cornerRadius: 8,
                    style: .continuous
                )
                .fill(KIRIColor.Background.primary)
            )
        }
    }

    private var editIcon: some View {
        Image(systemName: "pencil")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Color.white.opacity(0.5))
            .frame(width: 30, height: 30)
    }

    // MARK: - Family Members

    private var familyMemberSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("가족 구성원 관리")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(KIRIColor.textPrimary)

            if familyId == nil {
                Text("가족 구성원 정보를 확인할 수 없습니다.")
                    .font(KIRITypography.bodyMedium)
                    .foregroundStyle(KIRIColor.Text.secondary)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    memberCard(role: familyRole ?? "", nickname: nickname, isCurrentUser: true)
                }
            }
        }
    }

    private func memberCard(role: String, nickname memberNickname: String, isCurrentUser: Bool) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Text("역할 I \(localizedRole(role))")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(KIRIColor.Text.primary)
                    .lineLimit(1)
                if isCurrentUser {
                    NavigationLink {
                        NicknameEditView(nickname: Binding(
                            get: { self.nickname },
                            set: { self.nickname = $0 }
                        ))
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(KIRIColor.Icon.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(memberNickname.isEmpty ? "닉네임 미설정" : memberNickname)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(KIRIColor.Text.strong)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(minHeight: 73)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(KIRIColor.Background.primary)
        )
    }

    private func localizedRole(_ role: String) -> String {
        switch role.uppercased() {
        case "MOTHER": return "엄마"
        case "FATHER": return "아빠"
        case "SON": return "아들"
        case "DAUGHTER": return "딸"
        default: return role.isEmpty ? "미설정" : role
        }
    }

}

#Preview {
    NavigationStack {
        FamilySettingsView(familyId: 1, familyName: "끼리네 가족", nickname: "쥬123", familyRole: "딸")
    }
}
