import SwiftUI

struct MyPageView: View {
    let onLogout: () -> Void

    @State private var isLogoutAlertPresented = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                profileSection

                Divider()
                    .padding(.horizontal, KIRISpacing.horizontal)

                menuSection

                Spacer()
            }
            .background(KIRIColor.background)
            .navigationTitle("마이")
            .navigationBarTitleDisplayMode(.large)
            .alert(
                "로그아웃할까요?",
                isPresented: $isLogoutAlertPresented
            ) {
                Button(
                    "취소",
                    role: .cancel
                ) {
                }

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

    private var profileSection: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(KIRIColor.surface)
                    .frame(width: 60, height: 60)

                Image(systemName: "person.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(KIRIColor.textSecondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("내 프로필")
                    .font(KIRITypography.bodyMedium)
                    .foregroundStyle(KIRIColor.textPrimary)

                Text("프로필 정보는 서버 연동 후 표시됩니다.")
                    .font(KIRITypography.caption)
                    .foregroundStyle(KIRIColor.textSecondary)
            }

            Spacer()
        }
        .padding(.horizontal, KIRISpacing.horizontal)
        .padding(.vertical, 24)
    }

    private var menuSection: some View {
        VStack(spacing: 0) {
            Button {
                isLogoutAlertPresented = true
            } label: {
                HStack {
                    Text("로그아웃")
                        .font(KIRITypography.bodyMedium)
                        .foregroundStyle(KIRIColor.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(KIRIColor.textSecondary)
                }
                .frame(height: 56)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, KIRISpacing.horizontal)
        .padding(.top, 12)
    }
}

#Preview {
    MyPageView(
        onLogout: {}
    )
}
