//
// MARK: - 파일 가이드
// 파일: Core/Network/KakaoLocalGeocoder.swift
// 담당 영역: 카카오 Local 주소 검색 결과를 가족 주소 좌표로 변환합니다.
// 데이터 흐름: AddressSettingsView가 선택한 기본 주소와 우편번호를 전달하면
// 카카오 응답의 x(경도), y(위도)를 검증해 저장 가능한 좌표로 반환합니다.
// 보안: REST 키는 Info.plist의 빌드 설정에서 읽고 로그나 오류 메시지에 포함하지 않습니다.
//

import CoreLocation
import Foundation

enum KakaoLocalGeocoderError: Error {
    case missingAPIKey
    case invalidRequest
    case network
    case noMatchingResult
    case invalidCoordinate
}

struct KakaoLocalGeocoder {
    static let shared = KakaoLocalGeocoder()

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func resolve(address: String, postalCode: String) async throws -> CLLocationCoordinate2D {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "KAKAO_LOCAL_REST_API_KEY") as? String,
              !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !key.hasPrefix("$(") else {
            throw KakaoLocalGeocoderError.missingAPIKey
        }

        var components = URLComponents(string: "https://dapi.kakao.com/v2/local/search/address.json")
        components?.queryItems = [URLQueryItem(name: "query", value: address)]
        guard let url = components?.url else {
            throw KakaoLocalGeocoderError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("KakaoAK \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw KakaoLocalGeocoderError.network
        }

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw KakaoLocalGeocoderError.network
        }

        let payload: KakaoAddressSearchResponse
        do {
            payload = try JSONDecoder().decode(KakaoAddressSearchResponse.self, from: data)
        } catch {
            throw KakaoLocalGeocoderError.invalidRequest
        }

        let document = payload.documents.first { document in
            document.matches(address: address, postalCode: postalCode)
        }
        guard let document,
              let longitude = Double(document.x),
              let latitude = Double(document.y),
              (-180...180).contains(longitude),
              (-90...90).contains(latitude) else {
            throw KakaoLocalGeocoderError.noMatchingResult
        }

        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        guard CLLocationCoordinate2DIsValid(coordinate) else {
            throw KakaoLocalGeocoderError.invalidCoordinate
        }
        return coordinate
    }
}

private struct KakaoAddressSearchResponse: Decodable {
    let documents: [KakaoAddressDocument]
}

private struct KakaoAddressDocument: Decodable {
    let addressName: String
    let x: String
    let y: String
    let address: KakaoAddress?
    let roadAddress: KakaoRoadAddress?

    enum CodingKeys: String, CodingKey {
        case addressName = "address_name"
        case x
        case y
        case address
        case roadAddress = "road_address"
    }

    func matches(address selectedAddress: String, postalCode: String) -> Bool {
        let returnedPostalCodes = [roadAddress?.zoneNo, address?.zipCode].compactMap { $0 }
        if returnedPostalCodes.contains(postalCode) {
            return true
        }

        let selected = normalize(selectedAddress)
        let candidates = [addressName, address?.addressName, roadAddress?.addressName]
            .compactMap { $0 }
            .map(normalize)
        return !selected.isEmpty && candidates.contains { $0 == selected || $0.contains(selected) || selected.contains($0) }
    }

    private func normalize(_ value: String) -> String {
        value.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct KakaoAddress: Decodable {
    let addressName: String
    let zipCode: String?

    enum CodingKeys: String, CodingKey {
        case addressName = "address_name"
        case zipCode = "zip_code"
    }
}

private struct KakaoRoadAddress: Decodable {
    let addressName: String
    let zoneNo: String?

    enum CodingKeys: String, CodingKey {
        case addressName = "address_name"
        case zoneNo = "zone_no"
    }
}
