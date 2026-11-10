//
// MARK: - 파일 가이드
// 파일: Core/Components/KIRITabBar.swift
// 담당 화면: 홈·미션·기록·마이 공통 하단 내비게이션 (Figma 9901:23908)
// 주요 책임: 선택 탭, 아이콘/라벨 상태, 352×65pt 플로팅 글래스 바를 렌더링합니다.
// UI 수정 위치: 바 크기와 패딩은 body, 아이콘은 tabIcon, 탭 제목은 title(for:),
// 활성/비활성 색상은 KIRIColor.Navigation에서 조정합니다.
// 데이터 흐름: MainTabView의 selectedTab Binding을 받아 탭 전환을 전달합니다.
// 주의: 이 컴포넌트 수정은 네 개 탭 전체에 영향을 주므로 미션 화면 전용 구현을 추가하지 않습니다.
//

import SwiftUI

/// MainTabView가 표시하는 공통 탭바를 상세/입력 화면에서 숨기기 위한 환경 값입니다.
/// NavigationStack·route 내부 화면은 이 Binding을 false로 바꾸고, 사라질 때 true로 복원합니다.
private struct KIRITabBarVisibilityKey: EnvironmentKey {
    static let defaultValue = Binding.constant(true)
}

extension EnvironmentValues {
    var kiriTabBarVisibility: Binding<Bool> {
        get { self[KIRITabBarVisibilityKey.self] }
        set { self[KIRITabBarVisibilityKey.self] = newValue }
    }
}

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
        .padding(6)
        .frame(width: 352, height: 65)
        // Figma KIRI/Bottom Navigation은 배경이 비치는 플로팅 글래스 바입니다.
        // Material만으로 색이 달라지지 않도록 반투명 토큰을 함께 사용합니다.
        .background(.ultraThinMaterial, in: Capsule())
        .background(
            KIRIColor.Navigation.Bar.background.opacity(0.82),
            in: Capsule()
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
                tabIcon(tab, isSelected: isSelected)

                Text(
                    title(for: tab)
                )
                .font(KIRITypography.navigation)
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
                minHeight: 53,
                maxHeight: 53
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

    @ViewBuilder
    private func tabIcon(_ tab: MainTabView.AppTab, isSelected: Bool) -> some View {
        if tab == .mission {
            Image("figma_place_disabled")
                .renderingMode(isSelected ? .template : .original)
                .resizable()
                .scaledToFit()
                .foregroundStyle(isSelected ? KIRIColor.Navigation.Item.contentActive : KIRIColor.Navigation.Item.contentDefault)
                .frame(width: 24, height: 24)
        } else if let assetName = figmaAssetName(for: tab, isSelected: isSelected) {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
        } else {
            Image(systemName: isSelected ? activeIconName(for: tab) : iconName(for: tab))
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 24, height: 28)
        }
    }

    private func figmaAssetName(for tab: MainTabView.AppTab, isSelected: Bool) -> String? {
        switch (tab, isSelected) {
        case (.home, true): return "figma_home_active"
        case (.record, true): return "figma_calendar_active"
        case (.record, false): return "figma_calendar_disabled"
        case (.myPage, true): return "figma_profile_active"
        case (.myPage, false): return "figma_profile_disabled"
        case (.mission, false): return "figma_place_disabled"
        default: return nil
        }
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
            return "마이페이지"
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
