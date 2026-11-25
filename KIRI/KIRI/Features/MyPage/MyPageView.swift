//
// MARK: - 파일 가이드
// 파일: Features/MyPage/MyPageView.swift
// 담당 영역: 기능별 SwiftUI 화면과 상태
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//

import SwiftUI

/// Figma 8213:3062. API 연결 전에는 화면 로컬 상태를 사용한다.
struct MyPageView: View {
    @Environment(AppRouter.self) private var router
    let onLogout: () -> Void
    let onDeleteAccount: () async -> String?
    let nickname: String?
    let familyName: String?
    let familyId: Int?
    let familyRole: String?
    let onUpdateFamilyName: (String) async -> String?
    @State private var editedNickname = ""
    @State private var savedFamilyAddress: FamilyAddressUpdateResult?
    @State private var isBrowseFamilyDialogPresented = false
    @State private var isFamilyEntryPresented = false

    var body: some View {
        NavigationStack {
            ZStack {
                KIRIColor.Background.base.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Text("설정")
                            .font(KIRITypography.headingSmall)
                            .foregroundStyle(KIRIColor.Text.strong)
                            .frame(maxWidth: .infinity)
                            .frame(height: 62)
                        profileSection.padding(.top, 10)
                        menuSection(title: "내 설정") {
                            NavigationLink { TasteTestView() } label: { menuRow("내 취향 설정") }
                            NavigationLink { PushNotificationView() } label: { menuRow("알림 설정") }
                        }.padding(.top, 48)
                        menuSection(title: "가족 설정") {
                            if router.userMode == .browse {
                                Button {
                                    isBrowseFamilyDialogPresented = true
                                } label: {
                                    menuRow("가족 기본 설정")
                                }
                                .buttonStyle(.plain)
                            } else {
                                NavigationLink {
                                    FamilySettingsView(
                                        familyId: familyId,
                                        familyName: familyName,
                                        nickname: nickname,
                                        familyRole: familyRole,
                                        onUpdateFamilyName: onUpdateFamilyName
                                    )
                                } label: { menuRow("가족 기본 설정") }
                            }
                            if router.userMode == .browse {
                                Button {
                                    isBrowseFamilyDialogPresented = true
                                } label: {
                                    menuRow("우리집 주소 설정")
                                }
                                .buttonStyle(.plain)

                                Button {
                                    isBrowseFamilyDialogPresented = true
                                } label: {
                                    menuRow("공용초대링크 관리")
                                }
                                .buttonStyle(.plain)
                            } else {
                                NavigationLink {
                                    AddressSettingsView(familyId: familyId, savedAddress: $savedFamilyAddress)
                                } label: { menuRow("우리집 주소 설정") }
                                NavigationLink { InviteLinkView(familyId: familyId) } label: { menuRow("공용초대링크 관리") }
                            }
                        }.padding(.top, 48)
                        menuSection(title: "설정") {
                            NavigationLink { AccountInfoView(onLogout: onLogout, onDeleteAccount: onDeleteAccount) } label: { menuRow("계정 정보") }
                            NavigationLink { SuggestionView() } label: { menuRow("건의함") }
                        }.padding(.top, 48)
                        Color.clear.frame(height: 110)
                    }.padding(.horizontal, 18)
                }
                if isBrowseFamilyDialogPresented {
                    browseFamilyDialog
                        .transition(.opacity)
                        .zIndex(20)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .animation(.easeOut(duration: 0.18), value: isBrowseFamilyDialogPresented)
        .fullScreenCover(isPresented: $isFamilyEntryPresented) {
            BrowseFamilyEntryFlow(
                onDismiss: { isFamilyEntryPresented = false },
                onFamilyCreated: { name, code, familyId in
                    isFamilyEntryPresented = false
                    router.enterFamilyMode(familyName: name, inviteCode: code, familyId: familyId)
                },
                onFamilyJoined: { name, code, joinedFamilyId in
                    isFamilyEntryPresented = false
                    router.enterFamilyMode(familyName: name, inviteCode: code, familyId: joinedFamilyId)
                }
            )
        }
    }

    private var browseFamilyDialog: some View {
        ZStack {
            Color.black.opacity(0.62)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { isBrowseFamilyDialogPresented = false }

            VStack(alignment: .leading, spacing: 0) {
                Text("가족공간이 필요해요")
                    .kiriTextStyle(KIRITypography.headingMediumStyle)
                    .foregroundStyle(KIRIColor.Text.strong)

                Text("가족공간을 만들거나 초대받은 가족공간에 참여하면 가족 설정을 이용할 수 있어요.")
                    .font(KIRITypography.bodySmall)
                    .foregroundStyle(KIRIColor.Text.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)

                HStack(spacing: 10) {
                    Button("취소") {
                        isBrowseFamilyDialogPresented = false
                    }
                    .buttonStyle(MyPageDialogButtonStyle(isPrimary: false))

                    Button("가족공간 만들기") {
                        isBrowseFamilyDialogPresented = false
                        isFamilyEntryPresented = true
                    }
                    .buttonStyle(MyPageDialogButtonStyle(isPrimary: true))
                }
                .padding(.top, 24)
            }
            .padding(22)
            .frame(maxWidth: 342)
            .background(KIRIColor.Background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.25), radius: 22, y: 8)
        }
    }

    private var profileSection: some View {
        HStack(spacing: 12) {
            // Figma 9901:25875~25889: 48pt 프로필 영역 안에 원본 아바타 벡터(약 29pt)를
            // 중앙 배치합니다. SVG 자체가 배경과 캐릭터를 포함하므로 다시 Circle로 자르지 않습니다.
            ZStack {
                Circle()
                    .fill(KIRIColor.Background.tertiary)
                    .frame(width: 43.636, height: 43.636)
                Image(profileAvatarAsset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 27.216, height: 27.216)
            }
            .frame(width: 48, height: 48)
            VStack(alignment: .leading, spacing: 4) {
                Text(nickname ?? "닉네임을 설정해주세요").font(KIRITypography.headingSmall).foregroundStyle(KIRIColor.Text.strong)
                Text(profileSubtitle).font(KIRITypography.bodySmall).foregroundStyle(KIRIColor.Text.secondary)
            }
            Spacer()
            NavigationLink {
                NicknameEditView(
                    nickname: Binding(get: { nickname ?? "" }, set: { editedNickname = $0 }),
                    onSave: { value in await router.updateNickname(value) }
                )
            } label: {
                // Figma 9901:25894 / KIRI/Icon/Action/Edit 원본 벡터.
                // 수정 아이콘 크기와 터치 영역은 각각 24pt·36pt로 유지합니다.
                Image("figma_edit")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .frame(width: 36, height: 36)
            }.buttonStyle(.plain)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private var profileAvatarAsset: String {
        switch familyRole?.uppercased() {
        case "MOTHER", "MOM", "엄마": return "role_mom_active"
        case "FATHER", "DAD", "아빠": return "role_dad_active"
        case "SON", "아들": return "role_son_active"
        case "DAUGHTER", "딸": return "role_daughter_active"
        default: return "figma_family_member_default"
        }
    }

    private var profileSubtitle: String {
        guard let familyName else { return "가족공간 미가입" }
        if let familyRole, !familyRole.isEmpty { return "\(familyName) I \(localizedFamilyRole(familyRole))" }
        return familyName
    }

    private func menuSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title).font(KIRITypography.headingSmall).foregroundStyle(KIRIColor.Text.strong)
            VStack(spacing: 0, content: content).background(KIRIColor.Background.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private func menuRow(_ title: String) -> some View {
        HStack {
            Text(title).font(KIRITypography.bodyMedium).foregroundStyle(KIRIColor.Text.primary)
            Spacer()
            // Figma 9901:25902의 원본 화살표와 36pt 정렬 프레임을 공통 사용합니다.
            MyPageChevron()
        }.padding(.horizontal, 16).frame(height: 56).contentShape(Rectangle())
    }
}

#Preview { MyPageView(onLogout: {}, onDeleteAccount: { nil }, nickname: "쥬123", familyName: "끼리네 가족", familyId: 1, familyRole: "딸", onUpdateFamilyName: { _ in nil }).environment(AppRouter()) }
