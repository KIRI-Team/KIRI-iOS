
import SwiftUI

struct AuthEntryView: View {
    let onLogin: () -> Void
    let onSignUp: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 18) {
                Text("KIRI")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(KIRIColor.textPrimary)

                Text("우리 가족만의 취향,\n우리 가족만의 시간")
                    .font(KIRITypography.subtitle)
                    .foregroundStyle(KIRIColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
            }

            Spacer()

            VStack(spacing: 12) {
                KIRIPrimaryButton(
                    title: "로그인",
                    action: onLogin
                )

                Button(action: onSignUp) {
                    Text("회원가입")
                        .font(KIRITypography.button)
                        .foregroundStyle(KIRIColor.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(KIRIColor.surface)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: KIRIRadius.large
                            )
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, KIRISpacing.horizontal)
            .padding(.bottom, 20)
        }
        .background(KIRIColor.background)
    }
}

#Preview {
    AuthEntryView(
        onLogin: {},
        onSignUp: {}
    )
}
