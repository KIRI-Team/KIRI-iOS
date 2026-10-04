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
