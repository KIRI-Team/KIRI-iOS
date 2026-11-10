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
    let onLogout: () -> Void
    let onDeleteAccount: () async -> String?
    let nickname: String?
    let familyName: String?
    let familyId: Int?
    let familyRole: String?
    let onUpdateNickname: (String) async -> String?
    let onUpdateFamilyName: (String) async -> String?
    @State private var editedNickname = ""

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
                            NavigationLink {
                                FamilySettingsView(
                                    familyId: familyId,
                                    familyName: familyName,
                                    nickname: nickname,
                                    familyRole: familyRole,
                                    onUpdateFamilyName: onUpdateFamilyName
                                )
                            } label: { menuRow("가족 기본 설정") }
                            NavigationLink { AddressSettingsView() } label: { menuRow("우리집 주소 설정") }
                            NavigationLink { InviteLinkView(familyId: familyId) } label: { menuRow("공용초대링크 관리") }
                        }.padding(.top, 48)
                        menuSection(title: "설정") {
                            NavigationLink { AccountInfoView(onLogout: onLogout, onDeleteAccount: onDeleteAccount) } label: { menuRow("계정 정보") }
                            NavigationLink { SuggestionView() } label: { menuRow("건의함") }
                        }.padding(.top, 48)
                        Color.clear.frame(height: 110)
                    }.padding(.horizontal, 18)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var profileSection: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(KIRIColor.Background.tertiary)
                .frame(width: 44, height: 44)
                .overlay {
                    Image("family-me")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 38, height: 38)
                        .clipShape(Circle())
                }
            VStack(alignment: .leading, spacing: 4) {
                Text(nickname ?? "닉네임을 설정해주세요").font(KIRITypography.headingSmall).foregroundStyle(KIRIColor.Text.strong)
                Text(profileSubtitle).font(KIRITypography.bodySmall).foregroundStyle(KIRIColor.Text.secondary)
            }
            Spacer()
            NavigationLink { NicknameEditView(nickname: Binding(get: { nickname ?? "" }, set: { editedNickname = $0 }), onSave: onUpdateNickname) } label: {
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

    private var profileSubtitle: String {
        guard let familyName else { return "가족공간 미가입" }
        if let familyRole, !familyRole.isEmpty { return "\(familyName) I \(familyRole)" }
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
            // Figma 9901:25902 / KIRI/Icon/Navigation/Back 원본을 오른쪽 방향으로 사용합니다.
            // SF Symbol을 쓰지 않아 Figma의 8×16pt 선 굵기와 색상을 유지합니다.
            Image("figma_navigation_back")
                .resizable()
                .scaledToFit()
                .frame(width: 8, height: 16)
                .rotationEffect(.degrees(180))
                .frame(width: 36, height: 36)
        }.padding(.horizontal, 16).frame(height: 56).contentShape(Rectangle())
    }
}

#Preview { MyPageView(onLogout: {}, onDeleteAccount: { nil }, nickname: "쥬123", familyName: "끼리네 가족", familyId: 1, familyRole: "딸", onUpdateNickname: { _ in nil }, onUpdateFamilyName: { _ in nil }) }
