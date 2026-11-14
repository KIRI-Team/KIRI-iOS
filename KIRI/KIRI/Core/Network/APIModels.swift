//
// MARK: - 파일 가이드
// 파일: Core/Network/APIModels.swift
// 담당 영역: 공통 컴포넌트·디자인 시스템·네트워크·저장소
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//

import Foundation

struct APIEnvelope<Result: Decodable>: Decodable {
    let isSuccess: Bool
    let code: String
    let message: String
    let result: Result?
}

struct EmptyAPIResult: Decodable {}

/// 건의함 제출 요청. imageKey는 사진을 첨부한 경우에만 서버로 전달합니다.
struct SuggestionCreateRequest: Encodable, Sendable {
    let content: String
    let imageKey: String?
}

struct SuggestionCreateResult: Decodable, Sendable {
    let suggestionId: Int
}

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

struct MemberMyInfoResult: Decodable, Sendable {
    let memberId: Int
    let nickname: String
    let familyRole: String?
    let characterImageUrl: URL?
    let familyName: String?
}

struct FamilyIdResult: Decodable, Sendable {
    let familyId: Int
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

struct JoinFamilyRequest: Encodable, Sendable {
    let inviteCode: String
}

struct JoinFamilyResult: Decodable, Sendable {
    let familyId: Int
    let familyName: String
}

struct InviteTokenInfoResult: Decodable, Sendable {
    let familyId: Int
    let familyName: String
}

struct UpdateFamilyNameRequest: Encodable, Sendable {
    let name: String
}

struct FamilyNameUpdateResult: Decodable, Sendable {
    let familyId: Int
    let name: String
}

struct FamilyAddressUpdateRequest: Encodable, Sendable {
    let postalCode: String
    let address: String
    let detailAddress: String?
    let regionCode: String
    let latitude: Double
    let longitude: Double
}

struct FamilyAddressUpdateResult: Decodable, Sendable, Equatable {
    let familyId: Int
    let postalCode: String
    let address: String
    let detailAddress: String?
    let regionCode: String
    let latitude: Double
    let longitude: Double

    var displayAddress: String {
        let base = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let detail = detailAddress?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return detail.isEmpty ? base : "\(base) \(detail)"
    }
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

struct PresignedURLRequest: Encodable, Sendable {
    let contentType: String
    let contentLength: Int64
}

struct PresignedURLResult: Decodable, Sendable {
    let presignedUrl: URL
    let imageKey: String
    let expiresAt: String
}

struct ReviewCreateRequest: Encodable, Sendable {
    let starRating: Int
    let imageKeys: [String]
    let content: String
    let isRejoinIntended: Bool
}

struct ReviewCreateResult: Decodable, Sendable {
    let reviewId: Int
    let scheduleId: Int
}

struct ScheduleReviewsResult: Decodable, Sendable {
    let scheduleId: Int
    let representativePhotoId: Int?
    let reviews: [ReviewItemResult]
}

struct ReviewItemResult: Decodable, Identifiable, Sendable {
    let reviewId: Int
    let writer: ReviewWriterResult
    let content: String
    let starRating: Int
    let isRejoinIntended: Bool
    let photos: [ReviewPhotoResult]
    let createdAt: String
    let isMine: Bool

    var id: Int { reviewId }
}

struct ReviewWriterResult: Decodable, Sendable {
    let memberId: Int
    let nickname: String
    let familyRole: String?
}

struct ReviewPhotoResult: Decodable, Identifiable, Sendable {
    let reviewPhotoId: Int
    let imageKey: String
    let imageUrl: URL

    var id: Int { reviewPhotoId }
}

struct RepresentativePhotoRequest: Encodable, Sendable {
    let reviewPhotoId: Int
}

struct RepresentativePhotoResult: Decodable, Sendable {
    let scheduleId: Int
    let representativePhotoId: Int
}

struct ScheduleConditionsResult: Decodable, Sendable {
    let missionTitle: String
    let walkingLevel: String
    let durationMinMinutes: Int?
    let durationMaxMinutes: Int?
    let conditions: [String]
}

struct UpdateScheduleConditionsRequest: Encodable, Sendable {
    let conditions: [String]
}

struct CreateScheduleRequest: Encodable, Sendable {
    let scheduleDate: String
    let scheduleTime: String
    let participantMemberIds: [Int]
    let requestMessage: String?
}

struct AppEventBatchRequest: Encodable, Sendable {
    let events: [AppEventRequest]
}

struct AppEventRequest: Encodable, Sendable {
    let eventId: String
    let eventName: String
    let properties: [String: String]?
    let platform: String
    let appVersion: String?
    let occurredAt: String
}

struct ScheduleResult: Decodable, Sendable {
    let scheduleId: Int
    let bucketItemId: Int?
    let scheduleDate: String?
    let scheduleTime: String?
    let status: String
    let responseDeadline: String?
    let proposerId: Int?
    let participantMemberIds: [Int]?
    let myStatus: String?
}

/// GET /api/v1/schedules/{scheduleId} 응답입니다.
/// 서버가 일정 제목을 반환하지 않으므로 목록 제목은 화면에 유지하고
/// 날짜·시간·상태·참여자만 최신 서버 값으로 갱신합니다.
struct ScheduleDetailResult: Decodable, Sendable {
    let missionId: Int?
    let date: String
    let time: String?
    let status: String?
    let participants: [ScheduleParticipantResult]

    private enum CodingKeys: String, CodingKey {
        case missionId, date, time, status, participants
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        missionId = try container.decodeIfPresent(Int.self, forKey: .missionId)
        date = try container.decode(String.self, forKey: .date)
        time = try container.decodeIfPresent(String.self, forKey: .time)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        participants = try container.decodeIfPresent([ScheduleParticipantResult].self, forKey: .participants) ?? []
    }
}

struct ScheduleParticipantResult: Decodable, Sendable {
    let nickname: String
    let accepted: Bool
}

struct CalendarScheduleResult: Decodable, Sendable, Identifiable {
    let scheduleId: Int
    let date: String
    let time: String
    let status: String
    let myStatus: String
    var id: Int { scheduleId }
}

struct CalendarResult: Decodable, Sendable {
    let year: Int
    let month: Int
    let schedules: [CalendarScheduleResult]
}

struct UpcomingScheduleResult: Decodable, Sendable {
    let responseRequired: UpcomingSchedule?
    let upcoming: UpcomingSchedule?
}

struct UpcomingSchedule: Decodable, Sendable {
    let scheduleId: Int
    let date: String
    let time: String
    let status: String
    let myStatus: String
    let dDay: Int
    let type: String
    let title: String
}

struct UpdateScheduleRequest: Encodable, Sendable {
    let scheduleDate: String
    let scheduleTime: String
    let participantMemberIds: [Int]
    let requestMessage: String?
}

struct TasteResult: Codable, Sendable {
    let nickname: String
    let isSet: Bool
    let categories: [String]?
    let indoorOutdoor: String?
    let activityLevel: String?
    let priceLevel: String?
    let durationLevel: String?
}

struct TasteRequest: Encodable, Sendable {
    let categories: [String]
    let indoorOutdoor: String?
    let activityLevel: String?
    let priceLevel: String?
    let durationLevel: String?
}

struct InviteResult: Decodable, Sendable {
    let inviteCode: String
    let inviteUrl: String
    let inviteExpiresAt: String?
}

struct FamilyInfoResult: Decodable, Sendable {
    let familyId: Int
    let familyName: String
    let ownerMemberId: Int
    let memberCount: Int
    let members: [FamilyMemberInfoResult]
}

struct FamilyMemberInfoResult: Decodable, Identifiable, Sendable {
    let memberId: Int
    let nickname: String
    let familyRole: String?
    let characterImageUrl: URL?

    var id: Int { memberId }
}

struct NearbyMissionResult: Decodable, Identifiable, Sendable {
    /// 추천 카드가 가리키는 미션입니다. 구버전 일정 응답에는 없을 수 있어
    /// optional로 디코드하고, 값이 있는 경우에만 상세 이동을 제공합니다.
    let missionId: Int?
    let placeName: String
    let region: String
    let description: String
    let imageUrl: URL?
    let price: Int?
    /// 서버 초기 문서의 오탈자(distnace)와 정식 키(distance)를 모두 수용합니다.
    /// 값은 API 계약의 km 단위를 보존합니다.
    let distance: Double?

    var id: String { "\(missionId.map(String.init) ?? placeName)-\(region)-\(description)" }

    private enum CodingKeys: String, CodingKey {
        case missionId, placeName, region, description, imageUrl, price, distance, distnace
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        missionId = try container.decodeIfPresent(Int.self, forKey: .missionId)
        placeName = try container.decode(String.self, forKey: .placeName)
        region = try container.decode(String.self, forKey: .region)
        description = try container.decode(String.self, forKey: .description)
        imageUrl = try container.decodeIfPresent(URL.self, forKey: .imageUrl)
        price = try container.decodeIfPresent(Int.self, forKey: .price)
        distance = try container.decodeIfPresent(Double.self, forKey: .distance)
            ?? container.decodeIfPresent(Double.self, forKey: .distnace)
    }
}

struct ScheduleResponseRequest: Encodable, Sendable {
    let action: String
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

    /// 서버 enum은 요청·필터에는 원문을 사용하고, 사용자 화면에서는 한국어 라벨만 사용합니다.
    /// 서버에 새 값이 추가되어도 영문 enum이 그대로 노출되지 않도록 알 수 없는 값은 숨깁니다.
    var displayTags: [String] {
        [MissionDisplayLabel.category(category), MissionDisplayLabel.missionType(missionType)]
            .compactMap { $0 }
    }
}

enum MissionDisplayLabel {
    static func category(_ rawValue: String) -> String? {
        switch rawValue.uppercased() {
        case "EXHIBITION": return "전시·문화"
        case "POPUP": return "팝업·행사"
        case "EXPERIENCE": return "체험·놀거리"
        case "OUTDOOR": return "산책·야외"
        case "PERFORMANCE": return "공연"
        case "FOOD_CAFE": return "맛집·카페"
        default: return nil
        }
    }

    static func missionType(_ rawValue: String) -> String? {
        switch rawValue.uppercased() {
        case "PERMANENT": return "상시 운영"
        case "TEMPORARY": return "기간 운영"
        default: return nil
        }
    }
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

struct FamilyRecommendationResult: Decodable, Identifiable, Sendable {
    let missionId: Int
    let title: String
    let description: String
    let category: String
    let imageUrl: URL?
    let recommendationReason: String
    let score: Double?

    var id: Int { missionId }
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
