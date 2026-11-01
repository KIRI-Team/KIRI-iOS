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

struct MissionFeedResult: Decodable, Sendable {
    let missions: [MissionFeedItem]
    let nextCursor: Int?
    let hasNext: Bool
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
