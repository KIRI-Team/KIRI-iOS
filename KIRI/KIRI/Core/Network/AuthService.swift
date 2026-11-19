//
// MARK: - 파일 가이드
// 파일: Core/Network/AuthService.swift
// 담당 영역: 공통 컴포넌트·디자인 시스템·네트워크·저장소
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//

import Foundation

enum AuthServiceError: LocalizedError {
    case missingStoredSession

    var errorDescription: String? {
        switch self {
        case .missingStoredSession:
            return "저장된 로그인 정보가 없습니다."
        }
    }
}

final class AuthService {
    static let shared = AuthService()

    private let client: APIClient
    private let tokenStore: AuthTokenStoring

    init(
        client: APIClient = .shared,
        tokenStore: AuthTokenStoring = KeychainAuthTokenStore.shared
    ) {
        self.client = client
        self.tokenStore = tokenStore
    }

    // 입력 화면과 네트워크 요청이 서로 다른 문자열을 보지 않도록
    // 비동기 경계를 넘기기 전에 한 번만 NFC/공백 정규화를 수행합니다.
    private func normalizedNickname(_ value: String) -> String {
        value.precomposedStringWithCanonicalMapping
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func normalizedFamilyName(_ value: String) -> String {
        value.precomposedStringWithCanonicalMapping
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
    }

    private func isValidNickname(_ value: String) -> Bool {
        value.count >= 2 && value.count <= 12
            && value.range(of: "^[가-힣A-Za-z0-9]+$", options: .regularExpression) != nil
    }

    private func isValidFamilyName(_ value: String) -> Bool {
        value.count >= 2 && value.count <= 15
            && value.range(of: "^[가-힣A-Za-z0-9 ]+$", options: .regularExpression) != nil
    }

    func login(
        provider: SocialProvider,
        token: String,
        nonce: String
    ) async throws -> SocialLoginResult {
        let endpoint = APIEndpoint(
            path: "/api/v1/auth/login",
            method: .POST
        )
        let body = SocialLoginRequest(
            socialProvider: provider,
            socialProviderToken: token,
            nonce: nonce
        )
        #if DEBUG
        print(
            "[KIRI][Auth] login request: provider=\(provider.rawValue), "
                + "tokenPresent=\(!token.isEmpty), noncePresent=\(!nonce.isEmpty)"
        )
        #endif
        let envelope: APIEnvelope<SocialLoginResult> = try await client.requestEnvelope(
            endpoint: endpoint,
            body: body
        )
        guard let result = envelope.result else {
            throw APIError.decodingFailed
        }
        #if DEBUG
        print(
            "[KIRI][Auth] login response: provider=\(provider.rawValue), "
                + "isSuccess=\(envelope.isSuccess), "
                + "isNewUser=\(result.isNewUser), termsAgreed=\(result.termsAgreed)"
        )
        #endif
        try tokenStore.save(
            AuthTokens(
                accessToken: result.accessToken,
                refreshToken: result.refreshToken,
                expiresAt: nil
            )
        )
        return result
    }

    func reissue() async throws -> TokenReissueResult {
        guard let tokens = try tokenStore.read(),
              let refreshToken = tokens.refreshToken else {
            throw AuthServiceError.missingStoredSession
        }

        let endpoint = APIEndpoint(
            path: "/api/v1/auth/reissue",
            method: .POST
        )
        let envelope: APIEnvelope<TokenReissueResult> = try await client.requestEnvelope(
            endpoint: endpoint,
            body: TokenReissueRequest(refreshToken: refreshToken)
        )
        guard let result = envelope.result else {
            throw APIError.decodingFailed
        }
        try tokenStore.save(
            AuthTokens(
                accessToken: result.accessToken,
                refreshToken: result.refreshToken,
                expiresAt: nil
            )
        )
        return result
    }

    func myInfo() async throws -> MemberMyInfoResult {
        let endpoint = APIEndpoint(path: "/api/v1/members/me", requiresAuthentication: true)
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<MemberMyInfoResult> = try await client.requestEnvelope(
            endpoint: endpoint,
            accessToken: tokens.accessToken
        )
        guard let result = envelope.result else { throw APIError.decodingFailed }
        return result
    }

    func familyIdForCurrentMember() async throws -> FamilyIdResult {
        let endpoint = APIEndpoint(path: "/api/v1/families/me/id", requiresAuthentication: true)
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<FamilyIdResult> = try await client.requestEnvelope(
            endpoint: endpoint,
            accessToken: tokens.accessToken
        )
        guard let result = envelope.result else { throw APIError.decodingFailed }
        return result
    }

    func terms() async throws -> [Term] {
        #if DEBUG
        print("[KIRI][Terms] request started")
        #endif
        let endpoint = APIEndpoint(
            path: "/api/v1/terms",
            method: .GET,
            requiresAuthentication: true
        )
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<[Term]> = try await client.requestEnvelope(
            endpoint: endpoint,
            accessToken: tokens.accessToken
        )
        guard let result = envelope.result else {
            #if DEBUG
            print("[KIRI][Terms] decoded result missing: success=\(envelope.isSuccess), code=\(envelope.code)")
            #endif
            throw APIError.decodingFailed
        }
        #if DEBUG
        print("[KIRI][Terms] decoded count=\(result.count), success=\(envelope.isSuccess), code=\(envelope.code)")
        #endif
        return result
    }

    func agreementStatus() async throws -> TermsAgreementStatus {
        #if DEBUG
        print("[KIRI][Terms] agreement request started")
        #endif
        let endpoint = APIEndpoint(
            path: "/api/v1/terms/agreements",
            method: .GET,
            requiresAuthentication: true
        )
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<TermsAgreementStatus> = try await client.requestEnvelope(
            endpoint: endpoint,
            accessToken: tokens.accessToken
        )
        guard let result = envelope.result else {
            throw APIError.decodingFailed
        }
        return result
    }

    func agree(to agreements: [TermAgreement]) async throws {
        let endpoint = APIEndpoint(
            path: "/api/v1/terms/agreements",
            method: .POST,
            requiresAuthentication: true
        )
        let tokens = try authenticatedTokens()
        let _: APIEnvelope<EmptyAPIResult> = try await client.requestEnvelope(
            endpoint: endpoint,
            body: AgreeTermsRequest(agreements: agreements),
            accessToken: tokens.accessToken
        )
    }

    func logout() async throws {
        let endpoint = APIEndpoint(
            path: "/api/v1/auth/logout",
            method: .POST,
            requiresAuthentication: true
        )
        let tokens = try authenticatedTokens()
        let _: APIEnvelope<EmptyAPIResult> = try await client.requestEnvelope(
            endpoint: endpoint,
            accessToken: tokens.accessToken
        )
    }

    func deleteAccount() async throws {
        let endpoint = APIEndpoint(
            path: "/api/v1/members/me",
            method: .DELETE,
            requiresAuthentication: true
        )
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<EmptyAPIResult> = try await client.requestEnvelope(
            endpoint: endpoint,
            accessToken: tokens.accessToken
        )
        // 탈퇴 성공 응답은 MEMBER200_3/result: null일 수 있습니다. result의
        // 유무로 성공을 판단하지 않고 공통 envelope의 성공 플래그를 기준으로
        // 처리합니다.
        guard envelope.isSuccess else {
            throw APIError.serverError(code: envelope.code, message: envelope.message)
        }
    }

    func updateNickname(_ nickname: String) async throws -> NicknameUpdateResult {
        let endpoint = APIEndpoint(
            path: "/api/v1/members/nickname",
            method: .PATCH,
            requiresAuthentication: true
        )
        let tokens = try authenticatedTokens()
        // Copy and validate the value before crossing the async boundary. The
        // nickname originates in a SwiftUI TextField and must never share its
        // mutable String storage with request construction. JSONSerialization
        // also lets us validate the exact object sent by the PATCH contract
        // (`{\"nickname\": string}`) without passing an existential Encodable
        // through the request pipeline.
        // The caller has already captured the edit value on MainActor. Make
        // one immutable value for validation and JSON construction instead of
        // reading SwiftUI state again after the async boundary.
        let nicknameValue = normalizedNickname(String(nickname))
        #if DEBUG
        print(
            "[KIRI][AuthService] updateNickname "
                + "inputLength=\(nickname.count) utf8Length=\(nicknameValue.utf8.count)"
        )
        #endif
        guard isValidNickname(nicknameValue) else {
            throw APIError.serverError(
                code: "COMMON400_1",
                message: "닉네임은 한글·영문·숫자 2~12자로 입력해 주세요."
            )
        }
        let bodyObject: [String: String] = ["nickname": nicknameValue]
        let bodyData = try JSONSerialization.data(
            withJSONObject: bodyObject,
            options: []
        )
        #if DEBUG
        // 원문은 기록하지 않고 계약 검증에 필요한 키·바이트 수·길이만 남깁니다.
        print("[KIRI][API] PATCH /api/v1/members/nickname bodyKeys=nickname bodyBytes=\(bodyData.count) nicknameLength=\(nicknameValue.count)")
        #endif
        let envelope: APIEnvelope<NicknameUpdateResult> = try await client.requestEnvelope(
            endpoint: endpoint,
            bodyData: bodyData,
            accessToken: tokens.accessToken
        )
        guard let result = envelope.result else { throw APIError.decodingFailed }
        return result
    }

    func updateFamilyRole(_ role: String) async throws -> FamilyRoleUpdateResult {
        let endpoint = APIEndpoint(
            path: "/api/v1/members/family-role",
            method: .PATCH,
            requiresAuthentication: true
        )
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<FamilyRoleUpdateResult> = try await client.requestEnvelope(
            endpoint: endpoint,
            body: FamilyRoleUpdateRequest(familyRole: role),
            accessToken: tokens.accessToken
        )
        guard let result = envelope.result else { throw APIError.decodingFailed }
        return result
    }

    /// 입력한 6자리 초대 코드로 현재 인증 사용자를 가족공간에 참여시킵니다.
    func joinFamily(inviteCode: String) async throws -> JoinFamilyResult {
        let endpoint = APIEndpoint(
            path: "/api/v1/families/join/code",
            method: .POST,
            requiresAuthentication: true
        )
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<JoinFamilyResult> = try await client.requestEnvelope(
            endpoint: endpoint,
            body: JoinFamilyRequest(inviteCode: inviteCode),
            accessToken: tokens.accessToken
        )
        guard let result = envelope.result else { throw APIError.decodingFailed }
        return result
    }

    func inviteTokenInfo(_ token: String) async throws -> InviteTokenInfoResult {
        let endpoint = APIEndpoint(
            path: "/api/v1/families/invite/\(token)",
            method: .GET,
            requiresAuthentication: false
        )
        let envelope: APIEnvelope<InviteTokenInfoResult> = try await client.requestEnvelope(endpoint: endpoint)
        guard let result = envelope.result else { throw APIError.decodingFailed }
        return result
    }

    func joinFamily(inviteToken: String) async throws -> JoinFamilyResult {
        let endpoint = APIEndpoint(
            path: "/api/v1/families/join/\(inviteToken)",
            method: .POST,
            requiresAuthentication: true
        )
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<JoinFamilyResult> = try await client.requestEnvelope(
            endpoint: endpoint,
            accessToken: tokens.accessToken
        )
        guard let result = envelope.result else { throw APIError.decodingFailed }
        return result
    }

    func createFamily(name: String) async throws -> CreateFamilyResult {
        let endpoint = APIEndpoint(
            path: "/api/v1/families",
            method: .POST,
            requiresAuthentication: true
        )
        let tokens = try authenticatedTokens()
        let nameValue = normalizedFamilyName(String(name))
        guard isValidFamilyName(nameValue) else {
            throw APIError.serverError(
                code: "COMMON400_1",
                message: "가족명은 한글·영문·숫자·띄어쓰기 2~15자로 입력해 주세요."
            )
        }
        let envelope: APIEnvelope<CreateFamilyResult> = try await client.requestEnvelope(
            endpoint: endpoint,
            body: CreateFamilyRequest(name: nameValue),
            accessToken: tokens.accessToken
        )
        guard let result = envelope.result else { throw APIError.decodingFailed }
        return result
    }

    func updateFamilyName(familyId: Int, name: String) async throws -> FamilyNameUpdateResult {
        let endpoint = APIEndpoint(
            path: "/api/v1/families/\(familyId)",
            method: .PATCH,
            requiresAuthentication: true
        )
        let tokens = try authenticatedTokens()
        // SwiftUI 입력 State를 네트워크 비동기 경계 밖에서 확정하고,
        // 가족명 PATCH 계약({"name": string})과 동일한 JSON 바이트를 전송합니다.
        #if DEBUG
        print("[KIRI][AuthService] updateFamilyName received charLength=\(name.count) utf8Length=\(name.utf8.count)")
        #endif
        let nameValue = normalizedFamilyName(String(name))
        guard isValidFamilyName(nameValue) else {
            throw APIError.serverError(
                code: "COMMON400_1",
                message: "가족명은 한글·영문·숫자·띄어쓰기 2~15자로 입력해 주세요."
            )
        }
        let bodyData = try JSONSerialization.data(
            withJSONObject: ["name": nameValue],
            options: []
        )
        #if DEBUG
        print("[KIRI][API] PATCH /api/v1/families/\(familyId) bodyKeys=name bodyBytes=\(bodyData.count) nameLength=\(nameValue.count)")
        #endif
        let envelope: APIEnvelope<FamilyNameUpdateResult> = try await client.requestEnvelope(
            endpoint: endpoint,
            bodyData: bodyData,
            accessToken: tokens.accessToken
        )
        guard let result = envelope.result else { throw APIError.decodingFailed }
        return result
    }

    func updateFamilyAddress(familyId: Int, request: FamilyAddressUpdateRequest) async throws -> FamilyAddressUpdateResult {
        let endpoint = APIEndpoint(
            path: "/api/v1/families/\(familyId)/address",
            method: .PUT,
            requiresAuthentication: true
        )
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<FamilyAddressUpdateResult> = try await client.requestEnvelope(
            endpoint: endpoint,
            body: request,
            accessToken: tokens.accessToken
        )
        guard let result = envelope.result else { throw APIError.decodingFailed }
        return result
    }

    func myTaste() async throws -> TasteResult {
        let endpoint = APIEndpoint(path: "/api/v1/members/taste", requiresAuthentication: true)
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<TasteResult> = try await client.requestEnvelope(endpoint: endpoint, accessToken: tokens.accessToken)
        guard let result = envelope.result else { throw APIError.decodingFailed }
        return result
    }

    func saveTaste(_ request: TasteRequest) async throws -> TasteResult {
        let endpoint = APIEndpoint(path: "/api/v1/members/taste", method: .PUT, requiresAuthentication: true)
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<TasteResult> = try await client.requestEnvelope(endpoint: endpoint, body: request, accessToken: tokens.accessToken)
        guard let result = envelope.result else { throw APIError.decodingFailed }
        return result
    }

    func familyInvite(familyId: Int) async throws -> InviteResult {
        let endpoint = APIEndpoint(path: "/api/v1/families/\(familyId)/invite", requiresAuthentication: true)
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<InviteResult> = try await client.requestEnvelope(endpoint: endpoint, accessToken: tokens.accessToken)
        guard let result = envelope.result else { throw APIError.decodingFailed }
        return result
    }

    func familyInfo(familyId: Int) async throws -> FamilyInfoResult {
        let endpoint = APIEndpoint(path: "/api/v1/families/\(familyId)", requiresAuthentication: true)
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<FamilyInfoResult> = try await client.requestEnvelope(endpoint: endpoint, accessToken: tokens.accessToken)
        guard let result = envelope.result else { throw APIError.decodingFailed }
        return result
    }

    /// KIRI-SERVER access token은 JWT subject에 인증된 memberId를 담습니다.
    /// 닉네임 변경과 무관하게 참여자 선택에서 현재 사용자를 제외하기 위한 값입니다.
    func currentMemberId() throws -> Int {
        let tokens = try authenticatedTokens()
        let segments = tokens.accessToken.split(separator: ".")
        guard segments.count == 3 else { throw AuthServiceError.missingStoredSession }
        var payload = String(segments[1])
        payload += String(repeating: "=", count: (4 - payload.count % 4) % 4)
        payload = payload.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        guard let data = Data(base64Encoded: payload),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let subject = object["sub"] as? String,
              let memberId = Int(subject) else {
            throw AuthServiceError.missingStoredSession
        }
        return memberId
    }

    func reissueFamilyInvite(familyId: Int) async throws -> InviteResult {
        let endpoint = APIEndpoint(path: "/api/v1/families/\(familyId)/invite", method: .PATCH, requiresAuthentication: true)
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<InviteResult> = try await client.requestEnvelope(endpoint: endpoint, accessToken: tokens.accessToken)
        guard let result = envelope.result else { throw APIError.decodingFailed }
        return result
    }

    /// 현재 가족의 초대 코드와 링크를 폐기합니다.
    /// Android 계약상 성공 응답의 result는 사용하지 않습니다.
    func deleteFamilyInvite(familyId: Int) async throws {
        let endpoint = APIEndpoint(path: "/api/v1/families/\(familyId)/invite", method: .DELETE, requiresAuthentication: true)
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<EmptyAPIResult> = try await client.requestEnvelope(endpoint: endpoint, accessToken: tokens.accessToken)
        guard envelope.isSuccess else {
            throw APIError.serverError(code: envelope.code, message: envelope.message)
        }
    }

    func todayQuestion() async throws -> TodayQuestionResult {
        let endpoint = APIEndpoint(
            path: "/api/v1/questions/today",
            method: .GET,
            requiresAuthentication: true
        )
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<TodayQuestionResult> = try await client.requestEnvelope(
            endpoint: endpoint,
            accessToken: tokens.accessToken
        )
        guard let result = envelope.result else { throw APIError.decodingFailed }
        return result
    }

    func familyAnswers(questionId: Int) async throws -> FamilyAnswersResult {
        let endpoint = APIEndpoint(
            path: "/api/v1/questions/\(questionId)/answers",
            method: .GET,
            requiresAuthentication: true
        )
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<FamilyAnswersResult> = try await client.requestEnvelope(
            endpoint: endpoint,
            accessToken: tokens.accessToken
        )
        guard let result = envelope.result else { throw APIError.decodingFailed }
        #if DEBUG
        print("[KIRI][Question] family answers response count=\(result.answers.count)")
        #endif
        return result
    }

    /// 일정 참여자 선택에 필요한 실제 가족 구성원 목록입니다.
    /// 오늘 질문 응답 API는 미답변 구성원도 포함하므로 질문이 배정된 날에는
    /// 가족 상세 응답보다 이 경로를 우선 사용합니다.
    func scheduleParticipantMembers(familyId: Int) async throws -> [FamilyMemberInfoResult] {
        do {
            let question = try await todayQuestion()
            if let questionId = question.questionId {
                let answers = try await familyAnswers(questionId: questionId)
                return answers.answers.map {
                    FamilyMemberInfoResult(
                        memberId: $0.memberId,
                        nickname: $0.nickname,
                        familyRole: $0.familyRole,
                        characterImageUrl: nil
                    )
                }
            }
        } catch let APIError.serverError(code, _) where code == "QUESTION404_1" {
            // 오늘 질문이 없는 날에는 아래 가족 상세 경로를 시도합니다.
        }

        return try await familyInfo(familyId: familyId).members
    }

    /// 오늘 질문의 가족 구성원을 콕 찌릅니다.
    ///
    /// 가족 답변 목록이 세션 전환 직후의 값으로 남아 있으면 목록의 memberId가
    /// 현재 가족의 ID와 달라질 수 있습니다. 서버가 이 경우 QUESTION404_3을
    /// 반환하므로, 해당 응답에서만 현재 가족 정보를 다시 조회해 같은 닉네임의
    /// 실제 구성원 ID로 한 번 재시도합니다. QUESTION404_3 자체를 중복 전송으로
    /// 처리하지는 않습니다.
    func pokeMember(memberId: Int, familyId: Int? = nil, nickname: String? = nil) async throws {
        do {
            try await sendPoke(to: memberId)
        } catch let error as APIError {
            guard case let .serverError(code, _) = error,
                  code.uppercased() == "QUESTION404_3",
                  let familyId,
                  let nickname,
                  let family = try? await familyInfo(familyId: familyId),
                  let refreshedMember = family.members.first(where: {
                      $0.memberId != memberId && $0.nickname == nickname
                  }) else {
                throw error
            }
            try await sendPoke(to: refreshedMember.memberId)
        }
    }

    private func sendPoke(to memberId: Int) async throws {
        let endpoint = APIEndpoint(path: "/api/v1/questions/today/members/\(memberId)/pokes", method: .POST, requiresAuthentication: true)
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<EmptyAPIResult> = try await client.requestEnvelope(endpoint: endpoint, accessToken: tokens.accessToken)
        guard envelope.isSuccess else { throw APIError.serverError(code: envelope.code, message: envelope.message) }
    }

    func missionFeed(
        category: String? = nil,
        regionCode: String? = nil,
        distance: Int? = nil,
        date: String? = nil,
        time: String? = nil,
        isFree: Bool? = nil,
        maxPrice: Int? = nil,
        cursor: Int? = nil,
        size: Int = 20
    ) async throws -> MissionFeedResult {
        var queryItems = [URLQueryItem(name: "size", value: String(size))]
        if let category { queryItems.append(URLQueryItem(name: "category", value: category)) }
        if let regionCode { queryItems.append(URLQueryItem(name: "regionCode", value: regionCode)) }
        if let distance { queryItems.append(URLQueryItem(name: "distance", value: String(distance)) ) }
        if let date { queryItems.append(URLQueryItem(name: "date", value: date)) }
        if let time { queryItems.append(URLQueryItem(name: "time", value: time)) }
        if let isFree { queryItems.append(URLQueryItem(name: "isFree", value: String(isFree))) }
        if let maxPrice { queryItems.append(URLQueryItem(name: "maxPrice", value: String(maxPrice))) }
        if let cursor { queryItems.append(URLQueryItem(name: "cursor", value: String(cursor)) ) }
#if DEBUG
        // 인증 토큰이나 사용자 입력은 기록하지 않고, 필터 검증에 필요한
        // 실제 GET 쿼리만 남깁니다. URLSession이 보내는 요청과 동일한
        // URLQueryItem 배열이므로 누락·잘못된 이름을 확인할 수 있습니다.
        let debugQuery = queryItems
            .compactMap { item in
                guard let value = item.value else { return item.name }
                return "\(item.name)=\(value)"
            }
            .joined(separator: "&")
        print("[KIRI][Mission] GET /api/v1/missions?\(debugQuery)")
#endif
        let endpoint = APIEndpoint(
            path: "/api/v1/missions",
            method: .GET,
            queryItems: queryItems,
            requiresAuthentication: true
        )
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<MissionFeedResult> = try await client.requestEnvelope(
            endpoint: endpoint,
            accessToken: tokens.accessToken
        )
        guard let result = envelope.result else { throw APIError.decodingFailed }
#if DEBUG
        let freeMatches = isFree.map { free in
            result.missions.filter { (($0.price ?? -1) == 0) == free }.count
        }
        let budgetMatches = maxPrice.map { limit in
            result.missions.filter { ($0.price ?? Int.max) <= limit }.count
        }
        let freeMatchDescription = freeMatches.map { String($0) } ?? "n/a"
        let budgetMatchDescription = budgetMatches.map { String($0) } ?? "n/a"
        print(
            "[KIRI][Mission] response count=\(result.missions.count) "
                + "hasNext=\(result.hasNext) nextCursorPresent=\(result.nextCursor != nil) "
                // 현재 MissionFeedItem 응답에는 지역 필드가 없어 지역 결과의
                // 항목별 일치 여부는 서버 응답 원문/백엔드 로그로 확인해야 합니다.
                + "regionMatches=n/a "
                + "freeMatches=\(freeMatchDescription) "
                + "budgetMatches=\(budgetMatchDescription)"
        )
#endif
        return result
    }

    func missionDetail(missionId: Int) async throws -> MissionDetailResult {
        let endpoint = APIEndpoint(
            path: "/api/v1/missions/\(missionId)",
            method: .GET,
            requiresAuthentication: true
        )
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<MissionDetailResult> = try await client.requestEnvelope(
            endpoint: endpoint,
            accessToken: tokens.accessToken
        )
        guard let result = envelope.result else {
            throw APIError.decodingFailed
        }
        #if DEBUG
        print(
            "[KIRI][Mission] detail decoded: missionId=\(result.missionId), "
                + "bucketState=\(result.bucketState), steps=\(result.steps.count), "
                + "prepareItems=\(result.prepareItems.count)"
        )
        #endif
        return result
    }

    /// 일정이 없는 미션 상세에서도 서버가 계산한 맞춤 준비물을 조회합니다.
    func missionEssentials(missionId: Int) async throws -> [MissionDetailItem] {
        let endpoint = APIEndpoint(
            path: "/api/v1/missions/\(missionId)/essentials",
            method: .GET,
            requiresAuthentication: true
        )
        let tokens = try authenticatedTokens()
        #if DEBUG
        print("[KIRI][Mission] essentials request missionId=\(missionId) tokenPresent=\(!tokens.accessToken.isEmpty)")
        #endif
        let envelope: APIEnvelope<MissionEssentialsResult> = try await client.requestEnvelope(
            endpoint: endpoint,
            accessToken: tokens.accessToken
        )
        guard envelope.isSuccess else {
            #if DEBUG
            print("[KIRI][Mission] essentials response missionId=\(missionId) success=false code=\(envelope.code)")
            #endif
            throw APIError.serverError(code: envelope.code, message: envelope.message)
        }
        guard let result = envelope.result else {
            throw APIError.serverError(code: envelope.code, message: envelope.message)
        }
        #if DEBUG
        print("[KIRI][Mission] essentials response missionId=\(missionId) success=true code=\(envelope.code) resultCount=\(result.items.count)")
        #endif
        return result.items
    }

    /// 현재 로그인 사용자의 알림을 최신순으로 조회합니다.
    func notifications(page: Int = 0, size: Int = 20) async throws -> NotificationPageResult {
        let endpoint = APIEndpoint(
            path: "/api/v1/notifications",
            method: .GET,
            queryItems: [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "size", value: String(size))
            ],
            requiresAuthentication: true
        )
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<NotificationPageResult> = try await client.requestEnvelope(
            endpoint: endpoint,
            accessToken: tokens.accessToken
        )
        guard let result = envelope.result else {
            throw APIError.serverError(code: envelope.code, message: envelope.message)
        }
        #if DEBUG
        print("[KIRI][Notification] GET page=\(page) count=\(result.content.count) hasNext=\(result.hasNext)")
        #endif
        return result
    }

    /// 알림을 읽음 처리합니다. 서버 성공 응답 이후에만 화면 상태를 갱신합니다.
    func markNotificationAsRead(notificationId: Int) async throws {
        let endpoint = APIEndpoint(
            path: "/api/v1/notifications/\(notificationId)/read",
            method: .PATCH,
            requiresAuthentication: true
        )
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<EmptyAPIResult> = try await client.requestEnvelope(
            endpoint: endpoint,
            accessToken: tokens.accessToken
        )
        guard envelope.isSuccess else {
            throw APIError.serverError(code: envelope.code, message: envelope.message)
        }
    }

    /// 홈의 알림 점은 페이지에 잘린 로컬 상태가 아니라 서버 목록을 기준으로
    /// 계산합니다. 별도 unread-count 계약이 없는 현재 서버에서는 페이지를
    /// 끝까지 읽어 전체 미읽음 수를 계산합니다.
    func unreadNotificationsCount() async throws -> Int {
        var page = 0
        var count = 0
        var hasNext = true
        while hasNext {
            let result = try await notifications(page: page)
            count += result.content.filter { !$0.isRead }.count
            hasNext = result.hasNext
            page += 1
        }
        return count
    }

    func saveMissionToBucket(missionId: Int) async throws -> BucketSaveResult {
        let endpoint = APIEndpoint(
            path: "/api/v1/missions/\(missionId)/bucket",
            method: .POST,
            requiresAuthentication: true
        )
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<BucketSaveResult> = try await client.requestEnvelope(
            endpoint: endpoint,
            accessToken: tokens.accessToken
        )
        guard let result = envelope.result else { throw APIError.decodingFailed }
        return result
    }

    func bucketItems(memberId: Int? = nil, cursor: Int? = nil, size: Int = 20) async throws -> BucketListResult {
        var queryItems = [URLQueryItem(name: "size", value: String(size))]
        if let memberId { queryItems.append(URLQueryItem(name: "memberId", value: String(memberId))) }
        if let cursor { queryItems.append(URLQueryItem(name: "cursor", value: String(cursor))) }
        let endpoint = APIEndpoint(
            path: "/api/v1/bucket-items",
            method: .GET,
            queryItems: queryItems,
            requiresAuthentication: true
        )
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<BucketListResult> = try await client.requestEnvelope(
            endpoint: endpoint,
            accessToken: tokens.accessToken
        )
        guard let result = envelope.result else { throw APIError.decodingFailed }
        #if DEBUG
        print("[KIRI][Record] bucket response count=\(result.bucketItems.count) hasNext=\(result.hasNext)")
        #endif
        return result
    }

    func deleteBucketItem(bucketItemId: Int) async throws {
        let endpoint = APIEndpoint(
            path: "/api/v1/bucket-items/\(bucketItemId)",
            method: .DELETE,
            requiresAuthentication: true
        )
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<EmptyAPIResult> = try await client.requestEnvelope(
            endpoint: endpoint,
            accessToken: tokens.accessToken
        )
        guard envelope.isSuccess else {
            throw APIError.serverError(code: envelope.code, message: envelope.message)
        }
    }

    /// 미션 ID만 알고 있는 상세 화면에서 버킷 항목을 해제합니다.
    /// 삭제 API는 bucketItemId를 요구하므로 서버 목록을 조회해 실제 항목 ID를
    /// 찾은 뒤 삭제합니다. 목록에 없는 항목을 로컬에서 삭제된 것처럼 처리하지 않습니다.
    func removeMissionFromBucket(missionId: Int) async throws {
        var cursor: Int?
        while true {
            let page = try await bucketItems(cursor: cursor)
            if let item = page.bucketItems.first(where: { $0.mission.missionId == missionId }) {
                guard item.deletable else {
                    throw APIError.serverError(code: "BUCKET403_2", message: "이 버킷은 삭제할 수 없어요.")
                }
                try await deleteBucketItem(bucketItemId: item.bucketItemId)
                return
            }
            guard page.hasNext, let nextCursor = page.nextCursor, nextCursor != cursor else { break }
            cursor = nextCursor
        }
        throw APIError.serverError(code: "BUCKET404_1", message: "저장된 버킷을 찾을 수 없어요.")
    }

    func createSchedule(bucketItemId: Int, request: CreateScheduleRequest) async throws -> ScheduleResult {
        let endpoint = APIEndpoint(path: "/api/v1/bucket-items/\(bucketItemId)/schedules", method: .POST, requiresAuthentication: true)
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<ScheduleResult> = try await client.requestEnvelope(endpoint: endpoint, body: request, accessToken: tokens.accessToken)
        guard let result = envelope.result else { throw APIError.decodingFailed }
        return result
    }

    func createSchedule(missionId: Int, request: CreateScheduleRequest) async throws -> ScheduleResult {
        let endpoint = APIEndpoint(
            path: "/api/v1/missions/\(missionId)/schedules",
            method: .POST,
            requiresAuthentication: true
        )
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<ScheduleResult> = try await client.requestEnvelope(
            endpoint: endpoint,
            body: request,
            accessToken: tokens.accessToken
        )
        guard let result = envelope.result else { throw APIError.decodingFailed }
        return result
    }

    func calendar(year: Int, month: Int) async throws -> CalendarResult {
        let endpoint = APIEndpoint(path: "/api/v1/schedules/calendar", queryItems: [
            URLQueryItem(name: "year", value: String(year)), URLQueryItem(name: "month", value: String(month))
        ], requiresAuthentication: true)
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<CalendarResult> = try await client.requestEnvelope(endpoint: endpoint, accessToken: tokens.accessToken)
        guard let result = envelope.result else { throw APIError.decodingFailed }
        return result
    }

    func upcomingSchedules() async throws -> UpcomingScheduleResult {
        let endpoint = APIEndpoint(path: "/api/v1/schedules/upcoming", requiresAuthentication: true)
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<UpcomingScheduleResult> = try await client.requestEnvelope(endpoint: endpoint, accessToken: tokens.accessToken)
        guard let result = envelope.result else { throw APIError.decodingFailed }
        return result
    }

    func scheduleConditions(scheduleId: Int) async throws -> ScheduleConditionsResult {
        let endpoint = APIEndpoint(
            path: "/api/v1/schedules/\(scheduleId)/conditions",
            requiresAuthentication: true
        )
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<ScheduleConditionsResult> = try await client.requestEnvelope(
            endpoint: endpoint,
            accessToken: tokens.accessToken
        )
        guard let result = envelope.result else { throw APIError.decodingFailed }
        return result
    }

    func updateScheduleConditions(scheduleId: Int, conditions: [String]) async throws {
        let endpoint = APIEndpoint(
            path: "/api/v1/schedules/\(scheduleId)/conditions",
            method: .PUT,
            requiresAuthentication: true
        )
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<EmptyAPIResult> = try await client.requestEnvelope(
            endpoint: endpoint,
            body: UpdateScheduleConditionsRequest(conditions: conditions),
            accessToken: tokens.accessToken
        )
        guard envelope.isSuccess else {
            throw APIError.serverError(code: envelope.code, message: envelope.message)
        }
    }

    func nearbyMissions(scheduleId: Int) async throws -> [NearbyMissionResult] {
        let endpoint = APIEndpoint(path: "/api/v1/schedules/\(scheduleId)/nearby", requiresAuthentication: true)
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<[NearbyMissionResult]> = try await client.requestEnvelope(endpoint: endpoint, accessToken: tokens.accessToken)
        guard let result = envelope.result else { throw APIError.decodingFailed }
        return result
    }

    /// 일정 없이 미션의 장소를 기준으로 주변 놀거리를 조회합니다.
    func nearbyMissions(missionId: Int) async throws -> [NearbyMissionResult] {
        let endpoint = APIEndpoint(path: "/api/v1/missions/\(missionId)/nearby", requiresAuthentication: true)
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<[NearbyMissionResult]> = try await client.requestEnvelope(
            endpoint: endpoint,
            accessToken: tokens.accessToken
        )
        guard let result = envelope.result else {
            throw APIError.serverError(code: envelope.code, message: envelope.message)
        }
        return result
    }

    func familyRecommendation() async throws -> FamilyRecommendationResult? {
        let endpoint = APIEndpoint(path: "/api/v1/missions/recommendations", requiresAuthentication: true)
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<FamilyRecommendationResult> = try await client.requestEnvelope(endpoint: endpoint, accessToken: tokens.accessToken)
        guard envelope.isSuccess else { throw APIError.serverError(code: envelope.code, message: envelope.message) }
        return envelope.result
    }

    /// 기록탭 일정 상세를 서버에서 다시 확인합니다.
    func scheduleDetail(scheduleId: Int) async throws -> ScheduleDetailResult {
        let endpoint = APIEndpoint(path: "/api/v1/schedules/\(scheduleId)", requiresAuthentication: true)
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<ScheduleDetailResult> = try await client.requestEnvelope(
            endpoint: endpoint,
            accessToken: tokens.accessToken
        )
        guard let result = envelope.result else { throw APIError.decodingFailed }
        #if DEBUG
        print("[KIRI][Record] schedule detail loaded id=\(scheduleId) status=\(result.status ?? "unknown")")
        #endif
        return result
    }

    func updateSchedule(scheduleId: Int, request: UpdateScheduleRequest) async throws -> ScheduleResult {
        let endpoint = APIEndpoint(path: "/api/v1/schedules/\(scheduleId)", method: .PATCH, requiresAuthentication: true)
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<ScheduleResult> = try await client.requestEnvelope(endpoint: endpoint, body: request, accessToken: tokens.accessToken)
        guard let result = envelope.result else { throw APIError.decodingFailed }
        return result
    }

    func respondToSchedule(scheduleId: Int, action: ScheduleResponseAction) async throws -> ScheduleResult {
        let endpoint = APIEndpoint(path: "/api/v1/schedules/\(scheduleId)/response", method: .PATCH, requiresAuthentication: true)
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<ScheduleResult> = try await client.requestEnvelope(endpoint: endpoint, body: ScheduleResponseRequest(action: action), accessToken: tokens.accessToken)
        guard let result = envelope.result else { throw APIError.decodingFailed }
        NotificationCenter.default.post(name: .kiriScheduleDidChange, object: nil, userInfo: ["scheduleId": scheduleId])
        return result
    }

    func cancelSchedule(scheduleId: Int) async throws -> ScheduleResult {
        let endpoint = APIEndpoint(path: "/api/v1/schedules/\(scheduleId)/cancel", method: .PATCH, requiresAuthentication: true)
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<ScheduleResult> = try await client.requestEnvelope(endpoint: endpoint, accessToken: tokens.accessToken)
        guard let result = envelope.result else { throw APIError.decodingFailed }
        NotificationCenter.default.post(name: .kiriScheduleDidChange, object: nil, userInfo: ["scheduleId": scheduleId])
        return result
    }


    func issuePresignedURL(contentType: String, contentLength: Int64) async throws -> PresignedURLResult {
        let endpoint = APIEndpoint(path: "/api/v1/images/presigned-url", method: .POST, requiresAuthentication: true)
        let tokens = try authenticatedTokens()
        let body = PresignedURLRequest(contentType: contentType, contentLength: contentLength)
        let envelope: APIEnvelope<PresignedURLResult> = try await client.requestEnvelope(endpoint: endpoint, body: body, accessToken: tokens.accessToken)
        guard let result = envelope.result else { throw APIError.decodingFailed }
        return result
    }

    /// 인증된 사용자의 건의를 서버에 등록합니다. 사진 업로드가 끝난 뒤 imageKey를 전달합니다.
    func createSuggestion(content: String, imageKey: String?) async throws -> SuggestionCreateResult {
        let endpoint = APIEndpoint(
            path: "/api/v1/suggestions",
            method: .POST,
            requiresAuthentication: true
        )
        let tokens = try authenticatedTokens()
        let body = SuggestionCreateRequest(content: content, imageKey: imageKey)
        let envelope: APIEnvelope<SuggestionCreateResult> = try await client.requestEnvelope(
            endpoint: endpoint,
            body: body,
            accessToken: tokens.accessToken
        )
        guard let result = envelope.result else { throw APIError.decodingFailed }
        return result
    }

    func recordAppEvent(_ event: AppEventRequest) async throws {
        let endpoint = APIEndpoint(path: "/api/v1/events", method: .POST, requiresAuthentication: true)
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<[String: Int]> = try await client.requestEnvelope(
            endpoint: endpoint,
            body: AppEventBatchRequest(events: [event]),
            accessToken: tokens.accessToken
        )
        guard envelope.isSuccess else { throw APIError.serverError(code: envelope.code, message: envelope.message) }
    }

    func uploadImage(data: Data, to presignedURL: URL, contentType: String) async throws {
        var request = URLRequest(url: presignedURL)
        request.httpMethod = "PUT"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        // The server signs the presigned PUT with the original content length.
        // URLSession may otherwise omit it when using upload(for:from:), which
        // makes S3 reject an otherwise valid upload before the review request.
        request.setValue(String(data.count), forHTTPHeaderField: "Content-Length")
        let response: URLResponse
        do { response = try await URLSession.shared.upload(for: request, from: data).1 }
        catch { throw APIError.networkError(error) }
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.httpError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
    }

    func createReview(scheduleId: Int, request: ReviewCreateRequest) async throws -> ReviewCreateResult {
        let endpoint = APIEndpoint(path: "/api/v1/schedules/\(scheduleId)/reviews", method: .POST, requiresAuthentication: true)
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<ReviewCreateResult> = try await client.requestEnvelope(endpoint: endpoint, body: request, accessToken: tokens.accessToken)
        guard let result = envelope.result else { throw APIError.decodingFailed }
        return result
    }

    /// 사진 업로드부터 리뷰 생성·수정, 대표사진 보정까지 모든 리뷰 작성 진입점이
    /// 동일하게 사용하는 서버 저장 경로입니다.
    func saveReview(
        scheduleId: Int,
        rating: Int,
        images: [Data],
        comment: String,
        wantsToRepeat: Bool,
        existingReviewId: Int? = nil
    ) async throws -> ScheduleReviewsResult {
        var imageKeys: [String] = []
        for data in images {
            let contentType = "image/jpeg"
            let presigned = try await issuePresignedURL(
                contentType: contentType,
                contentLength: Int64(data.count)
            )
            try await uploadImage(
                data: data,
                to: presigned.presignedUrl,
                contentType: contentType
            )
            imageKeys.append(presigned.imageKey)
        }

        let request = ReviewCreateRequest(
            starRating: rating,
            imageKeys: imageKeys,
            content: comment,
            isRejoinIntended: wantsToRepeat
        )
        if let existingReviewId {
            _ = try await updateReview(
                scheduleId: scheduleId,
                reviewId: existingReviewId,
                request: request
            )
        } else {
            _ = try await createReview(scheduleId: scheduleId, request: request)
        }

        let latest = try await scheduleReviews(scheduleId: scheduleId)
        let mineReviews = latest.reviews
            .filter { $0.isMine }
            .sorted { $0.createdAt < $1.createdAt }
        let firstPhoto = mineReviews.first.flatMap { $0.photos.first }
        if latest.representativePhotoId == nil, let firstPhoto {
            _ = try? await changeRepresentativePhoto(
                scheduleId: scheduleId,
                reviewPhotoId: firstPhoto.reviewPhotoId
            )
        }
        return latest
    }

    func scheduleReviews(scheduleId: Int) async throws -> ScheduleReviewsResult {
        let endpoint = APIEndpoint(path: "/api/v1/schedules/\(scheduleId)/reviews", requiresAuthentication: true)
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<ScheduleReviewsResult> = try await client.requestEnvelope(endpoint: endpoint, accessToken: tokens.accessToken)
        guard let result = envelope.result else { throw APIError.decodingFailed }
        return result
    }

    func changeRepresentativePhoto(scheduleId: Int, reviewPhotoId: Int) async throws -> RepresentativePhotoResult {
        let endpoint = APIEndpoint(
            path: "/api/v1/schedules/\(scheduleId)/representative-photo",
            method: .PATCH,
            requiresAuthentication: true
        )
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<RepresentativePhotoResult> = try await client.requestEnvelope(
            endpoint: endpoint,
            body: RepresentativePhotoRequest(reviewPhotoId: reviewPhotoId),
            accessToken: tokens.accessToken
        )
        guard let result = envelope.result else { throw APIError.decodingFailed }
        return result
    }

    func updateReview(scheduleId: Int, reviewId: Int, request: ReviewCreateRequest) async throws -> ReviewCreateResult {
        let endpoint = APIEndpoint(path: "/api/v1/schedules/\(scheduleId)/reviews/\(reviewId)", method: .PUT, requiresAuthentication: true)
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<ReviewCreateResult> = try await client.requestEnvelope(endpoint: endpoint, body: request, accessToken: tokens.accessToken)
        guard let result = envelope.result else { throw APIError.decodingFailed }
        return result
    }

    func deleteReview(scheduleId: Int, reviewId: Int) async throws {
        let endpoint = APIEndpoint(path: "/api/v1/schedules/\(scheduleId)/reviews/\(reviewId)", method: .DELETE, requiresAuthentication: true)
        let tokens = try authenticatedTokens()
        _ = try await client.requestEnvelope(endpoint: endpoint, accessToken: tokens.accessToken) as APIEnvelope<EmptyAPIResult>
    }


    /// The current API exposes family membership through the question payload.
    /// No member/family profile lookup endpoint is present in the OpenAPI spec.
    func familyMembership() async throws -> Bool {
        do {
            return try await todayQuestion().hasFamily
        } catch let APIError.serverError(code, _) where code == "QUESTION404_1" {
            // The API uses QUESTION404_1 when the authenticated family has no
            // question assigned today. This is distinct from a successful
            // hasFamily=false response and must not route the user to Browse.
            #if DEBUG
            print("[KIRI][Question] membership confirmed; no question assigned")
            #endif
            return true
        }
    }

    func writeAnswer(questionId: Int, answer: String) async throws {
        try await writeAnswer(questionId: questionId, answerData: Data(answer.utf8))
    }

    /// Saves an answer from an immutable UTF-8 snapshot captured by the UI.
    /// Keeping Data across the async boundary avoids reading mutable SwiftUI
    /// String storage in the request task.
    func writeAnswer(questionId: Int, answerData: Data) async throws {
        let endpoint = APIEndpoint(
            path: "/api/v1/questions/\(questionId)/answers/me",
            method: .PUT,
            requiresAuthentication: true
        )
        let tokens = try authenticatedTokens()
        #if DEBUG
        print("[KIRI][Question] AuthService received answerUTF8Length=\(answerData.count)")
        #endif
        guard let answer = String(data: answerData, encoding: .utf8) else {
            throw APIError.serverError(code: "COMMON400_1", message: "답변을 입력해 주세요.")
        }
        let normalizedAnswer = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedAnswer.isEmpty else {
            throw APIError.serverError(code: "COMMON400_1", message: "답변을 입력해 주세요.")
        }
        #if DEBUG
        print("[KIRI][Question] PUT questionId=\(questionId) answerLength=\(normalizedAnswer.count)")
        #endif
        // Build the JSON bytes before entering URLSession. This request is
        // initiated from a SwiftUI TextEditor task; using a fresh immutable
        // object here avoids sharing the editor's String storage with a
        // generic Encodable encoder across the async boundary.
        let bodyData = try JSONSerialization.data(
            withJSONObject: ["answer": normalizedAnswer],
            options: []
        )
        #if DEBUG
        print("[KIRI][Question] bodyKeys=answer bodyBytes=\(bodyData.count)")
        #endif
        let _: APIEnvelope<EmptyAPIResult> = try await client.requestEnvelope(
            endpoint: endpoint,
            bodyData: bodyData,
            accessToken: tokens.accessToken
        )
    }

    func clearSession() throws {
        try tokenStore.clear()
    }

    private func authenticatedTokens() throws -> AuthTokens {
        guard let tokens = try tokenStore.read() else {
            throw AuthServiceError.missingStoredSession
        }
        return tokens
    }
}
