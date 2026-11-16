//
// MARK: - 파일 가이드
// 파일: Features/Record/Request/InvitationRequestView.swift
// 담당 영역: 기능별 SwiftUI 화면과 상태
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//


import SwiftUI

struct InvitationRequestView: View {

    struct RequestData {
        struct Participant: Identifiable {
            let id: Int
            let nickname: String
            let familyRole: String?
            let status: String
            let characterImageURL: URL?
        }

        let senderRole: String
        let title: String
        let date: String
        let participants: String
        let participantDetails: [Participant]
        let description: String
        let familyMessage: String
    }

    let request: RequestData

    let onBack: () -> Void
    let onCancel: () -> Void
    let onConfirmSchedule: () -> Void
    var onMissionDetail: (() -> Void)? = nil
    var respondsDirectly: Bool = false

    @State private var isAddScheduleSheetVisible = false
    @State private var isDescriptionExpanded = false

    var body: some View {
        ZStack {
            KIRIColor.Background.base
                .ignoresSafeArea()

            VStack(spacing: 0) {
                navigationBar

                acceptanceStatus

                ScrollView(
                    .vertical,
                    showsIndicators: false
                ) {
                    content
                }
                .scrollIndicators(.hidden)
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    bottomButtons
                        .padding(.horizontal, 18)
                        .padding(.top, 10)
                        .padding(.bottom, 8)
                        .background(KIRIColor.Background.base)
                }
            }

            if isAddScheduleSheetVisible {
                AddScheduleSheet(
                    title: request.title,
                    date: request.date,
                    participants: request.participants,
                    onClose: {
                        closeAddScheduleSheet()
                    },
                    onCancel: {
                        closeAddScheduleSheet()
                    },
                    onConfirm: {
                        isAddScheduleSheetVisible = false
                        onConfirmSchedule()
                    }
                )
                .zIndex(20)
            }
        }
    }

    // MARK: - Navigation

    private var navigationBar: some View {
        ZStack {
            Text("요청알림")
                .font(KIRITypography.headingSmall)
                .tracking(-0.72)
                .foregroundStyle(KIRIColor.Text.strong)

            HStack {
                KIRIBackButton(
                    action: onBack
                )

                Spacer()
            }
        }
        .padding(.horizontal, 6)
        .frame(height: 62)
    }

    // MARK: - Content

    private var acceptanceStatus: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("초대 수락 현황")
                .font(KIRITypography.bodyMedium)
                .foregroundStyle(KIRIColor.Text.primary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(request.participantDetails) { participant in
                        VStack(spacing: 5) {
                            participantAvatar(participant)
                                .frame(width: 42, height: 42)
                                .background(KIRIColor.Background.tertiary)
                                .clipShape(Circle())
                            Text(participant.nickname)
                                .font(KIRITypography.captionMedium)
                                .foregroundStyle(KIRIColor.Text.secondary)
                                .lineLimit(1)
                                .frame(maxWidth: 60)
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    private var content: some View {
        VStack(spacing: 0) {
            activityCard
                .padding(.horizontal, 35)
                .padding(.top, 35)

            detailButton
                .padding(.horizontal, 36)
                .padding(.top, 16)

            if !request.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                descriptionSection
                    .padding(.horizontal, 36)
                    .padding(.top, 26)
            }

            if !request.familyMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                familyMessageSection
                    .padding(.horizontal, 35)
                    .padding(.top, 30)
            }

            Color.clear.frame(height: 28)
        }
        .padding(.top, 8)
    }

    // MARK: - Activity Card

    private var activityCard: some View {
        ZStack {
            Image("figma_invitation_envelope")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, minHeight: 189)
                .clipped()

            VStack(
                alignment: .center,
                spacing: 6
            ) {
                Text("활동명")
                .font(KIRITypography.captionMedium)
                .tracking(-0.48)
                .foregroundStyle(KIRIColor.Text.tertiary)

                Text(request.title)
                .font(KIRITypography.headingLarge)
                .tracking(-0.96)
                .foregroundStyle(KIRIColor.Text.strong)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)

            HStack(spacing: 4) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(
                        KIRIColor.Icon.secondary
                    )
                    .frame(
                        width: 18,
                        height: 18
                    )

                Text(request.date)
                    .font(KIRITypography.bodySmall)
                    .tracking(-0.56)
                    .foregroundStyle(
                        KIRIColor.Text.secondary
                    )
            }

            Text(request.participants)
                .font(KIRITypography.bodySmall)
                .tracking(-0.56)
                .foregroundStyle(KIRIColor.Text.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .frame(
            maxWidth: .infinity,
            minHeight: 189
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
    }

    // MARK: - Detail

    private var detailButton: some View {
        Button {
            onMissionDetail?()
        } label: {
            Text("자세히 보러가기")
                .font(KIRITypography.bodyMedium)
                .tracking(-0.64)
                .foregroundStyle(KIRIColor.Text.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 45)
                .background(
                    KIRIColor.Background.tertiary
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 12
                    )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Description

    private var descriptionSection: some View {
        VStack(
            alignment: .leading,
            spacing: 2
        ) {
            Text("행사설명")
                .font(KIRITypography.headingSmall)
                .tracking(-0.72)
                .foregroundStyle(
                    KIRIColor.Text.tertiary
                )

            Text(request.description)
                .font(KIRITypography.body)
                .tracking(-0.64)
                .foregroundStyle(
                    KIRIColor.Text.primary
                )
                .lineLimit(isDescriptionExpanded ? nil : 3)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

            if request.description.count > 120 {
                Button(isDescriptionExpanded ? "접기" : "더 보기") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isDescriptionExpanded.toggle()
                    }
                }
                .font(KIRITypography.captionMedium)
                .foregroundStyle(KIRIColor.Text.accent)
                .padding(.top, 4)
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    // MARK: - Family Message

    private var familyMessageSection: some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            Text("가족에게 한 줄")
                .font(KIRITypography.bodyMedium)
                .tracking(-0.64)
                .foregroundStyle(
                    KIRIColor.Text.primary
                )

            Text(request.familyMessage)
                .font(KIRITypography.bodySmall)
                .tracking(-0.56)
                .foregroundStyle(
                    KIRIColor.Text.secondary
                )
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    // MARK: - Bottom Buttons

    private var bottomButtons: some View {
        HStack(spacing: 8) {
            Button {
                onCancel()
            } label: {
                Text("취소")
                    .font(KIRITypography.button)
                    .tracking(-0.64)
                    .foregroundStyle(KIRIColor.Text.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        KIRIColor.Background.tertiary
                    )
                    .clipShape(
                        Capsule()
                    )
            }
            .buttonStyle(.plain)

            Button {
                if respondsDirectly {
                    onConfirmSchedule()
                } else {
                    openAddScheduleSheet()
                }
            } label: {
                Text("약속 확정하기")
                    .font(KIRITypography.button)
                    .tracking(-0.64)
                    .foregroundStyle(KIRIColor.Text.onGreen)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        KIRIColor.Primary.default
                    )
                    .clipShape(
                        Capsule()
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Actions

    private func openAddScheduleSheet() {
        withAnimation(
            .easeOut(duration: 0.2)
        ) {
            isAddScheduleSheetVisible = true
        }
    }

    private func closeAddScheduleSheet() {
        withAnimation(
            .easeOut(duration: 0.2)
        ) {
            isAddScheduleSheetVisible = false
        }
    }

    @ViewBuilder
    private func participantAvatar(_ participant: RequestData.Participant) -> some View {
        if let asset = roleAssetName(for: participant) {
            Image(asset)
                .resizable()
                .scaledToFit()
        } else if let url = participant.characterImageURL {
            AsyncImage(url: url) { phase in
                if case .success(let image) = phase {
                    image.resizable().scaledToFit()
                } else {
                    Image("figma_family_member_default").resizable().scaledToFit()
                }
            }
            .frame(width: 22, height: 22)
        } else {
            Image("figma_family_member_default")
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
        }
    }

    private func roleAssetName(for participant: RequestData.Participant) -> String? {
        let base: String
        switch participant.familyRole?.uppercased() {
        case "MOTHER": base = "role_mom"
        case "FATHER": base = "role_dad"
        case "SON": base = "role_son"
        case "DAUGHTER": base = "role_daughter"
        default: return nil
        }
        let accepted = ["ACCEPTED", "CONFIRMED", "COMPLETED"].contains(participant.status.uppercased())
        return accepted ? "\(base)_active" : base
    }
}

#Preview {
    InvitationRequestView(
        request: InvitationRequestView.RequestData(
            senderRole: "딸",
            title: "한강 뚜벅뚜벅 축제",
            date: "26.06.23",
            participants: "엄마, 아빠, 나",
            participantDetails: [],
            description: """
            2026 한강 뚜벅뚜벅 축제는 잠수교를 보행교로 전환해 시민이 직접 걸으며 공연·체험·미식 등 다양한 문화·여가 프로그램을 즐기는 서울 대표 한강 축제입니다.
            """,
            familyMessage: "엄마, 아빠 나 여기 가고싶은데 우리 10월 초에 갈래요??"
        ),
        onBack: {},
        onCancel: {},
        onConfirmSchedule: {}
    )
}
