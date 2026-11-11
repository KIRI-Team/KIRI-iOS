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

    @State private var isFamilyCreationPresented = false
    @State private var isFamilyJoinPresented = false
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

                        recommendationSection(title: "엄마와 함께라면 여기!")
                            .padding(.top, 36)

                        recommendationSection(title: "오늘 가을분위기를 느끼고 싶다면")
                            .padding(.top, 36)

                        Spacer()
                            .frame(height: 140)
                    }
                    .padding(.leading, 18)
                }
            }
            .fullScreenCover(isPresented: $isFamilyCreationPresented) {
                BrowseFamilyCreationFlow(
                    onDismiss: { isFamilyCreationPresented = false },
                    onFamilyCreated: onFamilyCreated
                )
            }
            .fullScreenCover(isPresented: $isFamilyJoinPresented) {
                BrowseFamilyJoinFlow(
                    onDismiss: { isFamilyJoinPresented = false },
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
        VStack(spacing: 10) {
            Button {
                isFamilyCreationPresented = true
            } label: {
                familyActionRow(
                    title: "가족공간 만들기",
                    subtitle: "가족과 함께 시작해요"
                )
            }
            .buttonStyle(.plain)

            Button {
                isFamilyJoinPresented = true
            } label: {
                familyActionRow(
                    title: "초대코드로 참여하기",
                    subtitle: "받은 코드로 가족공간에 참여해요"
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 18)
        .frame(width: 354)
        .background(KIRIColor.Background.primary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func familyActionRow(title: String, subtitle: String) -> some View {
            HStack(spacing: 12) {
                ZStack {
                    KIRIColor.Background.secondary

                    Image("browse_action_icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
                .frame(width: 48, height: 48)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("아직 가족 공간이 없군요!")
                        .font(KIRITypography.caption)
                        .foregroundStyle(KIRIColor.Text.tertiary)

                    Text(title)
                        .font(KIRITypography.headingSmall)
                        .foregroundStyle(KIRIColor.Text.strong)
                }

                Spacer()

                Image("browse_arrow")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
            }
            .frame(height: 62)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(title)
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

private struct BrowseFamilyCreationFlow: View {
    private enum Step {
        case entry
        case familyName
        case loading
        case code
    }

    @State private var step: Step = .entry
    @State private var familyName = ""
    @State private var familyCode = ""
    @State private var errorMessage: String?

    let onDismiss: () -> Void
    let onFamilyCreated: (String, String) -> Void

    var body: some View {
        ZStack {
            KIRIColor.Background.base
                .ignoresSafeArea()

            switch step {
            case .entry:
                FamilyEntryView(
                    mode: .creationOnly,
                    onBack: onDismiss,
                    onCreateFamily: {
                        step = .familyName
                    },
                    onEnterFamilyCode: {},
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
            }
        }
        .alert("가족공간을 만들 수 없어요", isPresented: Binding(
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
}

private struct BrowseFamilyJoinFlow: View {
    enum Step { case code, confirm, loading }
    @State private var step: Step = .code
    @State private var code = ""
    @State private var familyName = ""
    @State private var errorMessage: String?
    let onDismiss: () -> Void
    let onFamilyJoined: (String, String, Int?) -> Void

    var body: some View {
        ZStack {
            KIRIColor.Background.base.ignoresSafeArea()
            switch step {
            case .code:
                FamilyCodeInputView(familyCode: $code, onBack: onDismiss, onNext: findFamily)
            case .confirm:
                FamilyJoinConfirmView(
                    familyName: familyName,
                    familyCode: code,
                    onBack: { step = .code },
                    onJoin: joinFamily
                )
            case .loading:
                FamilyJoinLoadingView()
            }
        }
        .alert("가족공간에 참여할 수 없어요", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) { Button("확인", role: .cancel) {} } message: {
            Text(errorMessage ?? "잠시 후 다시 시도해 주세요.")
        }
        .preferredColorScheme(.dark)
    }

    private func findFamily() {
        let normalized = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard normalized.count == 6, normalized.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber) }) else {
            errorMessage = "초대 코드는 영문 대문자와 숫자 6자리여야 해요."
            return
        }
        code = normalized
        familyName = "입력한 초대 코드의 가족공간"
        step = .confirm
    }

    private func joinFamily() {
        step = .loading
        Task { @MainActor in
            do {
                let result = try await AuthService.shared.joinFamily(inviteCode: code)
                AppSessionStore().saveFamily(name: result.familyName, inviteCode: code, familyId: result.familyId)
                onFamilyJoined(result.familyName, code, result.familyId)
            } catch {
                errorMessage = "가족공간에 참여하지 못했어요. 코드를 확인하고 다시 시도해 주세요."
                step = .code
            }
        }
    }
}

#Preview {
    BrowseHomeView(onFamilyCreated: { _, _ in }, onRetryFamilyState: {})
}
