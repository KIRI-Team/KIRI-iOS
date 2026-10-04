import SwiftUI

struct KIRISearchField: View {

    @Binding var text: String

    var placeholder: String = "장소나 활동을 검색해보세요"
    var onSubmit: (() -> Void)? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 0) {
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(KIRITypography.bodyMedium)
                        .tracking(-0.64)
                        .foregroundStyle(KIRIColor.Input.helperDefault)
                        .allowsHitTesting(false)
                }

                TextField("", text: $text)
                    .font(KIRITypography.bodyMedium)
                    .tracking(-0.64)
                    .foregroundStyle(KIRIColor.Input.contentDefault)
                    .tint(KIRIColor.Primary.default)
                    .focused($isFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        onSubmit?()
                    }
            }
            .padding(.leading, 20)

            trailingButton
        }
        .frame(height: 56)
        .background(KIRIColor.Input.backgroundDefault)
        .clipShape(
            RoundedRectangle(
                cornerRadius: KIRIRadius.large
            )
        )
    }

    // MARK: - Trailing Button

    private var trailingButton: some View {
        Button {
            if text.isEmpty {
                isFocused = true
            } else {
                text = ""
                isFocused = true
            }
        } label: {
            Image(
                systemName: text.isEmpty
                    ? "magnifyingglass"
                    : "xmark"
            )
            .font(
                .system(
                    size: 17,
                    weight: .medium
                )
            )
            .foregroundStyle(KIRIColor.Icon.secondary)
            .frame(
                width: 48,
                height: 48
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.trailing, 4)
        .accessibilityLabel(
            text.isEmpty
                ? "검색"
                : "검색어 지우기"
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
