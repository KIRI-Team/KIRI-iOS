import SwiftUI

struct OnboardingFlowView: View {
    enum Step {
        case nickname
        case role
        case familyEntry

        case familyName
        case familyCodeLoading
        case familyCode
    }

    @State private var step: Step = .nickname

    @State private var nickname: String = ""
    @State private var selectedRole: FamilyRole?
    @State private var familyName: String = ""

    @State private var familyCode: String = ""
    @State private var isInviteSheetPresented = false

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
                        step = .familyName
                    },
                    onEnterFamilyCode: {
                        // 다음 단계에서 구현
                    },
                    onBrowse: onBrowse
                )

            case .familyName:
                FamilyNameView(
                    familyName: $familyName,
                    onBack: {
                        step = .familyEntry
                    },
                    onNext: {
                        createFamilyCode()
                    }
                )

            case .familyCodeLoading:
                FamilyCodeLoadingView()

            case .familyCode:
                FamilyCodeView(
                    familyName: familyName,
                    familyCode: familyCode,
                    onBack: {
                        step = .familyName
                    },
                    onInvite: {
                        isInviteSheetPresented = true
                    },
                    onComplete: onBrowse
                )
            }
        }
        .animation(.easeInOut(duration: 0.2), value: step)
        .sheet(isPresented: $isInviteSheetPresented) {
            FamilyInviteSheet(
                familyName: familyName,
                familyCode: familyCode,
                onComplete: {
                    isInviteSheetPresented = false
                    onBrowse()
                }
            )
        }
    }

    private func createFamilyCode() {
        step = .familyCodeLoading

        // TODO: 가족공간 생성 API 연결 후 제거
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            familyCode = "KIRI24"
            step = .familyCode
        }
    }
}

#Preview {
    OnboardingFlowView {}
}
