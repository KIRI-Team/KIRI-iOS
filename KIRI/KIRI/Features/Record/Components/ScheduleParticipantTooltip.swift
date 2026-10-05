
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
