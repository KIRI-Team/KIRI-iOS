import SwiftUI
struct NotificationView: View {
    private enum NotificationFilter:
        String,
        CaseIterable,
        Hashable {
        case inbox = "받은 메일함"
        case schedule = "일정 알림"
        case poke = "콕 알림"
        case record = "기록 알림"
        case mission = "미션 알림"
    }
    private enum NotificationKind {
        case schedule
        case poke
        case record
        case mission
        var icon: String {
            switch self {
            case .schedule:
                return "calendar"
            case .poke:
                return "hand.tap"
            case .record:
                return "book.closed"
            case .mission:
                return "flag"
            }
        }
        var filter: NotificationFilter {
            switch self {
            case .schedule:
                return .schedule
            case .poke:
                return .poke
            case .record:
                return .record
            case .mission:
                return .mission
            }
        }
    }
    private struct NotificationItem:
        Identifiable,
        Equatable {
        let id: Int
        let kind: NotificationKind
        let description: String
        let time: String
        let opensInvitation: Bool
    }
    let onBack: () -> Void
    let onSelectInvitation: () -> Void
    @State private var selectedFilter:
        NotificationFilter = .inbox
    @State private var readNotificationIDs:
        Set<Int> = []
    // 최신 OpenAPI에는 알림함 목록/읽음 처리 endpoint가 없습니다.
    // 서버 데이터가 없는 상태에서 샘플 알림을 실제 알림처럼 노출하지 않습니다.
    private let notifications: [NotificationItem] = []
    private var filteredNotifications:
        [NotificationItem] {
        guard selectedFilter != .inbox else {
            return notifications
        }
        return notifications.filter {
            $0.kind.filter == selectedFilter
        }
    }
    private var unreadCount: Int {
        notifications.filter {
            !readNotificationIDs.contains($0.id)
        }
        .count
    }
    var body: some View {
        ZStack {
            KIRIColor.Background.base
                .ignoresSafeArea()
            VStack(spacing: 0) {
                navigationBar
                filterSection
                    .padding(.top, 18)
                notificationList
                    .padding(.top, 24)
            }
        }
    }
    // MARK: - Navigation
    private var navigationBar: some View {
        ZStack {
            HStack(spacing: 6) {
                Text("알림함")
                    .font(KIRITypography.headingSmall)
                    .tracking(-0.72)
                    .foregroundStyle(
                        KIRIColor.Text.strong
                    )
                if unreadCount > 0 {
                    Text(
                        unreadCount > 99
                            ? "+99"
                            : "+\(unreadCount)"
                    )
                    .font(KIRITypography.bodySmallMedium)
                    .tracking(-0.56)
                    .foregroundStyle(
                        KIRIColor.Text.accent
                    )
                }
            }
            HStack {
                KIRIBackButton(
                    action: onBack
                )
                Spacer()
                Button {
                    markAllAsRead()
                } label: {
                    Text("모두읽음")
                        .font(KIRITypography.bodySmall)
                        .tracking(-0.56)
                        .foregroundStyle(
                            KIRIColor.Text.secondary
                        )
                        .frame(
                            minWidth: 60,
                            minHeight: 44
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 6)
        }
        .frame(height: 62)
    }
    // MARK: - Filter
    private var filterSection: some View {
        ScrollView(
            .horizontal,
            showsIndicators: false
        ) {
            HStack(spacing: 8) {
                ForEach(
                    NotificationFilter.allCases,
                    id: \.self
                ) { filter in
                    filterButton(filter)
                }
            }
            .padding(.horizontal, 18)
        }
    }
    private func filterButton(
        _ filter: NotificationFilter
    ) -> some View {
        Button {
            withAnimation(
                .easeOut(duration: 0.15)
            ) {
                selectedFilter = filter
            }
        } label: {
            Text(filter.rawValue)
                .font(KIRITypography.bodySmallMedium)
                .tracking(-0.56)
                .foregroundStyle(
                    selectedFilter == filter
                        ? KIRIColor.Text.onGreen
                        : KIRIColor.Text.secondary
                )
                .padding(.horizontal, 14)
                .frame(height: 36)
                .background(
                    selectedFilter == filter
                        ? KIRIColor.Primary.default
                        : KIRIColor.Background.tertiary
                )
                .clipShape(
                    Capsule()
                )
        }
        .buttonStyle(.plain)
    }
    // MARK: - Notification List
    private var notificationList: some View {
        ScrollView(
            .vertical,
            showsIndicators: false
        ) {
            LazyVStack(spacing: 0) {
                ForEach(filteredNotifications) {
                    notification in
                    notificationRow(notification)
                    Divider()
                        .overlay(
                            KIRIColor.Border.subtle
                        )
                        .padding(.leading, 78)
                }
                if filteredNotifications.isEmpty {
                    Text("새로운 알림이 없어요")
                        .font(KIRITypography.bodySmall)
                        .foregroundStyle(KIRIColor.Text.tertiary)
                        .frame(maxWidth: .infinity, minHeight: 240)
                }
                Color.clear
                    .frame(height: 120)
            }
        }
    }
    private func notificationRow(
        _ notification: NotificationItem
    ) -> some View {
        Button {
            handleNotificationTap(
                notification
            )
        } label: {
            HStack(
                alignment: .top,
                spacing: 14
            ) {
                notificationIcon(
                    notification
                )
                VStack(
                    alignment: .leading,
                    spacing: 7
                ) {
                    HStack(
                        alignment: .top,
                        spacing: 8
                    ) {
                        VStack(
                            alignment: .leading,
                            spacing: 5
                        ) {
                            Text(
                                notification.description
                            )
                            .font(
                                KIRITypography.bodySmall
                            )
                            .tracking(-0.56)
                            .foregroundStyle(
                                isRead(notification)
                                    ? KIRIColor.Text.secondary
                                    : KIRIColor.Text.strong
                            )
                            .multilineTextAlignment(
                                .leading
                            )
                            .fixedSize(
                                horizontal: false,
                                vertical: true
                            )
                        }
                        Spacer(minLength: 8)
                        if !isRead(notification) {
                            Circle()
                                .fill(
                                    KIRIColor.Primary.default
                                )
                                .frame(
                                    width: 7,
                                    height: 7
                                )
                                .padding(.top, 6)
                        }
                    }
                    Text(notification.time)
                        .font(KIRITypography.caption)
                        .tracking(-0.48)
                        .foregroundStyle(
                            KIRIColor.Text.tertiary
                        )
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    // MARK: - Icon
    private func notificationIcon(
        _ notification: NotificationItem
    ) -> some View {
        ZStack {
            Circle()
                .fill(
                    KIRIColor.Background.tertiary
                )
            Image(
                systemName: notification.kind.icon
            )
            .font(
                .system(
                    size: 19,
                    weight: .regular
                )
            )
            .foregroundStyle(
                KIRIColor.Icon.primary
            )
        }
        .frame(
            width: 46,
            height: 46
        )
    }
    // MARK: - State
    private func isRead(
        _ notification: NotificationItem
    ) -> Bool {
        readNotificationIDs.contains(
            notification.id
        )
    }
    private func markAllAsRead() {
        withAnimation(
            .easeOut(duration: 0.15)
        ) {
            readNotificationIDs = Set(
                notifications.map(\.id)
            )
        }
    }
    private func handleNotificationTap(
        _ notification: NotificationItem
    ) {
        readNotificationIDs.insert(
            notification.id
        )
        guard notification.opensInvitation else {
            return
        }
        onSelectInvitation()
    }
}
#Preview {
    NotificationView(
        onBack: {},
        onSelectInvitation: {}
    )
}
