# 미션 상세 주변 놀거리 추천 API 조사 및 계약 제안

- 조사 시각: 2026-11-13 KST
- 기준 브랜치: `develop` (`058e2c44428b389c9f786d2748ad55bbd00ff26b`)
- Figma: `9901:24342`

이번 재조사에서는 접근 가능한 `KIRI-SERVER` 저장소 `develop`
(`805bb307fc82b8644853183c9d3784de114ed3da`)의 Controller·Service·DTO까지
대조했다.

## 조사 결과

Swagger 원본은 Basic 인증으로 차단되어 있지만, 접근 가능한 최신 백엔드 저장소의
Controller·Service·DTO를 직접 확인했다. 해당 저장소 기준으로는 일정 없이 미션 장소를
기준으로 조회하는 nearby endpoint가 없다.

| 자료 | 확인 결과 |
|---|---|
| 최신 Swagger UI | 접근 시 HTTP 401 (`Basic realm="KIRI dev"`) |
| 최신 `/v3/api-docs` | 접근 시 HTTP 401 (`Basic realm="KIRI dev"`) |
| 저장된 OpenAPI 조사 보고서 | 2026-11-01 인증 스냅샷 기준 29 paths/33 operations. 해당 스냅샷에는 `nearby`, `recommendation`, `places` 전용 operation 없음 |
| 백엔드 `MissionController` | `GET /api/v1/missions`, `GET /api/v1/missions/{missionId}`, `GET /api/v1/missions/recommendations`만 제공. 미션/장소 기준 nearby operation 없음 |
| 백엔드 `ScheduleController` | `GET /api/v1/schedules/{scheduleId}/nearby`만 제공. `scheduleId`가 필수 |
| 백엔드 `ScheduleResDTO.NearbyItem` | `placeName`, `region`, `description`, `imageUrl`, `price`만 반환하며 `missionId`·`placeId`가 없음 |
| iOS `AuthService` | 미션 상세는 `GET /api/v1/missions/{missionId}`, 주변 추천은 일정 상세의 `GET /api/v1/schedules/{scheduleId}/nearby`만 호출 |
| iOS `MissionDetailResult` | `place`와 좌표(`latitude`, `longitude`)는 있으나 주변 추천 배열·추천 이유 필드 없음 |
| iOS `MissionActivityDetailView` | 추천 영역은 서버 카드가 아닌 빈 상태 안내만 표시하며 주변 장소 호출 없음 |
| Android 저장소 | 접근 가능한 로컬 checkout의 `MissionApi` 상세 응답에도 nearby/custom 필드가 없고 nearby Retrofit endpoint가 검색되지 않음. 이것만으로 서버 API 부재를 확정하지 않음 |

`GET /api/v1/schedules/{scheduleId}/nearby`는 백엔드 구현과 iOS 일정 상세 화면에 연결되어
있으며, `scheduleId`가 필수이므로 일정 없이 미션 상세에서 호출할 수 없다. 응답에도
`missionId`·`placeId`가 없어 현재 카드에서 미션 상세로 이동할 식별자도 제공하지 않는다.

`GET /api/v1/missions/{missionId}`의 백엔드 상세 DTO에는 미션·장소 정보만 있고 주변 추천 배열이
없다. `GET /api/v1/missions/recommendations`는 가족 취향 기반 단일 추천이며 기준 장소 주변
목록 API가 아니므로 미션 상세의 nearby로 재사용하지 않는다.

`/api/v1/schedules/{scheduleId}/nearby`가 실제 서버 계약이라면 일정 상세 화면에서만
실제 `scheduleId`를 전달해 호출해야 하며, `missionId`나 `placeId`로 대체해서는 안 된다.
다음 자료를 백엔드에서 받아야 iOS 연동을 시작할 수 있다: 인증 요구사항, 쿼리·페이지네이션,
성공 응답 JSON, 추천 카드의 상세 이동 ID, 빈 결과·오류 코드.

## 백엔드 계약 제안

실제 경로와 필드명은 백엔드 합의 전까지 확정하지 않는다. 아래는 필요한 의미를 정의한 제안이다.

### 목적

현재 상세 페이지의 미션 장소를 기준으로 주변의 활성 놀거리 또는 미션을 조회한다. 사용자의 현재 GPS 위치는 사용하지 않는다.

### 요청에 필요한 값

- 기준 `missionId` 또는 `placeId` 중 하나(둘 다 받을 경우 서버의 기준 우선순위 명시)
- 장소 좌표가 서버에 없을 때만 `latitude`, `longitude`를 사용할지 여부
- `radius`와 단위(미터 또는 킬로미터)
- `limit` 및 커서 기반 `cursor`(페이지네이션이 필요한 경우)

### 서버 정책 확인 질문

1. 반경의 기본값과 최대값은 무엇인가?
2. 현재 미션 자체와 동일 `placeId`를 제외하는가?
3. 비활성·운영 종료 미션을 제외하는가?
4. 거리순, 추천순, 운영 상태순 중 어떤 정렬을 사용하는가?
5. 장소 추천과 미션 추천을 같은 결과로 취급하는가?
6. 추천 이유를 서버가 생성하는가, iOS가 표시하지 않아야 하는가?
7. 이미지가 없을 때 응답을 생략하는가, 공통 placeholder 정책을 사용하는가?
8. 빈 결과와 권한·인증 오류의 응답 코드는 무엇인가?

### 제안 응답 의미

응답에는 최소한 다음 정보가 필요하다.

- `placeId` 또는 `missionId`
- 대표 이미지 URL(선택)
- 장소명
- 지역 또는 주소에서 사용할 표시 지역
- 거리(선택)
- 서버가 제공하는 추천 이유(선택)
- 상세 화면 이동에 필요한 식별자
- 다음 페이지 커서와 `hasNext`(페이지네이션을 제공할 경우)

추천 이유와 이미지는 서버가 제공하지 않는 한 iOS에서 생성하거나 Figma 샘플을 재사용하지 않는다.

## iOS 연동 계획

계약이 확정되면 기능 브랜치에서 다음 순서로 연결한다.

1. 응답 DTO와 오류 코드를 계약 그대로 추가
2. `AuthService`에 인증된 GET 호출 추가
3. 상세 응답의 `place.placeId`를 기준으로 요청하고, 미션 변경 시 이전 요청을 취소하거나 결과를 무시
4. 로딩·성공·빈 결과·오류 상태를 분리
5. Figma의 약 251×284pt 가로 스크롤 카드에 서버 이미지·장소명·지역·추천 이유만 표시
6. 카드 선택 시 응답의 missionId/placeId로 상세 화면 이동
7. 실제 인증 응답과 iPhone 17 Pro 렌더링을 별도로 검증

현재는 계약이 없으므로 미션 상세용 nearby DTO·Service·View 호출을 추가하지 않았다.
`MissionActivityDetailView`는 허위 추천 카드 대신 기존 계약으로 제공되는 맞춤 추천/미지원 상태만
표시한다. 일정 상세의 nearby 호출은 기존 `scheduleId` 경로를 그대로 유지한다.

## 백엔드 또는 Swagger 접근에 필요한 자료

현재 `https://kiri-dev.halo-app.co.kr/v3/api-docs`와 Swagger UI는
`HTTP 401 Basic realm="KIRI dev"`를 반환한다. iOS Bearer 토큰은 Swagger Basic 인증을 대체하지 않는다.
조사를 재개하려면 다음 중 하나가 필요하다.

- 개발 서버 Swagger Basic 인증의 사용자명·비밀번호를 안전한 비공개 경로로 제공
- 인증된 OpenAPI JSON 파일 또는 Controller/DTO/응답 예시 공유
- 접근 가능한 백엔드 저장소의 추천 Controller·DTO·Enum 경로

인증정보는 로그·소스·커밋에 기록하지 않는다.

## 백엔드 요청 자료

- 최신 Swagger 또는 인증된 OpenAPI JSON
- 주변 추천 Controller/Service/DTO와 enum
- 요청 경로·쿼리·응답 예시(JSON)
- 반경·제외·정렬·페이지네이션 정책
- 이미지 URL의 사용 권한과 만료 정책
- 인증·빈 결과·오류 코드 정의

현재 백엔드에 필요한 추가 계약은 다음과 같다.

- 일정 생성 전 미션 상세에서 사용할 `GET` endpoint와 기준 식별자(`missionId` 또는 `placeId`)
- 반경·정렬·현재 미션/장소 제외 정책
- 카드 표시용 `missionId` 또는 `placeId`, 이미지, 장소명, 지역/주소, 거리, 서버 추천 이유
- 빈 결과·권한·인증 오류 및 페이지네이션 계약
