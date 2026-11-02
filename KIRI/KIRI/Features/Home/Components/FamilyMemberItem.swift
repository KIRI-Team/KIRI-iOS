import SwiftUI

struct FamilyMemberItem: View {
    let name: String
    let role: String?
    let isMe: Bool
    let hasAnswered: Bool

    init(name: String, role: String? = nil, isMe: Bool, hasAnswered: Bool) {
        self.name = name
        self.role = role
        self.isMe = isMe
        self.hasAnswered = hasAnswered
    }

    private var imageName: String {
        switch role?.uppercased() {
        case "MOTHER", "엄마": return "role_mom"
        case "FATHER", "아빠": return "role_dad"
        case "SON", "아들": return "role_son"
        case "DAUGHTER", "딸": return "role_daughter"
        default: return isMe ? "family-me" : "family-member"
        }
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
                    .opacity(hasAnswered ? 1 : 0.45)
            }

            Text(name)
                .font(KIRITypography.bodyMedium)
                .foregroundStyle(KIRIColor.textPrimary)
                .lineLimit(1)
        }
    }

    private var borderColor: Color {
        return hasAnswered
            ? KIRIColor.Text.accent
            : Color.white.opacity(0.25)
    }
}

#Preview {
    HStack(spacing: 18) {
        FamilyMemberItem(
            name: "내 답변",
            role: "딸",
            isMe: true,
            hasAnswered: true
        )

        FamilyMemberItem(
            name: "엄마",
            role: "엄마",
            isMe: false,
            hasAnswered: true
        )

        FamilyMemberItem(
            name: "엄마",
            role: "엄마",
            isMe: false,
            hasAnswered: false
        )
    }
    .padding()
    .background(KIRIColor.background)
}
