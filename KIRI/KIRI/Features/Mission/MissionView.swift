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
    @State private var rows: [MissionRow] = []
    @State private var selectedMission: MissionRow?
    @State private var searchText = ""
    @State private var selectedCategory: Category = .all
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
                Text("미션").font(KIRITypography.headingSmall).foregroundStyle(KIRIColor.Text.strong).frame(maxWidth: .infinity).frame(height: 62)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        KIRISearchField(text: $searchText).padding(.horizontal, 18).padding(.top, 6)
                        categorySection.padding(.top, 13)
                        HStack { Text("활동 \(filteredRows.count)개").font(KIRITypography.bodySmallMedium).foregroundStyle(KIRIColor.Text.secondary); Spacer(); if isLoading { ProgressView().controlSize(.small) } }.frame(height: 20).padding(.horizontal, 18).padding(.top, 24)
                        content.padding(.horizontal, 18).padding(.top, 16)
                        Color.clear.frame(height: 100)
                    }
                }
                .refreshable { await load(reset: true) }
            }
        }
        .task { await load(reset: true) }
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
            let result = try await AuthService.shared.missionFeed(category: selectedCategory.apiValue, cursor: reset ? nil : nextCursor)
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

#Preview { MissionView() }
