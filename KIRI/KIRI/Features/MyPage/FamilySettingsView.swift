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
    @Environment(\.kiriTabBarVisibility) private var tabBarVisibility
    @Environment(\.kiriTabBarSubscreenCount) private var tabBarSubscreenCount
    @State private var didRegisterSubscreen = false

    let familyId: Int?
    let initialFamilyName: String?
    let initialNickname: String?
    let familyRole: String?
    let currentMemberId: Int?
    let onUpdateFamilyName: (String) async -> String?
    let onUpdateNickname: (String) async -> String?

    @State private var familyName: String
    @State private var nickname: String
    @State private var members: [FamilyMemberInfoResult] = []
    @State private var isLoadingMembers = false
    @State private var memberLoadError: String?

    init(
        familyId: Int? = nil,
        familyName: String? = nil,
        nickname: String? = nil,
        familyRole: String? = nil,
        currentMemberId: Int? = AppSessionStore().memberId,
        onUpdateFamilyName: @escaping (String) async -> String? = { _ in nil },
        onUpdateNickname: @escaping (String) async -> String? = { _ in nil }
    ) {
        self.familyId = familyId
        self.initialFamilyName = familyName
        self.initialNickname = nickname
        self.familyRole = familyRole
        self.currentMemberId = currentMemberId
        self.onUpdateFamilyName = onUpdateFamilyName
        self.onUpdateNickname = onUpdateNickname
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

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 18)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            tabBarVisibility.wrappedValue = false
            if !didRegisterSubscreen {
                tabBarSubscreenCount.wrappedValue += 1
                didRegisterSubscreen = true
            }
        }
        .onDisappear {
            if didRegisterSubscreen {
                tabBarSubscreenCount.wrappedValue = max(0, tabBarSubscreenCount.wrappedValue - 1)
                didRegisterSubscreen = false
            }
            tabBarVisibility.wrappedValue = tabBarSubscreenCount.wrappedValue == 0
        }
        .task { await loadFamilyMembers() }
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
        // 마이페이지 공통 수정 아이콘(figma_edit)을 사용합니다.
        // Asset 원본과 동일한 비율을 유지하고 바깥 프레임은 터치 영역으로만 둡니다.
        Image("figma_edit")
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
            .frame(width: 30, height: 30)
    }

    // MARK: - Family Members

    private var familyMemberSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("가족 구성원 관리")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(KIRIColor.textPrimary)

            if isLoadingMembers {
                ProgressView().frame(maxWidth: .infinity)
            } else if let memberLoadError {
                VStack(alignment: .leading, spacing: 8) {
                    Text(memberLoadError).font(KIRITypography.bodyMedium).foregroundStyle(KIRIColor.Text.secondary)
                    Button("다시 시도") { Task { await loadFamilyMembers() } }.foregroundStyle(KIRIColor.Text.accent)
                }
            } else if members.isEmpty {
                Text("가족 구성원 정보를 확인할 수 없습니다.")
                    .font(KIRITypography.bodyMedium)
                    .foregroundStyle(KIRIColor.Text.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(members) { member in
                        memberCard(member: member)
                    }
                }
            }
        }
    }

    private func memberCard(member: FamilyMemberInfoResult) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 4).fill(KIRIColor.Background.secondary)
                Image(memberAsset(for: member.familyRole))
                    .resizable().scaledToFit().padding(4)
            }.frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 0) {
                Text(member.nickname).font(.system(size: 16, weight: .regular)).foregroundStyle(KIRIColor.Text.strong)
                Text(localizedFamilyRole(member.familyRole).isEmpty ? "미설정" : localizedFamilyRole(member.familyRole)).font(.system(size: 12, weight: .medium)).foregroundStyle(KIRIColor.Text.primary)
            }
            Spacer()
            if isCurrentMember(member) {
                NavigationLink {
                    NicknameEditView(
                        nickname: Binding(get: { nickname }, set: { nickname = $0 }),
                        onSave: { value in
                            let snapshot = String(decoding: Array(value.utf8), as: UTF8.self)
                            #if DEBUG
                            print("[KIRI][FamilySettings] nickname callback trace=\(NicknameSaveTrace.id ?? "-") inputLength=\(snapshot.count)")
                            #endif
                            return await onUpdateNickname(snapshot)
                        }
                    )
                } label: {
                    Image("figma_edit").resizable().scaledToFit().frame(width: 18, height: 18).frame(width: 36, height: 36)
                }.buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 8).frame(minHeight: 56)
        .background(RoundedRectangle(cornerRadius: 8).fill(KIRIColor.Background.primary))
    }

    private func memberAsset(for role: String?) -> String {
        switch role?.uppercased() {
        case "MOTHER", "MOM": return "figma_family_member_active_mom"
        case "FATHER", "DAD": return "figma_family_member_active"
        case "SON": return "figma_family_member_active_son"
        case "DAUGHTER": return "figma_family_member_active_daughter"
        default: return "figma_family_member_active"
        }
    }

    private func isCurrentMember(_ member: FamilyMemberInfoResult) -> Bool {
        guard let currentMemberId else { return false }
        return member.memberId == currentMemberId
    }

    private func loadFamilyMembers() async {
        guard let familyId else { return }
        isLoadingMembers = true; memberLoadError = nil
        do { members = try await AuthService.shared.familyInfo(familyId: familyId).members }
        catch { memberLoadError = "가족 구성원 정보를 불러오지 못했어요." }
        isLoadingMembers = false
    }


}

#Preview {
    NavigationStack {
        FamilySettingsView(familyId: 1, familyName: "끼리네 가족", nickname: "쥬123", familyRole: "딸")
    }
}
