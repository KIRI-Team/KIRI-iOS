import SwiftUI

struct KIRIValidationGuidance: View {

    enum ValidationState {
        case neutral
        case invalid
        case valid
    }

    var items: [String] = [
        "한글/영어/숫자 혼합 가능",
        "최소 2자 ~ 최대 12자 이내",
        "특수 문자 입력 불가능"
    ]
    var state: ValidationState = .neutral

    private var textColor: Color {
        switch state {
        case .neutral:
            return KIRIColor.Text.tertiary
        case .invalid:
            return KIRIColor.Status.error
        case .valid:
            return KIRIColor.Status.success
        }
    }

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 3
        ) {
            ForEach(items, id: \.self) { item in
                Text("✓ \(item)")
                    .font(KIRITypography.captionMedium)
                    .tracking(-0.48)
                    .foregroundStyle(textColor)
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
