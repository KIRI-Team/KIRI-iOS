//
// MARK: - 파일 가이드
// 파일: Features/Home/HomeView.swift
// 담당 영역: 기능별 SwiftUI 화면과 상태
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//

import SwiftUI

@Observable
final class HomeTutorialStore {
    private let identity: String?
    private static let legacyBrowseKey = "kiri_browse_tutorial_completed"

    var mode: HomeTutorialView.Mode
    var step: Int = 0
    var isActive: Bool = false
    var scopeKey: String {
        if let identity, !identity.isEmpty { return "kiri_home_tutorial_completed.\(identity)" }
        return "kiri_home_tutorial_completed.guest"
    }

    init(mode: HomeTutorialView.Mode, familyId: Int? = nil, identity: String? = nil) {
        self.mode = mode
        self.identity = identity
        migrateLegacyCompletionIfNeeded(familyId: familyId)
        isActive = mode == .family && !UserDefaults.standard.bool(forKey: scopeKey)
    }

    func updateScope(mode: HomeTutorialView.Mode, familyId: Int?) {
        self.mode = mode
        step = 0
        migrateLegacyCompletionIfNeeded(familyId: familyId)
        // 둘러보기는 튜토리얼 없이 Figma 9898:15398 Browse 홈으로 바로 진입합니다.
        isActive = mode == .family && !UserDefaults.standard.bool(forKey: scopeKey)
    }

    private func migrateLegacyCompletionIfNeeded(familyId: Int?) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: scopeKey) else { return }
        // Legacy keys were not account-scoped. Never copy them into a stable
        // account key, otherwise one account's completion could suppress the
        // first tutorial for another account.
        guard identity == nil else { return }
        let legacyFamilyKey = familyId.map { "kiri_family_tutorial_completed.\($0)" }
        if defaults.bool(forKey: Self.legacyBrowseKey)
            || legacyFamilyKey.map({ defaults.bool(forKey: $0) }) == true {
            defaults.set(true, forKey: scopeKey)
        }
    }
}

struct HomeView: View {
    let userMode: AppRouter.UserMode
    let familyName: String?
    let familyInviteCode: String?
    let familyId: Int?
    let nickname: String?
    let familyRole: String?
    let familyState: AppRouter.FamilyState
    let onRetryFamilyState: () -> Void
    let tutorialStore: HomeTutorialStore
    let onFamilyCreated: (String, String) -> Void
    let onExploreMission: () -> Void

    @State private var didApplyDebugReset = false
    @State private var tutorialFrames: [HomeTutorialTarget: CGRect] = [:]

    init(
        userMode: AppRouter.UserMode,
        familyName: String?,
        familyInviteCode: String?,
        familyId: Int? = nil,
        nickname: String? = nil,
        familyRole: String? = nil,
        familyState: AppRouter.FamilyState = .unknown,
        onRetryFamilyState: @escaping () -> Void = {},
        tutorialStore: HomeTutorialStore,
        onFamilyCreated: @escaping (String, String) -> Void,
        onExploreMission: @escaping () -> Void
    ) {
        self.userMode = userMode
        self.familyName = familyName
        self.familyInviteCode = familyInviteCode
        self.familyId = familyId
        self.nickname = nickname
        self.familyRole = familyRole
        self.familyState = familyState
        self.onRetryFamilyState = onRetryFamilyState
        self.tutorialStore = tutorialStore
        self.onFamilyCreated = onFamilyCreated
        self.onExploreMission = onExploreMission
    }

    private var tutorialCompleted: Bool {
        UserDefaults.standard.bool(forKey: tutorialStore.scopeKey)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            homeContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if tutorialStore.isActive {
                HomeTutorialView(
                    mode: tutorialStore.mode,
                    frames: tutorialFrames,
                    onComplete: completeTutorial,
                    onStepChanged: { tutorialStore.step = $0 }
                )
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .topLeading
                )
                .zIndex(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .coordinateSpace(name: "homeTutorial")
        .onPreferenceChange(HomeTutorialFramePreferenceKey.self) { frames in
            tutorialFrames = frames
        }
        .onAppear {
            applyDebugResetIfRequested()
            syncTutorialState()
            debugLog("onAppear")
        }
        .onChange(of: String(describing: userMode)) { _, _ in
            syncTutorialState()
        }
        .task(id: String(describing: userMode)) {
            // Root/AppRouter가 둘러보기에서 가족공간으로 전환되는 경우에도
            // HomeView가 새 모드의 완료 상태를 즉시 다시 평가한다.
            syncTutorialState()
        }
    }

    @ViewBuilder
    private var homeContent: some View {
        switch userMode {
        case .family:
                FamilyHomeView(
                    familyName: familyName,
                    familyId: familyId,
                    familyInviteCode: familyInviteCode,
                    nickname: nickname,
                    familyRole: familyRole,
                    tutorialStep: tutorialStore.isActive ? tutorialStore.step : nil,
                    loadsServerQuestion: true,
                    onExploreMission: onExploreMission
            )

        case .browse:
            BrowseHomeView(
                familyState: familyState,
                onFamilyCreated: onFamilyCreated,
                onRetryFamilyState: onRetryFamilyState
            )
        }
    }

    private func syncTutorialState() {
        let mode: HomeTutorialView.Mode = {
            switch userMode {
            case .browse:
                return .browse
            case .family:
                return .family
            }
        }()
        tutorialStore.updateScope(mode: mode, familyId: familyId)

        // 둘러보기 홈은 가족 튜토리얼의 대상이 아닙니다. updateScope에서
        // 비활성화한 상태를 여기서 다시 활성화하지 않도록 모드를 먼저 종료합니다.
        guard userMode == .family else {
            tutorialStore.isActive = false
            tutorialStore.step = 0
            return
        }

        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-force-kiri-home-tutorial") {
            if !tutorialStore.isActive {
                tutorialStore.step = 0
            }
            tutorialStore.isActive = true
            debugLog("DEBUG force tutorial")
            return
        }
        #endif

        guard !tutorialCompleted else {
            tutorialStore.isActive = false
            return
        }

        if !tutorialStore.isActive {
            tutorialStore.step = 0
            tutorialStore.isActive = true
        }
        debugLog("tutorial synchronized")
    }

    private func completeTutorial() {
        UserDefaults.standard.set(true, forKey: tutorialStore.scopeKey)
        tutorialStore.isActive = false
        tutorialStore.step = 0
        debugLog("tutorial completed")
    }

    #if DEBUG
    private func debugLog(_ event: String) {
        print(
            "[KIRI TutorialDebug][HomeContainer] \(event) " +
            "mode=\(String(describing: tutorialStore.mode)) " +
            "active=\(tutorialStore.isActive) " +
            "step=\(tutorialStore.step) " +
            "completed=\(tutorialCompleted)"
        )
    }

    private func applyDebugResetIfRequested() {
        guard !didApplyDebugReset else { return }
        didApplyDebugReset = true
        guard ProcessInfo.processInfo.arguments.contains("-reset-kiri-home-tutorial") else { return }
        UserDefaults.standard.set(false, forKey: tutorialStore.scopeKey)
        tutorialStore.step = 0
        tutorialStore.isActive = true
        print("[KIRI TutorialDebug][HomeContainer] DEBUG tutorial completion reset")
    }
    #else
    private func debugLog(_ event: String) {}
    private func applyDebugResetIfRequested() {}
    #endif
}

#Preview("Family") {
    MainTabView(
        userMode: .family,
        familyName: "끼리네 가족",
        familyInviteCode: "KIRI24",
        onFamilyCreated: { _, _ in },
        onLogout: {}
    )
}

#Preview("Browse") {
    MainTabView(
        userMode: .browse,
        familyName: nil,
        familyInviteCode: nil,
        onFamilyCreated: { _, _ in },
        onLogout: {}
    )
}
