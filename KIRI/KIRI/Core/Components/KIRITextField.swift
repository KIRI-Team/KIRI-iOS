
import SwiftUI

struct KIRITextField: View {
    let placeholder: String

    @Binding var text: String

    var body: some View {
        TextField(
            "",
            text: $text,
            prompt: Text(placeholder)
                .foregroundStyle(KIRIColor.textSecondary)
        )
        .font(KIRITypography.body)
        .foregroundStyle(KIRIColor.textPrimary)
        .padding(.horizontal, 24)
        .frame(height: 60)
        .background(KIRIColor.surface)
        .clipShape(
            RoundedRectangle(
                cornerRadius: KIRIRadius.large
            )
        )
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
    }
}

#Preview {
    @Previewable @State var text = ""

    ZStack {
        KIRIColor.background
            .ignoresSafeArea()

        KIRITextField(
            placeholder: "이름을 입력하세요.",
            text: $text
        )
        .padding()
    }
}
