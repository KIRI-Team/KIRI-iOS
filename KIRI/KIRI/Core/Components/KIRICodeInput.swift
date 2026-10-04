import SwiftUI

struct KIRICodeInput: View {

    @Binding var text: String

    var length: Int = 6

    @FocusState private var isFocused: Bool

    private var characters: [Character] {
        Array(text)
    }

    var body: some View {
        ZStack {
            HStack(spacing: 10) {
                ForEach(0..<length, id: \.self) { index in
                    codeCell(at: index)
                }
            }

            TextField("", text: $text)
                .focused($isFocused)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .keyboardType(.asciiCapable)
                .foregroundStyle(.clear)
                .tint(.clear)
                .opacity(0.01)
                .onChange(of: text) { _, newValue in
                    let sanitized = sanitize(newValue)

                    if sanitized != text {
                        text = sanitized
                    }
                }
                .accessibilityLabel("가족코드 입력")
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = true
        }
        .onAppear {
            let sanitized = sanitize(text)

            if sanitized != text {
                text = sanitized
            }
        }
    }

    // MARK: - Cell

    private func codeCell(
        at index: Int
    ) -> some View {
        let character = character(at: index)
        let isCurrent =
            isFocused &&
            text.count < length &&
            index == text.count

        return ZStack {
            RoundedRectangle(
                cornerRadius: 4
            )
            .fill(KIRIColor.Background.tertiary)

            if let character {
                Text(String(character))
                    .font(KIRITypography.headingSmall)
                    .tracking(-0.72)
                    .foregroundStyle(KIRIColor.Text.strong)
            } else {
                Rectangle()
                    .fill(
                        isCurrent
                            ? KIRIColor.Primary.default
                            : KIRIColor.Border.default
                    )
                    .frame(
                        width: 15,
                        height: isCurrent ? 2 : 1
                    )
            }
        }
        .frame(
            width: 43,
            height: 56
        )
        .overlay {
            if isCurrent {
                RoundedRectangle(
                    cornerRadius: 4
                )
                .stroke(
                    KIRIColor.Primary.default,
                    lineWidth: 1
                )
            }
        }
    }

    // MARK: - Helpers

    private func character(
        at index: Int
    ) -> Character? {
        guard characters.indices.contains(index) else {
            return nil
        }

        return characters[index]
    }

    private func sanitize(
        _ value: String
    ) -> String {
        let filtered = value
            .uppercased()
            .filter { character in
                character.isASCII &&
                (character.isLetter || character.isNumber)
            }

        return String(filtered.prefix(length))
    }
}

// MARK: - Preview

#Preview {
    KIRICodeInputPreview()
}

private struct KIRICodeInputPreview: View {

    @State private var code = "KI"

    var body: some View {
        ZStack {
            KIRIColor.Background.base
                .ignoresSafeArea()

            KIRICodeInput(
                text: $code
            )
        }
    }
}
