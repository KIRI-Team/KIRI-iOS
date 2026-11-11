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
import UIKit
import UserNotifications
import CoreLocation
import MapKit
import WebKit

private struct MyPageAppBar<Content: View>: View {
    let title: String
    let content: () -> Content
    @Environment(\.dismiss) private var dismiss
    @Environment(\.kiriTabBarVisibility) private var tabBarVisibility
    @Environment(\.kiriTabBarSubscreenCount) private var tabBarSubscreenCount
    @State private var didRegisterSubscreen = false

    init(title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                KIRIBackButton { dismiss() }
                Spacer()
                Text(title).font(KIRITypography.headingSmall).foregroundStyle(KIRIColor.Text.strong)
                Spacer()
                Color.clear.frame(width: 52, height: 52)
            }
            content()
        }
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
    }
}

/// Figma 9901:25866의 KIRI/Icon/Navigation/Back 원본을 메뉴 방향으로 표시합니다.
/// SVG는 24×24 캔버스 안에 8×16 path를 포함하므로, 이미지 프레임도 24pt로
/// 유지해야 실제 화살표가 축소되지 않습니다. 행의 터치·정렬 영역은 36pt입니다.
struct MyPageChevron: View {
    var body: some View {
        Image("figma_navigation_back")
            .resizable()
            .scaledToFit()
            .frame(width: 24, height: 24)
            .rotationEffect(.degrees(180))
            .frame(width: 36, height: 36)
            .accessibilityHidden(true)
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
                    MyPageChevron()
                }.padding(.horizontal, 16).frame(height: 56)
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
                    VStack(spacing: 36) {
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
                    }.padding(.horizontal, 18).padding(.top, 31).padding(.bottom, 24)
                }
            }
            if isLogoutAlertPresented {
                logoutDialog
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var logoutDialog: some View {
        ZStack {
            Color.black.opacity(0.58).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Text("정말로 로그아웃 하시겠어요?")
                    .font(KIRITypography.headingSmall)
                    .foregroundStyle(KIRIColor.Text.strong)
                Text("다시 로그인하면 우리 가족의 기록을 이어갈 수 있어요.")
                    .font(KIRITypography.caption)
                    .foregroundStyle(KIRIColor.Text.secondary)
                    .padding(.top, 2)
                Image("figma_logout")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 20)
                Spacer(minLength: 0)
                HStack(spacing: 12) {
                    Button("취소") { isLogoutAlertPresented = false }
                        .buttonStyle(MyPageDialogButtonStyle(isPrimary: false))
                    Button("로그아웃") {
                        isLogoutAlertPresented = false
                        onLogout()
                    }
                    .buttonStyle(MyPageDialogButtonStyle(isPrimary: true))
                }
            }
            .padding(22)
            .frame(width: 340, height: 280, alignment: .topLeading)
            .background(KIRIColor.Background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .transition(.opacity)
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
                MyPageChevron()
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
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
                            HStack { Text("오픈라이선스").font(KIRITypography.bodyMedium).foregroundStyle(KIRIColor.Text.primary); Spacer(); MyPageChevron() }
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
    @Environment(\.kiriTabBarVisibility) private var tabBarVisibility
    let onDeleteAccount: () async -> String?
    @State private var confirmed = false
    @State private var isConfirmPresented = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    var body: some View {
        ZStack { KIRIColor.Background.base.ignoresSafeArea()
            MyPageAppBar(title: "회원탈퇴") {
                VStack(alignment: .leading, spacing: 0) {
                    Text("잠깐! 떠나기 전에 확인해주세요")
                        .font(KIRITypography.title)
                        .foregroundStyle(KIRIColor.Text.strong)
                        .padding(.top, 24)
                    Text("탈퇴하면 계정은 삭제되지만,\n가족이 함께한 기록은 남을 수 있어요.")
                        .font(KIRITypography.body)
                        .foregroundStyle(KIRIColor.Text.tertiary)
                        .padding(.top, 4)
                    Text("삭제되는 내 정보")
                        .font(KIRITypography.headingSmall)
                        .foregroundStyle(KIRIColor.Text.primary)
                        .padding(.top, 34)
                    Text("• 계정 인증정보와 개인 프로필\n• 내 취향과 개인 설정\n• 가족공간의 내 참여 관계")
                        .font(KIRITypography.body)
                        .foregroundStyle(KIRIColor.Text.primary)
                        .lineSpacing(0)
                        .padding(.top, 12)
                    Text("가족과 함께한 기록")
                        .font(KIRITypography.headingSmall)
                        .foregroundStyle(KIRIColor.Text.primary)
                        .padding(.top, 36)
                    Text("• 가족의 과거 일정과 완료 활동은 유지돼요.\n• 기록의 작성자는 ‘탈퇴한 멤버’로 표시돼요.\n• 가족 활동 맥락에 필요한 버킷 항목은 남아요.")
                        .font(KIRITypography.body)
                        .foregroundStyle(KIRIColor.Text.primary)
                        .lineSpacing(0)
                        .padding(.top, 12)
                    if let errorMessage {
                        Text(errorMessage).font(KIRITypography.caption).foregroundStyle(KIRIColor.Status.error).padding(.top, 8)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 18)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    Button("탈퇴할게요") { isConfirmPresented = true }
                        .disabled(isSubmitting)
                        .buttonStyle(MyPageDialogButtonStyle(isPrimary: false))
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 18)
                        .padding(.bottom, 40)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        // 상위 마이페이지의 생명주기와 관계없이 탈퇴 화면에서는 탭바를 숨깁니다.
        // safeAreaInset의 버튼은 홈 인디케이터 영역 위에 배치됩니다.
        .onAppear { tabBarVisibility.wrappedValue = false }
        .onDisappear { tabBarVisibility.wrappedValue = true }
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

private struct MyPageDialogButtonStyle: ButtonStyle {
    let isPrimary: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(KIRITypography.bodyMedium)
                // Figma 9901:26148: 강조 버튼은 밝은 초록 배경 위에 검정 텍스트를 사용합니다.
                // 취소/중립 버튼은 기존 밝은 텍스트 색을 유지합니다.
                .foregroundStyle(isPrimary ? Color.black : KIRIColor.Text.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(isPrimary ? KIRIColor.Primary.default : KIRIColor.Background.tertiary)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .opacity(configuration.isPressed ? 0.75 : 1)
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
    let familyId: Int?
    @Binding var savedAddress: FamilyAddressUpdateResult?
    @Environment(\.dismiss) private var dismiss
    @State private var address = ""
    @State private var postalCode = ""
    @State private var detailAddress = ""
    @State private var regionCode = ""
    @State private var latitude: Double?
    @State private var longitude: Double?
    @State private var isSearchPresented = false
    @State private var isEditing = false
    @State private var isSaving = false
    @State private var isResolvingCoordinates = false
    @State private var coordinateResolutionID = UUID()
    @State private var errorMessage: String?
    @State private var toastMessage: String?
    @State private var toastIsError = false

    init(familyId: Int?, savedAddress: Binding<FamilyAddressUpdateResult?>) {
        self.familyId = familyId
        self._savedAddress = savedAddress
    }

    var body: some View {
        ZStack {
            KIRIColor.Background.base.ignoresSafeArea()
            MyPageAppBar(title: "우리집 주소 설정") {
                if familyId == nil {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("가족공간에 참여하면 우리집 주소를 설정할 수 있어요")
                            .font(KIRITypography.headingMedium)
                            .foregroundStyle(KIRIColor.Text.strong)
                        Text("가족공간을 만들거나 초대 링크로 참여한 뒤 다시 시도해주세요.")
                            .font(KIRITypography.bodySmall)
                            .foregroundStyle(KIRIColor.Text.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 28)
                } else if let savedAddress, !isEditing {
                    savedContent(savedAddress)
                } else {
                    formContent
                }
            }
            if let toastMessage {
                KIRIToast(message: toastMessage, isError: toastIsError)
                    .padding(.horizontal, 18)
                    .safeAreaPadding(.top, 8)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .zIndex(4)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isSearchPresented) {
            AddressPostcodePicker(
                onSelected: { selection in
                    isSearchPresented = false
                    address = selection.address
                    postalCode = selection.zonecode
                    regionCode = selection.bcode
                    latitude = nil
                    longitude = nil
                    detailAddress = ""
                    let resolutionID = UUID()
                    coordinateResolutionID = resolutionID
                    Task { await resolveCoordinates(for: selection.address, postalCode: selection.zonecode, id: resolutionID) }
                },
                onFailure: { message in
                    isSearchPresented = false
                    showToast(message, isError: true)
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            if let savedAddress, !isEditing, address.isEmpty {
                address = savedAddress.address
                postalCode = savedAddress.postalCode
                detailAddress = savedAddress.detailAddress ?? ""
                regionCode = savedAddress.regionCode
                latitude = savedAddress.latitude
                longitude = savedAddress.longitude
            }
        }
    }

    private func savedContent(_ value: FamilyAddressUpdateResult) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("우리 집 주소가 등록되었어요")
                .font(KIRITypography.headingMedium)
                .foregroundStyle(KIRIColor.Text.strong)
            VStack(alignment: .leading, spacing: 8) {
                Text("등록된 주소").font(KIRITypography.caption).foregroundStyle(KIRIColor.Text.tertiary)
                Text(value.displayAddress).font(KIRITypography.body).foregroundStyle(KIRIColor.Text.primary).fixedSize(horizontal: false, vertical: true)
                Text("우편번호 \(value.postalCode)").font(KIRITypography.caption).foregroundStyle(KIRIColor.Text.secondary)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(KIRIColor.Background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            Button("수정") {
                isEditing = true
                address = value.address
                postalCode = value.postalCode
                detailAddress = value.detailAddress ?? ""
                regionCode = value.regionCode
                latitude = value.latitude
                longitude = value.longitude
            }
            .font(KIRITypography.button)
            .foregroundStyle(KIRIColor.Text.onGreen)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(KIRIColor.Primary.default)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 28)
    }

    private var formContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text(isEditing ? "우리 집 주소를 수정해주세요" : "우리 집 주소 작성하기")
                    .font(KIRITypography.headingMedium)
                    .foregroundStyle(KIRIColor.Text.strong)
                Text("우편번호 찾기에서 기본 주소를 선택한 뒤 상세 주소를 입력해주세요.")
                    .font(KIRITypography.bodySmall)
                    .foregroundStyle(KIRIColor.Text.secondary)
                HStack(spacing: 8) {
                    KIRITextField(placeholder: "우편번호", text: $postalCode, state: .disabled)
                    Button("우편번호 찾기") { isSearchPresented = true }
                        .font(KIRITypography.button)
                        .foregroundStyle(KIRIColor.Text.primary)
                        .frame(width: 118, height: 54)
                        .background(KIRIColor.Background.elevated)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                KIRITextField(placeholder: "기본 주소", text: $address, state: .disabled)
                KIRITextField(placeholder: "상세 주소 (선택)", text: $detailAddress)
                if let errorMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(errorMessage).font(KIRITypography.caption).foregroundStyle(KIRIColor.Status.error)
                        if !isResolvingCoordinates, !address.isEmpty {
                            Button("좌표 다시 확인") {
                                let resolutionID = UUID()
                                coordinateResolutionID = resolutionID
                                Task { await resolveCoordinates(for: address, postalCode: postalCode, id: resolutionID) }
                            }
                            .font(KIRITypography.captionMedium)
                            .foregroundStyle(KIRIColor.Text.accent)
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 28)
            .padding(.bottom, 110)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button(isSaving ? "저장 중..." : "저장") { Task { await saveAddress() } }
                .font(KIRITypography.button)
                .foregroundStyle(isSaveEnabled ? KIRIColor.Text.onGreen : KIRIColor.Text.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(isSaveEnabled ? KIRIColor.Primary.default : KIRIColor.Button.FilledAccent.backgroundDisabled)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .disabled(!isSaveEnabled)
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 10)
                .background(KIRIColor.Background.base)
        }
    }

    private var isSaveEnabled: Bool {
        guard familyId != nil, !isSaving, !isResolvingCoordinates,
              postalCode.range(of: "^[0-9]{5}$", options: .regularExpression) != nil,
              !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              regionCode.range(of: "^[0-9]{10}$", options: .regularExpression) != nil,
              let latitude, let longitude else { return false }
        return (-90...90).contains(latitude) && (-180...180).contains(longitude)
    }

    private func resolveCoordinates(for value: String, postalCode: String, id: UUID) async {
        await MainActor.run {
            isResolvingCoordinates = true
            latitude = nil
            longitude = nil
            errorMessage = nil
        }

        let queries = ["\(postalCode) \(value)", value]
        var lastFailure: CoordinateResolutionFailure = .noResult

        for query in queries {
            do {
                let coordinate = try await geocode(query: query)
                if (-90...90).contains(coordinate.latitude),
                   (-180...180).contains(coordinate.longitude) {
                    await MainActor.run {
                        guard coordinateResolutionID == id else { return }
                        latitude = coordinate.latitude
                        longitude = coordinate.longitude
                        isResolvingCoordinates = false
                        errorMessage = nil
                    }
                    return
                }
                lastFailure = .noCoordinate
            } catch let failure as CoordinateResolutionFailure {
                lastFailure = failure
            } catch let error as CLError {
                #if DEBUG
                print("[KIRI][Address] geocode failure domain=\((error as NSError).domain) code=\(error.code.rawValue)")
                #endif
                switch error.code {
                case .network:
                    lastFailure = .network
                case .geocodeCanceled:
                    lastFailure = .cancelled
                case .geocodeFoundNoResult:
                    lastFailure = .noResult
                default:
                    lastFailure = .unknown
                }
            } catch {
                #if DEBUG
                print("[KIRI][Address] geocode failure domain=\((error as NSError).domain) code=\((error as NSError).code)")
                #endif
                lastFailure = .unknown
            }
        }

        await MainActor.run {
            guard coordinateResolutionID == id else { return }
            isResolvingCoordinates = false
            latitude = nil
            longitude = nil
            errorMessage = lastFailure.message
        }
    }

    private func geocode(query: String) async throws -> CLLocationCoordinate2D {
        if #available(iOS 26.0, *) {
            guard let request = MKGeocodingRequest(addressString: query) else {
                throw CoordinateResolutionFailure.noResult
            }
            let items = try await request.mapItems
            guard let coordinate = items.first?.placemark.coordinate else {
                throw CoordinateResolutionFailure.noCoordinate
            }
            return coordinate
        }

        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.geocodeAddressString(query)
        guard let coordinate = placemarks.first?.location?.coordinate else {
            throw CoordinateResolutionFailure.noCoordinate
        }
        return coordinate
    }

    private func saveAddress() async {
        guard let familyId, isSaveEnabled, let latitude, let longitude else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        let request = FamilyAddressUpdateRequest(
            postalCode: postalCode,
            address: address,
            detailAddress: detailAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : detailAddress,
            regionCode: regionCode,
            latitude: latitude,
            longitude: longitude
        )
        do {
            let result = try await AuthService.shared.updateFamilyAddress(familyId: familyId, request: request)
            savedAddress = result
            AppSessionStore().markFamilyAddressConfigured(for: familyId)
            isEditing = false
            showToast("주소를 저장했어요", isError: false)
        } catch {
            errorMessage = "주소를 저장하지 못했어요. 다시 시도해 주세요."
            showToast(errorMessage ?? "주소를 저장하지 못했어요. 다시 시도해 주세요.", isError: true)
        }
    }

    private func showToast(_ message: String, isError: Bool) {
        toastIsError = isError
        withAnimation(.easeOut(duration: 0.2)) { toastMessage = message }
        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run { withAnimation(.easeOut(duration: 0.2)) { toastMessage = nil } }
        }
    }
}

private enum CoordinateResolutionFailure: Error {
    case network
    case noResult
    case noCoordinate
    case cancelled
    case unknown

    var message: String {
        switch self {
        case .network: return "주소 위치 확인에 실패했어요. 네트워크를 확인하고 다시 시도해 주세요."
        case .noResult: return "선택한 주소의 위치를 찾지 못했어요. 다른 주소를 선택해 주세요."
        case .noCoordinate: return "주소 검색 결과에 좌표가 없어 다시 확인이 필요해요."
        case .cancelled: return "주소 위치 확인이 취소됐어요. 다시 시도해 주세요."
        case .unknown: return "주소 위치를 확인하지 못했어요. 다시 시도해 주세요."
        }
    }
}

private struct PostcodeSelection: Equatable {
    let zonecode: String
    let address: String
    let bcode: String
}

private struct AddressPostcodePicker: View {
    @Environment(\.dismiss) private var dismiss
    let onSelected: (PostcodeSelection) -> Void
    let onFailure: (String) -> Void

    var body: some View {
        NavigationStack {
            AddressSearchWebView(onSelected: onSelected, onFailure: onFailure)
                .navigationTitle("주소 검색")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarLeading) { Button("닫기") { dismiss() } } }
        }
    }
}

private struct AddressSearchWebView: UIViewRepresentable {
    let onSelected: (PostcodeSelection) -> Void
    let onFailure: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onSelected: onSelected, onFailure: onFailure) }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.navigationDelegate = context.coordinator
        view.backgroundColor = UIColor(KIRIColor.Background.base)
        view.loadHTMLString(Self.html, baseURL: URL(string: "https://postcode.map.kakao.com/")!)
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate {
        let onSelected: (PostcodeSelection) -> Void
        let onFailure: (String) -> Void
        init(onSelected: @escaping (PostcodeSelection) -> Void, onFailure: @escaping (String) -> Void) { self.onSelected = onSelected; self.onFailure = onFailure }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else { decisionHandler(.cancel); return }
            if url.scheme == "kiri-address" {
                if url.host == "error" { onFailure("주소 검색을 불러오지 못했어요. 다시 시도해주세요.") }
                if url.host == "selected", let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                   let zonecode = components.queryItems?.first(where: { $0.name == "zip" })?.value,
                   let address = components.queryItems?.first(where: { $0.name == "address" })?.value,
                   let bcode = components.queryItems?.first(where: { $0.name == "region" })?.value,
                   zonecode.range(of: "^[0-9]{5}$", options: .regularExpression) != nil,
                   bcode.range(of: "^[0-9]{10}$", options: .regularExpression) != nil,
                   !address.isEmpty {
                    onSelected(PostcodeSelection(zonecode: zonecode, address: address, bcode: bcode))
                } else if url.host == "selected" {
                    onFailure("선택한 주소를 확인하지 못했어요. 다른 주소를 선택해주세요.")
                }
                decisionHandler(.cancel); return
            }
            if navigationAction.targetFrame?.isMainFrame == true,
               let host = url.host,
               !["postcode.map.kakao.com", "postcode.map.daum.net", "t1.kakaocdn.net"].contains(host) {
                decisionHandler(.cancel); return
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { onFailure("주소 검색을 불러오지 못했어요. 다시 시도해주세요.") }
    }

    private static let html = """
    <!doctype html><html lang=\"ko\"><head><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"></head>
    <body style=\"margin:0;background:#1A1A1A\"><div id=\"picker\" style=\"width:100%;height:100vh\"></div>
    <script>function fail(){location.href='kiri-address://error';}function openPicker(){try{var P=(window.kakao&&kakao.Postcode)||(window.daum&&daum.Postcode);if(!P){fail();return;}new P({oncomplete:function(d){var a=d.userSelectedType==='R'?(d.roadAddress||d.autoRoadAddress):(d.jibunAddress||d.autoJibunAddress);a=a||d.roadAddress||d.jibunAddress||'';location.href='kiri-address://selected?zip='+encodeURIComponent(d.zonecode||'')+'&address='+encodeURIComponent(a)+'&region='+encodeURIComponent(d.bcode||'');},width:'100%',height:'100%'}).embed(document.getElementById('picker'),{autoClose:false});}catch(e){fail();}}</script>
    <script src=\"https://t1.kakaocdn.net/mapjsapi/bundle/postcode/prod/postcode.v2.js\" onload=\"openPicker()\" onerror=\"fail()\"></script></body></html>
    """
}

struct InviteLinkView: View {
    let familyId: Int?
    @State private var invite: InviteResult?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isDeleteConfirmationPresented = false
    @State private var toastMessage: String?
    @State private var toastIsError = false
    @State private var toastGeneration = 0
    var body: some View {
        ZStack { KIRIColor.Background.base.ignoresSafeArea()
            MyPageAppBar(title: "공용초대링크 관리") {
                VStack(alignment: .leading, spacing: 20) {
                    Text("가족이 모이면 더 즐거워져요!").font(KIRITypography.title).foregroundStyle(KIRIColor.Text.strong)
                    Text("초대 링크는 7일 동안 사용할 수 있어요.").font(KIRITypography.bodySmall).foregroundStyle(KIRIColor.Text.tertiary)
                    if let invite {
                        inviteCard(label: "링크코드", value: invite.inviteCode)
                        inviteCard(label: "초대링크", value: invite.inviteUrl)
                        if let expiresAt = invite.inviteExpiresAt { Text("\(expiresAt)까지 사용가능").font(KIRITypography.bodySmall).foregroundStyle(KIRIColor.Text.tertiary) }
                        Button("리셋하기") { Task { await reissue() } }
                        .font(KIRITypography.bodySmall).underline().foregroundStyle(KIRIColor.Text.tertiary)
                        Button("초대 링크 폐기") { isDeleteConfirmationPresented = true }
                        .font(KIRITypography.bodySmall)
                        .foregroundStyle(KIRIColor.Status.error)
                        .disabled(isLoading)
                        ShareLink(item: invite.inviteUrl) {
                        Text("초대 링크 공유").font(KIRITypography.button).foregroundStyle(KIRIColor.Text.onGreen)
                            .frame(maxWidth: .infinity).frame(height: 54).background(KIRIColor.Primary.default).clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    } else if isLoading { ProgressView().frame(maxWidth: .infinity) }
                    else {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(errorMessage ?? "초대 링크를 불러올 수 없어요.")
                                .font(KIRITypography.bodySmall)
                                .foregroundStyle(KIRIColor.Text.secondary)
                            Button("다시 시도") { Task { await loadInvite() } }
                                .font(KIRITypography.captionMedium)
                                .foregroundStyle(KIRIColor.Text.accent)
                            Button("새 초대 링크 발급") { Task { await reissue() } }
                                .font(KIRITypography.captionMedium)
                                .foregroundStyle(KIRIColor.Text.accent)
                        }
                    }
                    Spacer()
                }.padding(18)
            }
        }
        .overlay(alignment: .top) {
            if let toastMessage {
                KIRIToast(message: toastMessage, isError: toastIsError)
                    .padding(.horizontal, 18)
                    .safeAreaPadding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await loadInvite() }
        .confirmationDialog("초대 링크를 폐기할까요?", isPresented: $isDeleteConfirmationPresented) {
            Button("초대 링크 폐기", role: .destructive) { Task { await deleteInvite() } }
            Button("취소", role: .cancel) {}
        } message: {
            Text("기존 초대 코드와 링크를 더 이상 사용할 수 없어요.")
        }
    }
    private func loadInvite() async {
        guard let familyId, !isLoading else { return }
        isLoading = true; defer { isLoading = false }
        do { invite = try await AuthService.shared.familyInvite(familyId: familyId); errorMessage = nil }
        catch { errorMessage = "초대 링크를 불러오지 못했어요." }
    }
    private func reissue() async {
        guard let familyId, !isLoading else { return }
        isLoading = true; defer { isLoading = false }
        do { invite = try await AuthService.shared.reissueFamilyInvite(familyId: familyId); errorMessage = nil; showToast("초대 링크를 새로 발급했어요.") }
        catch { showToast("초대 링크를 재발급하지 못했어요. 다시 시도해 주세요.", isError: true) }
    }
    private func deleteInvite() async {
        guard let familyId, !isLoading else { return }
        isLoading = true; defer { isLoading = false }
        do {
            try await AuthService.shared.deleteFamilyInvite(familyId: familyId)
            invite = nil
            errorMessage = nil
            showToast("초대 링크를 폐기했어요.")
        } catch {
            showToast("초대 링크를 폐기하지 못했어요. 다시 시도해 주세요.", isError: true)
        }
    }
    private func showToast(_ message: String, isError: Bool = false) {
        toastGeneration += 1
        let generation = toastGeneration
        toastMessage = message
        toastIsError = isError
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.2))
            guard generation == toastGeneration else { return }
            withAnimation(.easeOut(duration: 0.2)) { toastMessage = nil }
        }
    }
    private func inviteCard(label: String, value: String) -> some View {
        Button {
            UIPasteboard.general.string = value
            showToast(label == "링크코드" ? "링크코드를 복사했어요." : "초대 링크를 복사했어요.")
        } label: {
            VStack(spacing: 2) {
                Text(label).font(KIRITypography.caption).foregroundStyle(KIRIColor.Text.tertiary)
                HStack(spacing: 8) {
                    Text(value).font(label == "링크코드" ? KIRITypography.headingLarge : KIRITypography.bodyMedium).foregroundStyle(KIRIColor.Text.strong).lineLimit(1)
                    Image(systemName: "doc.on.doc").foregroundStyle(KIRIColor.Icon.primary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 90)
            .background(KIRIColor.Background.elevated)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
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
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var toastMessage: String?
    @State private var toastIsError = false
    @State private var toastGeneration = 0

    // 다섯 선호 그룹 중 하나라도 선택하면 저장할 수 있습니다.
    // 선택하지 않은 그룹은 nil/빈 배열로 서버 계약에 맞춰 전달합니다.
    private var hasValidTasteSelection: Bool {
        !selectedActivities.isEmpty ||
        !space.isEmpty ||
        !amount.isEmpty ||
        !cost.isEmpty ||
        !duration.isEmpty
    }

    private var canSaveTaste: Bool {
        hasValidTasteSelection && !isSaving
    }

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
                    if let errorMessage { Text(errorMessage).font(KIRITypography.caption).foregroundStyle(KIRIColor.Status.error) }
                    Button {
                        guard canSaveTaste else { return }
                        Task { await saveTaste() }
                    } label: {
                        HStack {
                            Spacer()
                            if isSaving {
                                ProgressView().tint(KIRIColor.Button.FilledNeutral.contentDefault)
                            } else {
                                Text("저장")
                            }
                            Spacer()
                        }
                        .font(KIRITypography.button)
                        .foregroundStyle(canSaveTaste ? KIRIColor.Button.FilledAccent.contentDefault : KIRIColor.Button.FilledNeutral.contentDefault)
                    }
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(canSaveTaste ? KIRIColor.Button.FilledAccent.backgroundDefault : KIRIColor.Button.FilledNeutral.backgroundDisabled)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .disabled(!canSaveTaste)
                    .buttonStyle(.plain)
                    Spacer()
                }.padding(18)
            }
        }
        .overlay(alignment: .top) {
            if let toastMessage {
                KIRIToast(message: toastMessage, isError: toastIsError)
                    .padding(.horizontal, 18)
                    .safeAreaPadding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task { await loadTaste() }
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
                    Button {
                        // 단일 선택 그룹은 같은 항목을 다시 누르면 선택을 해제합니다.
                        selectedValue.wrappedValue = selectedValue.wrappedValue == option ? "" : option
                    } label: { chip(option, isSelected: selectedValue.wrappedValue == option) }.buttonStyle(.plain)
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

    private func loadTaste() async {
        guard !isLoading else { return }
        isLoading = true; defer { isLoading = false }
        do {
            let result = try await AuthService.shared.myTaste()
            guard result.isSet else { return }
            selectedActivities = Set((result.categories ?? []).compactMap { tasteCategoryLabel($0) })
            space = tasteSpaceLabel(result.indoorOutdoor)
            amount = tasteActivityLabel(result.activityLevel)
            cost = tastePriceLabel(result.priceLevel)
            duration = tasteDurationLabel(result.durationLevel)
        } catch { errorMessage = "취향을 불러오지 못했어요." }
    }

    private func saveTaste() async {
        guard canSaveTaste else { return }
        isSaving = true; defer { isSaving = false }
        do {
            _ = try await AuthService.shared.saveTaste(TasteRequest(
                categories: selectedActivities.compactMap(tasteCategoryRaw),
                indoorOutdoor: tasteSpaceRaw(space),
                activityLevel: tasteActivityRaw(amount),
                priceLevel: tastePriceRaw(cost),
                durationLevel: tasteDurationRaw(duration)
            ))
            errorMessage = nil
            showToast("취향을 저장했어요.")
        } catch {
            // 실패해도 현재 선택값은 유지해 즉시 재시도할 수 있습니다.
            errorMessage = nil
            showToast("취향을 저장하지 못했어요. 다시 시도해 주세요.", isError: true)
        }
    }

    private func showToast(_ message: String, isError: Bool = false) {
        toastGeneration += 1
        let generation = toastGeneration
        toastMessage = message
        toastIsError = isError
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2.2))
            guard generation == toastGeneration else { return }
            withAnimation(.easeOut(duration: 0.2)) { toastMessage = nil }
        }
    }

    private func tasteCategoryLabel(_ raw: String) -> String? { ["EXHIBITION":"전시·문화", "POPUP":"팝업·행사", "PERFORMANCE":"공연", "FOOD_CAFE":"맛집·카페", "OUTDOOR":"산책·야외", "EXPERIENCE":"체험·놀거리"][raw] }
    private func tasteCategoryRaw(_ label: String) -> String? { ["전시·문화":"EXHIBITION", "팝업·행사":"POPUP", "공연":"PERFORMANCE", "맛집·카페":"FOOD_CAFE", "산책·야외":"OUTDOOR", "체험·놀거리":"EXPERIENCE"][label] }
    private func tasteSpaceLabel(_ raw: String?) -> String { ["INDOOR":"실내", "OUTDOOR":"야외"][raw ?? ""] ?? "상관없음" }
    private func tasteSpaceRaw(_ label: String) -> String? { ["실내":"INDOOR", "야외":"OUTDOOR"][label] }
    private func tasteActivityLabel(_ raw: String?) -> String { ["LIGHT":"가볍게", "MODERATE":"적당히", "ACTIVE":"많이 움직여도 괜찮음"][raw ?? ""] ?? "" }
    private func tasteActivityRaw(_ label: String) -> String? { ["가볍게":"LIGHT", "적당히":"MODERATE", "많이 움직여도 괜찮음":"ACTIVE"][label] }
    private func tastePriceLabel(_ raw: String?) -> String { ["FREE":"무료 위주", "LOW":"부담 적게"][raw ?? ""] ?? "비용 상관없음" }
    private func tastePriceRaw(_ label: String) -> String? { ["무료 위주":"FREE", "부담 적게":"LOW"][label] }
    private func tasteDurationLabel(_ raw: String?) -> String { ["WITHIN_1H":"1시간 이내", "H1_TO_3":"1~3시간", "HALF_DAY_PLUS":"반나절 이상"][raw ?? ""] ?? "상관없음" }
    private func tasteDurationRaw(_ label: String) -> String? { ["1시간 이내":"WITHIN_1H", "1~3시간":"H1_TO_3", "반나절 이상":"HALF_DAY_PLUS"][label] }
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
                    let isSendEnabled = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    Button("보내기") {}.disabled(!isSendEnabled)
                        .font(KIRITypography.button)
                        .foregroundStyle(isSendEnabled ? KIRIColor.Button.FilledAccent.contentDefault : KIRIColor.Button.FilledNeutral.contentDefault)
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(isSendEnabled ? KIRIColor.Button.FilledAccent.backgroundDefault : KIRIColor.Button.FilledNeutral.backgroundDisabled)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .buttonStyle(.plain)
                    Text("건의 전송 API가 없어 서버로 전송하지 않습니다.").font(KIRITypography.caption).foregroundStyle(KIRIColor.Text.tertiary)
                    Spacer()
                }.padding(18)
            }
        }.toolbar(.hidden, for: .navigationBar)
    }
}
