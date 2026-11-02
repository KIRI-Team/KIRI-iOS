# KIRI iOS API 연동 현황

- 조사 시각: 2026-11-02T00:53:58+09:00 (Asia/Seoul)
- 코드 기준 커밋: `a5182a9f35083d851b25aa623ab90dd230286408`
- `origin/develop`: `348455402c84b30b8dcadde9c6bca504b9816a42`
- OpenAPI 기준: `/tmp/kiri-openapi-latest.json` (2026-11-01 21:22 KST에 확보한 인증 스냅샷, 29 paths/33 operations)
- 최신 URL 재조회 결과: `GET https://kiri-dev.halo-app.co.kr/v3/api-docs`가 HTTP 401을 반환하여 이번 실행에서 서버 원본을 직접 갱신하지 못함. 아래 표는 마지막 인증 스냅샷과 현재 코드의 대조 결과임.

## 전체 현황

| 구분 | Method | API Path | 기능 | 상태 | 연결 화면 | 실서버 검증 | 비고 |
|---|---|---|---|---|---|---|---|
| 질문/답변 | PUT | /api/v1/questions/{questionId}/answers/me | 내 질문 답변 작성·수정 | 연결 완료 | FamilyHomeView | 미검증 | APIEndpoint·WriteAnswer·writeAnswer 호출 및 성공/오류 상태 연결 |
| 취향 | GET | /api/v1/members/taste | 내 취향 조회 | 미연결 | 없음 | 미검증 | Service/DTO/View 호출 없음 |
| 취향 | PUT | /api/v1/members/taste | 내 취향 저장 | 미연결 | 없음 | 미검증 | Service/DTO/View 호출 없음 |
| 약관 | GET | /api/v1/terms/agreements | 약관 동의 상태 조회 | 연결 완료 | AuthFlowView, AppRouter | 미검증 | agreementStatus DTO·인증 요청·오류 처리; 서버 result 빈 배열 이슈는 별도 확인 필요 |
| 약관 | POST | /api/v1/terms/agreements | 약관 동의 저장 | 연결 완료 | AuthFlowView | 미검증 | AgreeTermsRequest(agreements)와 성공 전환/실패 유지 |
| 리뷰/기록 | POST | /api/v1/schedules/{scheduleId}/reviews | 리뷰 작성 | 미연결 | Review 화면(로컬 상태) | 미검증 | 실제 API 호출 없음; 로컬 draft/store 사용 |
| 질문/답변 | POST | /api/v1/questions/today/members/{memberId}/pokes | 가족 구성원 콕 찌르기 | 미연결 | FamilyHomeView(버튼/상태 UI) | 미검증 | Service 호출 및 DTO 없음 |
| 버킷리스트 | POST | /api/v1/missions/{missionId}/bucket | 미션 버킷 저장 | 연결 완료 | MissionView | 미검증 | saveMissionToBucket 호출 및 저장 오류 처리 |
| 이미지 | POST | /api/v1/images/presigned-url | Presigned 업로드 URL 발급 | 미연결 | Record 이미지 UI | 미검증 | 실제 endpoint 호출 없음 |
| 가족공간 | POST | /api/v1/families | 가족공간 생성 | 연결 완료 | OnboardingFlowView, BrowseHomeView | 미검증 | CreateFamilyRequest/Result 및 성공 전환·오류 처리 |
| 일정 | POST | /api/v1/bucket-items/{bucketItemId}/schedules | 버킷 일정 생성/초대 | 미연결 | Record 화면(로컬) | 미검증 | 실제 Service 호출 없음 |
| 인증/토큰 | POST | /api/v1/auth/reissue | 토큰 재발급 | 연결 완료 | AppRouter.restoreSession | 미검증 | Refresh Token 재발급 및 인증 오류 분기 |
| 인증/토큰 | POST | /api/v1/auth/logout | 로그아웃 | 연결 완료 | MyPageView, AccountInfoView, AppRouter | 미검증 | 서버 요청 후 로컬 세션 정리 |
| 인증/토큰 | POST | /api/v1/auth/login | 소셜 로그인 | 연결 완료 | AuthFlowView | 성공 확인 | Google 로그인 HTTP 200은 사용자 테스트 기록; Kakao/Apple 코드는 연결됨 |
| 일정 | PATCH | /api/v1/schedules/{scheduleId} | 일정 수정 | 미연결 | Record 화면(로컬) | 미검증 | 실제 API 호출 없음 |
| 일정 | PATCH | /api/v1/schedules/{scheduleId}/response | 일정 초대 수락/거절 | 미연결 | Record 화면(로컬) | 미검증 | 실제 API 호출 없음 |
| 일정 | PATCH | /api/v1/schedules/{scheduleId}/cancel | 일정 취소 | 미연결 | Record 화면(로컬) | 미검증 | 실제 API 호출 없음 |
| 회원/프로필 | PATCH | /api/v1/members/nickname | 닉네임 설정/수정 | 연결 완료 | OnboardingFlowView, MyPageView/AppRouter | 미검증 | Nickname DTO·저장 후 세션 반영 |
| 회원/프로필 | PATCH | /api/v1/members/family-role | 가족 역할 설정 | 연결 완료 | OnboardingFlowView | 미검증 | SelectFamilyRole DTO·성공 전환/실패 유지 |
| 가족공간 | PATCH | /api/v1/families/{familyId} | 가족명 변경 | 연결 완료 | FamilyNameEditView, RootView/AppRouter | 미검증 | UpdateName DTO 및 familyId 경로 호출 |
| 가족 초대 | GET | /api/v1/families/{familyId}/invite | 초대 코드/링크 조회 | 연결 중 | MyPageSupportViews, FamilyCodeView | 미검증 | 화면은 있으나 현재 Mock 초대값; API 호출 없음 |
| 가족 초대 | DELETE | /api/v1/families/{familyId}/invite | 초대 코드/링크 삭제 | 미연결 | 없음 | 미검증 | endpoint 호출 없음 |
| 가족 초대 | PATCH | /api/v1/families/{familyId}/invite | 초대 코드/링크 생성·재생성 | 미연결 | FamilyCodeView(로컬 흐름) | 미검증 | endpoint 호출 없음 |
| 약관 | GET | /api/v1/terms | 약관 목록 조회 | 연결 완료 | AuthFlowView, AppRouter | 실패 확인 | 코드 연결 및 실패 처리 완료; 사용자 로그에서 HTTP 200/TERM200_1/result=[] 반복 확인 |
| 일정 | GET | /api/v1/schedules/upcoming | 다가오는 일정 조회 | 미연결 | Home/Record 화면(로컬) | 미검증 | 실제 API 호출 없음 |
| 일정 | GET | /api/v1/schedules/calendar | 월간 캘린더 약속 조회 | 미연결 | RecordCalendarView(로컬) | 미검증 | 실제 API 호출 없음 |
| 질문/답변 | GET | /api/v1/questions/{questionId}/answers | 가족 답변 조회 | 연결 중 | FamilyHomeView/FamilyMemberItem | 미검증 | UI 상태 필드는 있으나 가족 답변 endpoint 호출·DTO 없음 |
| 질문/답변 | GET | /api/v1/questions/today | 오늘의 질문 조회 | 연결 완료 | FamilyHomeView, AppRouter | 미검증 | TodayQuestion DTO·로딩/빈/오류/재시도 처리 |
| 미션 | GET | /api/v1/missions | 미션 피드 조회 | 연결 중 | MissionView, FamilyHomeView | 미검증 | 실제 호출·pagination은 연결됐지만 Swagger의 latitude/longitude/date/time/isFree/maxPrice 등 전체 필터는 미구현 |
| 미션 | GET | /api/v1/missions/{missionId} | 미션 상세 조회 | 연결 중 | MissionActivityDetailView | 미검증 | 상세 View는 있으나 목록 응답을 전달하는 로컬 상세; 상세 endpoint 호출 없음 |
| 버킷리스트 | GET | /api/v1/bucket-items | 가족 버킷리스트 조회 | 연결 중 | RecordBucketListView | 미검증 | MissionBucketStore/로컬 목록; GET endpoint 미호출 |
| 회원/프로필 | DELETE | /api/v1/members/me | 회원 탈퇴 | 연결 완료 | MyPageView/AppRouter | 미검증 | deleteAccount 호출, 성공 후 세션 정리; 파괴적 실서버 테스트 미수행 |
| 버킷리스트 | DELETE | /api/v1/bucket-items/{bucketItemId} | 버킷리스트 항목 삭제 | 연결 중 | RecordBucketListView | 미검증 | 로컬 삭제 처리; 서버 DELETE 미호출 |

## 집계

- Swagger operation: **33개** (path 29개)
- 연결 완료: **14개**
- 연결 중: **6개**
- 미연결: **13개**
- 완료 연동률: **42.4%**

### 기능군별

| 기능군 | 전체 | 완료 | 진행 중 | 미연결 | 완료율 |
|---|---:|---:|---:|---:|---:|
| 가족 초대 | 3 | 0 | 1 | 2 | 0.0% |
| 가족공간 | 2 | 2 | 0 | 0 | 100.0% |
| 리뷰/기록 | 1 | 0 | 0 | 1 | 0.0% |
| 미션 | 2 | 1 | 1 | 0 | 50.0% |
| 버킷리스트 | 3 | 1 | 2 | 0 | 33.3% |
| 약관 | 3 | 3 | 0 | 0 | 100.0% |
| 이미지 | 1 | 0 | 0 | 1 | 0.0% |
| 인증/토큰 | 3 | 3 | 0 | 0 | 100.0% |
| 일정 | 6 | 0 | 0 | 6 | 0.0% |
| 질문/답변 | 4 | 2 | 1 | 1 | 50.0% |
| 취향 | 2 | 0 | 0 | 2 | 0.0% |
| 회원/프로필 | 3 | 3 | 0 | 0 | 100.0% |

## 판정 기준 및 코드 근거

- `연결 완료`: OpenAPI operation에 대응하는 endpoint/DTO/service가 있고 실제 SwiftUI 사용자 흐름에서 호출되며 성공·실패 상태를 처리함.
- `연결 중`: 화면 또는 일부 로컬 흐름은 있으나 해당 operation 호출, DTO, 또는 일부 동작이 빠짐.
- `미연결`: 현재 저장소에서 해당 operation 호출을 확인하지 못함.
- endpoint 구현은 `KIRI/KIRI/Core/Network/AuthService.swift`, 호출 화면은 `KIRI/KIRI/Features` 및 `KIRI/KIRI/App/AppRouter.swift`를 기준으로 `rg`와 전체 경로 대조를 수행함.

## Swagger에는 없지만 화면에 필요한 API

| 필요한 기능 | 필요한 화면 | 기존 API 대체 가능성 | 신규 API 필요 | 우선순위 |
|---|---|---|---|---|
| 현재 회원 상세 조회(memberId/nickname/role) | AppRouter·MyPageView | 로그인 응답과 로컬 캐시만으로 재설치 복원 불가 | 필요 | P0 |
| 가족 상세·구성원 목록·membership 상태 | FamilyHomeView·FamilyMemberItem | questions/today의 hasFamily는 소속 여부만 제공 | 필요 | P0 |
| 가족 초대 코드 검증·참여/탈퇴 | FamilyCodeInputView·FamilyJoinConfirmView | 현재 생성/조회 invite API만으로 참여 완료 불가 | 필요 | P0 |
| 알림 목록·읽음·삭제·설정·디바이스 토큰 | NotificationView | 대체 API 없음 | 필요 | P1 |
| 추천 콘텐츠/장소 전용 조회 | HomeView·FamilyHomeView·PlaceCard | missions는 미션 피드이며 별도 콘텐츠 계약 없음 | 확인 필요 | P1 |
| 가족 답변 상세 member metadata | FamilyHomeView·FamilyMemberItem | questions/{id}/answers는 답변만 제공하고 현재 iOS 미호출 | 기존 endpoint 연결 우선 | P1 |

## 우선 연동 대상 10개

1. `GET /api/v1/questions/{questionId}/answers` — 현재 화면 흐름을 서버 데이터와 연결하기 위해 우선 확인/연동
2. `POST /api/v1/questions/today/members/{memberId}/pokes` — 현재 화면 흐름을 서버 데이터와 연결하기 위해 우선 확인/연동
3. `GET /api/v1/families/{familyId}/invite` — 현재 화면 흐름을 서버 데이터와 연결하기 위해 우선 확인/연동
4. `PATCH /api/v1/families/{familyId}/invite` — 현재 화면 흐름을 서버 데이터와 연결하기 위해 우선 확인/연동
5. `GET /api/v1/bucket-items` — 현재 화면 흐름을 서버 데이터와 연결하기 위해 우선 확인/연동
6. `DELETE /api/v1/bucket-items/{bucketItemId}` — 현재 화면 흐름을 서버 데이터와 연결하기 위해 우선 확인/연동
7. `POST /api/v1/bucket-items/{bucketItemId}/schedules` — 현재 화면 흐름을 서버 데이터와 연결하기 위해 우선 확인/연동
8. `GET /api/v1/schedules/upcoming` — 현재 화면 흐름을 서버 데이터와 연결하기 위해 우선 확인/연동
9. `GET /api/v1/schedules/calendar` — 현재 화면 흐름을 서버 데이터와 연결하기 위해 우선 확인/연동
10. `POST /api/v1/images/presigned-url` — 현재 화면 흐름을 서버 데이터와 연결하기 위해 우선 확인/연동

## P0/P1/P2

- **P0**: 가족 구성원·가족 상세/참여 상태 조회(현재 Swagger 부재), 가족 답변 GET 및 콕 찌르기, 초대 참여 계약, 재로그인 시 서버 회원/가족 상태 복원.
- **P1**: 버킷리스트 GET/DELETE 및 일정 생성·수정·응답·취소·캘린더·리뷰, Presigned 이미지, 취향 API, 미션 상세.
- **P2**: 알림함(현재 Swagger에 관련 operation 없음), 추천 콘텐츠/장소 전용 API 및 부가 설정.

## 실서버 검증 현황

- 사용자가 제공한 기록으로 Google 소셜 로그인 `POST /api/v1/auth/login` HTTP 200은 확인됨.
- 약관 목록은 사용자의 시뮬레이터 로그에서 HTTP 200/`TERM200_1`/`result=[]`가 반복되어 **실패 확인**으로 기록함.
- 나머지 operation은 이번 감사에서 서버 요청을 실행하지 않았으므로 **미검증**이며, DELETE 회원탈퇴 같은 파괴적 API는 의도적으로 호출하지 않음.

## API가 없거나 코드에서 해결 가능한 사항

- iOS에서 즉시 가능한 작업: 이미 구현된 AuthService endpoint의 실제 View 연결 보강, answers GET/poke/bucket/schedule 호출 코드 추가, DTO·오류 상태·재시도 구현, 로컬 Mock 표시 차단.
- 백엔드 확인 필요: 회원 상세/가족 상세·구성원·초대 참여/코드 검증·알림 API 및 추천 콘텐츠 계약. 현재 OpenAPI 스냅샷에는 해당 operation이 없음.
- 서버 원본 Swagger를 재조회하려면 개발 서버 인증 권한이 필요함(현재 401). 인증 후 동일 경로를 재확인해야 함.

## Swagger 계약 요약

아래는 스냅샷의 각 operation에 선언된 요청 본문 스키마와 응답 상태 코드다. `$ref` 이름은 OpenAPI components 기준이며, 응답 본문이 없는 operation은 `-`로 표시했다.

| Method | API Path | Request schema | Response status |
|---|---|---|---|
| PUT | /api/v1/questions/{questionId}/answers/me | WriteAnswer | 200, 400, 401, 404, 409 |
| GET | /api/v1/members/taste | - | 200, 401, 404, 500 |
| PUT | /api/v1/members/taste | Save | 200, 400, 401, 404, 500 |
| GET | /api/v1/terms/agreements | - | 200, 401, 404 |
| POST | /api/v1/terms/agreements | Agree | 200, 400, 401, 404, 409 |
| POST | /api/v1/schedules/{scheduleId}/reviews | Create | 200, 400, 401, 403, 404, 409, 500 |
| POST | /api/v1/questions/today/members/{memberId}/pokes | - | 200, 400, 401, 403, 404, 409 |
| POST | /api/v1/missions/{missionId}/bucket | - | 200, 400, 401, 403, 404, 409 |
| POST | /api/v1/images/presigned-url | PresignedUrl | 200, 400, 401, 500 |
| POST | /api/v1/families | Create | 201, 400, 401, 404, 409, 500 |
| POST | /api/v1/bucket-items/{bucketItemId}/schedules | Create | 200, 400, 403, 404, 409 |
| POST | /api/v1/auth/reissue | TokenReissue | 200, 400, 401, 500 |
| POST | /api/v1/auth/logout | - | 200, 401, 404, 500 |
| POST | /api/v1/auth/login | Login | 200, 400, 401 |
| PATCH | /api/v1/schedules/{scheduleId} | Update | 200, 400, 403, 404, 409 |
| PATCH | /api/v1/schedules/{scheduleId}/response | Response | 200, 400, 403, 404, 409 |
| PATCH | /api/v1/schedules/{scheduleId}/cancel | - | 200, 403, 404, 409 |
| PATCH | /api/v1/members/nickname | Nickname | 200, 400, 401, 404, 409, 500 |
| PATCH | /api/v1/members/family-role | SelectFamilyRole | 200, 400, 401, 404, 500 |
| PATCH | /api/v1/families/{familyId} | UpdateName | 200, 400, 401, 403, 404, 409, 500 |
| GET | /api/v1/families/{familyId}/invite | - | 200, 401, 403, 404, 500 |
| DELETE | /api/v1/families/{familyId}/invite | - | 200, 401, 403, 404, 500 |
| PATCH | /api/v1/families/{familyId}/invite | - | 200, 401, 403, 404, 500 |
| GET | /api/v1/terms | - | 200, 401 |
| GET | /api/v1/schedules/upcoming | - | 200, 401, 403 |
| GET | /api/v1/schedules/calendar | - | 200, 400, 401, 403 |
| GET | /api/v1/questions/{questionId}/answers | - | 200, 400, 401, 404 |
| GET | /api/v1/questions/today | - | 200, 401, 404 |
| GET | /api/v1/missions | - | 200, 400, 401, 404 |
| GET | /api/v1/missions/{missionId} | - | 200, 400, 401, 404 |
| GET | /api/v1/bucket-items | - | 200, 400, 401, 403, 404 |
| DELETE | /api/v1/members/me | - | 200, 401, 404, 500 |
| DELETE | /api/v1/bucket-items/{bucketItemId} | - | 200, 400, 401, 403, 404, 409 |
