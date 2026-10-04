import SwiftUI

struct KIRIValidationGuidance: View {

    var items: [String] = [
        "한글/영어/숫자 혼합 가능",
        "최소 2자 ~ 최대 10자 이내",
        "특수 문자 입력 불가능"
    ]

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 3
        ) {
            ForEach(items, id: \.self) { item in
                Text("✓ \(item)")
                    .font(KIRITypography.captionMedium)
                    .tracking(-0.48)
                    .foregroundStyle(KIRIColor.Text.tertiary)
                    .frame(
                        minHeight: 17,
                        alignment: .leading
                    )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        KIRIColor.Background.base
            .ignoresSafeArea()

        KIRIValidationGuidance()
    }
}
