# QA 결함 보고서

이번 회차에서 실제 실행으로 재현·확정한 제품 결함은 없습니다. Simulator, Android, 백엔드·배치 실행 환경이 확보되지 않아 코드만으로 결함을 추정 등록하지 않았습니다.

## 환경 차단 이슈 (제품 결함 아님)

- CoreSimulatorService 연결 거부로 iOS 앱 설치·실행·스크린샷을 수행하지 못했습니다.
- 현재 저장소에는 Android 및 백엔드 소스/실행 설정이 없어 해당 플랫폼과 API·DB·배치 검증을 수행하지 못했습니다.
- 권한 확장 Debug 빌드는 성공했으므로 Swift 컴파일 오류로 판단할 근거는 없습니다.

**결함 ID:** BUG-001

**관련 TC ID:** TC-PLAN-09-002, TC-PLAN-09-003, TC-PLAN-09-004

**기능 ID:** PLAN-09

**기능명:** 초대장 발송 방법 선택 및 카카오톡 공유

**심각도:** S1 - Major

**플랫폼:** iOS

**발견 방식:** STATIC_ANALYSIS (실서버·수신자 흐름 미실행)

**발생 환경:** develop 작업 트리 `de2963215fd7efbda734d299e4ec6b1415517689`, iOS 소스 정적 검토

**사전조건:** 일정 생성 후 초대장 발송 방법에서 카카오톡으로 보내기를 선택하는 흐름

**재현 절차:** `RecordView`의 `InvitationView`에서 `onSendKakao`를 실행하는 경로를 추적한다.

**기대 결과:** 카카오톡 공유 가능한 일정 초대 링크/메시지를 공유하고, 취소·실패에도 일정과 인앱 상태를 유지한다.

**실제 결과 또는 정적 분석 결과:** `RecordView.swift:428-437`의 `handleKakaoInvitation()`은 공유 SDK·공유 시트를 호출하지 않고 `selectedInvitation = nil`, `selectedTab = .bucket`만 수행한다. 카카오톡 공유 또는 실패/취소 결과를 판별하는 코드가 없다.

**오류 로그 및 증빙:** `qa/evidence/static-plan09-kakao.txt`

**관련 파일 및 코드 위치:** `KIRI/KIRI/Features/Record/RecordView.swift:428-437`; 호출 연결 `RecordView.swift:120-126`

**원인 분석:** 카카오 공유 구현이 TODO 상태로 남아 있어 발송 동작이 연결되지 않았다. 서버 계약과 실제 공유 링크 발급 여부는 계정/API 접근이 없어 확인하지 못했다.

**사용자 영향:** 카카오톡 발송을 선택해도 수신자에게 일정 초대가 전달되지 않는다. 해당 흐름의 P0 테스트를 통과할 수 없다.

**수정 방향 제안:** 최신 서버 계약의 일정 초대 링크/토큰을 사용해 공유 URL을 구성하고, OS 공유 시트 또는 카카오 SDK 결과를 성공·취소·실패로 분기한다. 일정 생성은 공유 재시도와 독립적으로 1회만 수행한다.

**회귀 테스트 대상:** TC-PLAN-09-001~006

**수정 여부:** 미수정 (QA 범위상 제품 코드 변경 금지)

**결함 ID:** BUG-002

**관련 TC ID:** TC-FAM-02-001, TC-FAM-02-002, TC-FAM-02-003, TC-FAM-03-003, TC-FAM-03-004, TC-MY-05-001, TC-MY-05-002

**기능 ID:** FAM-02, FAM-03, MY-05

**기능명:** 가족 초대 링크·코드 조회 및 관리

**심각도:** S1 - Major

**플랫폼:** iOS

**발생 환경:** 로그인된 가족 사용자, 앱 재실행 또는 세션 복원 후 홈의 가족 초대하기 진입

**사전조건:** 가족 정보와 familyId는 복원됐지만 로컬 familyInviteCode가 없는 세션

**재현 절차:** 홈에서 가족 초대하기를 누른다.

**기대 결과:** 현재 familyId로 `GET /api/v1/families/{familyId}/invite`를 조회하고 서버가 발급한 코드를 기존 초대 화면에 표시한다.

**실제 결과:** 수정 전 `FamilyHomeView`가 로컬 `familyInviteCode`가 비어 있으면 서버 요청 없이 오류 팝업을 표시했다. 앱 재실행·로그인 복원 뒤 초대 기능이 차단됐다.

**오류 로그 및 증빙:** 수정 전 guard는 `FamilyHomeView`의 초대 버튼 분기였으며, 수정 빌드 및 화면 스모크는 `qa/evidence/bug002-build-retry.log`, `qa/evidence/bug002-login.png`에 기록했다.

**관련 파일 및 코드 위치:** `KIRI/KIRI/Features/Home/FamilyHomeView.swift`; `KIRI/KIRI/App/AppRouter.swift`; `KIRI/KIRI/Core/Network/AuthService.swift:446-452`

**원인 분석:** `GET /api/v1/families/me/id`와 초대 정보 GET API는 서비스에 존재했지만 홈 버튼과 연결되지 않았다. `AppRouter.syncServerIdentity()`는 familyId만 저장하고 inviteCode를 조회하지 않았다.

**수정 내용:** AppRouter에 서버 초대코드 복구 메서드를 추가하고, RootView → MainTabView → HomeView → FamilyHomeView로 비동기 조회 콜백을 전달했다. 버튼은 로컬 코드가 없을 때 해당 콜백을 호출하며, 성공한 코드만 저장·표시한다. FAMILY404 계열(초대 미생성)과 네트워크/기타 실패를 구분하고 후자는 재시도할 수 있게 했다. PATCH 재발급은 호출하지 않는다.

**검증 결과:** Debug 빌드 성공 및 수정 앱 설치·로그인 화면 실행을 확인했다. 테스트 계정과 초대 데이터가 없어 실제 서버 응답·코드 표시·복사·공유·재실행 회귀는 미검증이다.

**사용자 영향:** 수정 전에는 기존 가족 사용자가 홈에서 초대 화면에 진입할 수 없었다. 수정 후 서버 조회 경로는 연결됐으나 실계정 E2E 확인이 필요하다.

**수정 여부:** 수정 완료, 실서버 회귀 검증 대기
