//
// MARK: - 파일 가이드
// 파일: Core/Network/APIError.swift
// 담당 영역: 공통 컴포넌트·디자인 시스템·네트워크·저장소
// 주요 책임: 이 파일의 View·상태·서비스 연결을 담당합니다.
// UI 수정: 이 파일의 body와 private computed view의 frame, padding, spacing, font, color를 확인하세요.
// 데이터 흐름: 상위 라우터/화면에서 상태를 받고 하위 컴포넌트에 전달합니다.
// 주의: 공통 컴포넌트·네트워크·저장소 변경은 여러 화면에 영향을 줄 수 있습니다.
//


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
