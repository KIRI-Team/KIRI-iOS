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

            VStack(alignment: .leading, spacing: 0) {
                Text("가족공간이\n완성되었어요!")
                    .font(KIRITypography.title)
                    .foregroundStyle(KIRIColor.textPrimary)
                    .lineSpacing(7)

                Text("가족들에게 코드를 공유하고 함께 시작해보세요.")
                    .font(KIRITypography.subtitle)
                    .foregroundStyle(KIRIColor.textSecondary)
                    .padding(.top, 12)

                Spacer()

                familyCodeCard

                Spacer()

                VStack(spacing: 12) {
                    KIRIPrimaryButton(
                        title: "초대하기",
                        action: {
                            isShareSheetPresented = true
                        }
                    )

                    Button(action: onComplete) {
                        Text("나중에 할게요")
                            .font(KIRITypography.button)
                            .foregroundStyle(KIRIColor.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, KIRISpacing.horizontal)
            .padding(.bottom, 10)
        }
        .background(KIRIColor.background)
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
        VStack(spacing: 22) {
            VStack(spacing: 8) {
                Text(familyName)
                    .font(KIRITypography.subtitle)
                    .foregroundStyle(KIRIColor.textSecondary)

                Text("가족코드")
                    .font(KIRITypography.caption)
                    .foregroundStyle(KIRIColor.textSecondary)
            }

            Text(familyCode)
                .font(.system(size: 30, weight: .semibold))
                .tracking(5)
                .foregroundStyle(KIRIColor.textPrimary)

            Button {
                copyFamilyCode()
            } label: {
                HStack(spacing: 8) {
                    Image(
                        systemName: didCopyCode
                            ? "checkmark"
                            : "doc.on.doc"
                    )

                    Text(
                        didCopyCode
                            ? "복사했어요"
                            : "코드 복사"
                    )
                }
                .font(KIRITypography.bodyMedium)
                .foregroundStyle(KIRIColor.textPrimary)
                .padding(.horizontal, 20)
                .frame(height: 44)
                .background(KIRIColor.background)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(KIRIColor.surface)
        .clipShape(
            RoundedRectangle(
                cornerRadius: KIRIRadius.xLarge
            )
        )
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

#Preview {
    FamilyCodeView(
        familyName: "끼리가족",
        familyCode: "KIRI24",
        onBack: {},
        onComplete: {}
    )
    .background(KIRIColor.background)
}
