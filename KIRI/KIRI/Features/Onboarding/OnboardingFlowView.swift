//
// MARK: - 파일 가이드
// 파일: Features/Onboarding/OnboardingFlowView.swift
// 담당 영역: 기능별 SwiftUI 화면과 상태
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//

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

    let onEnterFamily: (String, String, Int?) -> Void
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
                        onEnterFamily(familyName, createdFamilyCode, nil)
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

    // MARK: - Family Join

    /// 코드 조회 전용 API가 없으므로, 확인 화면은 참여 의사를 명시적으로 받습니다.
    /// 실제 코드 검증과 가족 이름 반환은 사용자가 참여를 누른 뒤 POST에서 수행합니다.
    private func findFamily() {
        guard !isSaving else { return }
        familyOperationError = nil
        joinedFamilyName = "입력한 초대 코드의 가족공간"
        step = .familyJoinConfirm
    }

    private func findInvitedFamily(_ invitation: FamilyInvitation) {
        guard !isSaving else { return }
        enteredFamilyCode = invitation.code
        familyOperationError = nil
        joinedFamilyName = invitation.familyName ?? "입력한 초대 코드의 가족공간"
        step = .familyJoinConfirm
    }

    private func joinFamily() {
        guard !isSaving else { return }
        let code = enteredFamilyCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard code.count == 6, code.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber) }) else {
            familyOperationError = "초대 코드는 영문 대문자와 숫자 6자리여야 해요."
            step = .familyCodeInput
            return
        }
        isSaving = true
        familyOperationError = nil
        step = .familyJoinLoading
        Task { @MainActor in
            do {
                let result = try await AuthService.shared.joinFamily(inviteCode: code)
                AppSessionStore().saveFamily(name: result.familyName, inviteCode: code, familyId: result.familyId)
                onEnterFamily(result.familyName, code, result.familyId)
            } catch {
                familyOperationError = Self.familyJoinMessage(for: error)
                step = .familyCodeInput
            }
            isSaving = false
        }
    }

    private static func familyJoinMessage(for error: Error) -> String {
        guard let apiError = error as? APIError,
              case let .serverError(code, _) = apiError else {
            return "가족공간에 참여하지 못했어요. 잠시 후 다시 시도해 주세요."
        }
        switch code {
        case "FAMILY404_2": return "유효하지 않은 초대 코드예요. 코드를 다시 확인해 주세요."
        case "FAMILY410_1": return "초대 코드가 만료됐어요. 새로운 코드를 받아 주세요."
        case "FAMILY409_2": return "이미 다른 가족공간에 가입되어 있어요."
        default: return "가족공간에 참여하지 못했어요. 다시 시도해 주세요."
        }
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
        onEnterFamily: { _, _, _ in },
        onBrowse: {},
        onCancelInvitation: {},
        onBackToTerms: {}
    )
}
