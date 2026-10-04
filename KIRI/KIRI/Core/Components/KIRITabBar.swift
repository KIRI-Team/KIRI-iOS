import SwiftUI

struct KIRITabBar: View {

    @Binding var selectedTab: MainTabView.AppTab

    private let height: CGFloat = 64

    var body: some View {
        HStack(spacing: 0) {
            tabButton(
                tab: .home,
                title: "홈",
                icon: "house.fill"
            )

            tabButton(
                tab: .mission,
                title: "미션",
                icon: "sparkles"
            )

            tabButton(
                tab: .record,
                title: "기록",
                icon: "calendar"
            )

            tabButton(
                tab: .myPage,
                title: "마이",
                icon: "person.fill"
            )
        }
        .padding(4)
        .frame(height: height)
        .background(
            KIRIColor.Navigation.Bar.background
        )
        .clipShape(
            Capsule()
        )
        .overlay {
            Capsule()
                .stroke(
                    KIRIColor.Navigation.Bar.border,
                    lineWidth: 1
                )
        }
    }

    // MARK: - Tab Button

    private func tabButton(
        tab: MainTabView.AppTab,
        title: String,
        icon: String
    ) -> some View {

        let isSelected = selectedTab == tab

        return Button {
            withAnimation(
                .easeInOut(duration: 0.18)
            ) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(
                        .system(
                            size: 18,
                            weight: .semibold
                        )
                    )
                    .frame(
                        width: 24,
                        height: 24
                    )

                Text(title)
                    .font(
                        .system(
                            size: 10,
                            weight: .medium
                        )
                    )
                    .lineLimit(1)
            }
            .foregroundStyle(
                isSelected
                ? KIRIColor.Navigation.Item.contentActive
                : KIRIColor.Navigation.Item.contentDefault
            )
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                isSelected
                ? KIRIColor.Navigation.Item.backgroundActive
                : KIRIColor.Navigation.Item.backgroundDefault
            )
            .clipShape(
                Capsule()
            )
            .contentShape(
                Capsule()
            )
        }
        .buttonStyle(
            KIRITabItemButtonStyle(
                isSelected: isSelected
            )
        )
        .accessibilityLabel(title)
        .accessibilityAddTraits(
            isSelected
            ? .isSelected
            : []
        )
    }
}

// MARK: - Tab Item Button Style

private struct KIRITabItemButtonStyle: ButtonStyle {

    let isSelected: Bool

    func makeBody(
        configuration: Configuration
    ) -> some View {
        configuration.label
            .opacity(
                configuration.isPressed
                ? 0.8
                : 1
            )
            .scaleEffect(
                configuration.isPressed
                ? 0.97
                : 1
            )
            .animation(
                .easeOut(duration: 0.1),
                value: configuration.isPressed
            )
    }
}

// MARK: - Preview

#Preview {
    @Previewable
    @State var selectedTab:
        MainTabView.AppTab = .home

    ZStack {
        KIRIColor.Background.base
            .ignoresSafeArea()

        VStack {
            Spacer()

            KIRITabBar(
                selectedTab: $selectedTab
            )
            .padding(
                .horizontal,
                KIRISpacing.horizontal
            )
            .padding(
                .bottom,
                KIRISpacing.small
            )
        }
    }
}
