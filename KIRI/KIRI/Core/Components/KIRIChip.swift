
import SwiftUI

struct KIRIChip: View {

    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(KIRITypography.bodySmallMedium)
                .tracking(-0.56)
                .foregroundStyle(
                    isSelected
                        ? KIRIColor.Chip.contentSelected
                        : KIRIColor.Chip.contentDefault
                )
                .frame(height: 20)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected
                        ? KIRIColor.Chip.backgroundSelected
                        : KIRIColor.Chip.backgroundDefault
                )
                .clipShape(Capsule())
        }
        .buttonStyle(KIRIChipButtonStyle())
        .accessibilityAddTraits(
            isSelected
                ? .isSelected
                : []
        )
    }
}

private struct KIRIChipButtonStyle: ButtonStyle {

    func makeBody(
        configuration: Configuration
    ) -> some View {
        configuration.label
            .opacity(
                configuration.isPressed
                    ? 0.8
                    : 1
            )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        KIRIColor.Background.base
            .ignoresSafeArea()

        HStack(spacing: 8) {
            KIRIChip(
                title: "전체",
                isSelected: true,
                action: {}
            )

            KIRIChip(
                title: "전시·문화",
                isSelected: false,
                action: {}
            )
        }
    }
}
