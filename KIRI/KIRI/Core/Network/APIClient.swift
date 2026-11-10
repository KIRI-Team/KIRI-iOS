//
// MARK: - 파일 가이드
// 파일: Core/Network/APIClient.swift
// 담당 영역: 공통 컴포넌트·디자인 시스템·네트워크·저장소
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//


import Foundation

extension Notification.Name {
    /// refresh token까지 만료되어 현재 세션을 재인증해야 할 때 발생합니다.
    static let kiriAuthenticationExpired = Notification.Name("kiri.authenticationExpired")
}

final class APIClient {
    static let shared = APIClient()

    private let session: URLSession

    private init() {
        self.session = URLSession.shared
    }

    func request<Response: Decodable>(
        endpoint: APIEndpoint,
        accessToken: String? = nil
    ) async throws -> Response {
        return try await requestImpl(
            endpoint: endpoint,
            bodyData: nil,
            accessToken: accessToken
        )
    }

    func request<Response: Decodable, Body: Encodable>(
        endpoint: APIEndpoint,
        body: Body,
        accessToken: String? = nil
    ) async throws -> Response {
        // Encode the value before entering the async request pipeline. This keeps
        // the request payload independent from the caller's object lifetime and
        // prevents an existential/body value from crossing an async boundary.
        let bodyData = try JSONEncoder().encode(body)
        return try await requestImpl(
            endpoint: endpoint,
            bodyData: bodyData,
            accessToken: accessToken
        )
    }

    private func requestImpl<Response: Decodable>(
        endpoint: APIEndpoint,
        bodyData: Data?,
        accessToken: String?
    ) async throws -> Response {
        // APIClient.shared는 여러 화면의 Task에서 동시에 사용됩니다.
        // JSONEncoder/JSONDecoder는 요청 간 공유하지 않고 요청마다 생성해야
        // 인코딩·디코딩 중 내부 상태가 다른 요청과 경합하지 않습니다.
        let responseDecoder = JSONDecoder()
        let request = try makeRequest(
            endpoint: endpoint,
            bodyData: bodyData,
            accessToken: accessToken
        )

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        #if DEBUG
        if endpoint.path.contains("/terms")
            || endpoint.path == "/api/v1/members/nickname"
            || endpoint.path == "/api/v1/families"
            || endpoint.path.contains("/api/v1/questions")
            || endpoint.path.contains("/api/v1/missions")
            || endpoint.path.contains("/api/v1/bucket-items") {
            print(
                "[KIRI][API] \(endpoint.method.rawValue) \(endpoint.path) "
                    + "status=\(httpResponse.statusCode)"
            )
        }
        if endpoint.path == "/api/v1/terms" {
            logTermsResultShape(data)
        }
        #endif

        if httpResponse.statusCode == 401 {
            #if DEBUG
            if let envelope = try? responseDecoder.decode(
                APIEnvelope<EmptyAPIResult>.self,
                from: data
            ) {
                print(
                    "[KIRI][API] auth failure: "
                        + "code=\(envelope.code), message=\(envelope.message)"
                )
            }
            #endif
            #if DEBUG
            if endpoint.path.contains("/terms") {
                print("[KIRI][Terms] response status=401")
            }
            #endif
            // 만료된 access token은 공통 갱신 게이트를 통과해 한 번만
            // 재발급한 뒤, 실패했던 원래 요청을 한 번만 재시도합니다.
            // 재발급 endpoint 자체는 다시 갱신하지 않아 무한 루프를 막습니다.
            if endpoint.requiresAuthentication,
               endpoint.path != "/api/v1/auth/reissue",
               let accessToken,
               !accessToken.isEmpty {
                let refreshed: AuthTokens
                do {
                    refreshed = try await AuthRefreshCoordinator.shared.refreshIfNeeded(
                        failedAccessToken: accessToken,
                        session: session,
                        encoder: JSONEncoder(),
                        decoder: JSONDecoder()
                    )
                } catch let refreshError as APIError {
                    if case .unauthorized = refreshError {
                        NotificationCenter.default.post(name: .kiriAuthenticationExpired, object: nil)
                    }
                    throw refreshError
                }
                let retryRequest = try makeRequest(
                    endpoint: endpoint,
                    bodyData: bodyData,
                    accessToken: refreshed.accessToken
                )
                do {
                    let (retryData, retryResponse) = try await session.data(for: retryRequest)
                    guard let retryHTTP = retryResponse as? HTTPURLResponse else {
                        throw APIError.invalidResponse
                    }
                    guard retryHTTP.statusCode != 401 else {
                        throw APIError.unauthorized
                    }
                    guard (200...299).contains(retryHTTP.statusCode) else {
                        if let envelope = try? responseDecoder.decode(APIEnvelope<EmptyAPIResult>.self, from: retryData) {
                            throw APIError.serverError(code: envelope.code, message: envelope.message)
                        }
                        throw APIError.httpError(statusCode: retryHTTP.statusCode)
                    }
                    do {
                        return try responseDecoder.decode(Response.self, from: retryData)
                    } catch {
                        throw APIError.decodingFailed
                    }
                } catch let error as APIError {
                    throw error
                } catch {
                    throw APIError.networkError(error)
                }
            }

            throw APIError.unauthorized
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let envelope = try? responseDecoder.decode(
                APIEnvelope<EmptyAPIResult>.self,
                from: data
            ) {
                #if DEBUG
                if endpoint.path == "/api/v1/auth/login"
                    || endpoint.path == "/api/v1/families"
                    || endpoint.path.contains("/api/v1/questions")
                    || endpoint.path.contains("/api/v1/missions")
            || endpoint.path.contains("/api/v1/schedules") {
                    print(
                        "[KIRI][API] auth failure: "
                            + "code=\(envelope.code), message=\(envelope.message)"
                    )
                }
                #endif
                #if DEBUG
                if endpoint.path.contains("/terms") {
                    print("[KIRI][Terms] response status=\(httpResponse.statusCode), code=\(envelope.code), message=\(envelope.message)")
                }
                #endif
                throw APIError.serverError(
                    code: envelope.code,
                    message: envelope.message
                )
            }

            throw APIError.httpError(
                statusCode: httpResponse.statusCode
            )
        }

        do {
            return try responseDecoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decodingFailed
        }
    }

    func requestEnvelope<Response: Decodable>(
        endpoint: APIEndpoint,
        accessToken: String? = nil
    ) async throws -> APIEnvelope<Response> {
        try await request(
            endpoint: endpoint,
            accessToken: accessToken
        )
    }

    func requestEnvelope<Response: Decodable, Body: Encodable>(
        endpoint: APIEndpoint,
        body: Body,
        accessToken: String? = nil
    ) async throws -> APIEnvelope<Response> {
        try await request(
            endpoint: endpoint,
            body: body,
            accessToken: accessToken
        )
    }

    private func makeRequest(
        endpoint: APIEndpoint,
        bodyData: Data?,
        accessToken: String?
    ) throws -> URLRequest {
        let baseURL = APIConfig.baseURL

        let normalizedPath = endpoint.path.hasPrefix("/")
            ? String(endpoint.path.dropFirst())
            : endpoint.path

        guard !normalizedPath.contains("://"),
              !normalizedPath.hasPrefix("//"),
              !normalizedPath.contains("?"),
              !normalizedPath.contains("#"),
              !normalizedPath.contains("..") else {
            throw APIError.invalidURL
        }

        let url = baseURL.appendingPathComponent(normalizedPath)

        guard var components = URLComponents(
            url: url,
            resolvingAgainstBaseURL: false
        ) else {
            throw APIError.invalidURL
        }

        if !endpoint.queryItems.isEmpty {
            components.queryItems = endpoint.queryItems
        }

        guard let finalURL = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: finalURL)
        // Android's OkHttp client has no response cache configured. Avoid reusing
        // a stale terms response from URLSession's shared cache as well.
        request.cachePolicy = .reloadIgnoringLocalCacheData

        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = 30

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )

        if endpoint.requiresAuthentication {
            guard let accessToken,
                  !accessToken.isEmpty else {
                throw APIError.unauthorized
            }

            request.setValue(
                "Bearer \(accessToken)",
                forHTTPHeaderField: "Authorization"
            )
        }

        if let bodyData {
            request.httpBody = bodyData

            request.setValue(
                "application/json",
                forHTTPHeaderField: "Content-Type"
            )
        }

        return request
    }

    #if DEBUG
    private func logTermsResultShape(_ data: Data) {
        guard let object = try? JSONSerialization.jsonObject(with: data),
              let envelope = object as? [String: Any] else {
            print("[KIRI][Terms] raw result shape=invalid-json")
            return
        }
        guard let result = envelope["result"] else {
            print("[KIRI][Terms] raw result shape=missing")
            return
        }
        if let array = result as? [Any] {
            print("[KIRI][Terms] raw result shape=array count=\(array.count)")
        } else if result is NSNull {
            print("[KIRI][Terms] raw result shape=null")
        } else {
            print("[KIRI][Terms] raw result shape=\(String(describing: type(of: result)))")
        }
    }
    #endif
}

/// 여러 API가 동시에 401을 받아도 refresh token 재발급을 한 번만 수행합니다.
/// 마지막으로 갱신된 access token이 실패한 요청의 토큰과 다르면 재발급 결과를 재사용합니다.
private actor AuthRefreshCoordinator {
    static let shared = AuthRefreshCoordinator()

    private var lastRefreshedAccessToken: String?

    func refreshIfNeeded(
        failedAccessToken: String,
        session: URLSession,
        encoder: JSONEncoder,
        decoder: JSONDecoder
    ) async throws -> AuthTokens {
        guard let stored = try KeychainAuthTokenStore.shared.read(),
              let refreshToken = stored.refreshToken,
              !refreshToken.isEmpty else {
            throw APIError.unauthorized
        }

        if let lastRefreshedAccessToken,
           lastRefreshedAccessToken != failedAccessToken,
           stored.accessToken == lastRefreshedAccessToken {
            return stored
        }

        let normalizedPath = "api/v1/auth/reissue"
        let url = APIConfig.baseURL.appendingPathComponent(normalizedPath)
        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.POST.rawValue
        request.timeoutInterval = 30
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(TokenReissueRequest(refreshToken: refreshToken))

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            if http.statusCode == 401 {
                throw APIError.unauthorized
            }
            if let envelope = try? decoder.decode(APIEnvelope<EmptyAPIResult>.self, from: data) {
                throw APIError.serverError(code: envelope.code, message: envelope.message)
            }
            throw APIError.httpError(statusCode: http.statusCode)
        }
        let envelope: APIEnvelope<TokenReissueResult>
        do {
            envelope = try decoder.decode(APIEnvelope<TokenReissueResult>.self, from: data)
        } catch {
            throw APIError.decodingFailed
        }
        guard let result = envelope.result else {
            throw APIError.serverError(code: envelope.code, message: envelope.message)
        }
        let refreshed = AuthTokens(
            accessToken: result.accessToken,
            refreshToken: result.refreshToken,
            expiresAt: nil
        )
        try KeychainAuthTokenStore.shared.save(refreshed)
        lastRefreshedAccessToken = refreshed.accessToken
        return refreshed
    }
}
