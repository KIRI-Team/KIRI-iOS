
import SwiftUI

struct OnboardingFlowView: View {
    enum Step {
        case nickname
        case role
        case familyEntry
    }

    @State private var step: Step = .nickname
    @State private var nickname: String = ""
    @State private var selectedRole: FamilyRole?

    let onBrowse: () -> Void

    var body: some View {
        ZStack {
            KIRIColor.background
                .ignoresSafeArea()

            switch step {
            case .nickname:
                NicknameView(
                    nickname: $nickname,
                    onBack: {},
                    onNext: {
                        step = .role
                    }
                )

            case .role:
                RoleSelectionView(
                    nickname: nickname,
                    selectedRole: $selectedRole,
                    onBack: {
                        step = .nickname
                    },
                    onNext: {
                        step = .familyEntry
                    }
                )

            case .familyEntry:
                FamilyEntryView(
                    onBack: {
                        step = .role
                    },
                    onCreateFamily: {
                        // 다음 단계에서 구현
                    },
                    onEnterFamilyCode: {
                        // 다음 단계에서 구현
                    },
                    onBrowse: onBrowse
                )
            }
        }
        .animation(.easeInOut(duration: 0.2), value: step)
    }
}

#Preview {
    OnboardingFlowView {}
}
