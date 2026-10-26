
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

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let envelope = try? decoder.decode(
                APIEnvelope<EmptyAPIResult>.self,
                from: data
            ) {
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
}
