//
// MARK: - 파일 가이드
// 파일: Features/Home/Components/FamilyMemberItem.swift
// 담당 영역: 기능별 SwiftUI 화면과 상태
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//

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
        default: return isMe ? "family-me" : "figma_family_member_default"
        }
    }

    var body: some View {
        // Figma KIRI/Member Avatar Item(8413:5804): 46pt 폭, 아바타 44pt,
        // 내부 배경 40pt, 역할 캐릭터 24pt, 이름과의 간격 2pt를 사용합니다.
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(KIRIColor.Background.secondary)
                    .frame(width: 40, height: 40)

                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .opacity(hasAnswered ? 1 : 0.45)

                Image("figma_family_avatar_ring")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
            }
            .frame(width: 44, height: 44)

            Text(name)
                .font(KIRITypography.bodyMedium)
                .foregroundStyle(KIRIColor.textPrimary)
                .lineLimit(1)
                .frame(width: 46)
        }
        .frame(width: 46)
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
