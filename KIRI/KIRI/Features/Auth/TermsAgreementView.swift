import SwiftUI

struct TermsAgreementView: View {
    @State private var agreementsByID: [Int: Bool]
    @State private var selectedTerm: Term?

    let onBack: () -> Void
    let onComplete: ([TermAgreement]) -> Void
    let terms: [Term]
    let onRetry: () -> Void

    init(
        onBack: @escaping () -> Void,
        onComplete: @escaping ([TermAgreement]) -> Void,
        terms: [Term],
        initialAgreements: [TermAgreement] = [],
        onRetry: @escaping () -> Void = {}
    ) {
        self.onBack = onBack
        self.onComplete = onComplete
        self.terms = terms
        self.onRetry = onRetry
        _agreementsByID = State(initialValue: Dictionary(
            uniqueKeysWithValues: initialAgreements.map { ($0.termId, $0.isAgreed) }
        ))
    }

    private var allAgreed: Bool {
        !terms.isEmpty && terms.allSatisfy { isAgreed(for: $0) }
    }

    private var requiredAgreed: Bool {
        terms.filter(\.isRequired).allSatisfy { isAgreed(for: $0) }
    }

    var body: some View {
        ZStack {
            KIRIColor.Background.base
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                VStack(
                    alignment: .leading,
                    spacing: 0
                ) {
                    titleSection

                    if terms.isEmpty {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("약관 정보를 불러오지 못했습니다.")
                                .font(KIRITypography.bodyMedium)
                                .foregroundStyle(KIRIColor.Text.secondary)
                            Text("잠시 후 다시 로그인해 주세요.")
                                .font(KIRITypography.caption)
                                .foregroundStyle(KIRIColor.Text.tertiary)
                            Button("다시 시도", action: onRetry)
                                .foregroundStyle(KIRIColor.Text.accent)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 72)
                    } else {
                        agreementSection
                            .padding(.top, 72)
                    }

                    Spacer()

                    continueButton
                }
                .padding(
                    .horizontal,
                    KIRISpacing.horizontal
                )
                .padding(.bottom, 10)
            }
        }
        .onAppear {
            #if DEBUG
            print("[KIRI][Terms] view received count=\(terms.count)")
            #endif
        }
        .sheet(item: $selectedTerm) { term in
            SharedTermDetailView(term: term)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            KIRIBackButton(action: onBack)

            Spacer()
        }
        .padding(
            .horizontal,
            KIRISpacing.xSmall
        )
        .frame(height: 56)
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            Text("서비스 이용을 위해\n동의가 필요해요")
                .font(KIRITypography.titleBold)
                .foregroundStyle(
                    KIRIColor.Text.strong
                )
                .tracking(-0.8)
                .lineSpacing(8)

            Text("필수 내용을 확인한 뒤 계속할 수 있어요")
                .font(KIRITypography.subtitle)
                .foregroundStyle(
                    KIRIColor.Text.secondary
                )
        }
    }

    // MARK: - Agreements

    private var agreementSection: some View {
        VStack(spacing: 10) {
            allAgreementButton

            ForEach(terms) { term in
                let requirement = term.isRequired ? "필수" : "선택"
                TermAgreementRow(
                    title: "[\(requirement)] \(term.title)",
                    isChecked: isAgreed(for: term),
                    onCheck: { agreementsByID[term.termId] = !isAgreed(for: term) },
                    onDetail: { selectedTerm = term }
                )
            }
        }
    }

    // MARK: - All Agreement

    private var allAgreementButton: some View {
        Button {
            let newValue = !allAgreed

            for term in terms { agreementsByID[term.termId] = newValue }
        } label: {
            HStack(spacing: 8) {
                AgreementCheckbox(
                    isChecked: allAgreed
                )

                Text("전체동의")
                    .font(KIRITypography.bodyMedium)
                    .foregroundStyle(
                        KIRIColor.Text.strong
                    )

                Spacer()

                Image(systemName: "chevron.right")
                    .font(
                        .system(
                            size: 15,
                            weight: .regular
                        )
                    )
                    .foregroundStyle(KIRIColor.Icon.secondary)
                    .frame(width: 24, height: 44)
            }
            .padding(
                .horizontal,
                KIRISpacing.xLarge
            )
            .frame(height: 56)
            .background(
                KIRIColor.Card.backgroundPressed
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: KIRIRadius.small
                )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("약관 전체 동의")
        .accessibilityValue(
            allAgreed ? "동의됨" : "동의 안 됨"
        )
    }

    // MARK: - Continue

    private var continueButton: some View {
        KIRIPrimaryButton(
            title: "동의하고 계속하기",
            isEnabled: !terms.isEmpty && requiredAgreed,
            action: {
                onComplete(terms.compactMap { term in
                    TermAgreement(termId: term.termId, isAgreed: isAgreed(for: term))
                })
            }
        )
    }

    private func isAgreed(for term: Term) -> Bool {
        agreementsByID[term.termId] ?? false
    }
}

// MARK: - Agreement Row

private struct TermAgreementRow: View {
    let title: String
    let isChecked: Bool

    let onCheck: () -> Void
    let onDetail: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onCheck) {
                AgreementCheckbox(
                    isChecked: isChecked
                )
            }
            .buttonStyle(.plain)

            Button(action: onCheck) {
                Text(title)
                    .font(KIRITypography.subtitle)
                    .foregroundStyle(
                        KIRIColor.Text.primary
                    )
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
            }
            .buttonStyle(.plain)

            Button(action: onDetail) {
                Image(systemName: "chevron.right")
                    .font(
                        .system(
                            size: 15,
                            weight: .regular
                        )
                    )
                    .foregroundStyle(
                        KIRIColor.Icon.secondary
                    )
                    .frame(
                        width: 30,
                        height: 44
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(title) 상세보기")
        }
        .padding(
            .horizontal,
            KIRISpacing.xLarge
        )
        .frame(height: 56)
        .background(
            KIRIColor.Card.backgroundDefault
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: KIRIRadius.small
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: KIRIRadius.small
            )
            .stroke(
                isChecked
                ? KIRIColor.Card.borderSelected
                : KIRIColor.Card.borderDefault,
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
            Circle()
                .fill(
                    isChecked
                    ? KIRIColor.Icon.primary
                    : KIRIColor.Background.transparent
                )
                .frame(width: 24, height: 24)

            Circle()
                .stroke(
                    isChecked
                    ? KIRIColor.Icon.primary
                    : KIRIColor.Border.default,
                    lineWidth: 1
                )
                .frame(width: 24, height: 24)

            if isChecked {
                Image(systemName: "checkmark")
                    .font(
                        .system(
                            size: 11,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(KIRIColor.Icon.onGreen)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TermsAgreementView(
        onBack: {},
        onComplete: { _ in },
        terms: []
    )
}
