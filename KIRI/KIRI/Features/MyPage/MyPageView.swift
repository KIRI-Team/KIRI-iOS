import SwiftUI

struct MyPageView: View {
    let onLogout: () -> Void

    @State private var isLogoutAlertPresented = false

    var body: some View {
        NavigationStack {
            ZStack {
                KIRIColor.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        header

                        profileSection
                            .padding(.top, 26)

                        tasteTestButton
                            .padding(.top, 28)

                        familyManagementSection
                            .padding(.top, 36)

                        settingsSection
                            .padding(.top, 46)

                        logoutButton
                            .padding(.top, 20)

                        Color.clear
                            .frame(height: 120)
                    }
                    .padding(.horizontal, 18)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .alert(
                "로그아웃할까요?",
                isPresented: $isLogoutAlertPresented
            ) {
                Button(
                    "취소",
                    role: .cancel
                ) {}

                Button(
                    "로그아웃",
                    role: .destructive
                ) {
                    onLogout()
                }
            } message: {
                Text("현재 계정에서 로그아웃합니다.")
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        Text("설정")
            .font(
                .system(
                    size: 18,
                    weight: .semibold
                )
            )
            .foregroundStyle(
                KIRIColor.textPrimary
            )
            .frame(maxWidth: .infinity)
            .padding(.top, 14)
    }

    // MARK: - Profile

    private var profileSection: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        Color.white.opacity(0.14)
                    )
                    .frame(
                        width: 48,
                        height: 48
                    )

                Image(
                    systemName: "person.2.fill"
                )
                .font(
                    .system(
                        size: 20,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    Color.white.opacity(0.32)
                )
            }

            VStack(
                alignment: .leading,
                spacing: 5
            ) {
                Text("쥬123")
                    .font(
                        .system(
                            size: 17,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        KIRIColor.textPrimary
                    )

                Text("끼리네가족 | 딸")
                    .font(
                        .system(
                            size: 13,
                            weight: .regular
                        )
                    )
                    .foregroundStyle(
                        KIRIColor.textSecondary
                    )
            }

            Spacer()

            Button {
                // TODO: 프로필 수정
            } label: {
                Image(systemName: "pencil")
                    .font(
                        .system(
                            size: 17,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        Color.white.opacity(0.55)
                    )
                    .frame(
                        width: 40,
                        height: 40
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("프로필 수정")
        }
    }

    // MARK: - Taste Test

    private var tasteTestButton: some View {
        Button {
            // TODO: 취향 테스트
        } label: {
            HStack {
                Text("취향테스트 하기")
                    .font(
                        .system(
                            size: 16,
                            weight: .regular
                        )
                    )
                    .foregroundStyle(
                        KIRIColor.textPrimary
                    )

                Spacer()

                Image(
                    systemName: "chevron.right"
                )
                .font(
                    .system(
                        size: 16,
                        weight: .regular
                    )
                )
                .foregroundStyle(
                    Color.white.opacity(0.25)
                )
            }
            .padding(.horizontal, 16)
            .frame(height: 88)
            .background(
                RoundedRectangle(
                    cornerRadius: 8,
                    style: .continuous
                )
                .fill(
                    Color.white.opacity(0.07)
                )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Family Management

    private var familyManagementSection: some View {
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            sectionTitle("가족관리")

            menuCard {
                NavigationLink {
                    FamilySettingsView()
                } label: {
                    menuRowLabel(
                        title: "가족 기본 설정"
                    )
                }
                .buttonStyle(.plain)

                Button {
                    // TODO: 우리집 주소 설정
                } label: {
                    menuRowLabel(
                        title: "우리집 주소 설정"
                    )
                }
                .buttonStyle(.plain)

                Button {
                    // TODO: 공용 초대링크 관리
                } label: {
                    menuRowLabel(
                        title: "공용초대링크 관리"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(
            alignment: .leading,
            spacing: 16
        ) {
            sectionTitle("설정")

            menuCard {
                Button {
                    // TODO: 계정 정보
                } label: {
                    menuRowLabel(
                        title: "계정 정보"
                    )
                }
                .buttonStyle(.plain)

                Button {
                    // TODO: 건의함
                } label: {
                    menuRowLabel(
                        title: "건의함"
                    )
                }
                .buttonStyle(.plain)

                Button {
                    // TODO: 약관정보
                } label: {
                    menuRowLabel(
                        title: "약관정보"
                    )
                }
                .buttonStyle(.plain)

                Button {
                    // TODO: 알림 설정
                } label: {
                    menuRowLabel(
                        title: "알림 설정"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Logout

    private var logoutButton: some View {
        Button {
            isLogoutAlertPresented = true
        } label: {
            HStack {
                Text("로그아웃")
                    .font(
                        .system(
                            size: 15,
                            weight: .regular
                        )
                    )
                    .foregroundStyle(
                        KIRIColor.textSecondary
                    )

                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Components

    private func sectionTitle(
        _ title: String
    ) -> some View {
        Text(title)
            .font(
                .system(
                    size: 17,
                    weight: .medium
                )
            )
            .foregroundStyle(
                KIRIColor.textPrimary
            )
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
    }

    private func menuCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(
            RoundedRectangle(
                cornerRadius: 8,
                style: .continuous
            )
            .fill(
                Color.white.opacity(0.07)
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 8,
                style: .continuous
            )
        )
    }

    private func menuRowLabel(
        title: String
    ) -> some View {
        HStack {
            Text(title)
                .font(
                    .system(
                        size: 16,
                        weight: .regular
                    )
                )
                .foregroundStyle(
                    KIRIColor.textPrimary
                )

            Spacer()

            Image(
                systemName: "chevron.right"
            )
            .font(
                .system(
                    size: 16,
                    weight: .regular
                )
            )
            .foregroundStyle(
                Color.white.opacity(0.25)
            )
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .contentShape(Rectangle())
    }
}

#Preview {
    MyPageView(
        onLogout: {}
    )
}
