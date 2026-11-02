//
// MARK: - 파일 가이드
// 파일: Core/Components/KIRICodeInput.swift
// 담당 영역: 공통 컴포넌트·디자인 시스템·네트워크·저장소
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//

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
