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

    var id: Int { termId }
}
