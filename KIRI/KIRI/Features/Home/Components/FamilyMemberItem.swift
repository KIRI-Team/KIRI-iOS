import SwiftUI

struct FamilyMemberItem: View {
    let name: String
    let isMe: Bool
    let hasAnswered: Bool

    private var imageName: String {
        isMe
            ? "family-me"
            : "family-member"
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(
                        borderColor,
                        lineWidth: 1
                    )
                    .frame(width: 44, height: 44)

                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            }

            Text(name)
                .font(KIRITypography.bodyMedium)
                .foregroundStyle(KIRIColor.textPrimary)
                .lineLimit(1)
        }
    }

    private var borderColor: Color {
        if isMe {
            return Color.white.opacity(0.55)
        }

        return hasAnswered
            ? Color.green
            : Color.white.opacity(0.25)
    }
}

#Preview {
    HStack(spacing: 18) {
        FamilyMemberItem(
            name: "내 답변",
            isMe: true,
            hasAnswered: true
        )

        FamilyMemberItem(
            name: "엄마",
            isMe: false,
            hasAnswered: true
        )

        FamilyMemberItem(
            name: "엄마",
            isMe: false,
            hasAnswered: false
        )
    }
    .padding()
    .background(KIRIColor.background)
}
