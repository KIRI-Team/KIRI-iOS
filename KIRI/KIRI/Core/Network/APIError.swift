
import Foundation

enum APIError: LocalizedError {
    case serverNotConfigured
    case invalidURL
    case invalidResponse
    case unauthorized
    case httpError(statusCode: Int)
    case serverError(code: String, message: String)
    case decodingFailed
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .serverNotConfigured:
            return "서버 주소가 설정되지 않았습니다."

        case .invalidURL:
            return "올바르지 않은 API 주소입니다."

        case .invalidResponse:
            return "서버 응답을 확인할 수 없습니다."

        case .unauthorized:
            return "인증이 필요하거나 로그인 정보가 만료되었습니다."

        case .httpError(let statusCode):
            return "서버 요청에 실패했습니다. (HTTP \(statusCode))"

        case .serverError(_, let message):
            return message

        case .decodingFailed:
            return "서버 응답 데이터를 처리할 수 없습니다."

        case .networkError(let error):
            return "네트워크 오류: \(error.localizedDescription)"
        }
    }
}
