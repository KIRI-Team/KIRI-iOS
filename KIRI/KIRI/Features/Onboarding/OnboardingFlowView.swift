import SwiftUI

struct OnboardingFlowView: View {
    enum Step {
        case nickname
        case role
        case familyEntry

        // 가족공간 생성
        case familyName
        case familyCodeLoading
        case familyCode

        // 기존 가족공간 참여
        case familyCodeInput
        case familyJoinLoading
        case familyJoinConfirm
    }
        // 입력 허용, 밑에 유효성 검사 빨간 글씨 사용하기
    @State private var step: Step = .nickname
    @State private var nickname: String = ""
    @State private var selectedRole: FamilyRole?
    @State private var familyName: String = ""

    @State private var createdFamilyCode: String = ""
    @State private var enteredFamilyCode: String = ""
    @State private var joinedFamilyName: String = ""

    let invitation: FamilyInvitation?

    let onEnterFamily: () -> Void
    let onBrowse: () -> Void
    let onCancelInvitation: () -> Void

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
                        handleRoleSelectionCompleted()
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
                        enteredFamilyCode = ""
                        step = .familyCodeInput
                    },
                    onBrowse: {
                        onBrowse()
                    }
                )

            // MARK: - 가족공간 생성

            case .familyName:
                FamilyNameView(
                    familyName: $familyName,
                    onBack: {
                        step = .familyEntry
                    },
                    onNext: {
                        createFamily()
                    }
                )

            case .familyCodeLoading:
                FamilyCodeLoadingView()

            case .familyCode:
                FamilyCodeView(
                    familyName: familyName,
                    familyCode: createdFamilyCode,
                    onBack: {
                        step = .familyName
                    },
                    onComplete: {
                        onEnterFamily()
                    }
                )

            // MARK: - 가족공간 참여

            case .familyCodeInput:
                FamilyCodeInputView(
                    familyCode: $enteredFamilyCode,
                    onBack: {
                        step = .familyEntry
                    },
                    onNext: {
                        findFamily()
                    }
                )

            case .familyJoinLoading:
                FamilyJoinLoadingView()

            case .familyJoinConfirm:
                FamilyJoinConfirmView(
                    familyName: joinedFamilyName,
                    familyCode: enteredFamilyCode,
                    onBack: {
                        handleJoinConfirmBack()
                    },
                    onJoin: {
                        joinFamily()
                    }
                )
            }
        }
        .animation(.easeInOut(duration: 0.2), value: step)
    }

    // MARK: - Role Completion

    private func handleRoleSelectionCompleted() {
        guard let invitation else {
            step = .familyEntry
            return
        }

        enteredFamilyCode = invitation.code
        findInvitedFamily(invitation)
    }

    // MARK: - Mock Family Creation

    private func createFamily() {
        step = .familyCodeLoading

        // TODO: 가족공간 생성 API 연결 후 제거
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            createdFamilyCode = "KIRI24"
            step = .familyCode
        }
    }

    // MARK: - Mock Manual Family Search

    private func findFamily() {
        step = .familyJoinLoading

        // TODO: 가족코드 조회 API 연결 후 제거
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            joinedFamilyName = "끼리가족"
            step = .familyJoinConfirm
        }
    }

    // MARK: - Mock Invitation Family Search

    private func findInvitedFamily(
        _ invitation: FamilyInvitation
    ) {
        step = .familyJoinLoading

        // TODO: 초대정보 검증 및 가족공간 조회 API 연결
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            joinedFamilyName =
                invitation.familyName ?? "끼리가족"

            step = .familyJoinConfirm
        }
    }

    // MARK: - Family Join

    private func joinFamily() {
        // TODO: 가족공간 참여 API 연결
        onEnterFamily()
    }

    private func handleJoinConfirmBack() {
        if invitation != nil {
            onCancelInvitation()
            enteredFamilyCode = ""
            joinedFamilyName = ""
            step = .familyEntry
        } else {
            step = .familyCodeInput
        }
    }
}

#Preview {
    OnboardingFlowView(
        invitation: nil,
        onEnterFamily: {},
        onBrowse: {},
        onCancelInvitation: {}
    )
}
