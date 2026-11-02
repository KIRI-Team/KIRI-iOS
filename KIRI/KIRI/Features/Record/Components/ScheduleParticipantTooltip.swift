//
// MARK: - 파일 가이드
// 파일: Features/Record/Components/ScheduleParticipantTooltip.swift
// 담당 영역: 기능별 SwiftUI 화면과 상태
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//


import SwiftUI

struct ScheduleParticipantTooltip: View {

    private struct Participant: Identifiable {
        let id = UUID()

        let role: String
        let isJoining: Bool
    }

    private let participants: [Participant] = [
        Participant(
            role: "엄마",
            isJoining: true
        ),
        Participant(
            role: "아빠",
            isJoining: true
        ),
        Participant(
            role: "딸",
            isJoining: false
        )
    ]

    var body: some View {
        HStack(spacing: 18) {
            ForEach(participants) { participant in
                participantItem(participant)
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .background(
            KIRIColor.Background.elevated
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
    }

    private func participantItem(
        _ participant: Participant
    ) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        participant.isJoining
                            ? KIRIColor.Primary.default
                            : KIRIColor.Background.secondary
                    )
                    .frame(
                        width: 27,
                        height: 27
                    )

                Image(
                    systemName: participant.isJoining
                        ? "checkmark"
                        : "xmark"
                )
                .font(
                    .system(
                        size: 14,
                        weight: .bold
                    )
                )
                .foregroundStyle(
                    participant.isJoining
                        ? KIRIColor.Text.onGreen
                        : KIRIColor.Icon.disabled
                )
            }

            Text(participant.role)
                .font(KIRITypography.bodyMedium)
                .tracking(-0.64)
                .foregroundStyle(
                    participant.isJoining
                        ? KIRIColor.Text.primary
                        : KIRIColor.Text.disabled
                )
        }
    }
}

#Preview {
    ZStack {
        KIRIColor.Background.base
            .ignoresSafeArea()

        ScheduleParticipantTooltip()
    }
}
