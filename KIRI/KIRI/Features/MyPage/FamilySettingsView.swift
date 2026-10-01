
import SwiftUI

struct FamilySettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var familyName = "끼리네 가족"
    @State private var nickname = "쥬123"

    private let members: [FamilyMember] = [
        FamilyMember(role: "딸", nickname: "쥬123", isMe: true),
        FamilyMember(role: "아들", nickname: "첫째", isMe: false),
        FamilyMember(role: "엄마", nickname: "마마", isMe: false),
        FamilyMember(role: "아들", nickname: "첫째", isMe: false),
        FamilyMember(role: "아들", nickname: "첫째", isMe: false),
        FamilyMember(role: "엄마", nickname: "마마", isMe: false)
    ]

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
                        .padding(.top, 38)

                    familyMemberSection
                        .padding(.top, 54)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 18)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
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
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(KIRIColor.textPrimary)

                Spacer()

                Text(familyName)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(KIRIColor.textPrimary)

                NavigationLink {
                    FamilyNameEditView(
                        familyName: $familyName
                    )
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(
                            Color.white.opacity(0.5)
                        )
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .frame(height: 58)
            .background(
                RoundedRectangle(
                    cornerRadius: 8,
                    style: .continuous
                )
                .fill(Color.white.opacity(0.07))
            )
        }
    }

    // MARK: - Family Members

    private var familyMemberSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("가족 구성원 관리")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(KIRIColor.textPrimary)

            LazyVGrid(
                columns: columns,
                spacing: 12
            ) {
                ForEach(members) { member in
                    memberCard(member)
                }
            }
        }
    }

    private func memberCard(
        _ member: FamilyMember
    ) -> some View {
        VStack(spacing: 8) {
            Text("역할 | \(member.role)")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(KIRIColor.textPrimary)

            HStack(spacing: 5) {
                Text(
                    member.isMe
                    ? nickname
                    : member.nickname
                )
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(KIRIColor.textPrimary)

                if member.isMe {
                    NavigationLink {
                        NicknameEditView(
                            nickname: $nickname
                        )
                    } label: {
                        Image(systemName: "pencil")
                            .font(
                                .system(
                                    size: 14,
                                    weight: .semibold
                                )
                            )
                            .foregroundStyle(
                                Color.white.opacity(0.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 74)
        .background(
            RoundedRectangle(
                cornerRadius: 8,
                style: .continuous
            )
            .fill(Color.white.opacity(0.07))
        )
    }
}

// MARK: - Model

private struct FamilyMember: Identifiable {
    let id = UUID()
    let role: String
    let nickname: String
    let isMe: Bool
}

#Preview {
    NavigationStack {
        FamilySettingsView()
    }
}
