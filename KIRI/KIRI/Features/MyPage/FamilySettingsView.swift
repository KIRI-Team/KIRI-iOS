//
// MARK: - 파일 가이드
// 파일: Features/MyPage/FamilySettingsView.swift
// 담당 영역: 기능별 SwiftUI 화면과 상태
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//


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
                        .padding(.top, 38)

                    familyMemberSection
                        .padding(.top, 54)

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
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(KIRIColor.textPrimary)

                Spacer()

                Text(familyName)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(KIRIColor.textPrimary)

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

    private var editIcon: some View {
        Image(systemName: "pencil")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Color.white.opacity(0.5))
            .frame(width: 30, height: 30)
    }

    // MARK: - Family Members

    private var familyMemberSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("가족 구성원 관리")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(KIRIColor.textPrimary)

            if familyId == nil {
                Text("가족 구성원 정보를 확인할 수 없습니다.")
                    .font(KIRITypography.bodyMedium)
                    .foregroundStyle(KIRIColor.textSecondary)
            } else {
                memberCard(role: familyRole ?? "", nickname: nickname)
            }
        }
    }

    private func memberCard(role: String, nickname: String) -> some View {
        VStack(spacing: 8) {
                Text("역할 | \(role)")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(KIRIColor.textPrimary)

            HStack(spacing: 5) {
                Text(
                    nickname
                )
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(KIRIColor.textPrimary)

                if !nickname.isEmpty {
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

#Preview {
    NavigationStack {
        FamilySettingsView(familyId: 1, familyName: "끼리네 가족", nickname: "쥬123", familyRole: "딸")
    }
}
