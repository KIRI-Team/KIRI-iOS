import SwiftUI

struct FamilyCodeView: View {
    let familyName: String
    let familyCode: String

    let onBack: () -> Void
    let onComplete: () -> Void

    @State private var didCopyCode = false
    @State private var isShareSheetPresented = false

    private var shareMessage: String {
        """
        KIRI에서 우리 가족공간에 초대했어요!

        가족명: \(familyName)
        가족코드: \(familyCode)

        KIRI 앱에서 가족코드를 입력하고 함께 시작해보세요.
        """
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            VStack(alignment: .center, spacing: 0) {
                Text("가족코드\n생성이 완료되었어요!")
                    .font(KIRITypography.title)
                    .foregroundStyle(KIRIColor.Text.strong)
                    .multilineTextAlignment(.center)
                    .lineSpacing(7)

                Text("복사해서 가족에게 보내주세요")
                    .font(KIRITypography.subtitle)
                    .foregroundStyle(KIRIColor.Text.secondary)
                    .padding(.top, 12)

                familyCodeCard
                    .padding(.top, 58)

                HStack(spacing: 8) {
                    Button("취소", action: onComplete)
                        .buttonStyle(InviteSecondaryButtonStyle())

                    Button("초대하기") {
                        isShareSheetPresented = true
                    }
                    .buttonStyle(InvitePrimaryButtonStyle())
                }
                .padding(.top, 18)
            }
            .padding(.horizontal, KIRISpacing.horizontal)
        }
        .background(KIRIColor.Background.base)
        .sheet(isPresented: $isShareSheetPresented) {
            KIRIShareSheet(
                items: [shareMessage]
            )
        }
    }

    private var header: some View {
        HStack {
            KIRIBackButton(action: onBack)

            Spacer()
        }
        .padding(.horizontal, 4)
        .frame(height: 70)
    }

    private var familyCodeCard: some View {
        VStack(spacing: 8) {
            Text("링크코드")
                .font(KIRITypography.caption)
                .foregroundStyle(KIRIColor.Text.tertiary)

            Button {
                copyFamilyCode()
            } label: {
                HStack(spacing: 6) {
                    Text(familyCode)
                        .font(.system(size: 22, weight: .regular))
                        .tracking(1.2)
                        .foregroundStyle(KIRIColor.Text.strong)

                    Image("family_code_copy")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
            }
            .buttonStyle(.plain)
        }
        .frame(width: 311, height: 90)
        .background(KIRIColor.Background.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func copyFamilyCode() {
        UIPasteboard.general.string = familyCode

        withAnimation {
            didCopyCode = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                didCopyCode = false
            }
        }
    }
}

private struct InvitePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(KIRITypography.button)
            .foregroundStyle(KIRIColor.Text.onGreen)
            .frame(width: 173, height: 54)
            .background(configuration.isPressed ? KIRIColor.Primary.pressed : KIRIColor.Primary.default)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct InviteSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(KIRITypography.button)
            .foregroundStyle(KIRIColor.Text.primary)
            .frame(width: 173, height: 54)
            .background(configuration.isPressed ? KIRIColor.State.pressed : KIRIColor.Background.primary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    FamilyCodeView(
        familyName: "끼리가족",
        familyCode: "KIRI24",
        onBack: {},
        onComplete: {}
    )
    .background(KIRIColor.background)
}
