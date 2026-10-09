// 어떤 주소에 어떤 http 방식으로 요청할지 정의하는 파일
import Foundation

enum HTTPMethod: String {
    case GET
    case POST
    case PUT
    case PATCH
    case DELETE
}

struct APIEndpoint {
    let path: String
    let method: HTTPMethod
    let queryItems: [URLQueryItem]
    let requiresAuthentication: Bool

    init(
        path: String,
        method: HTTPMethod = .GET,
        queryItems: [URLQueryItem] = [],
        requiresAuthentication: Bool = false
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.requiresAuthentication = requiresAuthentication
    }
}
