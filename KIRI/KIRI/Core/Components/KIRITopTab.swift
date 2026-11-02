//
// MARK: - 파일 가이드
// 파일: Core/Components/KIRITopTab.swift
// 담당 영역: 공통 컴포넌트·디자인 시스템·네트워크·저장소
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//

import SwiftUI

struct KIRITopTab<Item: Hashable>: View {

    let items: [Item]
    @Binding var selection: Item
    let title: (Item) -> String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.self) { item in
                tabItem(item)
            }
        }
        .frame(height: 35)
    }

    // MARK: - Tab Item

    private func tabItem(
        _ item: Item
    ) -> some View {
        let isSelected = selection == item

        return Button {
            selection = item
        } label: {
            VStack(spacing: 8) {
                Text(title(item))
                    .font(KIRITypography.headingSmall)
                    .tracking(-0.72)
                    .foregroundStyle(
                        isSelected
                            ? KIRIColor.Tab.contentActive
                            : KIRIColor.Tab.contentDefault
                    )
                    .frame(
                        maxWidth: .infinity,
                        minHeight: 27,
                        maxHeight: 27
                    )

                Rectangle()
                    .fill(
                        isSelected
                            ? KIRIColor.Tab.indicatorActive
                            : KIRIColor.Tab.indicatorDefault
                    )
                    .frame(height: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title(item))
        .accessibilityAddTraits(
            isSelected
                ? .isSelected
                : []
        )
    }
}

// MARK: - Preview

private enum KIRITopTabPreviewItem: Hashable {
    case calendar
    case bucket
}

#Preview {
    @Previewable @State var selection: KIRITopTabPreviewItem = .calendar

    ZStack {
        KIRIColor.Background.base
            .ignoresSafeArea()

        KIRITopTab(
            items: [
                .calendar,
                .bucket
            ],
            selection: $selection
        ) { item in
            switch item {
            case .calendar:
                return "캘린더"

            case .bucket:
                return "버킷리스트"
            }
        }
        .padding(.horizontal, 18)
    }
}
