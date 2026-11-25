//
// MARK: - 파일 가이드
// 파일: Features/Home/BrowseHomeView.swift
// 담당 영역: 기능별 SwiftUI 화면과 상태
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//

import SwiftUI

/// 둘러보기 전용 홈.
/// 가족공간에 연결되지 않은 사용자는 공개 장소 추천만 볼 수 있다.
struct BrowseHomeView: View {
    let familyState: AppRouter.FamilyState
    /// 둘러보기 모드는 가족공간 조회 실패와 별개의 화면 상태입니다.
    /// 라우터가 네트워크 상태를 갱신하는 동안에도 이 카드는 유지합니다.
    let isBrowseMode: Bool
    let onFamilyCreated: (String, String, Int?) -> Void
    let onFamilyJoined: (String, String, Int?) -> Void
    let onRetryFamilyState: () -> Void

    @State private var isFamilyEntryPresented = false
    @State private var missions: [MissionFeedItem] = []
    @State private var isLoadingMissions = false
    @State private var isLoadingMoreMissions = false
    @State private var nextMissionCursor: Int?
    @State private var hasMoreMissions = false
    @State private var missionError: String?
    @State private var selectedMission: MissionFeedItem?
    @State private var selectedMissionBookmark = false

    init(
        familyState: AppRouter.FamilyState = .noFamily,
        isBrowseMode: Bool = true,
        onFamilyCreated: @escaping (String, String, Int?) -> Void,
        onFamilyJoined: @escaping (String, String, Int?) -> Void = { _, _, _ in },
        onRetryFamilyState: @escaping () -> Void = {}
    ) {
        self.familyState = familyState
        self.isBrowseMode = isBrowseMode
        self.onFamilyCreated = onFamilyCreated
        self.onFamilyJoined = onFamilyJoined
        self.onRetryFamilyState = onRetryFamilyState
    }

    var body: some View {
        ZStack {
            KIRIColor.Background.base
                .ignoresSafeArea()

            VStack(spacing: 0) {
                navigationBar

                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        familyStateCard
                            .padding(.top, 18)

                        recommendationSection(title: "가족과 함께라면 여기!", missions: allPublicMissions)
                            .padding(.top, 36)

                        recommendationSection(title: "오늘 가을분위기를 느끼고 싶다면", missions: outdoorMissions)
                            .padding(.top, 36)

                        Spacer()
                            .frame(height: 140)
                    }
                    .padding(.leading, 18)
                }
            }
            .fullScreenCover(isPresented: $isFamilyEntryPresented) {
                BrowseFamilyEntryFlow(
                    onDismiss: { isFamilyEntryPresented = false },
                    onFamilyCreated: onFamilyCreated,
                    onFamilyJoined: onFamilyJoined
                )
            }
            .fullScreenCover(item: $selectedMission) { mission in
                MissionActivityDetailView(
                    missionId: mission.missionId,
                    title: mission.title,
                    placeName: mission.placeName,
                    district: MissionDisplayLabel.category(mission.category) ?? "",
                    rating: nil,
                    tags: mission.displayTags,
                    isRecommended: false,
                    imageURL: mission.imageUrl,
                    isBookmarked: $selectedMissionBookmark,
                    onBack: { selectedMission = nil }
                )
            }
            .task { await loadMissions() }
        }
    }

    @ViewBuilder
    private var familyStateCard: some View {
        // 둘러보기 사용자는 가족공간을 조회할 대상이 없으므로 조회 실패
        // 카드가 아니라 항상 가족공간 시작 카드를 봅니다.
        if isBrowseMode {
            familyActionCard
        } else {
            switch familyState {
            case .noFamily:
                familyActionCard
            case .loading:
                familyStatusCard(title: "가족공간을 확인하고 있어요", actionTitle: nil, action: {})
            case .unknown:
                familyStatusCard(title: "가족공간 정보를 확인하지 못했어요", actionTitle: "다시 시도", action: onRetryFamilyState)
            case .hasFamily:
                familyStatusCard(title: "가족공간 정보를 불러오고 있어요", actionTitle: nil, action: {})
            }
        }
    }

    private func familyStatusCard(
        title: String,
        actionTitle: String?,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(KIRITypography.headingSmall)
                .foregroundStyle(KIRIColor.Text.strong)
            if let actionTitle {
                Button(actionTitle, action: action)
                    .font(KIRITypography.caption)
                    .foregroundStyle(KIRIColor.Primary.default)
            }
        }
        .padding(.horizontal, 18)
        .frame(width: 354, height: 96, alignment: .leading)
        .background(KIRIColor.Background.primary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var navigationBar: some View {
        Text("끼리네 가족")
            .kiriTextStyle(KIRITypography.titleLarge)
            .foregroundStyle(KIRIColor.Text.strong)
            .frame(maxWidth: .infinity)
            .frame(height: 62)
    }

    private var familyActionCard: some View {
        Button {
            isFamilyEntryPresented = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    KIRIColor.Background.secondary

                    Image("browse_action_icon")
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
                .frame(width: 48, height: 48)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("아직 가족 공간이 없군요!")
                        .font(KIRITypography.bodySmall)
                        .foregroundStyle(KIRIColor.Text.secondary)

                    Text("가족공간 만들러 가기")
                        .font(KIRITypography.headingSmall)
                        .foregroundStyle(KIRIColor.Text.strong)
                }

                Spacer()

                Image("browse_arrow")
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    // Figma Action Row reuses the navigation-back vector and
                    // mirrors it for the trailing (right-facing) chevron.
                    .rotationEffect(.degrees(180))
            }
            .padding(.horizontal, 18)
            .frame(width: 354, height: 96)
            .background(KIRIColor.Background.primary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityLabel("가족공간 만들러 가기")
    }

    private var allPublicMissions: [MissionFeedItem] {
        missions
    }

    private var outdoorMissions: [MissionFeedItem] {
        missions.filter { $0.category.caseInsensitiveCompare("OUTDOOR") == .orderedSame }
    }

    private func recommendationSection(title: String, missions: [MissionFeedItem]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .kiriTextStyle(KIRITypography.titleLarge)
                .foregroundStyle(KIRIColor.Text.strong)

            missionContent(for: missions)
        }
        .onAppear {
            // 두 번째 세로 섹션에 접근할 때도 다음 커서를 미리 요청합니다.
            guard title == "오늘 가을분위기를 느끼고 싶다면" else { return }
            Task {
                await prefetchOutdoorImages()
                await loadMoreMissions()
            }
        }
    }

    private func prefetchOutdoorImages() async {
        let urls = outdoorMissions.prefix(3).compactMap(\.imageUrl)
        guard !urls.isEmpty else { return }
        let startedAt = Date()
        #if DEBUG
        print("[KIRI][BrowsePerf] autumn image prefetch started count=\(urls.count)")
        #endif
        await KIRIImagePrefetcher.prefetch(urls, maxPixelSize: 768)
        #if DEBUG
        print("[KIRI][BrowsePerf] autumn image prefetch complete elapsedMs=\(Int(Date().timeIntervalSince(startedAt) * 1000))")
        #endif
    }

    @ViewBuilder
    private func missionContent(for missions: [MissionFeedItem]) -> some View {
        if isLoadingMissions && missions.isEmpty {
            ProgressView().tint(KIRIColor.Primary.default).frame(height: 284)
        } else if missionError != nil, self.missions.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("미션을 불러오지 못했어요")
                    .font(KIRITypography.bodySmall)
                    .foregroundStyle(KIRIColor.Text.secondary)
                Button("다시 시도") { Task { await loadMissions() } }
                    .font(KIRITypography.captionMedium)
                    .foregroundStyle(KIRIColor.Text.accent)
            }
            .frame(width: 251, height: 120, alignment: .center)
        } else if missions.isEmpty {
            Text("추천 미션이 아직 없어요")
                .font(KIRITypography.bodySmall)
                .foregroundStyle(KIRIColor.Text.secondary)
                .frame(width: 251, height: 120, alignment: .center)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    ForEach(missions) { mission in
                        Button {
                            AppEventTracker.record("mission_card_click", properties: ["mission_id": String(mission.missionId)])
                            selectedMission = mission
                            selectedMissionBookmark = false
                        } label: {
                            PlaceCard(
                                title: mission.title,
                                location: mission.placeName,
                                rating: nil,
                                description: nil,
                                imageURL: mission.imageUrl
                            )
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            guard let index = missions.firstIndex(where: { $0.missionId == mission.missionId }),
                                  index >= max(missions.count - 2, 0) else { return }
                            Task { await loadMoreMissions() }
                        }
                    }
                    if hasMoreMissions {
                        ProgressView()
                            .tint(KIRIColor.Primary.default)
                            .frame(width: 24, height: 24)
                            .padding(.horizontal, 6)
                    }
                }
                .padding(.trailing, 18)
            }
        }
    }

    @MainActor
    private func loadMissions() async {
        guard !isLoadingMissions else { return }
        let startedAt = Date()
        isLoadingMissions = true
        missionError = nil
        defer { isLoadingMissions = false }
        do {
            let page = try await AuthService.shared.missionFeed(cursor: nil, size: 5)
            var seen = Set<Int>()
            missions = page.missions.filter { seen.insert($0.missionId).inserted }
            nextMissionCursor = page.nextCursor
            hasMoreMissions = page.hasNext && page.nextCursor != nil
            #if DEBUG
            print("[KIRI][BrowsePerf] missionFeed firstPage items=\(missions.count) hasNext=\(hasMoreMissions) elapsedMs=\(Int(Date().timeIntervalSince(startedAt) * 1000))")
            #endif
        } catch {
            missionError = "미션 조회 실패"
            #if DEBUG
            print("[KIRI][BrowsePerf] missionFeed failed elapsedMs=\(Int(Date().timeIntervalSince(startedAt) * 1000))")
            #endif
        }
    }

    @MainActor
    private func loadMoreMissions() async {
        guard hasMoreMissions, !isLoadingMoreMissions, let cursor = nextMissionCursor else { return }
        isLoadingMoreMissions = true
        defer { isLoadingMoreMissions = false }
        do {
            let page = try await AuthService.shared.missionFeed(cursor: cursor, size: 5)
            let existing = Set(missions.map(\.missionId))
            missions.append(contentsOf: page.missions.filter { !existing.contains($0.missionId) })
            nextMissionCursor = page.nextCursor
            hasMoreMissions = page.hasNext && page.nextCursor != cursor && page.nextCursor != nil
        } catch {
            // 이미 표시 중인 카드는 유지하고 다음 가로 스크롤에서 재시도합니다.
        }
    }
}

struct BrowseFamilyEntryFlow: View {
    private enum Step {
        case entry
        case familyName
        case loading
        case code
        case familyCodeInput
        case familyJoinLoading
        case familyJoinConfirm
    }

    @State private var step: Step = .entry
    @State private var familyName = ""
    @State private var familyCode = ""
    @State private var createdFamilyId: Int?
    @State private var joinedFamilyName = ""
    @State private var errorMessage: String?

    let onDismiss: () -> Void
    let onFamilyCreated: (String, String, Int?) -> Void
    let onFamilyJoined: (String, String, Int?) -> Void

    var body: some View {
        ZStack {
            KIRIColor.Background.base
                .ignoresSafeArea()

            switch step {
            case .entry:
                FamilyEntryView(
                    // 둘러보기 홈에서 시작한 생성 흐름에서는 다시 둘러보기로
                    // 돌아가는 버튼을 보여주지 않습니다. 뒤로가기는 기존 홈으로
                    // 복귀시키고, 온보딩의 기본 진입은 .all을 유지합니다.
                    mode: .familyConnection,
                    onBack: onDismiss,
                    onCreateFamily: {
                        step = .familyName
                    },
                    onEnterFamilyCode: {
                        familyCode = ""
                        step = .familyCodeInput
                    },
                    onBrowse: {}
                )

            case .familyName:
                FamilyNameView(
                    familyName: $familyName,
                    onBack: {
                        step = .entry
                    },
                    onNext: {
                        step = .loading
                        createFamilyCode()
                    }
                )

            case .loading:
                FamilyCodeLoadingView()

            case .code:
                FamilyCodeView(
                    familyName: familyName,
                    familyCode: familyCode,
                    onBack: {
                        step = .familyName
                    },
                    onComplete: { onFamilyCreated(familyName, familyCode, createdFamilyId) },
                    onShareFinished: { onFamilyCreated(familyName, familyCode, createdFamilyId) }
                )

            case .familyCodeInput:
                FamilyCodeInputView(
                    familyCode: $familyCode,
                    onBack: { step = .entry },
                    onNext: findFamily
                )

            case .familyJoinLoading:
                FamilyJoinLoadingView()

            case .familyJoinConfirm:
                FamilyJoinConfirmView(
                    familyName: joinedFamilyName,
                    familyCode: familyCode,
                    onBack: { step = .familyCodeInput },
                    onJoin: joinFamily
                )
            }
        }
        .alert("가족공간을 처리할 수 없어요", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) { Button("확인", role: .cancel) {} } message: {
            Text(errorMessage ?? "잠시 후 다시 시도해주세요.")
        }
        .preferredColorScheme(.dark)
    }

    private func createFamilyCode() {
        Task { @MainActor in
            do {
                let result = try await AuthService.shared.createFamily(name: familyName)
                familyCode = result.inviteCode
                createdFamilyId = result.familyId
                AppSessionStore().saveFamily(
                    name: result.name,
                    inviteCode: result.inviteCode,
                    familyId: result.familyId
                )
                step = .code
            } catch {
                errorMessage = error.localizedDescription
                step = .familyName
            }
        }
    }

    private func findFamily() {
        let normalized = familyCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard normalized.count == 6, normalized.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber) }) else {
            errorMessage = "초대 코드는 영문 대문자와 숫자 6자리여야 해요."
            return
        }
        familyCode = normalized
        joinedFamilyName = "입력한 초대 코드의 가족공간"
        step = .familyJoinConfirm
    }

    private func joinFamily() {
        step = .familyJoinLoading
        Task { @MainActor in
            do {
                let result = try await AuthService.shared.joinFamily(inviteCode: familyCode)
                AppSessionStore().saveFamily(name: result.familyName, inviteCode: familyCode, familyId: result.familyId)
                onFamilyJoined(result.familyName, familyCode, result.familyId)
            } catch {
                errorMessage = "가족공간에 참여하지 못했어요. 코드를 확인하고 다시 시도해 주세요."
                step = .familyCodeInput
            }
        }
    }
}

#Preview {
    BrowseHomeView(onFamilyCreated: { _, _, _ in }, onRetryFamilyState: {})
}
