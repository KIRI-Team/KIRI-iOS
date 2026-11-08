//
// MARK: - 파일 가이드
// 파일: Features/Mission/MissionView.swift
// 담당 영역: 기능별 SwiftUI 화면과 상태
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
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
        var maxPrice: Int?

        static let empty = MissionFilter(regionCode: nil, distance: nil, maxPrice: nil)
        var count: Int { [regionCode, distance, maxPrice].compactMap { $0 }.count }
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
                        Color.clear.frame(height: 100)
                    }
                }
                .refreshable { await load(reset: true) }
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
            MissionActivityDetailView(missionId: row.mission.missionId, title: row.mission.title, placeName: row.mission.placeName, district: row.mission.category, rating: nil, tags: [row.mission.missionType], isRecommended: false, imageURL: row.mission.imageUrl, isBookmarked: Binding(get: { rows.first(where: { $0.id == row.id })?.isBookmarked ?? false }, set: { value in Task { await save(row.id, value: value) } }), onBack: { selectedMission = nil })
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
                    MissionPlaceCard(title: row.mission.title, placeName: row.mission.placeName, district: row.mission.category, rating: nil, tags: [row.mission.missionType], isRecommended: false, imageURL: row.mission.imageUrl, isBookmarked: Binding(get: { rows.first(where: { $0.id == row.id })?.isBookmarked ?? false }, set: { value in Task { await save(row.id, value: value) } }))
                        .contentShape(Rectangle()).onTapGesture { selectedMission = row }
                        .onAppear { if row.id == rows.last?.id, hasNext, !isLoadingMore { Task { await load(reset: false) } } }
                }
                if isLoadingMore { ProgressView().padding() }
            }
        }
    }

    private func load(reset: Bool) async {
        if reset { guard !isLoading else { return }; isLoading = true; errorMessage = nil } else { guard hasNext, !isLoadingMore else { return }; isLoadingMore = true }
        do {
            let result = try await AuthService.shared.missionFeed(category: selectedCategory.apiValue, regionCode: appliedFilter.regionCode, distance: appliedFilter.distance, maxPrice: appliedFilter.maxPrice, cursor: reset ? nil : nextCursor)
            let newRows = result.missions.map { MissionRow(id: $0.missionId, mission: $0, isBookmarked: false) }
            if reset { rows = newRows } else { rows.append(contentsOf: newRows) }
            nextCursor = result.nextCursor; hasNext = result.hasNext; errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
        isLoading = false; isLoadingMore = false
    }

    private func save(_ missionID: Int, value: Bool) async {
        guard value, savingMissionID == nil, let index = rows.firstIndex(where: { $0.id == missionID }), !rows[index].isBookmarked else { return }
        savingMissionID = missionID
        do { _ = try await AuthService.shared.saveMissionToBucket(missionId: missionID); rows[index].isBookmarked = true }
        catch { errorMessage = error.localizedDescription }
        savingMissionID = nil
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
    @State private var maxPrice: Int?

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
        _maxPrice = State(initialValue: initial.maxPrice)
    }

    var body: some View {
        ZStack {
            KIRIColor.Background.base.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left").font(.system(size: 18, weight: .medium)).frame(width: 44, height: 44)
                    }.buttonStyle(.plain)
                    Spacer()
                    Text("필터").font(KIRITypography.headingSmall)
                    Spacer()
                    Button { dismiss() } label: { Image(systemName: "xmark").font(.system(size: 18, weight: .medium)).frame(width: 44, height: 44) }.buttonStyle(.plain)
                }
                .foregroundStyle(KIRIColor.Text.strong)
                .padding(.horizontal, 8)
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 26) {
                        filterSection(title: "지역") {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 10) {
                                ForEach(regions) { region in chip(region.title, selected: regionCode == region.id) { regionCode = regionCode == region.id ? nil : region.id } }
                            }
                        }
                        filterSection(title: "거리") {
                            HStack(spacing: 8) { ForEach(distances, id: \.0) { item in chip(item.1, selected: distance == item.0) { distance = distance == item.0 ? nil : item.0 } } }
                        }
                        filterSection(title: "가격") {
                            HStack(spacing: 8) { ForEach(prices, id: \.0) { item in chip(item.1, selected: maxPrice == item.0) { maxPrice = maxPrice == item.0 ? nil : item.0 } } }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 100)
                }
            }
            VStack { Spacer(); actionButtons }
        }
        .preferredColorScheme(.dark)
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

    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button("초기화") { regionCode = nil; distance = nil; maxPrice = nil }
                .frame(maxWidth: .infinity).frame(height: 54).background(KIRIColor.Background.secondary).clipShape(RoundedRectangle(cornerRadius: 8))
            Button("적용하기") { onApply(MissionView.MissionFilter(regionCode: regionCode, distance: distance, maxPrice: maxPrice)) }
                .frame(maxWidth: .infinity).frame(height: 54).foregroundStyle(.black).background(KIRIColor.Text.accent).clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .font(KIRITypography.bodyMedium)
        .padding(.horizontal, 18)
        .padding(.bottom, 10)
        .background(KIRIColor.Background.base)
    }
}

#Preview { MissionView() }
