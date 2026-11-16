import SwiftUI

enum NotificationDestination: Equatable {
    case schedule(Int)
    case question(Int)
    case mission(Int)
    case unavailable
}

struct NotificationView: View {
    private enum Filter: String, CaseIterable, Hashable {
        case inbox = "받은 메일함"
        case schedule = "일정 알림"
        case poke = "콕 알림"
        case record = "기록 알림"
        case mission = "미션 알림"
        func matches(_ type: String) -> Bool {
            switch self {
            case .inbox: return true
            case .schedule: return type.hasPrefix("SCHEDULE")
            case .poke: return type == "POKE"
            case .record: return type == "RECORD" || type == "RECORD_CREATED" || type == "WEEKLY_MISSION_COMPLETED"
            case .mission: return type.contains("MISSION") || type == "EXTERNAL_EVENT_CANCELLED"
            }
        }
    }

    let onBack: () -> Void
    let onSelect: (NotificationDestination) -> Void
    @State private var selectedFilter: Filter = .inbox
    @State private var notifications: [NotificationPreviewResult] = []
    @State private var page = 0
    @State private var hasNext = false
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var errorMessage: String?
    @State private var readInFlight: Set<Int> = []
    @State private var toastMessage: String?
    @State private var toastIsError = false
    @State private var isMarkingAllRead = false
    @State private var serverUnreadCount: Int?

    private var filtered: [NotificationPreviewResult] {
        notifications.filter { selectedFilter.matches($0.notificationType) }
    }
    private var unreadCount: Int { serverUnreadCount ?? notifications.filter { !$0.isRead }.count }

    var body: some View {
        ZStack {
            KIRIColor.Background.base.ignoresSafeArea()
            VStack(spacing: 0) {
                navigationBar
                filterSection.padding(.top, 18)
                list.padding(.top, 24)
            }
            if let toastMessage {
                KIRIToast(message: toastMessage, isError: toastIsError)
                    .padding(.horizontal, 18)
                    .safeAreaPadding(.top, 8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .task {
            await load(page: 0, replacing: true)
        }
        .task {
            await refreshUnreadCount()
        }
    }

    private var navigationBar: some View {
        ZStack {
            HStack(spacing: 6) {
                KIRIBackButton(action: onBack)
                Text("알림함").font(KIRITypography.headingSmall).foregroundStyle(KIRIColor.Text.strong)
                if unreadCount > 0 {
                    Text(unreadCount > 99 ? "+99" : "+\(unreadCount)")
                        .font(KIRITypography.bodySmallMedium)
                        .foregroundStyle(KIRIColor.Text.accent)
                }
                Spacer()
                Button("모두읽음") {
                    Task { await markAllAsRead() }
                }
                .font(KIRITypography.bodySmallMedium)
                .foregroundStyle(unreadCount > 0 && !isMarkingAllRead ? KIRIColor.Text.accent : KIRIColor.Text.tertiary)
                .disabled(unreadCount == 0 || isMarkingAllRead)
            }
            .padding(.horizontal, 18)
        }.frame(height: 52)
    }

    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Filter.allCases, id: \.self) { filter in
                    Button { selectedFilter = filter } label: {
                        Text(filter.rawValue).font(KIRITypography.bodySmallMedium)
                            .foregroundStyle(selectedFilter == filter ? KIRIColor.Text.onGreen : KIRIColor.Text.secondary)
                            .padding(.horizontal, 14).frame(height: 36)
                            .background(selectedFilter == filter ? KIRIColor.Primary.default : KIRIColor.Background.tertiary)
                            .clipShape(Capsule())
                    }.buttonStyle(.plain)
                }
            }.padding(.horizontal, 18)
        }
    }

    private var list: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                if isLoading && notifications.isEmpty {
                    ProgressView().frame(maxWidth: .infinity, minHeight: 240)
                } else if let errorMessage, notifications.isEmpty {
                    VStack(spacing: 12) {
                        Text(errorMessage).font(KIRITypography.bodySmall).foregroundStyle(KIRIColor.Text.secondary)
                        Button("다시 시도") { Task { await load(page: 0, replacing: true) } }
                            .font(KIRITypography.captionMedium).foregroundStyle(KIRIColor.Text.accent)
                    }.frame(maxWidth: .infinity, minHeight: 240)
                } else if filtered.isEmpty {
                    Text("새로운 알림이 없어요").font(KIRITypography.bodySmall).foregroundStyle(KIRIColor.Text.tertiary).frame(maxWidth: .infinity, minHeight: 240)
                } else {
                    ForEach(filtered) { notification in
                        notificationRow(notification)
                        Divider().overlay(KIRIColor.Border.subtle).padding(.leading, 78)
                    }
                    if hasNext, let last = filtered.last { Color.clear.frame(height: 1).onAppear { loadNextIfNeeded(last) } }
                    if isLoadingMore { ProgressView().padding(.vertical, 14) }
                }
                Color.clear.frame(height: 120)
            }
        }
    }

    private func notificationRow(_ item: NotificationPreviewResult) -> some View {
        Button { Task { await handleTap(item) } } label: {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle().fill(KIRIColor.Background.tertiary)
                    Image(icon(for: item.notificationType))
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .opacity(item.isRead ? 0.42 : 1)
                }.frame(width: 40, height: 40)
                VStack(alignment: .leading, spacing: 7) {
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack(spacing: 5) {
                                Text(displayTitle(for: item))
                                    .font(KIRITypography.bodySmallMedium)
                                    .foregroundStyle(item.isRead ? KIRIColor.Text.secondary : KIRIColor.Text.strong)
                                    .lineLimit(1)
                                if isInvitationNotification(item.notificationType) {
                                    Image("invite_behind")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 22, height: 12)
                                        .opacity(item.isRead ? 0.72 : 1)
                                        .accessibilityHidden(true)
                                }
                            }
                            Text(item.body).font(KIRITypography.bodySmall).foregroundStyle(KIRIColor.Text.secondary).lineLimit(1)
                        }
                        Spacer(minLength: 8)
                        if !item.isRead { Circle().fill(KIRIColor.Primary.default).frame(width: 7, height: 7).padding(.top, 6) }
                    }
                    Text(formatDate(item.createdAt)).font(KIRITypography.caption).foregroundStyle(KIRIColor.Text.tertiary)
                }
            }.padding(.horizontal, 18).padding(.vertical, 18).frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
        }.buttonStyle(.plain).disabled(readInFlight.contains(item.id))
    }

    private func load(page: Int, replacing: Bool) async {
        if page == 0 && isLoading { return }
        if page > 0 && isLoadingMore { return }
        await MainActor.run { if page == 0 { isLoading = true; errorMessage = nil } else { isLoadingMore = true } }
        do {
            let result = try await AuthService.shared.notifications(page: page)
            await MainActor.run {
                let existing = replacing ? [] : notifications
                let merged = existing + result.content.filter { item in
                    !existing.contains(where: { $0.id == item.id })
                }
                notifications = merged; self.page = result.number; hasNext = result.hasNext
                isLoading = false; isLoadingMore = false
            }
        } catch {
            await MainActor.run { isLoading = false; isLoadingMore = false; errorMessage = "알림을 불러오지 못했어요. 다시 시도해 주세요." }
        }
    }

    private func loadNextIfNeeded(_ item: NotificationPreviewResult) {
        guard item.id == filtered.last?.id, hasNext else { return }
        Task { await load(page: page + 1, replacing: false) }
    }

    private func handleTap(_ item: NotificationPreviewResult) async {
        guard !readInFlight.contains(item.id) else { return }
        if !item.isRead {
            await MainActor.run { readInFlight.insert(item.id) }
            do {
                try await AuthService.shared.markNotificationAsRead(notificationId: item.id)
                await MainActor.run {
                    if let index = notifications.firstIndex(where: { $0.id == item.id }) {
                        let old = notifications[index]
                        notifications[index] = NotificationPreviewResult(notificationId: old.notificationId, title: old.title, body: old.body, notificationType: old.notificationType, isRead: true, referenceId: old.referenceId, createdAt: old.createdAt)
                    }
                    serverUnreadCount = max(0, (serverUnreadCount ?? 1) - 1)
                    readInFlight.remove(item.id)
                }
            } catch {
                await MainActor.run { readInFlight.remove(item.id); toastIsError = true; toastMessage = "알림을 읽음 처리하지 못했어요. 다시 시도해 주세요." }
                return
            }
        }
        await MainActor.run { onSelect(destination(for: item)) }
    }

    private func destination(for item: NotificationPreviewResult) -> NotificationDestination {
        guard let id = item.referenceId else { return .unavailable }
        if item.notificationType.hasPrefix("SCHEDULE") { return .schedule(id) }
        if item.notificationType == "QUESTION_REMINDER" || item.notificationType == "QUESTION_COMPLETE" || item.notificationType == "POKE" { return .question(id) }
        if item.notificationType == "RECORD" || item.notificationType == "RECORD_CREATED" {
            // 백엔드 NotificationConverter는 두 유형의 referenceId에
            // schedule.id를 넣으므로 일정 상세로 이동합니다.
            return .schedule(id)
        }
        if item.notificationType == "MISSION" || item.notificationType == "MISSION_CHANGED" || item.notificationType == "EXTERNAL_EVENT_CANCELLED" {
            return .mission(id)
        }
        // WEEKLY_MISSION_COMPLETED의 referenceId는 미션 ID가 아닌
        // 가족 추천 ID이므로 임의로 미션 상세로 이동하지 않습니다.
        return .unavailable
    }

    private func icon(for type: String) -> String {
        if type.hasPrefix("SCHEDULE") { return "figma_calendar_active" }
        if type == "POKE" { return "figma_gesture_tap" }
        if type == "INVITE" || type.contains("INVIT") { return "figma_invitation_envelope" }
        if type == "RECORD" || type == "RECORD_CREATED" || type == "WEEKLY_MISSION_COMPLETED" { return "figma_calendar_puzzle_answered" }
        if type.contains("MISSION") || type == "EXTERNAL_EVENT_CANCELLED" { return "figma_place_active" }
        return "figma_notification"
    }

    private func isInvitationNotification(_ type: String) -> Bool {
        let normalized = type.uppercased()
        return normalized == "INVITE" || normalized.contains("INVIT")
    }

    private func displayTitle(for item: NotificationPreviewResult) -> String {
        guard isInvitationNotification(item.notificationType) else { return item.title }
        var title = item.title
        // 일부 서버 알림 제목에 남아 있는 깨진 끝 기호만 초대장 행에서 제거합니다.
        for suffix in ["□?", "�?", "□", "�"] {
            while title.hasSuffix(suffix) {
                title.removeLast(suffix.count)
            }
        }
        return title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func markAllAsRead() async {
        guard !isMarkingAllRead else { return }
        let unread = notifications.filter { !$0.isRead }
        guard !unread.isEmpty else { return }
        await MainActor.run { isMarkingAllRead = true; toastMessage = nil }
        do {
            // 서버에 별도 전체 읽음 계약이 없는 현재 환경에서는 확인된
            // 개별 읽음 endpoint를 각 알림 ID에 대해 호출합니다.
            for item in unread {
                try await AuthService.shared.markNotificationAsRead(notificationId: item.id)
            }
            await load(page: 0, replacing: true)
            await refreshUnreadCount()
            await MainActor.run {
                isMarkingAllRead = false
                toastIsError = false
                toastMessage = "알림을 모두 읽었어요"
            }
        } catch {
            await MainActor.run {
                isMarkingAllRead = false
                toastIsError = true
                toastMessage = "알림을 읽음 처리하지 못했어요. 다시 시도해 주세요."
            }
        }
    }

    private func refreshUnreadCount() async {
        do {
            let count = try await AuthService.shared.unreadNotificationsCount()
            await MainActor.run { serverUnreadCount = count }
        } catch {
            // 목록 조회가 성공한 경우에는 현재 페이지의 실제 상태를
            // fallback으로 사용하고, 임의의 미읽음 수를 만들지 않습니다.
        }
    }

    private func formatDate(_ value: String) -> String {
        let input = ISO8601DateFormatter(); input.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let local = DateFormatter()
        local.locale = Locale(identifier: "en_US_POSIX")
        local.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        let localWithoutFraction = DateFormatter()
        localWithoutFraction.locale = Locale(identifier: "en_US_POSIX")
        localWithoutFraction.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        let date = input.date(from: value)
            ?? ISO8601DateFormatter().date(from: value)
            ?? local.date(from: value)
            ?? localWithoutFraction.date(from: value)
        guard let date else { return value }
        let formatter = RelativeDateTimeFormatter(); formatter.locale = Locale(identifier: "ko_KR"); formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview { NotificationView(onBack: {}, onSelect: { _ in }) }
