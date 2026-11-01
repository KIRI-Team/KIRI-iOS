import Foundation

struct HomeMockMember: Identifiable {
    let id: String
    let name: String
    let role: String
    var hasAnswered: Bool
    let isMe: Bool
}

/// 서버에서 확인된 가족 구성원만 홈에 표시하기 위한 모델입니다.
struct HomeMember: Identifiable, Equatable {
    let id: String
    let memberId: Int?
    let name: String
    let role: String?
    let hasAnswered: Bool
    let answer: String?
    let isMe: Bool
}

struct HomeMockQuestion {
    let number: Int
    var text: String
    var answer: String?
}

struct HomeMockMission {
    let title: String
    let location: String
    let tags: [String]
    var isComplete: Bool
}

struct HomeMockPlace: Identifiable {
    let id: String
    let title: String
    let location: String
    let rating: Double
    let description: String
    let tags: [String]
    let mockAssetName: String?
    let imageURL: URL?
}

struct HomeMockData {
    var members: [HomeMockMember] = [
        HomeMockMember(id: "me", name: "내 답변", role: "딸", hasAnswered: true, isMe: true),
        HomeMockMember(id: "dad", name: "아빠", role: "아빠", hasAnswered: true, isMe: false),
        HomeMockMember(id: "mom", name: "엄마", role: "엄마", hasAnswered: false, isMe: false),
        HomeMockMember(id: "son", name: "아들", role: "아들", hasAnswered: true, isMe: false)
    ]
    var question = HomeMockQuestion(number: 1, text: "내가 가장 좋아하는 음식은?", answer: "뚝배기불고기")
    // HOME-REC-01의 가족공간 공통 주간 미션을 표현하는 로컬 Mock입니다.
    var weeklyMission: HomeMockMission? = HomeMockMission(
        title: "광장시장에서 시장음식 먹어보기",
        location: "광장시장 · 종로구",
        tags: ["대중교통 편리", "혼잡도 높음"],
        isComplete: false
    )
    var places: [HomeMockPlace] = [
        HomeMockPlace(id: "gyeongbok", title: "경복궁에서 사진찍기", location: "경복궁 종로구", rating: 4.6, description: "대중교통이 편리하고, 부모님이랑 가기 좋아요!", tags: ["문화", "가족 추천"], mockAssetName: "home_gyeongbok", imageURL: nil),
        HomeMockPlace(id: "namsan", title: "남산에서 산책하기", location: "서울 중구", rating: 4.5, description: "가볍게 산책하면서 함께 시간을 보내기 좋아요.", tags: ["산책", "야외"], mockAssetName: "home_namsan", imageURL: nil)
    ]
    var isMissionComplete = false
    var hasSchedule = false
}
