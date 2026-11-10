//
// MARK: - 파일 가이드
// 파일: Features/MyPage/MyPageSupportViews.swift
// 담당 영역: 기능별 SwiftUI 화면과 상태
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//

import SwiftUI
import UserNotifications

private struct MyPageAppBar<Content: View>: View {
    let title: String
    let content: () -> Content
    @Environment(\.dismiss) private var dismiss
    @Environment(\.kiriTabBarVisibility) private var tabBarVisibility

    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left").font(.system(size: 18, weight: .medium))
                        .foregroundStyle(KIRIColor.Icon.primary).frame(width: 52, height: 52)
                }.buttonStyle(.plain)
                Spacer()
                Text(title).font(KIRITypography.headingSmall).foregroundStyle(KIRIColor.Text.strong)
                Spacer()
                Color.clear.frame(width: 52, height: 52)
            }
            content()
        }
        .onAppear { tabBarVisibility.wrappedValue = false }
        .onDisappear { tabBarVisibility.wrappedValue = true }
    }
}

private struct MyPageRows: View {
    let rows: [(String, String)]
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack {
                    Text(row.0).font(KIRITypography.bodyMedium).foregroundStyle(KIRIColor.Text.primary)
                    Spacer()
                    if !row.1.isEmpty { Text(row.1).font(KIRITypography.bodySmall).foregroundStyle(KIRIColor.Text.secondary) }
                    Image(systemName: "chevron.right").font(.system(size: 13)).foregroundStyle(KIRIColor.Icon.secondary)
                }.padding(.horizontal, 16).frame(height: 52)
            }
        }.background(KIRIColor.Background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct AccountInfoView: View {
    let onLogout: () -> Void
    let onDeleteAccount: () async -> String?
    @State private var isLogoutAlertPresented = false

    var body: some View {
        ZStack { KIRIColor.Background.base.ignoresSafeArea()
            MyPageAppBar(title: "계정 정보") {
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(spacing: 0) {
                            NavigationLink { TermsView() } label: { accountRow("이용 약관") }
                            NavigationLink { OpenLicenseView() } label: { accountRow("오픈 라이선스") }
                            accountRow("앱 버전", trailingText: "1.0.0", showsChevron: false)
                        }
                        .background(KIRIColor.Background.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                        VStack(spacing: 0) {
                            Button { isLogoutAlertPresented = true } label: { accountRow("로그아웃") }
                                .buttonStyle(.plain)
                            NavigationLink { WithdrawalView(onDeleteAccount: onDeleteAccount) } label: { accountRow("회원탈퇴", tint: KIRIColor.Status.error) }
                        }
                        .background(KIRIColor.Background.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }.padding(18)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert("로그아웃할까요?", isPresented: $isLogoutAlertPresented) {
            Button("취소", role: .cancel) {}
            Button("로그아웃", role: .destructive, action: onLogout)
        } message: {
            Text("현재 계정에서 로그아웃합니다.")
        }
    }

    private func accountRow(
        _ title: String,
        trailingText: String = "",
        showsChevron: Bool = true,
        tint: Color? = nil
    ) -> some View {
        HStack {
            Text(title)
                .font(KIRITypography.bodyMedium)
                .foregroundStyle(tint ?? KIRIColor.Text.primary)
            Spacer()
            if !trailingText.isEmpty {
                Text(trailingText)
                    .font(KIRITypography.bodySmall)
                    .foregroundStyle(KIRIColor.Text.secondary)
            }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundStyle(KIRIColor.Icon.secondary)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .contentShape(Rectangle())
    }
}

struct TermsView: View {
    var body: some View {
        ZStack { KIRIColor.Background.base.ignoresSafeArea()
            MyPageAppBar(title: "이용 약관") {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("세부 약관").font(KIRITypography.headingSmall).foregroundStyle(KIRIColor.Text.primary)
                        MyPageRows(rows: [("서비스 이용약관", ""), ("개인정보 처리방침", "")])
                        NavigationLink { OpenLicenseView() } label: {
                            HStack { Text("오픈라이선스").font(KIRITypography.bodyMedium).foregroundStyle(KIRIColor.Text.primary); Spacer(); Image(systemName: "chevron.right").foregroundStyle(KIRIColor.Icon.secondary) }
                                .padding(.horizontal, 16).frame(height: 52)
                        }.buttonStyle(.plain).background(KIRIColor.Background.secondary).clipShape(RoundedRectangle(cornerRadius: 8))
                        Text("약관 내용은 서버 정책 확정 후 연결됩니다.").font(KIRITypography.bodySmall).foregroundStyle(KIRIColor.Text.tertiary)
                    }.padding(18)
                }
            }
        }.toolbar(.hidden, for: .navigationBar)
    }
}

struct OpenLicenseView: View {
    var body: some View {
        ZStack { KIRIColor.Background.base.ignoresSafeArea()
            MyPageAppBar(title: "오픈라이선스") {
                ScrollView { Text("KIRI가 사용하는 오픈소스 라이선스 정보\n\n실제 라이선스 원문은 배포 전 제공된 목록으로 교체합니다.")
                    .font(KIRITypography.body).foregroundStyle(KIRIColor.Text.primary).frame(maxWidth: .infinity, alignment: .leading).padding(18) }
            }
        }.toolbar(.hidden, for: .navigationBar)
    }
}

struct WithdrawalView: View {
    let onDeleteAccount: () async -> String?
    @State private var confirmed = false
    @State private var isConfirmPresented = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    var body: some View {
        ZStack { KIRIColor.Background.base.ignoresSafeArea()
            MyPageAppBar(title: "회원탈퇴") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("잠깐! 떠나기 전에 확인해주세요").font(KIRITypography.title).foregroundStyle(KIRIColor.Text.strong)
                    Text("탈퇴하면 계정은 삭제되지만,\n가족이 함께한 기록은 남을 수 있어요.").font(KIRITypography.body).foregroundStyle(KIRIColor.Text.tertiary)
                    Text("삭제되는 내 정보").font(KIRITypography.headingSmall).foregroundStyle(KIRIColor.Text.primary).padding(.top, 24)
                    ToggleRow(title: "탈퇴 내용을 확인했습니다", value: $confirmed)
                        .background(KIRIColor.Background.secondary).clipShape(RoundedRectangle(cornerRadius: 8))
                    Button("탈퇴 요청") { isConfirmPresented = true }
                        .disabled(!confirmed || isSubmitting).frame(maxWidth: .infinity).frame(height: 54)
                        .background(confirmed ? KIRIColor.Status.error : KIRIColor.Background.tertiary)
                        .foregroundStyle(KIRIColor.Text.strong).clipShape(RoundedRectangle(cornerRadius: 8))
                    if let errorMessage {
                        Text(errorMessage).font(KIRITypography.caption).foregroundStyle(KIRIColor.Status.error)
                    }
                    Spacer()
                }.padding(18)
            }
        }.toolbar(.hidden, for: .navigationBar)
        .alert("정말 탈퇴할까요?", isPresented: $isConfirmPresented) {
            Button("취소", role: .cancel) {}
            Button("탈퇴", role: .destructive) {
                isSubmitting = true
                Task { @MainActor in
                    errorMessage = await onDeleteAccount()
                    isSubmitting = false
                }
            }
        } message: {
            Text("회원탈퇴 후에는 계정을 복구할 수 없습니다.")
        }
    }
}

struct PushNotificationView: View {
    @State private var allEnabled = true
    @State private var missionEnabled = true
    @State private var permissionText = "알림 권한 확인 중"
    var body: some View {
        ZStack { KIRIColor.Background.base.ignoresSafeArea()
            MyPageAppBar(title: "알림 설정") {
                VStack(spacing: 12) {
                    toggleRow("전체 알림 설정", isOn: $allEnabled)
                    toggleRow("미션 알림", isOn: $missionEnabled)
                    Text("알림 설정은 현재 기기 로컬 상태로만 동작합니다.")
                        .font(KIRITypography.caption).foregroundStyle(KIRIColor.Text.tertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(permissionText)
                        .font(KIRITypography.caption).foregroundStyle(KIRIColor.Text.tertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }.padding(18)
                Spacer()
            }
        }.toolbar(.hidden, for: .navigationBar)
            .task {
                let settings = await UNUserNotificationCenter.current().notificationSettings()
                permissionText = settings.authorizationStatus == .denied
                    ? "iOS 알림 권한이 꺼져 있어 푸시를 받을 수 없습니다. 설정에서 권한을 켜주세요."
                    : "iOS 알림 권한: 허용됨 또는 아직 결정되지 않음"
            }
    }
    private func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack { Text(title).font(KIRITypography.headingSmall).foregroundStyle(KIRIColor.Text.strong)
            Spacer(); Toggle("", isOn: isOn).labelsHidden().tint(KIRIColor.Primary.default)
        }.padding(.horizontal, 12).frame(height: 56)
    }
}

private struct ToggleRow: View {
    let title: String
    @Binding var value: Bool
    var body: some View { HStack { Text(title).font(KIRITypography.bodyMedium).foregroundStyle(KIRIColor.Text.primary); Spacer(); Toggle("", isOn: $value).labelsHidden().tint(KIRIColor.Primary.default) }.padding(.horizontal, 16).frame(height: 56) }
}

struct AddressSettingsView: View {
    @State private var address = ""
    @State private var postalCode = ""
    @State private var isSearchPresented = false
    var body: some View {
        ZStack { KIRIColor.Background.base.ignoresSafeArea()
            MyPageAppBar(title: "우리집 주소 설정") {
                VStack(alignment: .leading, spacing: 20) {
                    Text("우리 집 주소 작성하기").font(KIRITypography.headingMedium).foregroundStyle(KIRIColor.Text.strong)
                    HStack(spacing: 6) {
                        KIRITextField(placeholder: "주소를 입력해주세요", text: $address)
                        Button("우편번호 찾기") { isSearchPresented = true }
                            .font(KIRITypography.button).foregroundStyle(KIRIColor.Text.primary)
                            .frame(width: 113, height: 54).background(KIRIColor.Background.elevated)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    KIRITextField(placeholder: "상세 주소를 입력해주세요", text: $postalCode)
                    Text("주소 검색 API가 연결되기 전까지 입력값은 저장하지 않습니다.")
                        .font(KIRITypography.caption).foregroundStyle(KIRIColor.Text.tertiary)
                    Spacer()
                }.padding(18)
            }
        }.toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $isSearchPresented) {
                NavigationStack {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("주소 검색").font(KIRITypography.headingMedium)
                        Text("주소 검색 API 미연동 상태입니다.").font(KIRITypography.bodySmall).foregroundStyle(KIRIColor.Text.secondary)
                        Spacer()
                    }.padding(18).background(KIRIColor.Background.base).foregroundStyle(KIRIColor.Text.strong)
                }
                .presentationDetents([.medium])
            }
    }
}

struct InviteLinkView: View {
    private let link = "https://kiri.app/invite/NWTKYJ"
    private let code = "NWTKYJ"
    var body: some View {
        ZStack { KIRIColor.Background.base.ignoresSafeArea()
            MyPageAppBar(title: "공용초대링크 관리") {
                VStack(alignment: .leading, spacing: 20) {
                    Text("가족이 모이면 더 즐거워져요!").font(KIRITypography.title).foregroundStyle(KIRIColor.Text.strong)
                    Text("초대 링크는 7일 동안 사용할 수 있어요.").font(KIRITypography.bodySmall).foregroundStyle(KIRIColor.Text.tertiary)
                    inviteCard(label: "링크코드", value: code)
                    inviteCard(label: "초대링크", value: link)
                    Text("10월 12일까지 사용가능").font(KIRITypography.bodySmall).foregroundStyle(KIRIColor.Text.tertiary)
                    Button("리셋하기") { }
                        .font(KIRITypography.bodySmall).underline().foregroundStyle(KIRIColor.Text.tertiary)
                    ShareLink(item: link) {
                        Text("초대 링크 공유").font(KIRITypography.button).foregroundStyle(KIRIColor.Text.onGreen)
                            .frame(maxWidth: .infinity).frame(height: 54).background(KIRIColor.Primary.default).clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    Text("초대 링크는 Mock 값이며 서버에서 생성·저장되지 않습니다.").font(KIRITypography.caption).foregroundStyle(KIRIColor.Text.tertiary)
                    Spacer()
                }.padding(18)
            }
        }.toolbar(.hidden, for: .navigationBar)
    }
    private func inviteCard(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label).font(KIRITypography.caption).foregroundStyle(KIRIColor.Text.tertiary)
            HStack(spacing: 8) {
                Text(value).font(label == "링크코드" ? KIRITypography.headingLarge : KIRITypography.bodyMedium).foregroundStyle(KIRIColor.Text.strong).lineLimit(1)
                Image(systemName: "doc.on.doc").foregroundStyle(KIRIColor.Icon.primary)
            }
        }.frame(maxWidth: .infinity).frame(height: 90).background(KIRIColor.Background.elevated).clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct TasteTestView: View {
    private let activities = ["전시·문화", "팝업·행사", "공연", "맛집·카페", "산책·야외", "체험·놀거리"]
    private let spaces = ["실내", "야외", "상관없음"]
    private let amounts = ["가볍게", "적당히", "많이 움직여도 괜찮음"]
    private let costs = ["무료 위주", "부담 적게", "비용 상관없음"]
    private let durations = ["1시간 이내", "1~3시간", "반나절 이상", "상관없음"]
    @State private var selectedActivities: Set<String> = []
    @State private var space = ""
    @State private var amount = ""
    @State private var cost = ""
    @State private var duration = ""
    var body: some View {
        ZStack { KIRIColor.Background.base.ignoresSafeArea()
            MyPageAppBar(title: "내 취향 설정") {
                VStack(alignment: .leading, spacing: 16) {
                    Text("우리 가족의 취향을 알려주세요").font(KIRITypography.title).foregroundStyle(KIRIColor.Text.strong)
                    preferenceSection("선호 활동 (최대 3개)", options: activities, selected: $selectedActivities, limit: 3)
                    preferenceSection("공간", options: spaces, selectedValue: $space)
                    preferenceSection("활동량", options: amounts, selectedValue: $amount)
                    preferenceSection("비용", options: costs, selectedValue: $cost)
                    preferenceSection("활동시간", options: durations, selectedValue: $duration)
                    Text("명세서의 취향 데이터 저장 API가 없어 입력값은 저장하지 않습니다.")
                        .font(KIRITypography.caption).foregroundStyle(KIRIColor.Text.tertiary)
                    Spacer()
                }.padding(18)
            }
        }.toolbar(.hidden, for: .navigationBar)
    }

    private func preferenceSection(_ title: String, options: [String], selected: Binding<Set<String>>, limit: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(KIRITypography.bodyMedium).foregroundStyle(KIRIColor.Text.primary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                ForEach(options, id: \.self) { option in
                    Button {
                        if selected.wrappedValue.contains(option) { selected.wrappedValue.remove(option) }
                        else if selected.wrappedValue.count < limit { selected.wrappedValue.insert(option) }
                    } label: { chip(option, isSelected: selected.wrappedValue.contains(option)) }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func preferenceSection(_ title: String, options: [String], selectedValue: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(KIRITypography.bodyMedium).foregroundStyle(KIRIColor.Text.primary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                ForEach(options, id: \.self) { option in
                    Button { selectedValue.wrappedValue = option } label: { chip(option, isSelected: selectedValue.wrappedValue == option) }.buttonStyle(.plain)
                }
            }
        }
    }

    private func chip(_ title: String, isSelected: Bool) -> some View {
        Text(title).font(KIRITypography.bodySmall).foregroundStyle(isSelected ? KIRIColor.Text.onGreen : KIRIColor.Text.primary)
            .frame(maxWidth: .infinity).frame(height: 40)
            .background(isSelected ? KIRIColor.Primary.default : KIRIColor.Background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct SuggestionView: View {
    @State private var text = ""
    var body: some View {
        ZStack { KIRIColor.Background.base.ignoresSafeArea()
            MyPageAppBar(title: "건의함") {
                VStack(alignment: .leading, spacing: 18) {
                    Text("끼리가 더 발전할 수 있도록\n얘기해주세요!").font(KIRITypography.title).foregroundStyle(KIRIColor.Text.strong)
                    TextField("내용을 입력하세요.", text: $text, axis: .vertical).lineLimit(5...10)
                        .padding(16).background(KIRIColor.Background.secondary).clipShape(RoundedRectangle(cornerRadius: 8))
                    Button("보내기") {}.disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .frame(maxWidth: .infinity).frame(height: 54).background(KIRIColor.Primary.default).clipShape(RoundedRectangle(cornerRadius: 8))
                    Text("건의 전송 API가 없어 서버로 전송하지 않습니다.").font(KIRITypography.caption).foregroundStyle(KIRIColor.Text.tertiary)
                    Spacer()
                }.padding(18)
            }
        }.toolbar(.hidden, for: .navigationBar)
    }
}
