import SwiftUI

struct KIRITabBar: View {

    @Binding var selectedTab: MainTabView.AppTab

    private let tabs: [MainTabView.AppTab] = [
        .home,
        .mission,
        .record,
        .myPage
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(
                tabs,
                id: \.self
            ) { tab in
                tabItem(tab)
            }
        }
        .padding(4)
        .frame(height: 62)
        .background(
            KIRIColor.Navigation.Bar.background
        )
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(
                    KIRIColor.Navigation.Bar.border,
                    lineWidth: 1
                )
        }
    }

    // MARK: - Item

    private func tabItem(
        _ tab: MainTabView.AppTab
    ) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            withAnimation(
                .easeOut(duration: 0.15)
            ) {
                selectedTab = tab
            }
        } label: {
            VStack(
                spacing: isSelected ? 1 : 0.5
            ) {
                Image(
                    systemName:
                        isSelected
                            ? activeIconName(for: tab)
                            : iconName(for: tab)
                )
                .font(
                    .system(
                        size: 18,
                        weight: .semibold
                    )
                )
                .frame(
                    width: 24,
                    height: 28
                )

                Text(
                    title(for: tab)
                )
                .font(
                    .system(
                        size: 10,
                        weight: .semibold
                    )
                )
                .tracking(
                    isSelected
                        ? -0.1
                        : 0
                )
                .frame(height: 12)
            }
            .foregroundStyle(
                isSelected
                    ? KIRIColor.Navigation.Item.contentActive
                    : KIRIColor.Navigation.Item.contentDefault
            )
            .frame(
                maxWidth: .infinity,
                minHeight: 54,
                maxHeight: 54
            )
            .background {
                if isSelected {
                    Capsule()
                        .fill(
                            KIRIColor.Navigation.Item.backgroundActive
                        )
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(
            KIRITabButtonStyle()
        )
        .accessibilityLabel(
            title(for: tab)
        )
        .accessibilityAddTraits(
            isSelected
                ? .isSelected
                : []
        )
    }

    // MARK: - Title

    private func title(
        for tab: MainTabView.AppTab
    ) -> String {
        switch tab {
        case .home:
            return "홈"

        case .mission:
            return "미션"

        case .record:
            return "기록"

        case .myPage:
            return "마이"
        }
    }

    // MARK: - Icon

    private func iconName(
        for tab: MainTabView.AppTab
    ) -> String {
        switch tab {
        case .home:
            return "house"

        case .mission:
            return "flag"

        case .record:
            return "calendar"

        case .myPage:
            return "person"
        }
    }

    private func activeIconName(
        for tab: MainTabView.AppTab
    ) -> String {
        switch tab {
        case .home:
            return "house.fill"

        case .mission:
            return "flag.fill"

        case .record:
            return "calendar"

        case .myPage:
            return "person.fill"
        }
    }
}

// MARK: - Button Style

private struct KIRITabButtonStyle: ButtonStyle {

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
