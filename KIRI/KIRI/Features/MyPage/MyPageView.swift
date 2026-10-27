import SwiftUI

/// Figma 8213:3062. API 연결 전에는 화면 로컬 상태를 사용한다.
struct MyPageView: View {
    let onLogout: () -> Void
    let nickname: String?
    let familyName: String?
    @State private var editedNickname = ""
    @State private var isLogoutAlertPresented = false

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
                        }.padding(.top, 72)
                        menuSection(title: "가족 설정") {
                            NavigationLink { FamilySettingsView() } label: { menuRow("가족 기본 설정") }
                            NavigationLink { AddressSettingsView() } label: { menuRow("우리집 주소 설정") }
                            NavigationLink { InviteLinkView() } label: { menuRow("공용초대링크 관리") }
                        }.padding(.top, 36)
                        menuSection(title: "설정") {
                            NavigationLink { AccountInfoView(onLogout: onLogout) } label: { menuRow("계정 정보") }
                            NavigationLink { SuggestionView() } label: { menuRow("건의함") }
                        }.padding(.top, 36)
                        Button {
                            isLogoutAlertPresented = true
                        } label: {
                            HStack {
                                Text("로그아웃").font(KIRITypography.bodySmall)
                                    .foregroundStyle(KIRIColor.Text.secondary)
                                Spacer()
                            }.padding(.horizontal, 16).frame(height: 52)
                        }.buttonStyle(.plain).padding(.top, 20)
                        Color.clear.frame(height: 110)
                    }.padding(.horizontal, 18)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .alert("로그아웃할까요?", isPresented: $isLogoutAlertPresented) {
                Button("취소", role: .cancel) {}
                Button("로그아웃", role: .destructive, action: onLogout)
            } message: { Text("현재 계정에서 로그아웃합니다.") }
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
                Text(familyName.map { "\($0)" } ?? "가족공간 미가입").font(KIRITypography.bodySmall).foregroundStyle(KIRIColor.Text.secondary)
            }
            Spacer()
            NavigationLink { NicknameEditView(nickname: Binding(get: { nickname ?? "" }, set: { editedNickname = $0 })) } label: {
                Image(systemName: "pencil").font(.system(size: 18, weight: .medium))
                    .foregroundStyle(KIRIColor.Icon.secondary).frame(width: 36, height: 36)
            }.buttonStyle(.plain)
        }.frame(maxWidth: .infinity, alignment: .leading)
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
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .medium))
                .foregroundStyle(KIRIColor.Icon.secondary)
        }.padding(.horizontal, 16).frame(height: 52).contentShape(Rectangle())
    }
}

#Preview { MyPageView(onLogout: {}, nickname: "쥬123", familyName: "끼리네 가족") }
