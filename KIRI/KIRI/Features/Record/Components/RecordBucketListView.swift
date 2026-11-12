//
// MARK: - 파일 가이드
// 담당 화면: 기록탭 버킷리스트. 가족 필터와 서버 목록의 로딩·빈 상태·오류를 관리합니다.
// UI 수정 위치: filterSection spacing, bucketCard(_:) padding/반경, 빈 상태 문구.
// API: GET /api/v1/bucket-items, DELETE /api/v1/bucket-items/{bucketItemId}.
// Figma: 기록탭 9898:18872의 버킷리스트 화면.
//
import SwiftUI



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



    private struct BucketItem: Identifiable {

        let id: Int



        let title: String

        let savedBy: String

        let ownerId: Int

        let isCompleted: Bool

        let invitation: InvitationData?

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
    @State private var selectedBucketItem: BucketItemResult?
    @State private var selectedScheduleItem: BucketItemResult?



    init(

        showsInvitationSentBanner: Bool = false,

        onSelectInvitation: @escaping (InvitationData) -> Void = { _ in }

    ) {

        self.showsInvitationSentBanner = showsInvitationSentBanner

        self.onSelectInvitation = onSelectInvitation

    }



    // 운영 화면에서는 GET /api/v1/bucket-items 응답만 사용합니다.

    private var filteredItems: [BucketItem] {
        let mapped = serverItems.map { item in
            BucketItem(id: item.bucketItemId,
                       title: item.mission.title,
                       savedBy: "\(item.saver.nickname)이 저장했어요!",
                       ownerId: item.saver.memberId,
                       isCompleted: item.status == "COMPLETED",
                       invitation: nil)
        }
        guard let selectedMemberId = selectedFilter.id else { return mapped }
        return mapped.filter { $0.ownerId == selectedMemberId }
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
        .sheet(item: $selectedBucketItem) { item in
            BucketItemActionSheet(
                item: item,
                onSuggestSchedule: {
                    selectedBucketItem = nil
                    // 시트가 닫힌 뒤 기존 일정 요청서 화면을 엽니다.
                    DispatchQueue.main.async {
                        selectedScheduleItem = item
                    }
                }
            )
            .presentationDetents([.height(368)])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(28)
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
            await loadBuckets()
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
    private func bucketCard(_ item: BucketItem) -> some View {
        let serverItem = serverItems.first(where: { $0.bucketItemId == item.id })
        Button {
            guard let serverItem else { return }
            selectedBucketItem = serverItem
        } label: {
            HStack(alignment: .top, spacing: 14) {
                missionImage(serverItem?.mission.imageUrl)
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        Text(item.title)
                            .font(KIRITypography.headingSmall)
                            .tracking(-0.72)
                            .foregroundStyle(KIRIColor.Text.strong)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if serverItem?.schedulable == true {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(KIRIColor.Primary.default)
                                .accessibilityLabel("일정 제안 가능")
                        }
                    }
                    HStack(spacing: 8) {
                        tag(title: item.savedBy, isAccent: false)
                        if item.isCompleted { tag(title: "완료", isAccent: false) }
                    }
                    if let scheduledDate = serverItem?.scheduledDate, !scheduledDate.isEmpty {
                        Label(Self.displayScheduleDate(scheduledDate), systemImage: "calendar")
                            .font(KIRITypography.caption)
                            .foregroundStyle(KIRIColor.Text.secondary)
                    } else if serverItem?.schedulable == true {
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
            if let serverItem, serverItem.deletable {
                Button("버킷에서 삭제", role: .destructive) {
                    pendingDelete = serverItem
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
    let item: BucketItemResult
    let onSuggestSchedule: () -> Void

    private var statusText: String {
        if let scheduledDate = item.scheduledDate, !scheduledDate.isEmpty {
            return "일정이 연결되어 있어요"
        }
        if item.status.uppercased() == "COMPLETED" {
            return "완료한 활동이에요"
        }
        return "아직 일정이 연결되지 않았어요"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule()
                .fill(KIRIColor.Text.tertiary)
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .padding(.bottom, 20)

            HStack(alignment: .top, spacing: 14) {
                itemImage
                VStack(alignment: .leading, spacing: 7) {
                    Text(item.mission.title)
                        .font(KIRITypography.headingMedium)
                        .foregroundStyle(KIRIColor.Text.strong)
                        .lineLimit(3)
                    Text("\(item.saver.nickname)이 저장했어요")
                        .font(KIRITypography.caption)
                        .foregroundStyle(KIRIColor.Text.secondary)
                    Text(statusText)
                        .font(KIRITypography.caption)
                        .foregroundStyle(KIRIColor.Text.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()
                .overlay(KIRIColor.Border.default)
                .padding(.vertical, 20)

            Button(action: onSuggestSchedule) {
                Text(item.schedulable ? "일정 제안하기" : "일정 제안을 할 수 없어요")
                    .font(KIRITypography.button)
                    .foregroundStyle(item.schedulable ? KIRIColor.Text.onGreen : KIRIColor.Text.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(item.schedulable ? KIRIColor.Primary.default : KIRIColor.Background.elevated)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(!item.schedulable)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 18)
        .background(KIRIColor.Background.primary)
    }

    @ViewBuilder
    private var itemImage: some View {
        AsyncImage(url: item.mission.imageUrl) { phase in
            if case .success(let image) = phase {
                image.resizable().scaledToFill()
            } else {
                ZStack {
                    KIRIColor.Background.elevated
                    Image(systemName: "photo").foregroundStyle(KIRIColor.Text.tertiary)
                }
            }
        }
        .frame(width: 84, height: 84)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
