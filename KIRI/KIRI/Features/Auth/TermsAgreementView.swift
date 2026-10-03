import SwiftUI

struct TermsAgreementView: View {
    @State private var serviceTermsAgreed = false
    @State private var privacyCollectionAgreed = false
    @State private var privacyPolicyConfirmed = false
    @State private var locationAgreed = false

    @State private var selectedTerm: TermType?

    let onBack: () -> Void
    let onComplete: () -> Void

    // MARK: - Agreement State

    private var allAgreed: Bool {
        serviceTermsAgreed &&
        privacyCollectionAgreed &&
        privacyPolicyConfirmed &&
        locationAgreed
    }

    private var requiredAgreed: Bool {
        serviceTermsAgreed &&
        privacyCollectionAgreed &&
        privacyPolicyConfirmed
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            header

            VStack(alignment: .leading, spacing: 0) {
                titleSection

                agreementSection
                    .padding(.top, 82)

                Spacer()

                continueButton
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 10)
        }
        .background(KIRIColor.background)
        .sheet(item: $selectedTerm) { term in
            TermDetailView(term: term)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            KIRIBackButton(action: onBack)

            Spacer()
        }
        .padding(.horizontal, 4)
        .frame(height: 56)
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("서비스 이용을 위해\n동의가 필요해요")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(KIRIColor.textPrimary)
                .tracking(-0.8)
                .lineSpacing(8)

            Text("필수 내용을 확인한 뒤 계속할 수 있어요")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(KIRIColor.textSecondary)
        }
    }

    // MARK: - Agreement Section

    private var agreementSection: some View {
        VStack(spacing: 10) {
            allAgreementButton

            TermAgreementRow(
                title: "[필수] 서비스 이용약관",
                isChecked: serviceTermsAgreed,
                onCheck: {
                    serviceTermsAgreed.toggle()
                },
                onDetail: {
                    selectedTerm = .service
                }
            )

            TermAgreementRow(
                title: "[필수] 개인정보 수집·이용 동의",
                isChecked: privacyCollectionAgreed,
                onCheck: {
                    privacyCollectionAgreed.toggle()
                },
                onDetail: {
                    selectedTerm = .privacyCollection
                }
            )

            TermAgreementRow(
                title: "[필수] 개인정보 처리방침 확인",
                isChecked: privacyPolicyConfirmed,
                onCheck: {
                    privacyPolicyConfirmed.toggle()
                },
                onDetail: {
                    selectedTerm = .privacyPolicy
                }
            )

            TermAgreementRow(
                title: "[선택] 위치정보 이용 동의",
                isChecked: locationAgreed,
                onCheck: {
                    locationAgreed.toggle()
                },
                onDetail: {
                    selectedTerm = .location
                }
            )
        }
    }

    // MARK: - All Agreement

    private var allAgreementButton: some View {
        Button {
            let newValue = !allAgreed

            serviceTermsAgreed = newValue
            privacyCollectionAgreed = newValue
            privacyPolicyConfirmed = newValue
            locationAgreed = newValue
        } label: {
            HStack(spacing: 14) {
                AgreementCheckbox(
                    isChecked: allAgreed
                )

                Text("전체동의")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(KIRIColor.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(
                        KIRIColor.textSecondary.opacity(0.35)
                    )
            }
            .padding(.horizontal, 28)
            .frame(height: 57)
            .background(
                Color.white.opacity(0.08)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 8
                )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button(action: onComplete) {
            Text("동의하고 계속하기")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(
                    requiredAgreed
                        ? Color.black
                        : KIRIColor.textSecondary
                )
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    requiredAgreed
                        ? Color.white
                        : KIRIColor.surface
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 8
                    )
                )
        }
        .buttonStyle(.plain)
        .disabled(!requiredAgreed)
    }
}

// MARK: - Agreement Row

private struct TermAgreementRow: View {
    let title: String
    let isChecked: Bool

    let onCheck: () -> Void
    let onDetail: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onCheck) {
                AgreementCheckbox(
                    isChecked: isChecked
                )
            }
            .buttonStyle(.plain)

            Button(action: onCheck) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(KIRIColor.textPrimary)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
            }
            .buttonStyle(.plain)

            Button(action: onDetail) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 15))
                    .foregroundStyle(
                        KIRIColor.textSecondary.opacity(0.4)
                    )
                    .frame(
                        width: 30,
                        height: 44
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 28)
        .frame(height: 57)
        .overlay {
            RoundedRectangle(
                cornerRadius: 8
            )
            .stroke(
                Color.white.opacity(0.14),
                lineWidth: 1
            )
        }
    }
}

// MARK: - Checkbox

private struct AgreementCheckbox: View {
    let isChecked: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(
                cornerRadius: 4
            )
            .stroke(
                isChecked
                    ? Color.white
                    : Color.white.opacity(0.12),
                lineWidth: 1
            )
            .frame(
                width: 20,
                height: 20
            )

            if isChecked {
                RoundedRectangle(
                    cornerRadius: 4
                )
                .fill(Color.white)
                .frame(
                    width: 20,
                    height: 20
                )

                Image(systemName: "checkmark")
                    .font(
                        .system(
                            size: 11,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(Color.black)
            }
        }
    }
}

// MARK: - Terms

private enum TermType: String, Identifiable {
    case service
    case privacyCollection
    case privacyPolicy
    case location

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .service:
            return "서비스 이용약관"

        case .privacyCollection:
            return "개인정보 수집·이용 동의"

        case .privacyPolicy:
            return "개인정보 처리방침"

        case .location:
            return "위치정보 이용 동의"
        }
    }

    var content: String {
        switch self {
        case .service:
            return """
            KIRI 서비스 이용약관

            KIRI는 가족 구성원이 서로의 취향과 일상을 알아가고 함께 활동할 수 있도록 가족공간, 질문, 미션, 장소 탐색, 버킷, 일정 및 활동 기록 등의 기능을 제공합니다.

            이용자는 자신의 정보를 정확하게 제공해야 하며 다른 사람의 정보를 도용하거나 허위 정보를 입력해서는 안 됩니다.

            가족공간에서는 닉네임, 가족 내 역할, 질문 답변, 미션 수행 내역, 일정 및 활동 기록 등 서비스 이용에 필요한 일부 정보가 다른 가족 구성원에게 공개될 수 있습니다.

            이용자가 등록한 사진 및 기록의 권리는 원칙적으로 해당 이용자에게 있으며, KIRI는 서비스 제공에 필요한 범위에서 이를 처리합니다.

            KIRI는 서비스 개선 및 운영상 필요한 경우 서비스의 일부 내용을 변경할 수 있습니다.
            """

        case .privacyCollection:
            return """
            개인정보 수집·이용 동의

            KIRI는 회원 식별 및 서비스 제공을 위해 필요한 개인정보를 수집·이용합니다.

            수집 항목

            • 소셜 로그인 식별정보
            • 이메일 주소 등 소셜 로그인 제공 정보
            • 닉네임
            • 가족 내 역할
            • 가족명 및 가족공간 정보
            • 질문 답변
            • 미션 참여 및 수행 정보
            • 버킷 및 일정
            • 활동 기록 및 사진
            • 장소 저장 및 선택 정보
            • 서비스 이용 기록

            이용 목적

            • 회원 및 계정 관리
            • 가족공간 생성 및 가족 구성원 연결
            • 질문, 미션, 일정 및 기록 기능 제공
            • 이용자 취향 및 활동 데이터 분석
            • 가족 단위 취향 및 활동 성향 분석
            • 장소, 미션 및 콘텐츠 추천

            개인정보는 원칙적으로 회원 탈퇴 시까지 이용하며 관련 법령에 따라 별도의 보존 의무가 있는 경우 해당 기간 동안 보관할 수 있습니다.
            """

        case .privacyPolicy:
            return """
            개인정보 처리방침

            KIRI는 이용자의 개인정보를 중요하게 생각하며 관련 법령에 따라 개인정보를 처리합니다.

            개인정보는 회원가입, 이용자 식별, 가족공간 운영, 질문 및 미션 제공, 일정 및 활동 기록, 취향 분석 및 콘텐츠 추천 등의 목적으로 처리됩니다.

            가족공간 기반 서비스의 특성상 닉네임, 가족 내 역할, 질문 답변, 미션 수행 내용, 일정 및 활동 기록 등은 해당 가족공간의 다른 구성원에게 공개될 수 있습니다.

            개인정보는 원칙적으로 회원 탈퇴 시까지 보유하며 처리 목적이 달성되면 관련 법령에 따라 파기합니다.

            이용자는 관련 법령이 정하는 범위에서 개인정보의 열람, 정정, 삭제 및 처리정지 등을 요청할 수 있습니다.
            """

        case .location:
            return """
            위치정보 이용 동의

            KIRI는 주변 장소 탐색 및 활동 추천을 위해 이용자가 허용한 기기의 위치정보를 이용할 수 있습니다.

            이용 목적

            • 이용자 주변 장소 및 활동 탐색
            • 현재 위치 기준 거리 정보 제공
            • 지역 및 거리 기반 장소·미션 추천

            위치정보 이용 동의는 선택사항입니다.

            위치정보 이용에 동의하지 않더라도 KIRI의 기본 서비스는 이용할 수 있으나 주변 장소 탐색이나 거리 기반 추천 등의 일부 기능이 제한될 수 있습니다.

            이용자는 기기의 운영체제 설정에서 언제든지 위치 접근 권한을 변경할 수 있습니다.
            """
        }
    }
}

// MARK: - Term Detail

private struct TermDetailView: View {
    @Environment(\.dismiss)
    private var dismiss

    let term: TermType

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(term.content)
                    .font(.system(size: 15))
                    .foregroundStyle(KIRIColor.textPrimary)
                    .lineSpacing(6)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding(20)
            }
            .background(
                KIRIColor.background
                    .ignoresSafeArea()
            )
            .navigationTitle(term.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(
                    placement: .topBarTrailing
                ) {
                    Button("닫기") {
                        dismiss()
                    }
                    .foregroundStyle(Color.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview

#Preview {
    TermsAgreementView(
        onBack: {},
        onComplete: {}
    )
}
