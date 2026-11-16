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

/// 알림함 목록 응답. 서버의 Spring Page JSON을 그대로 보존해 다음 페이지를
/// 중복 없이 이어 붙일 수 있도록 합니다.
struct NotificationPreviewResult: Decodable, Identifiable, Sendable, Equatable {
    let notificationId: Int
    let title: String
    let body: String
    let notificationType: String
    let isRead: Bool
    let referenceId: Int?
    let createdAt: String

    var id: Int { notificationId }
}

struct NotificationPageResult: Decodable, Sendable {
    let content: [NotificationPreviewResult]
    let number: Int
    let totalPages: Int
    let last: Bool
    let empty: Bool

    var hasNext: Bool { !last && number + 1 < totalPages }

    private enum CodingKeys: String, CodingKey {
        case content, number, totalPages, last, empty
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        content = try c.decodeIfPresent([NotificationPreviewResult].self, forKey: .content) ?? []
        number = try c.decodeIfPresent(Int.self, forKey: .number) ?? 0
        totalPages = try c.decodeIfPresent(Int.self, forKey: .totalPages) ?? 1
        last = try c.decodeIfPresent(Bool.self, forKey: .last) ?? (number + 1 >= totalPages)
        empty = try c.decodeIfPresent(Bool.self, forKey: .empty) ?? content.isEmpty
    }
}

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

/// 닉네임 검증 실패 시 서버가 COMMON400_1의 result.nickname으로
/// 전달하는 필드입니다. 요청 실패 원인을 사용자에게 안내할 때만 사용합니다.
struct NicknameValidationErrorResult: Decodable, Sendable {
    let nickname: String?
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
    /// 버킷 목록 응답에 포함될 수 있는 미션 설명입니다.
    /// 구버전 응답에는 없을 수 있어 상세 API로 보완합니다.
    let description: String?
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
    /// 일부 리뷰 응답은 작성자 ID만 내려주므로 화면에서 가족 구성원 정보로 보완합니다.
    let nickname: String?
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
/// 일정 자체의 표시 정보와 응답 권한·재확인 변경 필드를 함께 보존합니다.
struct ScheduleDetailResult: Decodable, Sendable {
    let missionId: Int?
    let missionTitle: String?
    let missionDescription: String?
    let date: String
    let time: String?
    let status: String?
    let myStatus: String?
    let canRespond: Bool
    let canEdit: Bool
    let canCancel: Bool
    let changedFields: [String]
    let requestMessage: String?
    let proposer: ScheduleProposerResult?
    let participants: [ScheduleParticipantResult]

    private enum CodingKeys: String, CodingKey {
        case missionId, missionTitle, missionDescription, date, time, status, myStatus
        case canRespond, canEdit, canCancel, changedFields, requestMessage, proposer, participants
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        missionId = try container.decodeIfPresent(Int.self, forKey: .missionId)
        missionTitle = try container.decodeIfPresent(String.self, forKey: .missionTitle)
        missionDescription = try container.decodeIfPresent(String.self, forKey: .missionDescription)
        date = try container.decode(String.self, forKey: .date)
        time = try container.decodeIfPresent(String.self, forKey: .time)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        myStatus = try container.decodeIfPresent(String.self, forKey: .myStatus)
        canRespond = try container.decodeIfPresent(Bool.self, forKey: .canRespond) ?? false
        canEdit = try container.decodeIfPresent(Bool.self, forKey: .canEdit) ?? false
        canCancel = try container.decodeIfPresent(Bool.self, forKey: .canCancel) ?? false
        changedFields = try container.decodeIfPresent([String].self, forKey: .changedFields) ?? []
        requestMessage = try container.decodeIfPresent(String.self, forKey: .requestMessage)
        proposer = try container.decodeIfPresent(ScheduleProposerResult.self, forKey: .proposer)
        participants = try container.decodeIfPresent([ScheduleParticipantResult].self, forKey: .participants) ?? []
    }
}

struct ScheduleProposerResult: Decodable, Sendable {
    let memberId: Int?
    let nickname: String?
    let familyRole: String?
    let characterImageUrl: URL?
}

struct ScheduleParticipantResult: Decodable, Sendable {
    let nickname: String
    let memberId: Int?
    let status: String
    let characterImageUrl: URL?

    private enum CodingKeys: String, CodingKey { case memberId, nickname, status, characterImageUrl }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        memberId = try container.decodeIfPresent(Int.self, forKey: .memberId)
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname) ?? "가족 구성원"
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? "PENDING"
        characterImageUrl = try container.decodeIfPresent(URL.self, forKey: .characterImageUrl)
    }
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
    /// Android and the current API contract expose the activity level as
    /// `walkingLevel`; older responses may omit it.
    let walkingLevel: String?
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
    let place: MissionDetailPlace?
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
        place?.address.split(separator: " ").first.map(String.init) ?? ""
    }

    private enum CodingKeys: String, CodingKey {
        case missionId, title, description, category, missionType, status
        case indoorOutdoor, walkingLevel, imageUrl, imageSource, startDate, endDate
        case openingTime, closingTime, price, durationMinMinutes, durationMaxMinutes
        case estimatedStepsMin, estimatedStepsMax, sourceUrl, place, prepareItems, steps
        case bucketSaved, bucketState, averageRating, reviewCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        missionId = try container.decode(Int.self, forKey: .missionId)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description)
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
        missionType = try container.decodeIfPresent(String.self, forKey: .missionType) ?? ""
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? ""
        indoorOutdoor = try container.decodeIfPresent(String.self, forKey: .indoorOutdoor)
        walkingLevel = try container.decodeIfPresent(String.self, forKey: .walkingLevel)
        imageUrl = Self.decodeURL(container, key: .imageUrl)
        imageSource = try container.decodeIfPresent(String.self, forKey: .imageSource)
        startDate = try container.decodeIfPresent(String.self, forKey: .startDate)
        endDate = try container.decodeIfPresent(String.self, forKey: .endDate)
        openingTime = try container.decodeIfPresent(String.self, forKey: .openingTime)
        closingTime = try container.decodeIfPresent(String.self, forKey: .closingTime)
        price = try container.decodeIfPresent(Int.self, forKey: .price)
        durationMinMinutes = try container.decodeIfPresent(Int.self, forKey: .durationMinMinutes)
        durationMaxMinutes = try container.decodeIfPresent(Int.self, forKey: .durationMaxMinutes)
        estimatedStepsMin = try container.decodeIfPresent(Int.self, forKey: .estimatedStepsMin)
        estimatedStepsMax = try container.decodeIfPresent(Int.self, forKey: .estimatedStepsMax)
        sourceUrl = Self.decodeURL(container, key: .sourceUrl)
        place = try container.decodeIfPresent(MissionDetailPlace.self, forKey: .place)
        prepareItems = try container.decodeIfPresent([MissionDetailItem].self, forKey: .prepareItems) ?? []
        steps = try container.decodeIfPresent([MissionDetailItem].self, forKey: .steps) ?? []
        bucketState = try container.decodeIfPresent(String.self, forKey: .bucketState) ?? ""
        bucketSaved = try container.decodeIfPresent(Bool.self, forKey: .bucketSaved)
            ?? ["SAVED", "IN_BUCKET", "BUCKETED"].contains(bucketState.uppercased())
        averageRating = try container.decodeIfPresent(Double.self, forKey: .averageRating)
        reviewCount = try container.decodeIfPresent(Int.self, forKey: .reviewCount) ?? 0
    }

    init(
        missionId: Int, title: String, description: String?, category: String,
        missionType: String, status: String, indoorOutdoor: String?, imageUrl: URL?,
        imageSource: String?, startDate: String?, endDate: String?, openingTime: String?,
        closingTime: String?, price: Int?, durationMinMinutes: Int?, durationMaxMinutes: Int?,
        estimatedStepsMin: Int?, estimatedStepsMax: Int?, sourceUrl: URL?,
        place: MissionDetailPlace?, prepareItems: [MissionDetailItem], steps: [MissionDetailItem],
        bucketSaved: Bool, bucketState: String, averageRating: Double?, reviewCount: Int,
        walkingLevel: String? = nil
    ) {
        self.missionId = missionId; self.title = title; self.description = description
        self.category = category; self.missionType = missionType; self.status = status
        self.indoorOutdoor = indoorOutdoor; self.walkingLevel = walkingLevel
        self.imageUrl = imageUrl; self.imageSource = imageSource; self.startDate = startDate
        self.endDate = endDate; self.openingTime = openingTime; self.closingTime = closingTime
        self.price = price; self.durationMinMinutes = durationMinMinutes; self.durationMaxMinutes = durationMaxMinutes
        self.estimatedStepsMin = estimatedStepsMin; self.estimatedStepsMax = estimatedStepsMax
        self.sourceUrl = sourceUrl; self.place = place; self.prepareItems = prepareItems; self.steps = steps
        self.bucketSaved = bucketSaved; self.bucketState = bucketState; self.averageRating = averageRating
        self.reviewCount = reviewCount
    }

    private static func decodeURL<K: CodingKey>(_ container: KeyedDecodingContainer<K>, key: K) -> URL? {
        let raw: String?
        do {
            raw = try container.decodeIfPresent(String.self, forKey: key)
        } catch {
            return nil
        }
        guard let raw, !raw.isEmpty else { return nil }
        return URL(string: raw)
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

    private enum CodingKeys: String, CodingKey { case placeId, name, address, latitude, longitude }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        placeId = try container.decode(Int.self, forKey: .placeId)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        address = try container.decodeIfPresent(String.self, forKey: .address) ?? ""
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
    }

    init(placeId: Int, name: String, address: String, latitude: Double?, longitude: Double?) {
        self.placeId = placeId; self.name = name; self.address = address
        self.latitude = latitude; self.longitude = longitude
    }
}

struct MissionDetailItem: Decodable, Sendable, Identifiable {
    let title: String
    let description: String

    var id: String { "\(title)-\(description)" }

    private enum CodingKeys: String, CodingKey { case title, description }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
    }

    init(title: String, description: String) {
        self.title = title; self.description = description
    }
}

/// 미션 일정과 무관하게 조회하는 맞춤 준비물 응답입니다.
/// 서버 버전에 따라 배열 또는 essentials/items/prepareItems 래퍼를 수용합니다.
struct MissionEssentialsResult: Decodable, Sendable {
    let items: [MissionDetailItem]

    private enum CodingKeys: String, CodingKey { case essentials, items, prepareItems }

    init(from decoder: Decoder) throws {
        if let values = try? decoder.singleValueContainer().decode([MissionDetailItem].self) {
            items = values
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decodeIfPresent([MissionDetailItem].self, forKey: .essentials)
            ?? container.decodeIfPresent([MissionDetailItem].self, forKey: .items)
            ?? container.decodeIfPresent([MissionDetailItem].self, forKey: .prepareItems)
            ?? []
    }
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

/// 서버의 가족 역할 코드를 화면 표시용 한국어로 변환합니다.
/// 서버 값은 저장·요청에 그대로 사용하고, 이 함수는 표시 문자열에만 적용합니다.
func localizedFamilyRole(_ role: String?) -> String {
    guard let role, !role.isEmpty else { return "" }
    switch role.uppercased() {
    case "MOTHER", "MOM": return "엄마"
    case "FATHER", "DAD": return "아빠"
    case "DAUGHTER": return "딸"
    case "SON": return "아들"
    default: return role
    }
}
