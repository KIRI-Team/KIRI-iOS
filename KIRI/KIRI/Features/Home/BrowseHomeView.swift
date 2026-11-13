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
    let onFamilyCreated: (String, String) -> Void
    let onFamilyJoined: (String, String, Int?) -> Void
    let onRetryFamilyState: () -> Void

    @State private var isFamilyEntryPresented = false
    @State private var missions: [MissionFeedItem] = []
    @State private var isLoadingMissions = false
    @State private var missionError: String?
    @State private var selectedMission: MissionFeedItem?
    @State private var selectedMissionBookmark = false

    init(
        familyState: AppRouter.FamilyState = .noFamily,
        onFamilyCreated: @escaping (String, String) -> Void,
        onFamilyJoined: @escaping (String, String, Int?) -> Void = { _, _, _ in },
        onRetryFamilyState: @escaping () -> Void = {}
    ) {
        self.familyState = familyState
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
                    VStack(alignment: .leading, spacing: 0) {
                        familyStateCard
                            .padding(.top, 18)

                        recommendationSection(title: "추천 미션")
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
            .font(KIRITypography.headingSmall)
            .tracking(-0.72)
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

                Text("아직 가족 공간이 없군요!")
                    .font(KIRITypography.headingSmall)
                    .foregroundStyle(KIRIColor.Text.strong)

                Spacer()

                Image("browse_arrow")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
            .padding(.horizontal, 18)
            .frame(width: 354, height: 96)
            .background(KIRIColor.Background.primary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("가족공간 만들러 가기")
    }

    private func recommendationSection(title: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(KIRITypography.headingSmall)
                .tracking(-0.72)
                .foregroundStyle(KIRIColor.Text.strong)

            missionContent
        }
    }

    @ViewBuilder
    private var missionContent: some View {
        if isLoadingMissions && missions.isEmpty {
            ProgressView().tint(KIRIColor.Primary.default).frame(height: 284)
        } else if let missionError, missions.isEmpty {
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
                    }
                }
                .padding(.trailing, 18)
            }
        }
    }

    @MainActor
    private func loadMissions() async {
        guard !isLoadingMissions else { return }
        isLoadingMissions = true
        missionError = nil
        defer { isLoadingMissions = false }
        do {
            missions = try await AuthService.shared.missionFeed().missions
        } catch {
            missionError = "미션 조회 실패"
        }
    }
}

private struct BrowseFamilyEntryFlow: View {
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
    @State private var joinedFamilyName = ""
    @State private var errorMessage: String?

    let onDismiss: () -> Void
    let onFamilyCreated: (String, String) -> Void
    let onFamilyJoined: (String, String, Int?) -> Void

    var body: some View {
        ZStack {
            KIRIColor.Background.base
                .ignoresSafeArea()

            switch step {
            case .entry:
                FamilyEntryView(
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
                    onComplete: { onFamilyCreated(familyName, familyCode) }
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
    BrowseHomeView(onFamilyCreated: { _, _ in }, onRetryFamilyState: {})
}
