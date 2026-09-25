import SwiftUI

struct MainTabView: View {
    enum AppTab: Hashable {
        case home
        case mission
        case record
        case myPage
    }

    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("홈", systemImage: "house.fill", value: AppTab.home) {
                HomeView()
            }

            Tab("미션", systemImage: "sparkles", value: AppTab.mission) {
                MissionView()
            }

            Tab("기록", systemImage: "calendar", value: AppTab.record) {
                RecordView()
            }

            Tab("마이", systemImage: "person.fill", value: AppTab.myPage) {
                MyPageView()
            }
        }
    }
}

#Preview {
    MainTabView()
}
