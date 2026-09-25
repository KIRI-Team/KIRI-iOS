
import SwiftUI

struct KIRIPrimaryButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(KIRITypography.button)
                .foregroundStyle(
                    isEnabled
                    ? KIRIColor.selectedText
                    : KIRIColor.textSecondary
                )
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    isEnabled
                    ? KIRIColor.selectedBackground
                    : KIRIColor.disabled
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: KIRIRadius.pill
                    )
                )
        }
        .disabled(!isEnabled)
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        KIRIColor.background
            .ignoresSafeArea()

        VStack(spacing: 16) {
            KIRIPrimaryButton(
                title: "다음",
                isEnabled: true
            ) {}

            KIRIPrimaryButton(
                title: "다음",
                isEnabled: false
            ) {}
        }
        .padding()
    }
}
