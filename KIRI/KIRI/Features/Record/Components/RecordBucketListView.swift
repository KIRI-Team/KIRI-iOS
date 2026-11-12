//
// MARK: - 파일 가이드
// 담당 화면: 기록탭 버킷리스트. 가족 필터와 서버 목록의 로딩·빈 상태·오류를 관리합니다.
// UI 수정 위치: filterSection spacing, bucketCard(_:) padding/반경, 빈 상태 문구.
// API: GET /api/v1/bucket-items, DELETE /api/v1/bucket-items/{bucketItemId}.
// Figma: 기록탭 9898:18872의 버킷리스트 화면.
//
import SwiftUI

extension Notification.Name {
    static let bucketItemDidChange = Notification.Name("kiri.bucketItemDidChange")
}

struct RecordBucketListView: View {



    struct InvitationData: Identifiable, Equatable {

        let id = UUID()



        let title: String

        let dateTime: String

        let participants: String

        let description: String

        let familyMessage: String

    }



    /// 서버가 반환한 실제 저장자만 필터로 노출합니다.
    private struct FamilyFilter: Identifiable, Hashable {
        let id: Int?
        let title: String
    }



    fileprivate struct BucketItemGroup: Identifiable {
        let missionId: Int
        let items: [BucketItemResult]

        var id: Int { missionId }
        var representative: BucketItemResult { items[0] }
    }



    let showsInvitationSentBanner: Bool

    let onSelectInvitation: (InvitationData) -> Void



    @State private var selectedFilter = FamilyFilter(id: nil, title: "전체")
    @State private var serverItems: [BucketItemResult] = []
    @State private var serverSavers: [BucketSaver] = []
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var pendingDelete: BucketItemResult?
    @State private var showingDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var nextCursor: Int?
    @State private var hasNextPage = false
    @State private var selectedBucketGroup: BucketItemGroup?
    @State private var selectedScheduleItem: BucketItemResult?



    init(

        showsInvitationSentBanner: Bool = false,

        onSelectInvitation: @escaping (InvitationData) -> Void = { _ in }

    ) {

        self.showsInvitationSentBanner = showsInvitationSentBanner

        self.onSelectInvitation = onSelectInvitation

    }



    // 운영 화면에서는 GET /api/v1/bucket-items 응답만 사용합니다.

    private var filteredItems: [BucketItemGroup] {
        let visible = selectedFilter.id.map { memberId in
            serverItems.filter { $0.saver.memberId == memberId }
        } ?? serverItems

        var groups: [Int: [BucketItemResult]] = [:]
        var order: [Int] = []
        for item in visible {
            if groups[item.mission.missionId] == nil { order.append(item.mission.missionId) }
            groups[item.mission.missionId, default: []].append(item)
        }
        return order.compactMap { missionId in
            guard let items = groups[missionId], !items.isEmpty else { return nil }
            return BucketItemGroup(missionId: missionId, items: items)
        }
    }

    private var availableFilters: [FamilyFilter] {
        [FamilyFilter(id: nil, title: "전체")] + serverSavers.map {
            FamilyFilter(id: $0.memberId, title: $0.nickname)
        }
    }

    var body: some View {

        ZStack(alignment: .top) {

            ScrollView(

                .vertical,

                showsIndicators: false

            ) {

                VStack(spacing: 0) {

                    filterSection

                        .padding(.top, 32)



                    Group {
                        if isLoading {
                            ProgressView().frame(maxWidth: .infinity).padding(.top, 48)
                        } else if let loadError {
                            VStack(spacing: 12) {
                                Text(loadError).font(KIRITypography.bodyMedium).foregroundStyle(KIRIColor.Text.secondary)
                                Button("다시 시도") { Task { await loadBuckets(reset: true) } }
                            }.frame(maxWidth: .infinity).padding(.top, 48)
                        } else if filteredItems.isEmpty {
                            Text("저장한 버킷리스트가 없어요.").font(KIRITypography.bodyMedium).foregroundStyle(KIRIColor.Text.secondary).frame(maxWidth: .infinity).padding(.top, 48)
                        } else { bucketList }
                    }
                    .padding(.top, 29)



                    Color.clear

                        .frame(height: 110)

                }

            }



            if showsInvitationSentBanner {

                invitationSentBanner

                    .padding(.horizontal, 18)

                    .padding(.top, 21)

                    .transition(

                        .move(edge: .top)

                            .combined(with: .opacity)

                    )

                    .zIndex(10)

            }

        }
        .task { await loadBuckets(reset: true) }
        .confirmationDialog("버킷리스트를 삭제할까요?", isPresented: $showingDeleteConfirmation) {
            Button("삭제하기", role: .destructive) {
                if let item = pendingDelete { Task { await delete(item) } }
            }
            Button("취소", role: .cancel) {}
        } message: {
            Text("삭제한 버킷리스트는 다시 표시되지 않습니다.")
        }
        .sheet(item: $selectedScheduleItem) { item in
            ScheduleCreationSheet(bucket: item) {
                selectedScheduleItem = nil
                Task { await loadBuckets(reset: true) }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
        .sheet(item: $selectedBucketGroup) { group in
            BucketItemActionSheet(
                group: group,
                onClose: { selectedBucketGroup = nil },
                onSuggestSchedule: { item in
                    selectedBucketGroup = nil
                    DispatchQueue.main.async { selectedScheduleItem = item }
                },
                onDelete: { item in
                    selectedBucketGroup = nil
                    DispatchQueue.main.async {
                        pendingDelete = item
                        showingDeleteConfirmation = true
                    }
                }
            )
            .presentationDetents(group.items.count > 1 ? [.medium] : [.height(344)])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(28)
            .presentationBackground(KIRIColor.Background.secondary)
        }

    }



    private func loadBuckets(reset: Bool = false) async {
        guard !isLoading else { return }
        if reset {
            nextCursor = nil
            hasNextPage = false
            serverItems = []
            serverSavers = []
        } else if !hasNextPage {
            return
        }
        isLoading = true
        loadError = nil
        do {
            let result = try await AuthService.shared.bucketItems(cursor: nextCursor)
            if reset {
                serverItems = result.bucketItems
                serverSavers = result.savers
                if let selectedMemberId = selectedFilter.id,
                   !result.savers.contains(where: { $0.memberId == selectedMemberId }) {
                    selectedFilter = FamilyFilter(id: nil, title: "전체")
                }
            } else {
                let existing = Set(serverItems.map(\.bucketItemId))
                serverItems.append(contentsOf: result.bucketItems.filter { !existing.contains($0.bucketItemId) })
                let existingSavers = Set(serverSavers.map(\.memberId))
                serverSavers.append(contentsOf: result.savers.filter { !existingSavers.contains($0.memberId) })
            }
            nextCursor = result.nextCursor
            hasNextPage = result.hasNext && result.nextCursor != nil
        } catch {
            if reset { serverItems = [] }
            loadError = "버킷리스트를 불러오지 못했어요."
            #if DEBUG
            print("[KIRI][Record] bucket load failed: \(error)")
            #endif
        }
        isLoading = false
    }

    private func delete(_ item: BucketItemResult) async {
        guard !isDeleting, item.deletable else { return }
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await AuthService.shared.deleteBucketItem(bucketItemId: item.bucketItemId)
            NotificationCenter.default.post(
                name: .bucketItemDidChange,
                object: nil,
                userInfo: ["missionId": item.mission.missionId]
            )
            await loadBuckets(reset: true)
        } catch {
            loadError = "버킷리스트를 삭제하지 못했어요."
        }
    }

    // MARK: - Invitation Sent Banner



    private var invitationSentBanner: some View {

        HStack(spacing: 12) {

            Image(systemName: "paperplane.fill")

                .font(.system(size: 18, weight: .medium))

                .foregroundStyle(KIRIColor.Icon.primary)

                .frame(width: 24, height: 24)



            Text("초대를 발송했습니다!")

                .font(KIRITypography.headingSmall)

                .tracking(-0.72)

                .foregroundStyle(KIRIColor.Text.strong)



            Spacer(minLength: 0)

        }

        .padding(.horizontal, 16)

        .frame(height: 59)

        .background(KIRIColor.Background.tertiary)

        .clipShape(

            RoundedRectangle(

                cornerRadius: 12

            )

        )

    }



    // MARK: - Filter



    private var filterSection: some View {

        ScrollView(

            .horizontal,

            showsIndicators: false

        ) {

            HStack(spacing: 8) {

                ForEach(

                    availableFilters,

                    id: \.self

                ) { filter in

                    KIRIChip(

                        title: filter.title,

                        isSelected: selectedFilter == filter

                    ) {

                        withAnimation(

                            .easeOut(duration: 0.15)

                        ) {

                            selectedFilter = filter

                        }

                    }

                }

            }

            .padding(.horizontal, 18)

        }

    }



    // MARK: - List



    private var bucketList: some View {

        LazyVStack(spacing: 18) {

            ForEach(filteredItems) { item in

                bucketCard(item)

                if item.id == filteredItems.last?.id, hasNextPage {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .task { await loadBuckets() }
                }

            }

        }

        .padding(.horizontal, 18)

    }



    // MARK: - Card



    @ViewBuilder
    private func bucketCard(_ group: BucketItemGroup) -> some View {
        let item = group.representative
        let canSchedule = group.items.contains(where: \.schedulable)
        let savedBy = group.items.map { "\($0.saver.nickname)이 저장했어요!" }.joined(separator: " · ")
        Button {
            selectedBucketGroup = group
        } label: {
            HStack(alignment: .top, spacing: 14) {
                missionImage(item.mission.imageUrl)
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        Text(item.mission.title)
                            .font(KIRITypography.headingSmall)
                            .tracking(-0.72)
                            .foregroundStyle(KIRIColor.Text.strong)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if canSchedule {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(KIRIColor.Primary.default)
                                .accessibilityLabel("일정 제안 가능")
                        }
                    }
                    HStack(spacing: 8) {
                        tag(title: savedBy, isAccent: false)
                        if group.items.allSatisfy({ $0.status == "COMPLETED" }) { tag(title: "완료", isAccent: false) }
                    }
                    if let scheduledDate = group.items.compactMap(\.scheduledDate).first(where: { !$0.isEmpty }) {
                        Label(Self.displayScheduleDate(scheduledDate), systemImage: "calendar")
                            .font(KIRITypography.caption)
                            .foregroundStyle(KIRIColor.Text.secondary)
                    } else if canSchedule {
                        Text("일정을 제안할 수 있어요")
                            .font(KIRITypography.caption)
                            .foregroundStyle(KIRIColor.Text.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(KIRIColor.Background.tertiary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .contextMenu {
            if group.items.count == 1, item.deletable {
                Button("버킷에서 삭제", role: .destructive) {
                    pendingDelete = item
                    showingDeleteConfirmation = true
                }
            }
        }
    }

    @ViewBuilder
    private func missionImage(_ url: URL?) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image): image.resizable().scaledToFill()
            default:
                ZStack {
                    KIRIColor.Background.elevated
                    Image(systemName: "photo").foregroundStyle(KIRIColor.Text.tertiary)
                }
            }
        }
        .frame(width: 92, height: 92)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityHidden(true)
    }

    private static func displayScheduleDate(_ value: String) -> String {
        let input = ISO8601DateFormatter()
        guard let date = input.date(from: value) else { return value }
        return date.formatted(.dateTime.month(.defaultDigits).day(.defaultDigits).hour().minute())
    }

    // MARK: - Tag



    private func tag(

        title: String,

        isAccent: Bool

    ) -> some View {

        Text(title)

            .font(KIRITypography.bodySmallMedium)

            .tracking(-0.56)

            .foregroundStyle(

                isAccent

                    ? KIRIColor.Text.accent

                    : KIRIColor.Text.secondary

            )

            .padding(.horizontal, 8)

            .padding(.vertical, 6)

            .background(

                isAccent

                    ? KIRIColor.Background.greenSoft

                    : KIRIColor.Background.elevated

            )

            .clipShape(

                RoundedRectangle(

                    cornerRadius: 5

                )

            )

    }

}



#Preview {
    
    ZStack {
        
        KIRIColor.Background.base
        
            .ignoresSafeArea()
        
        
        
        RecordBucketListView(
            
            showsInvitationSentBanner: true
            
        )
        
    }
    
}

/// 버킷 항목을 탭했을 때 표시하는 Figma 기록탭 바텀시트입니다.
/// 시트에는 서버가 반환한 항목만 표시하고, 일정 제안은 기존 요청서 화면으로 위임합니다.
private struct BucketItemActionSheet: View {
    let group: RecordBucketListView.BucketItemGroup
    let onClose: () -> Void
    let onSuggestSchedule: (BucketItemResult) -> Void
    let onDelete: (BucketItemResult) -> Void
    @State private var selectedItemID: Int?

    private var selectedItem: BucketItemResult? {
        if group.items.count == 1 { return group.items[0] }
        guard let selectedItemID else { return nil }
        return group.items.first { $0.bucketItemId == selectedItemID }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                HStack(alignment: .top, spacing: 14) {
                    itemImage(group.representative.mission.imageUrl)
                    VStack(alignment: .leading, spacing: 7) {
                        Text(group.representative.mission.title)
                            .font(KIRITypography.headingMedium)
                            .foregroundStyle(KIRIColor.Text.strong)
                            .lineLimit(3)
                        if group.items.count == 1 {
                            Text("\(group.items[0].saver.nickname)이 저장했어요!")
                                .font(KIRITypography.caption)
                                .foregroundStyle(KIRIColor.Text.secondary)
                        } else {
                            Text("\(group.items.count)명이 저장했어요!")
                                .font(KIRITypography.caption)
                                .foregroundStyle(KIRIColor.Text.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(KIRIColor.Icon.secondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Divider().overlay(KIRIColor.Border.default).padding(.top, 20)

            if group.items.count > 1 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("일정을 제안하거나 삭제할 저장 기록을 선택해 주세요")
                        .font(KIRITypography.caption)
                        .foregroundStyle(KIRIColor.Text.secondary)
                    ForEach(group.items) { item in
                        Button {
                            selectedItemID = item.bucketItemId
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: selectedItemID == item.bucketItemId ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedItemID == item.bucketItemId ? KIRIColor.Primary.default : KIRIColor.Text.tertiary)
                                Text(item.saver.nickname)
                                    .font(KIRITypography.bodyMedium)
                                    .foregroundStyle(KIRIColor.Text.strong)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, minHeight: 38, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 12)
            }

            VStack(spacing: 10) {
                actionRow(
                    title: "일정 잡기",
                    icon: AnyView(Image("figma_toast_check").resizable().scaledToFit()),
                    tint: selectedItem?.schedulable == true ? KIRIColor.Icon.secondary : KIRIColor.Icon.disabled,
                    action: { if let selectedItem { onSuggestSchedule(selectedItem) } },
                    isEnabled: selectedItem?.schedulable == true
                )
                Divider().overlay(KIRIColor.Border.default)
                actionRow(
                    title: "삭제하기",
                    icon: AnyView(Image(systemName: "trash").font(.system(size: 18, weight: .medium))),
                    tint: selectedItem?.deletable == true ? KIRIColor.Status.error : KIRIColor.Icon.disabled,
                    action: { if let selectedItem { onDelete(selectedItem) } },
                    isEnabled: selectedItem?.deletable == true,
                    isDestructive: true
                )
            }
            .padding(.top, 12)

        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .background(KIRIColor.Background.primary)
    }

    private func actionRow(
        title: String,
        icon: AnyView,
        tint: Color,
        action: @escaping () -> Void,
        isEnabled: Bool,
        isDestructive: Bool = false
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                icon
                    .frame(width: 24, height: 24)
                    .foregroundStyle(tint)
                Text(title)
                    .font(KIRITypography.bodyMedium)
                    .foregroundStyle(isDestructive ? tint : (isEnabled ? KIRIColor.Text.strong : KIRIColor.Text.tertiary))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(KIRIColor.Icon.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    @ViewBuilder
    private func itemImage(_ url: URL?) -> some View {
        AsyncImage(url: url) { phase in
            if case .success(let image) = phase {
                image.resizable().scaledToFill()
            } else {
                ZStack {
                    KIRIColor.Background.elevated
                    Image(systemName: "photo").foregroundStyle(KIRIColor.Text.tertiary)
                }
            }
        }
        .frame(width: 64, height: 64)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
