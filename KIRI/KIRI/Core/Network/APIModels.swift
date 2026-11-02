import Foundation

struct APIEnvelope<Result: Decodable>: Decodable {
    let isSuccess: Bool
    let code: String
    let message: String
    let result: Result?
}

struct EmptyAPIResult: Decodable {}

enum SocialProvider: String, Codable, Sendable {
    case kakao = "KAKAO"
    case google = "GOOGLE"
    case apple = "APPLE"
}

struct SocialLoginRequest: Encodable, Sendable {
    let socialProvider: SocialProvider
    let socialProviderToken: String
    let nonce: String
}

struct SocialLoginResult: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String
    let isNewUser: Bool
    let termsAgreed: Bool
}

struct TokenReissueRequest: Encodable, Sendable {
    let refreshToken: String
}

struct TokenReissueResult: Decodable, Sendable {
    let accessToken: String
    let refreshToken: String
    let termsAgreed: Bool
}

struct NicknameUpdateRequest: Encodable, Sendable {
    let nickname: String
}

struct NicknameUpdateResult: Decodable, Sendable {
    let nickname: String
}

struct FamilyRoleUpdateRequest: Encodable, Sendable {
    let familyRole: String
}

struct FamilyRoleUpdateResult: Decodable, Sendable {
    let familyRole: String
}

struct CreateFamilyRequest: Encodable, Sendable {
    let name: String
}

struct UpdateFamilyNameRequest: Encodable, Sendable {
    let name: String
}

struct FamilyNameUpdateResult: Decodable, Sendable {
    let familyId: Int
    let name: String
}

struct CreateFamilyResult: Decodable, Sendable {
    let familyId: Int
    let name: String
    let inviteCode: String
    let inviteUrl: String?
    let inviteExpiresAt: String?
}

struct TodayQuestionResult: Decodable, Sendable {
    let hasFamily: Bool
    let questionId: Int?
    let question: String?
    let isAnswered: Bool
    var answer: String?
}

struct FamilyAnswersResult: Decodable, Sendable {
    let question: String
    let answers: [FamilyAnswer]
}

struct FamilyAnswer: Decodable, Identifiable, Sendable {
    let isMe: Bool
    let memberId: Int
    let nickname: String
    let familyRole: String?
    let isAnswered: Bool
    let answer: String?

    var id: Int { memberId }

    private enum CodingKeys: String, CodingKey {
        case isMe, memberId, nickname, familyRole, isAnswered, answer
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isMe = try container.decode(Bool.self, forKey: .isMe)
        memberId = try container.decode(Int.self, forKey: .memberId)
        nickname = try container.decode(String.self, forKey: .nickname)
        familyRole = try container.decodeIfPresent(String.self, forKey: .familyRole)
        isAnswered = try container.decode(Bool.self, forKey: .isAnswered)
        answer = try container.decodeIfPresent(String.self, forKey: .answer)
    }
}



struct MissionFeedResult: Decodable, Sendable {
    let missions: [MissionFeedItem]
    let nextCursor: Int?
    let hasNext: Bool
}

struct BucketSaveResult: Decodable, Sendable {
    let bucketItemId: Int
    let missionId: Int
    let status: String
    let savedAt: String
}

struct BucketListResult: Decodable, Sendable {
    let savers: [BucketSaver]
    let bucketItems: [BucketItemResult]
    let nextCursor: Int?
    let hasNext: Bool
}

struct BucketSaver: Decodable, Sendable, Identifiable {
    let memberId: Int
    let nickname: String
    let familyRole: String?
    let bucketCount: Int
    var id: Int { memberId }
}

struct BucketItemResult: Decodable, Sendable, Identifiable {
    let bucketItemId: Int
    let status: String
    let savedAt: String
    let completedAt: String?
    let mission: BucketMission
    let saver: BucketSaverResult
    let schedulable: Bool
    let deletable: Bool
    let scheduleId: Int?
    let scheduledDate: String?
    var id: Int { bucketItemId }
}

struct BucketMission: Decodable, Sendable {
    let missionId: Int
    let title: String
    let imageUrl: URL?
    let imageSource: String?
    let status: String
}

struct BucketSaverResult: Decodable, Sendable {
    let memberId: Int
    let nickname: String
    let familyRole: String?
    let withdrawn: Bool
}

struct MissionFeedItem: Decodable, Identifiable, Sendable {
    let missionId: Int
    let title: String
    let imageUrl: URL?
    let imageSource: String?
    let category: String
    let missionType: String
    let placeName: String
    let startDate: String?
    let endDate: String?
    let price: Int?
    let distance: Double?

    var id: Int { missionId }
}

struct MissionDetailResult: Decodable, Sendable {
    let missionId: Int
    let title: String
    let description: String?
    let category: String
    let missionType: String
    let status: String
    let indoorOutdoor: String?
    let imageUrl: URL?
    let imageSource: String?
    let startDate: String?
    let endDate: String?
    let openingTime: String?
    let closingTime: String?
    let price: Int?
    let durationMinMinutes: Int?
    let durationMaxMinutes: Int?
    let estimatedStepsMin: Int?
    let estimatedStepsMax: Int?
    let sourceUrl: URL?
    let place: MissionDetailPlace
    let prepareItems: [MissionDetailItem]
    let steps: [MissionDetailItem]
    let bucketSaved: Bool
    let bucketState: String
    let averageRating: Double?
    let reviewCount: Int

    var tags: [String] {
        [category, missionType].filter { !$0.isEmpty }
    }

    var district: String {
        place.address.split(separator: " ").first.map(String.init) ?? place.address
    }
}

struct MissionDetailPlace: Decodable, Sendable {
    let placeId: Int
    let name: String
    let address: String
    let latitude: Double?
    let longitude: Double?
}

struct MissionDetailItem: Decodable, Sendable, Identifiable {
    let title: String
    let description: String

    var id: String { "\(title)-\(description)" }
}

struct WriteAnswerRequest: Encodable, Sendable {
    let answer: String
}

struct TermAgreement: Codable, Identifiable, Sendable {
    let termId: Int
    var isAgreed: Bool

    var id: Int { termId }
}

struct AgreeTermsRequest: Encodable, Sendable {
    let agreements: [TermAgreement]
}

struct TermsAgreementStatus: Decodable, Sendable {
    let termsAgreed: Bool
    let agreements: [TermAgreement]
}

struct Term: Decodable, Identifiable, Sendable {
    let termId: Int
    let title: String
    let shortDescription: String
    let description: String
    let isRequired: Bool
    let updatedAt: String

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        termId = try c.decode(Int.self, forKey: .termId)
        title = try c.decode(String.self, forKey: .title)
        shortDescription = try c.decodeIfPresent(String.self, forKey: .shortDescription) ?? ""
        description = try c.decodeIfPresent(String.self, forKey: .description) ?? ""
        isRequired = try c.decodeIfPresent(Bool.self, forKey: .isRequired) ?? false
        updatedAt = try c.decodeIfPresent(String.self, forKey: .updatedAt) ?? ""
    }

    private enum CodingKeys: String, CodingKey {
        case termId, title, shortDescription, description, isRequired, updatedAt
    }

    var id: Int { termId }
}
