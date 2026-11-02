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

final class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        self.session = URLSession.shared
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    func request<Response: Decodable>(
        endpoint: APIEndpoint,
        body: (any Encodable)? = nil,
        accessToken: String? = nil
    ) async throws -> Response {
        let request = try makeRequest(
            endpoint: endpoint,
            body: body,
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
            if let envelope = try? decoder.decode(
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
            throw APIError.unauthorized
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let envelope = try? decoder.decode(
                APIEnvelope<EmptyAPIResult>.self,
                from: data
            ) {
                #if DEBUG
                if endpoint.path == "/api/v1/auth/login"
                    || endpoint.path == "/api/v1/families"
                    || endpoint.path.contains("/api/v1/questions")
                    || endpoint.path.contains("/api/v1/missions") {
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
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIError.decodingFailed
        }
    }

    func requestEnvelope<Response: Decodable>(
        endpoint: APIEndpoint,
        body: (any Encodable)? = nil,
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
        body: (any Encodable)?,
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

        if let body {
            request.httpBody = try encoder.encode(body)

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
