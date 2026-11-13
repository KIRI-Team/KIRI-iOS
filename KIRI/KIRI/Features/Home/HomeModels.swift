import Foundation

/// 서버 응답을 홈 화면에 표시하기 위한 가족 구성원 모델입니다.
struct HomeMember: Identifiable, Equatable {
    let id: String
    let memberId: Int?
    let name: String
    let role: String?
    let hasAnswered: Bool
    let answer: String?
    let isMe: Bool
}
