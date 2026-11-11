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
    @State private var bookmarkConfirmationMissionID: Int?
    @State private var bookmarkFeedback: String?
    // 필터·카테고리 변경으로 새 요청이 시작되면 이전 응답이 화면을 덮어쓰지 않도록 식별자를 갱신합니다.
    @State private var loadGeneration = UUID()

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
        }
        .task { await load(reset: true) }
        .fullScreenCover(isPresented: $isFilterPresented) {
            MissionFilterView(initial: appliedFilter) { newFilter in
                appliedFilter = newFilter
                isFilterPresented = false
                Task { await load(reset: true) }
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
                    KIRIChip(title: category.rawValue, isSelected: selectedCategory == category) { selectedCategory = category; Task { await load(reset: true) } }
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
                        .contentShape(Rectangle()).onTapGesture { selectedMission = row }
                        .onAppear { if row.id == rows.last?.id, hasNext, !isLoadingMore { Task { await load(reset: false) } } }
                }
                if isLoadingMore { ProgressView().padding() }
            }
        }
    }

    private func load(reset: Bool) async {
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
            guard hasNext, !isLoadingMore else { return }
            generation = loadGeneration
            isLoadingMore = true
        }
        do {
            let category = selectedCategory.apiValue
            let filter = appliedFilter
            let cursor = reset ? nil : nextCursor
            let result = try await AuthService.shared.missionFeed(category: category, regionCode: filter.regionCode, distance: filter.distance, date: filter.date, time: filter.time, isFree: filter.isFree, maxPrice: filter.maxPrice, cursor: cursor)
            guard !Task.isCancelled, generation == loadGeneration else { return }
            if reset {
                await refreshSavedMissionIDs()
            }
            let newRows = result.missions.map { MissionRow(id: $0.missionId, mission: $0, isBookmarked: savedMissionIDs.contains($0.missionId)) }
            if reset { rows = newRows } else { rows.append(contentsOf: newRows) }
            nextCursor = result.nextCursor; hasNext = result.hasNext; errorMessage = nil
        } catch {
            guard !Task.isCancelled, generation == loadGeneration else { return }
            errorMessage = error.localizedDescription
        }
        if generation == loadGeneration {
            isLoading = false
            isLoadingMore = false
        }
    }

    private func save(_ missionID: Int, value: Bool) async {
        guard savingMissionID == nil, rows.contains(where: { $0.id == missionID }) else { return }
        savingMissionID = missionID
        do {
            if value {
                _ = try await AuthService.shared.saveMissionToBucket(missionId: missionID)
            } else {
                try await AuthService.shared.removeMissionFromBucket(missionId: missionID)
            }
            savedMissionIDs = value ? savedMissionIDs.union([missionID]) : savedMissionIDs.subtracting([missionID])
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
            showBookmarkFeedback("버킷 저장 상태를 변경하지 못했어요. 다시 시도해 주세요.")
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

    private func refreshSavedMissionIDs() async {
        do {
            var cursor: Int?
            var ids = Set<Int>()
            while true {
                let page = try await AuthService.shared.bucketItems(cursor: cursor)
                ids.formUnion(page.bucketItems.map { $0.mission.missionId })
                guard page.hasNext, let nextCursor = page.nextCursor, nextCursor != cursor else { break }
                cursor = nextCursor
            }
            savedMissionIDs = ids
            for index in rows.indices {
                rows[index].isBookmarked = ids.contains(rows[index].id)
            }
        } catch {
            // 저장 목록 조회 실패 시 마지막으로 확인된 카드 상태를 유지합니다.
        }
    }
}

private struct MissionFilterView: View {
    private struct Region: Identifiable, Hashable {
        let id: String
        let title: String
    }

    let initial: MissionView.MissionFilter
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

    private let regions = [
        Region(id: "SEOUL", title: "서울"), Region(id: "INCHEON", title: "인천"),
        Region(id: "GYEONGGI", title: "경기"), Region(id: "DAEJEON", title: "대전"),
        Region(id: "SEJONG", title: "세종"), Region(id: "CHUNGCHEONG", title: "충청"),
        Region(id: "DAEGU", title: "대구"), Region(id: "GYEONGSANG", title: "경상"),
        Region(id: "ULSAN", title: "울산"), Region(id: "BUSAN", title: "부산"),
        Region(id: "GWANGJU", title: "광주"), Region(id: "JEOLLA", title: "전라"),
        Region(id: "GANGWON", title: "강원"), Region(id: "JEJU", title: "제주")
    ]
    private let distances: [(Int, String)] = [(1, "1km 이내"), (3, "3km 이내"), (5, "5km 이내"), (10, "10km 이내")]
    private let prices: [(Int, String)] = [(0, "무료"), (10000, "1만원 이하"), (30000, "3만원 이하")]

    init(initial: MissionView.MissionFilter, onApply: @escaping (MissionView.MissionFilter) -> Void) {
        self.initial = initial
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
                filterTab("날짜·인원", selected: true)
                filterTab("지역", selected: false)
                filterTab("거리", selected: false)
                filterTab("가격", selected: false)
            }
            .padding(.horizontal, 18)
            .overlay(alignment: .bottom) { Rectangle().fill(KIRIColor.Border.default).frame(height: 1).padding(.horizontal, 18) }

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
            .padding(.horizontal, 18)
            .padding(.top, 16)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 26) {
                    filterSection(title: "지역") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 10) {
                            ForEach(regions) { region in chip(region.title, selected: regionCode == region.id) { regionCode = regionCode == region.id ? nil : region.id } }
                        }
                    }
                    filterSection(title: "거리") {
                        ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 8) { ForEach(distances, id: \.0) { item in chip(item.1, selected: distance == item.0) { distance = distance == item.0 ? nil : item.0 } } } }
                    }
                    filterSection(title: "가격") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("1인 기준 요금").font(KIRITypography.bodySmall).foregroundStyle(KIRIColor.Text.secondary)
                            ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 8) { ForEach(prices, id: \.0) { item in priceChip(item) } } }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 24)
                .padding(.bottom, 110)
            }
            actionButtons
        }
        .background(KIRIColor.Background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .ignoresSafeArea(edges: .bottom)
    }

    private func filterTab(_ title: String, selected: Bool) -> some View {
        Button {} label: {
            Text(title).font(KIRITypography.bodySmallMedium)
                .foregroundStyle(selected ? KIRIColor.Text.strong : KIRIColor.Text.secondary)
                .frame(maxWidth: .infinity).frame(height: 48)
                .overlay(alignment: .bottom) { if selected { Rectangle().fill(KIRIColor.Text.strong).frame(height: 2) } }
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
