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
        let _: APIEnvelope<EmptyAPIResult> = try await client.requestEnvelope(
            endpoint: endpoint,
            accessToken: tokens.accessToken
        )
    }

    func updateNickname(_ nickname: String) async throws -> NicknameUpdateResult {
        let endpoint = APIEndpoint(
            path: "/api/v1/members/nickname",
            method: .PATCH,
            requiresAuthentication: true
        )
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<NicknameUpdateResult> = try await client.requestEnvelope(
            endpoint: endpoint,
            body: NicknameUpdateRequest(nickname: nickname),
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

    func createFamily(name: String) async throws -> CreateFamilyResult {
        let endpoint = APIEndpoint(
            path: "/api/v1/families",
            method: .POST,
            requiresAuthentication: true
        )
        let tokens = try authenticatedTokens()
        let envelope: APIEnvelope<CreateFamilyResult> = try await client.requestEnvelope(
            endpoint: endpoint,
            body: CreateFamilyRequest(name: name),
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
        let envelope: APIEnvelope<FamilyNameUpdateResult> = try await client.requestEnvelope(
            endpoint: endpoint,
            body: UpdateFamilyNameRequest(name: name),
            accessToken: tokens.accessToken
        )
        guard let result = envelope.result else { throw APIError.decodingFailed }
        return result
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
        print("[KIRI][Mission] response count=\(result.missions.count) hasNext=\(result.hasNext) nextCursorPresent=\(result.nextCursor != nil)")
#endif
        return result
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
        let endpoint = APIEndpoint(
            path: "/api/v1/questions/\(questionId)/answers/me",
            method: .PUT,
            requiresAuthentication: true
        )
        let tokens = try authenticatedTokens()
        let _: APIEnvelope<EmptyAPIResult> = try await client.requestEnvelope(
            endpoint: endpoint,
            body: WriteAnswerRequest(answer: answer),
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
