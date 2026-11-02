//
// MARK: - 파일 가이드
// 파일: Core/Components/KIRISearchField.swift
// 담당 영역: 공통 컴포넌트·디자인 시스템·네트워크·저장소
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//

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
