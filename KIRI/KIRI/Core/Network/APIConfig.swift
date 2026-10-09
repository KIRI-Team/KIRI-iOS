// DEBUG 개발 서버 주소 관리
// Release 주소 확정 전까지 릴리스에서 api 요청 차단
import Foundation

enum APIConfig {
    static var baseURL: URL? {
        #if DEBUG
        return URL(string: "http://54.116.65.215:8080")
        #else
        return nil
        #endif
    }
}
