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
    @State private var familyOperationError: String?
    @State private var isSaving = false

    let invitation: FamilyInvitation?

    let onEnterFamily: (String, String) -> Void
    let onBrowse: () -> Void
    let onCancelInvitation: () -> Void
    let onBackToTerms: () -> Void

    var body: some View {
        ZStack {
            KIRIColor.background
                .ignoresSafeArea()

            switch step {
            case .nickname:
                NicknameView(
                    nickname: $nickname,
                    onBack: onBackToTerms,
                    onNext: { saveNickname() }
                )

            case .role:
                RoleSelectionView(
                    nickname: nickname,
                    selectedRole: $selectedRole,
                    onBack: {
                        step = .nickname
                    },
                    onNext: { saveRole() }
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
                        onEnterFamily(familyName, createdFamilyCode)
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
        .onAppear {
            #if DEBUG
            print(
                "[KIRI][Onboarding] entered: "
                    + "invitation=\(invitation != nil), step=\(Self.stepName(step))"
            )
            #endif
        }
        .onChange(of: step) { oldStep, newStep in
            #if DEBUG
            print(
                "[KIRI][Onboarding] step changed: "
                    + "\(Self.stepName(oldStep)) -> \(Self.stepName(newStep))"
            )
            #endif
        }
        .alert("저장할 수 없어요", isPresented: Binding(
            get: { familyOperationError != nil },
            set: { if !$0 { familyOperationError = nil } }
        )) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(familyOperationError ?? "잠시 후 다시 시도해주세요.")
        }
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

    private func saveNickname() {
        guard !isSaving else { return }
        isSaving = true
        Task { @MainActor in
            do {
                let result = try await AuthService.shared.updateNickname(nickname)
                AppSessionStore().saveNickname(result.nickname)
                step = .role
            } catch {
                familyOperationError = error.localizedDescription
            }
            isSaving = false
        }
    }

    private func saveRole() {
        guard !isSaving, let selectedRole else { return }
        isSaving = true
        Task { @MainActor in
            do {
                let result = try await AuthService.shared.updateFamilyRole(selectedRole.apiValue)
                AppSessionStore().saveFamilyRole(result.familyRole)
                handleRoleSelectionCompleted()
            } catch {
                familyOperationError = error.localizedDescription
            }
            isSaving = false
        }
    }

    // MARK: - Family Creation

    private func createFamily() {
        step = .familyCodeLoading
        Task { @MainActor in
            do {
                let result = try await AuthService.shared.createFamily(name: familyName)
                createdFamilyCode = result.inviteCode
                AppSessionStore().saveFamily(
                    name: result.name,
                    inviteCode: result.inviteCode,
                    familyId: result.familyId
                )
                step = .familyCode
            } catch {
                familyOperationError = error.localizedDescription
                step = .familyName
            }
        }
    }

    // MARK: - Mock Manual Family Search

    private func findFamily() {
        familyOperationError = "가족 초대코드 조회 API가 현재 서버 명세에 없어 참여를 완료할 수 없습니다."
    }

    // MARK: - Mock Invitation Family Search

    private func findInvitedFamily(
        _ invitation: FamilyInvitation
    ) {
        familyOperationError = "초대 링크 검증 및 가족공간 참여 API가 현재 서버 명세에 없어 참여를 완료할 수 없습니다."
    }

    // MARK: - Family Join

    private func joinFamily() {
        familyOperationError = "가족공간 참여 API가 현재 서버 명세에 없어 참여를 완료할 수 없습니다."
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

    #if DEBUG
    private static func stepName(_ step: Step) -> String {
        switch step {
        case .nickname: return "nickname"
        case .role: return "role"
        case .familyEntry: return "familyEntry"
        case .familyName: return "familyName"
        case .familyCodeLoading: return "familyCodeLoading"
        case .familyCode: return "familyCode"
        case .familyCodeInput: return "familyCodeInput"
        case .familyJoinLoading: return "familyJoinLoading"
        case .familyJoinConfirm: return "familyJoinConfirm"
        }
    }
    #endif
}

#Preview {
    OnboardingFlowView(
        invitation: nil,
        onEnterFamily: { _, _ in },
        onBrowse: {},
        onCancelInvitation: {},
        onBackToTerms: {}
    )
}
