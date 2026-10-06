
import SwiftUI

struct InvitationView: View {

    let invitation: RecordBucketListView.InvitationData

    let onBack: () -> Void
    let onCancel: () -> Void
    let onSendInApp: () -> Void
    let onSendKakao: () -> Void

    @State private var isSendMethodVisible = false

    var body: some View {
        ZStack {
            KIRIColor.Background.base
                .ignoresSafeArea()

            VStack(spacing: 0) {
                navigationBar

                ScrollView(
                    .vertical,
                    showsIndicators: false
                ) {
                    content
                }
            }

            if isSendMethodVisible {
                InvitationSendMethodSheet(
                    onClose: {
                        closeSendMethod()
                    },
                    onSendInApp: {
                        isSendMethodVisible = false
                        onSendInApp()
                    },
                    onSendKakao: {
                        isSendMethodVisible = false
                        onSendKakao()
                    }
                )
                .zIndex(20)
            }
        }
    }

    // MARK: - Navigation

    private var navigationBar: some View {
        ZStack {
            Text("초대장")
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

    private var content: some View {
        VStack(spacing: 0) {
            Text("내가 저장한 미션이에요!")
                .font(KIRITypography.bodyMedium)
                .tracking(-0.64)
                .foregroundStyle(KIRIColor.Text.primary)
                .frame(
                    maxWidth: .infinity,
                    alignment: .center
                )

            activityCard
                .padding(.horizontal, 35)
                .padding(.top, 35)

            detailButton
                .padding(.horizontal, 36)
                .padding(.top, 16)

            descriptionSection
                .padding(.horizontal, 36)
                .padding(.top, 26)

            familyMessageSection
                .padding(.horizontal, 35)
                .padding(.top, 30)

            Spacer()
                .frame(height: 42)

            bottomButtons
                .padding(.horizontal, 18)

            Color.clear
                .frame(height: 34)
        }
        .padding(.top, 8)
    }

    // MARK: - Activity Card

    private var activityCard: some View {
        VStack(
            alignment: .leading,
            spacing: 0
        ) {
            Text("활동명")
                .font(KIRITypography.captionMedium)
                .tracking(-0.48)
                .foregroundStyle(KIRIColor.Text.tertiary)

            Text(invitation.title)
                .font(KIRITypography.headingLarge)
                .tracking(-0.96)
                .foregroundStyle(KIRIColor.Text.strong)
                .padding(.top, 8)

            Spacer(minLength: 16)

            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.system(size: 15))
                    .foregroundStyle(
                        KIRIColor.Icon.secondary
                    )
                    .frame(
                        width: 18,
                        height: 18
                    )

                Text(invitation.dateTime)
                    .font(KIRITypography.bodySmall)
                    .tracking(-0.56)
                    .foregroundStyle(
                        KIRIColor.Text.secondary
                    )
            }

            HStack(spacing: 8) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(
                        KIRIColor.Icon.secondary
                    )
                    .frame(
                        width: 18,
                        height: 18
                    )

                Text(invitation.participants)
                    .font(KIRITypography.bodySmall)
                    .tracking(-0.56)
                    .foregroundStyle(
                        KIRIColor.Text.secondary
                    )
            }
            .padding(.top, 10)
        }
        .padding(
            EdgeInsets(
                top: 20,
                leading: 20,
                bottom: 20,
                trailing: 20
            )
        )
        .frame(
            maxWidth: .infinity,
            minHeight: 167,
            alignment: .leading
        )
        .background(KIRIColor.Background.secondary)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
    }

    // MARK: - Detail Button

    private var detailButton: some View {
        Button {
            // TODO: 활동 상세 화면 연결
        } label: {
            Text("자세히 보러가기")
                .font(KIRITypography.bodyMedium)
                .tracking(-0.64)
                .foregroundStyle(KIRIColor.Text.primary)
                .frame(
                    maxWidth: .infinity
                )
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
            spacing: 12
        ) {
            Text("행사설명")
                .font(KIRITypography.headingSmall)
                .tracking(-0.72)
                .foregroundStyle(
                    KIRIColor.Text.tertiary
                )

            Text(invitation.description)
                .font(KIRITypography.body)
                .tracking(-0.64)
                .foregroundStyle(
                    KIRIColor.Text.primary
                )
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
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
                    KIRIColor.Text.accent
                )

            Text(invitation.familyMessage)
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
                    .foregroundStyle(
                        KIRIColor.Text.primary
                    )
                    .frame(
                        maxWidth: .infinity
                    )
                    .frame(height: 54)
                    .background(
                        KIRIColor.Background.secondary
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 8
                        )
                    )
            }
            .buttonStyle(.plain)

            Button {
                openSendMethod()
            } label: {
                Text("요청 보내기")
                    .font(KIRITypography.button)
                    .tracking(-0.64)
                    .foregroundStyle(
                        KIRIColor.Text.onGreen
                    )
                    .frame(
                        maxWidth: .infinity
                    )
                    .frame(height: 54)
                    .background(
                        KIRIColor.Primary.default
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 8
                        )
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Actions

    private func openSendMethod() {
        withAnimation(
            .easeOut(duration: 0.2)
        ) {
            isSendMethodVisible = true
        }
    }

    private func closeSendMethod() {
        withAnimation(
            .easeOut(duration: 0.2)
        ) {
            isSendMethodVisible = false
        }
    }
}

#Preview {
    InvitationView(
        invitation: RecordBucketListView.InvitationData(
            title: "한강 뚜벅뚜벅 축제",
            dateTime: "26.10.07·16:30분",
            participants: "엄마, 아빠, 나",
            description: """
            2026 한강 뚜벅뚜벅 축제는 잠수교를 보행교로 전환해 시민이 직접 걸으며 공연·체험·미식 등 다양한 문화·여가 프로그램을 즐기는 서울 대표 한강 축제입니다.
            """,
            familyMessage: "엄마, 아빠 나 여기 가고싶은데 우리 10월 초에 갈래요??"
        ),
        onBack: {},
        onCancel: {},
        onSendInApp: {},
        onSendKakao: {}
    )
}
