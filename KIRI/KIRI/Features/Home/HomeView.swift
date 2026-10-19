import SwiftUI

@Observable
final class HomeTutorialStore {
    var mode: HomeTutorialView.Mode
    var step: Int = 0
    var isActive: Bool = false

    init(mode: HomeTutorialView.Mode) {
        self.mode = mode
        let key = mode == .browse
            ? "kiri_browse_tutorial_completed"
            : "kiri_family_tutorial_completed"
        isActive = !UserDefaults.standard.bool(forKey: key)
    }
}

struct HomeView: View {
    let userMode: AppRouter.UserMode
    let familyName: String?
    let familyInviteCode: String?
    let tutorialStore: HomeTutorialStore
    let onFamilyCreated: (String, String) -> Void
    let onExploreMission: () -> Void

    @AppStorage("kiri_browse_tutorial_completed") private var browseTutorialCompleted = false
    @AppStorage("kiri_family_tutorial_completed") private var familyTutorialCompleted = false
    @State private var didApplyDebugReset = false
    @State private var tutorialFrames: [HomeTutorialTarget: CGRect] = [:]

    init(
        userMode: AppRouter.UserMode,
        familyName: String?,
        familyInviteCode: String?,
        tutorialStore: HomeTutorialStore,
        onFamilyCreated: @escaping (String, String) -> Void,
        onExploreMission: @escaping () -> Void
    ) {
        self.userMode = userMode
        self.familyName = familyName
        self.familyInviteCode = familyInviteCode
        self.tutorialStore = tutorialStore
        self.onFamilyCreated = onFamilyCreated
        self.onExploreMission = onExploreMission
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
                familyName: familyName ?? "끼리네 가족",
                familyInviteCode: familyInviteCode,
                tutorialStep: tutorialStore.isActive ? tutorialStore.step : nil,
                onExploreMission: onExploreMission
            )

        case .browse:
            if tutorialStore.isActive {
                FamilyHomeView(
                    familyName: "끼리네 가족",
                    familyInviteCode: nil,
                    tutorialStep: tutorialStore.step,
                    onExploreMission: onExploreMission
                )
            } else {
                BrowseHomeView(onFamilyCreated: onFamilyCreated)
            }
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
        let modeChanged = tutorialStore.mode != mode
        tutorialStore.mode = mode

        if modeChanged {
            tutorialStore.step = 0
            tutorialStore.isActive = false
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

        guard !isTutorialCompleted(for: mode) else {
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
        switch tutorialStore.mode {
        case .browse:
            browseTutorialCompleted = true
        case .family:
            familyTutorialCompleted = true
        }
        tutorialStore.isActive = false
        tutorialStore.step = 0
        debugLog("tutorial completed")
    }

    private func isTutorialCompleted(for mode: HomeTutorialView.Mode) -> Bool {
        switch mode {
        case .browse:
            return browseTutorialCompleted
        case .family:
            return familyTutorialCompleted
        }
    }

    #if DEBUG
    private func debugLog(_ event: String) {
        print(
            "[KIRI TutorialDebug][HomeContainer] \(event) " +
            "mode=\(String(describing: tutorialStore.mode)) " +
            "active=\(tutorialStore.isActive) " +
            "step=\(tutorialStore.step) " +
            "browseCompleted=\(browseTutorialCompleted) " +
            "familyCompleted=\(familyTutorialCompleted)"
        )
    }

    private func applyDebugResetIfRequested() {
        guard !didApplyDebugReset else { return }
        didApplyDebugReset = true
        guard ProcessInfo.processInfo.arguments.contains("-reset-kiri-home-tutorial") else { return }
        browseTutorialCompleted = false
        familyTutorialCompleted = false
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
