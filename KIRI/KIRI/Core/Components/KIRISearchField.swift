import SwiftUI

struct KIRISearchField: View {

    @Binding var text: String

    var placeholder: String = "장소나 활동을 검색해보세요"
    var onSubmit: (() -> Void)? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(
                    .system(
                        size: 18,
                        weight: .medium
                    )
                )
                .foregroundStyle(KIRIColor.Icon.secondary)
                .frame(
                    width: 24,
                    height: 24
                )

            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(KIRITypography.bodyMedium)
                        .tracking(-0.64)
                        .foregroundStyle(KIRIColor.Text.secondary)
                        .allowsHitTesting(false)
                }

                TextField("", text: $text)
                    .font(KIRITypography.bodyMedium)
                    .tracking(-0.64)
                    .foregroundStyle(KIRIColor.Text.primary)
                    .tint(KIRIColor.Primary.default)
                    .focused($isFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        onSubmit?()
                    }
            }

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(KIRIColor.Icon.secondary)
                        .frame(
                            width: 24,
                            height: 24
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("검색어 지우기")
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 56)
        .background(KIRIColor.Background.secondary)
        .clipShape(
            RoundedRectangle(
                cornerRadius: KIRIRadius.large
            )
        )
    }
}

// MARK: - Preview

#Preview {
    KIRISearchFieldPreview()
}

private struct KIRISearchFieldPreview: View {

    @State private var searchText = ""

    var body: some View {
        ZStack {
            KIRIColor.Background.base
                .ignoresSafeArea()

            KIRISearchField(
                text: $searchText
            )
            .padding(.horizontal, 18)
        }
    }
}
