import SwiftUI

struct KIRITabBar: View {
    @Binding var selectedTab: MainTabView.AppTab

    private let tabBarHeight: CGFloat = 72
    private let cornerRadius: CGFloat = 30

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
        .padding(.horizontal, 8)
        .frame(height: tabBarHeight)
        .background {
            glassBackground
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: cornerRadius,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: cornerRadius,
                style: .continuous
            )
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.24),
                        Color.white.opacity(0.08),
                        Color.white.opacity(0.04)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.8
            )
        }
        .shadow(
            color: Color.black.opacity(0.28),
            radius: 20,
            x: 0,
            y: 8
        )
    }

    private var glassBackground: some View {
        ZStack {
            RoundedRectangle(
                cornerRadius: cornerRadius,
                style: .continuous
            )
            .fill(.ultraThinMaterial)

            RoundedRectangle(
                cornerRadius: cornerRadius,
                style: .continuous
            )
            .fill(
                Color.black.opacity(0.16)
            )

            RoundedRectangle(
                cornerRadius: cornerRadius,
                style: .continuous
            )
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.10),
                        Color.white.opacity(0.025),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

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
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(
                        .system(
                            size: 19,
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
                            size: 11,
                            weight: .semibold
                        )
                    )
                    .lineLimit(1)
            }
            .foregroundStyle(
                isSelected
                    ? Color.green
                    : Color.white.opacity(0.45)
            )
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(
            isSelected ? .isSelected : []
        )
    }
}

#Preview {
    @Previewable @State var selectedTab: MainTabView.AppTab = .home

    ZStack {
        KIRIColor.background
            .ignoresSafeArea()

        VStack {
            Spacer()

            KIRITabBar(
                selectedTab: $selectedTab
            )
            .padding(.horizontal, 18)
            .padding(.bottom, 8)
        }
    }
}
