//
// MARK: - 파일 가이드
// 파일: Features/Mission/MissionView.swift
// 담당 화면: 미션(플레이스) 목록과 필터 진입 (Figma 9901:23876 / 9404:20244)
// 주요 책임: 검색·카테고리·필터 상태, GET /api/v1/missions 목록 및 커서 페이지네이션을 관리합니다.
// UI 수정 위치: 검색/칩/개수 행은 body, 카드 간격은 content의 LazyVStack, 필터 버튼은 count 행,
// 하단 여백은 ScrollView.safeAreaInset에서 조정합니다.
// 데이터 흐름: MainTabView → MissionView → AuthService.missionFeed → MissionPlaceCard.
// 주의: 필터 요청에는 서버 enum 원문을 사용하고, 사용자 표시는 MissionDisplayLabel을 사용합니다.
//

import SwiftUI

struct MissionView: View {
    private enum Category: String, CaseIterable, Hashable {
        case all = "전체", exhibition = "전시·문화", popup = "팝업·행사"
        case experience = "체험·놀거리", outdoor = "산책·야외", performance = "공연", food = "맛집·카페"
        var apiValue: String? {
            switch self {
            case .all: return nil
            case .exhibition: return "EXHIBITION"
            case .popup: return "POPUP"
            case .experience: return "EXPERIENCE"
            case .outdoor: return "OUTDOOR"
            case .performance: return "PERFORMANCE"
            case .food: return "FOOD_CAFE"
            }
        }
    }
    private struct MissionRow: Identifiable { let id: Int; let mission: MissionFeedItem; var isBookmarked: Bool }
    fileprivate struct MissionFilter: Equatable {
        var regionCode: String?
        var distance: Int?
        var isFree: Bool?
        var maxPrice: Int?
        /// 날짜와 시간은 GET /api/v1/missions가 지원하는 query입니다.
        var date: String?
        var time: String?
        /// Figma의 인원 선택값입니다. 현재 미션 목록 계약에는 인원 query가 없어
        /// 화면 상태만 보존하고 서버 요청에는 보내지 않습니다.
        var peopleCount: Int?

        static let empty = MissionFilter(regionCode: nil, distance: nil, isFree: nil, maxPrice: nil, date: nil, time: nil, peopleCount: nil)
        var count: Int { [regionCode != nil, distance != nil, isFree != nil, maxPrice != nil, date != nil, time != nil, peopleCount != nil].filter { $0 }.count }
    }
    @State private var rows: [MissionRow] = []
    @State private var selectedMission: MissionRow?
    @State private var searchText = ""
    @State private var selectedCategory: Category = .all
    @State private var appliedFilter = MissionFilter.empty
    @State private var isFilterPresented = false
    @State private var nextCursor: Int?
    @State private var hasNext = false
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var errorMessage: String?
    @State private var savingMissionID: Int?
    @State private var savedMissionIDs: Set<Int> = []
    // 미션별 서버 버킷 항목을 보존해 해제 시 실제 bucketItemId와 권한을 사용합니다.
    @State private var bucketItemsByMissionID: [Int: BucketItemResult] = [:]
    @State private var bookmarkConfirmationMissionID: Int?
    @State private var bookmarkFeedback: String?
    @State private var filterFeedback: String?
    @State private var filterFeedbackIsError = false
    // 필터·카테고리 변경으로 새 요청이 시작되면 이전 응답이 화면을 덮어쓰지 않도록 식별자를 갱신합니다.
    @State private var loadGeneration = UUID()

    private var hasFamilyAddressConfigured: Bool {
        guard let familyId = AppSessionStore().familyId else { return false }
        return AppSessionStore().hasFamilyAddressConfigured(for: familyId)
    }

    private var filteredRows: [MissionRow] {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !keyword.isEmpty else { return rows }
        return rows.filter { $0.mission.title.localizedCaseInsensitiveContains(keyword) || $0.mission.placeName.localizedCaseInsensitiveContains(keyword) }
    }

    var body: some View {
        ZStack {
            KIRIColor.Background.base.ignoresSafeArea()
            VStack(spacing: 0) {
                // Figma의 App Bar는 뒤로가기와 중앙 제목만 포함합니다.
                // 필터는 목록 개수 행의 오른쪽에 배치해야 카드 목록과 같은 세로 기준을 유지합니다.
                ZStack {
                    Text("미션")
                        .font(KIRITypography.headingSmall)
                        .foregroundStyle(KIRIColor.Text.strong)
                    HStack {
                        Button { } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .regular))
                                .foregroundStyle(KIRIColor.Text.strong)
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 62)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        KIRISearchField(text: $searchText).padding(.horizontal, 18).padding(.top, 6)
                        categorySection.padding(.top, 13)
                        HStack {
                            Text("활동 \(filteredRows.count)개")
                                .font(KIRITypography.bodySmall)
                                .foregroundStyle(KIRIColor.Text.secondary)
                            Spacer()
                            if isLoading { ProgressView().controlSize(.small) }
                            Button { isFilterPresented = true } label: {
                                ZStack(alignment: .topTrailing) {
                                    Image("mission_filter")
                                        .renderingMode(.original)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                    if appliedFilter.count > 0 {
                                        Circle().fill(KIRIColor.Text.accent).frame(width: 6, height: 6).offset(x: 1, y: -1)
                                    }
                                }
                                .frame(width: 44, height: 24, alignment: .trailing)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("mission.filter.button")
                            .accessibilityLabel("미션 필터")
                        }
                        .frame(height: 20)
                        .padding(.horizontal, 18)
                        .padding(.top, 24)
                        content.padding(.horizontal, 18).padding(.top, 16)
                    }
                }
                // 공통 플로팅 탭바 아래로 마지막 카드가 가려지지 않도록
                // 임의 Spacer 대신 실제 외부 네비게이션 높이만큼 inset을 확보합니다.
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    Color.clear.frame(height: 97)
                }
                .refreshable { await load(reset: true) }
            }

            if let missionID = bookmarkConfirmationMissionID,
               let row = rows.first(where: { $0.id == missionID }) {
                BucketSaveConfirmationModal(
                    title: row.mission.title,
                    onCancel: { bookmarkConfirmationMissionID = nil },
                    onConfirm: {
                        bookmarkConfirmationMissionID = nil
                        Task { await save(missionID, value: true) }
                    }
                )
                .transition(.opacity)
                .zIndex(10)
            }

            if let bookmarkFeedback {
                KIRIToast(message: bookmarkFeedback)
                    .padding(.horizontal, 18)
                    .safeAreaPadding(.top, 8)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(11)
            }

            if let filterFeedback {
                KIRIToast(message: filterFeedback, isError: filterFeedbackIsError)
                    .padding(.horizontal, 18)
                    .safeAreaPadding(.top, 8)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(12)
            }
        }
        .task { await load(reset: true) }
        .onReceive(NotificationCenter.default.publisher(for: .bucketItemDidChange)) { notification in
            guard let missionId = notification.userInfo?["missionId"] as? Int else { return }
            bucketItemsByMissionID[missionId] = nil
            savedMissionIDs.remove(missionId)
            if let index = rows.firstIndex(where: { $0.id == missionId }) {
                rows[index].isBookmarked = false
            }
        }
        .fullScreenCover(isPresented: $isFilterPresented) {
            MissionFilterView(initial: appliedFilter, distanceAvailable: hasFamilyAddressConfigured) { newFilter in
                appliedFilter = newFilter
                isFilterPresented = false
                // SwiftUI State 반영을 기다리며 다시 읽지 않고, 사용자가 방금
                // 적용한 값을 요청에 직접 전달합니다. 첫 요청이 이전 필터를
                // 사용하는 것을 막고 적용 직후 목록을 항상 새로 조회합니다.
                Task {
                    guard let result = await load(reset: true, filterOverride: newFilter) else { return }
                    showFilterFeedback(
                        result ? "필터를 적용했어요" : "필터를 적용하지 못했어요. 다시 시도해 주세요.",
                        isError: !result
                    )
                }
            }
        }
        .fullScreenCover(item: $selectedMission) { row in
            MissionActivityDetailView(missionId: row.mission.missionId, title: row.mission.title, placeName: row.mission.placeName, district: MissionDisplayLabel.category(row.mission.category) ?? "", rating: nil, tags: row.mission.displayTags, isRecommended: false, imageURL: row.mission.imageUrl, isBookmarked: Binding(get: { rows.first(where: { $0.id == row.id })?.isBookmarked ?? false }, set: { value in
                // 상세 화면이 서버 저장·해제를 완료한 뒤 목록의 표시 상태만 갱신합니다.
                // 상세 화면에서 다시 API를 호출하면 저장/해제가 중복 실행됩니다.
                if let index = rows.firstIndex(where: { $0.id == row.id }) {
                    rows[index].isBookmarked = value
                }
            }), onBack: { selectedMission = nil })
        }
    }

    private var categorySection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Category.allCases, id: \.self) { category in
                    KIRIChip(title: category.rawValue, isSelected: selectedCategory == category) {
                        selectedCategory = category
                        // 카테고리도 같은 상태 반영 시점 문제를 피하기 위해
                        // 선택한 값을 현재 요청에 명시적으로 넘깁니다.
                        Task { await load(reset: true, categoryOverride: category) }
                    }
                }
            }.padding(.horizontal, 18)
        }
    }

    @ViewBuilder private var content: some View {
        if let errorMessage, rows.isEmpty {
            VStack(spacing: 12) { Text(errorMessage).font(KIRITypography.bodySmall).foregroundStyle(KIRIColor.Text.secondary); Button("다시 시도") { Task { await load(reset: true) } }.foregroundStyle(KIRIColor.Text.accent) }.frame(maxWidth: .infinity, minHeight: 260)
        } else if isLoading && rows.isEmpty {
            ProgressView().frame(maxWidth: .infinity, minHeight: 260)
        } else if rows.isEmpty {
            Text("아직 진행할 미션이 없어요").font(KIRITypography.bodySmall).foregroundStyle(KIRIColor.Text.tertiary).frame(maxWidth: .infinity, minHeight: 260)
        } else {
            LazyVStack(spacing: 16) {
                ForEach(filteredRows) { row in
                    MissionPlaceCard(title: row.mission.title, placeName: row.mission.placeName, district: nil, rating: nil, tags: row.mission.displayTags, isRecommended: false, imageURL: row.mission.imageUrl, isBookmarked: Binding(get: { rows.first(where: { $0.id == row.id })?.isBookmarked ?? false }, set: { _ in }), onBookmarkTapped: {
                        guard savingMissionID == nil else { return }
                        if row.isBookmarked {
                            Task { await save(row.id, value: false) }
                        } else {
                            withAnimation(.easeOut(duration: 0.2)) {
                                bookmarkConfirmationMissionID = row.id
                            }
                        }
                    })
                        .contentShape(Rectangle()).onTapGesture {
                            AppEventTracker.record("mission_card_click", properties: ["mission_id": String(row.mission.missionId)])
                            selectedMission = row
                        }
                        .onAppear { if row.id == rows.last?.id, hasNext, !isLoadingMore { Task { await load(reset: false) } } }
                }
                if isLoadingMore { ProgressView().padding() }
            }
        }
    }

    private func load(
        reset: Bool,
        filterOverride: MissionFilter? = nil,
        categoryOverride: Category? = nil
    ) async -> Bool? {
        let generation: UUID
        if reset {
            generation = UUID()
            loadGeneration = generation
            isLoading = true
            isLoadingMore = false
            errorMessage = nil
            nextCursor = nil
            hasNext = false
        } else {
            guard hasNext, !isLoadingMore else { return nil }
            generation = loadGeneration
            isLoadingMore = true
        }
        do {
            let category = (categoryOverride ?? selectedCategory).apiValue
            let filter = filterOverride ?? appliedFilter
            let cursor = reset ? nil : nextCursor
            let result = try await AuthService.shared.missionFeed(category: category, regionCode: filter.regionCode, distance: filter.distance, date: filter.date, time: filter.time, isFree: filter.isFree, maxPrice: filter.maxPrice, cursor: cursor)
            guard !Task.isCancelled, generation == loadGeneration else { return nil }
            if reset {
                await refreshSavedMissionIDs()
            }
            let newRows = result.missions.map { MissionRow(id: $0.missionId, mission: $0, isBookmarked: savedMissionIDs.contains($0.missionId)) }
            if reset { rows = newRows } else { rows.append(contentsOf: newRows) }
            nextCursor = result.nextCursor; hasNext = result.hasNext; errorMessage = nil
        } catch {
            guard !Task.isCancelled, generation == loadGeneration else { return nil }
            errorMessage = error.localizedDescription
        }
        if generation == loadGeneration {
            isLoading = false
            isLoadingMore = false
        }
        return errorMessage == nil
    }

    private func save(_ missionID: Int, value: Bool) async {
        guard savingMissionID == nil, rows.contains(where: { $0.id == missionID }) else { return }
        savingMissionID = missionID
        do {
            if value {
                let result = try await AuthService.shared.saveMissionToBucket(missionId: missionID)
                #if DEBUG
                print("[KIRI][Bucket] save missionId=\(missionID) bucketItemId=\(result.bucketItemId)")
                #endif
                savedMissionIDs.insert(missionID)
            } else {
                var item = bucketItemsByMissionID[missionID]
                if item == nil {
                    // 목록이 오래된 경우 최신 페이지에서 실제 bucketItemId를 다시 확인합니다.
                    await refreshSavedMissionIDs()
                    item = bucketItemsByMissionID[missionID]
                }
                guard let item else {
                    throw APIError.serverError(code: "BUCKET404_1", message: "저장된 버킷을 찾을 수 없어요.")
                }
                guard item.deletable else {
                    throw APIError.serverError(code: "BUCKET403_2", message: "내가 저장한 버킷만 해제할 수 있어요.")
                }
                #if DEBUG
                print("[KIRI][Bucket] delete missionId=\(missionID) bucketItemId=\(item.bucketItemId)")
                #endif
                try await AuthService.shared.deleteBucketItem(bucketItemId: item.bucketItemId)
                bucketItemsByMissionID[missionID] = nil
                savedMissionIDs.remove(missionID)
            }
            if let index = rows.firstIndex(where: { $0.id == missionID }) {
                rows[index].isBookmarked = value
            }
            showBookmarkFeedback(value ? "버킷에 저장했어요" : "버킷에서 삭제했어요")
        } catch {
            if value, case APIError.serverError(let code, _) = error, code == "BUCKET409_1" {
                await refreshSavedMissionIDs()
                if let index = rows.firstIndex(where: { $0.id == missionID }), savedMissionIDs.contains(missionID) {
                    rows[index].isBookmarked = true
                    savingMissionID = nil
                    return
                }
            }
            if case APIError.serverError(let code, let message) = error, code == "BUCKET403_2" {
                showBookmarkFeedback(message)
            } else {
                showBookmarkFeedback("버킷 저장 상태를 변경하지 못했어요. 다시 시도해 주세요.")
            }
        }
        savingMissionID = nil
    }

    private func showBookmarkFeedback(_ message: String) {
        withAnimation(.easeOut(duration: 0.2)) { bookmarkFeedback = message }
        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) { bookmarkFeedback = nil }
            }
        }
    }

    private func showFilterFeedback(_ message: String, isError: Bool) {
        withAnimation(.easeOut(duration: 0.2)) {
            filterFeedback = message
            filterFeedbackIsError = isError
        }
        Task {
            try? await Task.sleep(for: .seconds(2))
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.2)) { filterFeedback = nil }
            }
        }
    }

    private func refreshSavedMissionIDs() async {
        do {
            var cursor: Int?
            var ids = Set<Int>()
            var itemsByMissionID: [Int: BucketItemResult] = [:]
            let currentMemberID = try? AuthService.shared.currentMemberId()
            while true {
                let page = try await AuthService.shared.bucketItems(cursor: cursor)
                for item in page.bucketItems {
                    ids.insert(item.mission.missionId)
                    let missionID = item.mission.missionId
                    let existing = itemsByMissionID[missionID]
                    // 같은 미션을 여러 가족 구성원이 저장할 수 있으므로,
                    // 해제 시에는 현재 사용자 항목을 우선하고 그 다음 삭제 가능 항목을 사용합니다.
                    if item.saver.memberId == currentMemberID || existing == nil || (!existing!.deletable && item.deletable) {
                        itemsByMissionID[missionID] = item
                    }
                }
                guard page.hasNext, let nextCursor = page.nextCursor, nextCursor != cursor else { break }
                cursor = nextCursor
            }
            savedMissionIDs = ids
            bucketItemsByMissionID = itemsByMissionID
            for index in rows.indices {
                rows[index].isBookmarked = ids.contains(rows[index].id)
            }
        } catch {
            // 저장 목록 조회 실패 시 마지막으로 확인된 카드 상태를 유지합니다.
        }
    }
}

private struct MissionFilterView: View {
    private enum FilterTab: String, CaseIterable, Hashable {
        case schedule = "날짜·인원"
        case region = "지역"
        case distance = "거리"
        case price = "가격"
    }

    private struct Region: Identifiable, Hashable {
        let id: String
        let title: String
    }

    let initial: MissionView.MissionFilter
    let distanceAvailable: Bool
    let onApply: (MissionView.MissionFilter) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var regionCode: String?
    @State private var distance: Int?
    @State private var isFree: Bool?
    @State private var maxPrice: Int?
    @State private var selectedDate: Date?
    @State private var selectedTime: String?
    @State private var peopleCount: Int?
    @State private var isScheduleSelectionPresented = false
    @State private var selectedTab: FilterTab = .schedule

    // 서버는 2자리 시·도 또는 5자리 시·군·구 코드만 받습니다.
    // 충청·경상·전라처럼 여러 시·도를 합친 값은 단일 regionCode로
    // 표현할 수 없으므로, 실제 요청 범위와 일치하는 시·도 단위로 나눕니다.
    private let regions = [
        Region(id: "11", title: "서울"), Region(id: "28", title: "인천"),
        Region(id: "41", title: "경기"), Region(id: "30", title: "대전"),
        Region(id: "36", title: "세종"), Region(id: "43", title: "충북"),
        Region(id: "44", title: "충남"), Region(id: "27", title: "대구"),
        Region(id: "47", title: "경북"), Region(id: "48", title: "경남"),
        Region(id: "31", title: "울산"), Region(id: "26", title: "부산"),
        Region(id: "29", title: "광주"), Region(id: "45", title: "전북"),
        Region(id: "46", title: "전남"), Region(id: "42", title: "강원"),
        Region(id: "50", title: "제주")
    ]
    private let distances: [(Int, String)] = [(1, "1km 이내"), (3, "3km 이내"), (5, "5km 이내"), (10, "10km 이내")]
    private let prices: [(Int, String)] = [(0, "무료"), (10000, "1만원 이하"), (30000, "3만원 이하")]

    init(initial: MissionView.MissionFilter, distanceAvailable: Bool, onApply: @escaping (MissionView.MissionFilter) -> Void) {
        self.initial = initial
        self.distanceAvailable = distanceAvailable
        self.onApply = onApply
        _regionCode = State(initialValue: initial.regionCode)
        _distance = State(initialValue: initial.distance)
        _isFree = State(initialValue: initial.isFree)
        _maxPrice = State(initialValue: initial.maxPrice)
        _selectedDate = State(initialValue: MissionFilterView.date(from: initial.date))
        _selectedTime = State(initialValue: initial.time)
        _peopleCount = State(initialValue: initial.peopleCount)
    }

    var body: some View {
        ZStack {
            KIRIColor.Background.base.ignoresSafeArea()
            VStack(spacing: 0) {
                filterHeader
                Spacer(minLength: 48)
                filterSheet
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $isScheduleSelectionPresented) {
            MissionFilterScheduleSelectionView(
                initialDate: selectedDate,
                initialTime: selectedTime,
                initialPeopleCount: peopleCount,
                onApply: { date, time, people in
                    selectedDate = date
                    selectedTime = time
                    peopleCount = people
                    isScheduleSelectionPresented = false
                }
            )
        }
    }

    private var filterHeader: some View {
        HStack {
            Button { dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 18, weight: .medium)).frame(width: 44, height: 44) }
            Spacer()
            Text("미션").font(KIRITypography.headingSmall)
            Spacer()
            Button { dismiss() } label: { Image(systemName: "xmark").font(.system(size: 18, weight: .medium)).frame(width: 44, height: 44) }
        }
        .foregroundStyle(KIRIColor.Text.strong)
        .padding(.horizontal, 8)
        .frame(height: 62)
    }

    private var filterSheet: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(FilterTab.allCases, id: \.self) { tab in
                    filterTab(tab)
                }
            }
            .padding(.horizontal, 18)
            .overlay(alignment: .bottom) { Rectangle().fill(KIRIColor.Border.default).frame(height: 1).padding(.horizontal, 18) }

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 26) {
                        scheduleSummaryButton.id(FilterTab.schedule)
                        filterSection(title: "지역") {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 10) {
                                ForEach(regions) { region in chip(region.title, selected: regionCode == region.id) { regionCode = regionCode == region.id ? nil : region.id } }
                            }
                        }
                        .id(FilterTab.region)
                        filterSection(title: "거리") {
                            VStack(alignment: .leading, spacing: 10) {
                                if !distanceAvailable {
                                    Text("기준 위치가 없어 거리 필터를 적용할 수 없어요. 가족공간에 우리 집 위치를 등록해 주세요.")
                                        .font(KIRITypography.caption)
                                        .foregroundStyle(KIRIColor.Text.tertiary)
                                }
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(distances, id: \.0) { item in
                                            chip(item.1, selected: distance == item.0) {
                                                guard distanceAvailable else { return }
                                                distance = distance == item.0 ? nil : item.0
                                            }
                                            .opacity(distanceAvailable ? 1 : 0.45)
                                            .allowsHitTesting(distanceAvailable)
                                        }
                                    }
                                }
                            }
                        }
                        .id(FilterTab.distance)
                        filterSection(title: "가격") {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("1인 기준 요금").font(KIRITypography.bodySmall).foregroundStyle(KIRIColor.Text.secondary)
                                ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 8) { ForEach(prices, id: \.0) { item in priceChip(item) } } }
                            }
                        }
                        .id(FilterTab.price)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 24)
                    .padding(.bottom, 110)
                }
                .onChange(of: selectedTab) { _, tab in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(tab, anchor: tab == .schedule ? .top : .center)
                    }
                }
            }
            actionButtons
        }
        .background(KIRIColor.Background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .ignoresSafeArea(edges: .bottom)
    }

    private var scheduleSummaryButton: some View {
        Button { isScheduleSelectionPresented = true } label: {
            HStack(spacing: 10) {
                Image("figma_calendar_active").resizable().scaledToFit().frame(width: 16, height: 16)
                Text(scheduleSummary).font(KIRITypography.bodySmall)
                Spacer()
                Image(systemName: "chevron.down").font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(KIRIColor.Text.secondary)
            .padding(.horizontal, 14)
            .frame(height: 50)
            .background(KIRIColor.Background.primary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(KIRIColor.Border.default, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .padding(.top, 16)
    }

    private func filterTab(_ tab: FilterTab) -> some View {
        Button { selectedTab = tab } label: {
            Text(tab.rawValue).font(KIRITypography.bodySmallMedium)
                .foregroundStyle(selectedTab == tab ? KIRIColor.Text.strong : KIRIColor.Text.secondary)
                .frame(maxWidth: .infinity).frame(height: 48)
                .overlay(alignment: .bottom) { if selectedTab == tab { Rectangle().fill(KIRIColor.Text.strong).frame(height: 2) } }
        }.buttonStyle(.plain)
    }

    private func filterSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).font(KIRITypography.headingSmall).foregroundStyle(KIRIColor.Text.strong)
            content()
        }
    }

    private func chip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(KIRITypography.bodySmallMedium).foregroundStyle(selected ? KIRIColor.Text.accent : KIRIColor.Text.secondary)
                .frame(minWidth: 55, minHeight: 36)
                .padding(.horizontal, 8)
                .background(selected ? KIRIColor.Background.greenSoft : KIRIColor.Background.tertiary)
                .clipShape(Capsule())
        }.buttonStyle(.plain)
    }

    private func priceChip(_ item: (Int, String)) -> some View {
        chip(item.1, selected: item.0 == 0 ? isFree == true : maxPrice == item.0) {
            if item.0 == 0 { isFree = isFree == true ? nil : true; maxPrice = nil }
            else { maxPrice = maxPrice == item.0 ? nil : item.0; isFree = nil }
        }
    }

    private var scheduleSummary: String {
        guard let selectedDate else { return "날짜·인원·시간" }
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: "ko_KR"); formatter.dateFormat = "M.dd (E)"
        let parts = [formatter.string(from: selectedDate), selectedTime, peopleCount.map { "\($0)명" }].compactMap { $0 }
        return parts.joined(separator: " · ")
    }

    private static func date(from value: String?) -> Date? {
        guard let value else { return nil }
        let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd"; return formatter.date(from: value)
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button("초기화") { regionCode = nil; distance = nil; isFree = nil; maxPrice = nil; selectedDate = nil; selectedTime = nil; peopleCount = nil }
                .frame(maxWidth: .infinity).frame(height: 54).background(KIRIColor.Background.secondary).clipShape(RoundedRectangle(cornerRadius: 8))
            Button("적용하기") { onApply(MissionView.MissionFilter(regionCode: regionCode, distance: distance, isFree: isFree, maxPrice: maxPrice, date: selectedDate.map { Self.apiDateFormatter.string(from: $0) }, time: selectedTime, peopleCount: peopleCount)) }
                .frame(maxWidth: .infinity).frame(height: 54).foregroundStyle(.black).background(KIRIColor.Text.accent).clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .font(KIRITypography.bodyMedium)
        .padding(.horizontal, 18)
        .padding(.bottom, 10)
        .background(KIRIColor.Background.base)
    }

    private static let apiDateFormatter: DateFormatter = { let formatter = DateFormatter(); formatter.dateFormat = "yyyy-MM-dd"; return formatter }()
}

private struct MissionFilterScheduleSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    let initialDate: Date?
    let initialTime: String?
    let initialPeopleCount: Int?
    let onApply: (Date?, String?, Int?) -> Void
    @State private var date: Date
    @State private var displayedMonth: Date
    @State private var time: String?
    @State private var peopleCount: Int?
    private let times = ["09:00", "09:30", "10:00", "10:30", "11:00", "11:30", "12:00"]
    private let people = Array(1...6)

    init(initialDate: Date?, initialTime: String?, initialPeopleCount: Int?, onApply: @escaping (Date?, String?, Int?) -> Void) {
        self.initialDate = initialDate; self.initialTime = initialTime; self.initialPeopleCount = initialPeopleCount; self.onApply = onApply
        let resolvedDate = initialDate ?? Date()
        _date = State(initialValue: resolvedDate); _displayedMonth = State(initialValue: Self.startOfMonth(resolvedDate)); _time = State(initialValue: initialTime); _peopleCount = State(initialValue: initialPeopleCount)
    }

    var body: some View {
        ZStack {
            KIRIColor.Background.base.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack { Button { dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 18, weight: .medium)).frame(width: 44, height: 44) }; Spacer(); Text("날짜 선택").font(KIRITypography.headingSmall); Spacer(); Color.clear.frame(width: 44, height: 44) }
                    .foregroundStyle(KIRIColor.Text.strong).padding(.horizontal, 8).frame(height: 62)
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        calendarView
                        pickerSection("시간 선택", values: times, selection: $time)
                        pickerSection("인원 선택", values: people.map(String.init), selection: Binding(get: { peopleCount.map(String.init) }, set: { peopleCount = $0.flatMap(Int.init) }))
                    }.padding(.horizontal, 18).padding(.top, 20).padding(.bottom, 110)
                }
                HStack(spacing: 8) {
                    Button("초기화") { date = Date(); time = nil; peopleCount = nil }.frame(maxWidth: .infinity).frame(height: 54).foregroundStyle(KIRIColor.Text.strong).background(KIRIColor.Background.secondary).clipShape(RoundedRectangle(cornerRadius: 8))
                    Button("적용하기") { onApply(date, time, peopleCount) }.frame(maxWidth: .infinity).frame(height: 54).foregroundStyle(.black).background(KIRIColor.Text.accent).clipShape(RoundedRectangle(cornerRadius: 8))
                }.font(KIRITypography.bodyMedium).padding(.horizontal, 18).padding(.bottom, 10).background(KIRIColor.Background.base)
            }
        }.preferredColorScheme(.dark)
    }

    private func pickerSection(_ title: String, values: [String], selection: Binding<String?>) -> some View {
        VStack(alignment: .leading, spacing: 14) { Text(title).font(KIRITypography.headingSmall).foregroundStyle(KIRIColor.Text.strong); ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 8) { ForEach(values, id: \.self) { value in Button(value) { selection.wrappedValue = selection.wrappedValue == value ? nil : value }.font(KIRITypography.bodySmall).foregroundStyle(selection.wrappedValue == value ? KIRIColor.Text.accent : KIRIColor.Text.secondary).padding(.horizontal, 12).frame(height: 38).background(selection.wrappedValue == value ? KIRIColor.Background.greenSoft : KIRIColor.Background.tertiary).clipShape(Capsule()).buttonStyle(.plain) } } } }
    }

    private var calendarView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(monthTitle).font(KIRITypography.bodyMedium).foregroundStyle(KIRIColor.Text.strong)
                Spacer()
                Button { displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth } label: { Image("figma_navigation_back").resizable().scaledToFit().frame(width: 20, height: 20) }.buttonStyle(.plain)
                Button { displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth } label: { Image("figma_navigation_back").resizable().scaledToFit().rotationEffect(.degrees(180)).frame(width: 20, height: 20) }.buttonStyle(.plain)
            }.foregroundStyle(KIRIColor.Text.strong)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 18) {
                ForEach(weekdaySymbols, id: \.self) { Text($0).font(KIRITypography.caption).foregroundStyle(KIRIColor.Text.tertiary).frame(maxWidth: .infinity) }
                ForEach(Array(calendarDays.enumerated()), id: \.offset) { _, day in
                    if let day {
                        Button { date = day } label: {
                            Text(String(calendar.component(.day, from: day))).font(KIRITypography.bodySmall).foregroundStyle(calendar.isDate(day, inSameDayAs: date) ? KIRIColor.Text.accent : KIRIColor.Text.strong).frame(width: 32, height: 32).background(calendar.isDate(day, inSameDayAs: date) ? KIRIColor.Background.greenSoft : .clear).clipShape(RoundedRectangle(cornerRadius: 8))
                        }.buttonStyle(.plain)
                    } else { Color.clear.frame(height: 32) }
                }
            }
        }
    }

    private var calendar: Calendar { var value = Calendar(identifier: .gregorian); value.locale = Locale(identifier: "ko_KR"); value.firstWeekday = 2; return value }
    private var weekdaySymbols: [String] { ["월", "화", "수", "목", "금", "토", "일"] }
    private var monthTitle: String { let formatter = DateFormatter(); formatter.locale = Locale(identifier: "ko_KR"); formatter.dateFormat = "yyyy년 M월"; return formatter.string(from: displayedMonth) }
    private var calendarDays: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth), let first = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) else { return [] }
        let weekday = calendar.component(.weekday, from: first)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        return Array(repeating: nil, count: leading) + range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: first) }
    }
    private static func startOfMonth(_ date: Date) -> Date { Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: date)) ?? date }
}

#Preview { MissionView() }
