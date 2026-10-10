import SwiftUI
import UserNotifications

private struct MyPageAppBar<Content: View>: View {
    let title: String
    let content: () -> Content
    @Environment(\.dismiss) private var dismiss

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
    var body: some View {
        ZStack { KIRIColor.Background.base.ignoresSafeArea()
            MyPageAppBar(title: "계정 정보") {
                ScrollView {
                    VStack(spacing: 16) {
                        MyPageRows(rows: [("이메일", "Apple 로그인"), ("가입일", "2026.06.23")])
                        NavigationLink { WithdrawalView() } label: {
                            HStack { Text("회원탈퇴").font(KIRITypography.bodyMedium).foregroundStyle(KIRIColor.Status.error); Spacer(); Image(systemName: "chevron.right").foregroundStyle(KIRIColor.Icon.secondary) }
                                .padding(.horizontal, 16).frame(height: 52)
                        }.buttonStyle(.plain).background(KIRIColor.Background.secondary).clipShape(RoundedRectangle(cornerRadius: 8))
                    }.padding(18)
                }
            }
        }.toolbar(.hidden, for: .navigationBar)
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
    @State private var confirmed = false
    var body: some View {
        ZStack { KIRIColor.Background.base.ignoresSafeArea()
            MyPageAppBar(title: "회원탈퇴") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("잠깐! 떠나기 전에 확인해주세요").font(KIRITypography.title).foregroundStyle(KIRIColor.Text.strong)
                    Text("탈퇴하면 계정은 삭제되지만,\n가족이 함께한 기록은 남을 수 있어요.").font(KIRITypography.body).foregroundStyle(KIRIColor.Text.tertiary)
                    Text("삭제되는 내 정보").font(KIRITypography.headingSmall).foregroundStyle(KIRIColor.Text.primary).padding(.top, 24)
                    ToggleRow(title: "탈퇴 내용을 확인했습니다", value: $confirmed)
                        .background(KIRIColor.Background.secondary).clipShape(RoundedRectangle(cornerRadius: 8))
                    Button("탈퇴 요청") { }
                        .disabled(!confirmed).frame(maxWidth: .infinity).frame(height: 54)
                        .background(confirmed ? KIRIColor.Status.error : KIRIColor.Background.tertiary)
                        .foregroundStyle(KIRIColor.Text.strong).clipShape(RoundedRectangle(cornerRadius: 8))
                    Text("탈퇴 API가 연결되기 전까지 계정 삭제를 수행하지 않습니다.").font(KIRITypography.caption).foregroundStyle(KIRIColor.Text.tertiary)
                    Spacer()
                }.padding(18)
            }
        }.toolbar(.hidden, for: .navigationBar)
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
    var body: some View {
        ZStack { KIRIColor.Background.base.ignoresSafeArea()
            MyPageAppBar(title: "우리집 주소 설정") {
                VStack(alignment: .leading, spacing: 20) {
                    Text("우리집 주소를 설정해주세요").font(KIRITypography.title).foregroundStyle(KIRIColor.Text.strong)
                    KIRITextField(placeholder: "주소를 입력하세요.", text: $address)
                    Text("주소 검색 API가 연결되기 전까지 입력값은 저장하지 않습니다.")
                        .font(KIRITypography.caption).foregroundStyle(KIRIColor.Text.tertiary)
                    Spacer()
                }.padding(18)
            }
        }.toolbar(.hidden, for: .navigationBar)
    }
}

struct InviteLinkView: View {
    private let link = "https://kiri.app/invite/KIRI24"
    var body: some View {
        ZStack { KIRIColor.Background.base.ignoresSafeArea()
            MyPageAppBar(title: "공용초대링크 관리") {
                VStack(alignment: .leading, spacing: 20) {
                    Text("가족을 초대해보세요").font(KIRITypography.title).foregroundStyle(KIRIColor.Text.strong)
                    Text(link).font(KIRITypography.bodyMedium).foregroundStyle(KIRIColor.Text.primary)
                        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                        .background(KIRIColor.Background.secondary).clipShape(RoundedRectangle(cornerRadius: 8))
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
