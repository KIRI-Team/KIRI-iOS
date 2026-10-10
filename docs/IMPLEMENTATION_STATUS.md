# KIRI iOS 구현 현황 — 최신 기능명세서 기준

검증일: 2026-10-10 (Asia/Seoul)
기준 브랜치: `develop`
기준 HEAD: `24025222e1fb591d22dbba2df75a852b0b4765c2` — `[Docs] : KIRI iOS 구현 현황 및 기능명세서 분석`
기준 명세: [KIRI_FEATURE_SPEC_LATEST.csv](specs/KIRI_FEATURE_SPEC_LATEST.csv)

## 1. 검증 범위·결론

**최신 CSV의 107개 기능 ID(P0 84개, P1 23개)를 전수 대조했다. 기존 화면 목록 중심 분석을 기능 ID·정책·예외 처리 중심으로 갱신했으며, 개발 순서는 5절을 확정 기준으로 사용한다.**

- CSV는 UTF-8 BOM 및 따옴표 내부 줄바꿈을 처리하는 CSV 파서로 읽었다. 10개 열, 107개 고유 ID이며 중복·누락 ID는 없다. 이름이 비슷해도 ID를 합치거나 빠진 번호를 임의 생성하지 않았다.
- CSV SHA-256: `e723d48d8045da24943437ba5066ec76cc71acedcf68eb31a3939d108c54887a`.
- Swift는 70개 파일·13,079줄. `git diff 81620ed HEAD -- KIRI` 결과가 비어 있어 이전 코드 분석 이후 앱 코드 변경이 없음을 확인했고, 최신 정책과 관련된 상태·콜백·모델·가드·API 호출 지점을 재검증했다.
- 시작 시 추적 파일 변경은 없고 `docs/specs/`가 사용자 제공 미추적 디렉터리였다. 이를 수정·스테이징하지 않았다. 로컬 `develop`과 기록된 `origin/develop`은 일치하며 fetch/pull은 하지 않았다.
- 이번 작업에서 Figma 지정 [끼리 UI 페이지](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7883-11018)의 전체 메타데이터를 다시 조회했다. 직속 화면 프레임 100개 및 하위 시안/설명과 대조했다. 각 행에 직접 시안, 연관 시안, 정책 차이, 전용 시안 미확인, 비화면을 구분했다.
- 이전 분석에서 질문 입력·일정 등록·설정·세부미션 스크린샷 4개를 확인했다. 이번에는 Figma 구조/텍스트와 코드 경로를 재대조했으며 전체 픽셀 QA나 시뮬레이터 터치 검증을 새로 수행한 것은 아니다.
- 분석 범위는 **이 iOS 저장소**다. 서버 소스·운영 서버를 검증하지 않았으므로 비화면 기능은 ‘iOS 연동 미구현 / 서버 구현 미검증’으로 기록한다. 서버에 기능이 없다고 단정하지 않는다.
- 최신 명세의 기능·정책·P0/P1이 기존 Figma 문구와 이전 문서의 제안보다 우선한다. 기존 디자인 시스템과 일치하는 화면 구성은 재사용한다.

### 상태 판정

| 구분 | 정의 |
| --- | --- |
| UI 구현 완료(로컬) | 해당 입력/조작의 로컬 경로가 연결됨. 실제 서버 저장·전체 정책·픽셀 QA 완료를 뜻하지 않음 |
| UI 부분 구현 | 기존 화면/컴포넌트는 있으나 상태·진입·오류·결과 반영 일부 누락 |
| UI 미구현 | 해당 동작을 수행할 UI가 없음. 화면 이름이나 Preview만으로 완료 판정하지 않음 |
| UI 비화면 | 수집·집계·추천·권한/이벤트처럼 전용 화면을 만들 필요가 없는 기능. 관련 UI 상태는 따로 표시 |
| 기능 부분 구현 | UI/로컬 처리 일부는 있지만 기능 ID 전체의 정책·데이터·예외 처리 미충족 |
| 기능 미구현 | 해당 흐름 없음. 관련 재사용 코드는 근거 열에 기록 |
| 기능 연동 미구현 | 비화면 기능의 iOS 계약/호출 경로 미연결. 서버 상태는 미검증 |

| 범위 | 구현 완료 | 부분 구현 | 미구현 | 비화면/연동 미구현 |
| --- | ---: | ---: | ---: | ---: |
| UI·로컬 범위 (107개 ID) | 5 | 53 | 30 | 19 |
| 기능 ID 전체 요건 (107개 ID) | 0 | 58 | 30 | 19 |

기능 전체 완료 0은 화면이 전혀 없다는 뜻이 아니다. 약관 체크, 별점·재참여 입력, 로컬 로그아웃, 모두 읽음의 기존 UI는 재작성할 필요가 없다. 반대로 화면이 있어도 저장자/참여자·마감·권한 등의 정책을 누락하면 기능 전체 완료로 올리지 않는다. 수치는 화면 수나 개발 공수 비율이 아닌 **ID별 분류 수**다.

## 2. 코드 근거와 기존 화면 재사용

아래 C 번호는 4절 기능별 표의 코드 근거다. 모든 경로는 현재 저장소에서 확인했다. 세부 파일 70개 인벤토리는 부록 B에 유지했다.

| 근거 | 현재 파일 / 확인 지점 | 재사용·제약 |
| --- | --- | --- |
| C01 | [AppRouter](../KIRI/KIRI/App/AppRouter.swift), [RootView](../KIRI/KIRI/App/RootView.swift), [MainTabView](../KIRI/KIRI/App/MainTabView.swift), [AppSessionStore](../KIRI/KIRI/Core/Storage/AppSessionStore.swift) | Bool 세션/모드 복원, pendingInvitation, 로그아웃. receiveInvitation 외부 호출 없음, userMode는 홈에만 전달. switch 탭 교체로 하위 State 유지 보장 없음 |
| C02 | [AuthFlowView](../KIRI/KIRI/Features/Auth/AuthFlowView.swift), [LoginView](../KIRI/KIRI/Features/Auth/LoginView.swift), [TermsAgreementView](../KIRI/KIRI/Features/Auth/TermsAgreementView.swift) | 로그인→약관→온보딩. Apple 시스템 버튼은 LoginView 내 구현. 별도 AppleSignInButton.swift는 빈 파일. TermDetailView는 private |
| C03 | [OnboardingFlowView](../KIRI/KIRI/Features/Onboarding/OnboardingFlowView.swift)와 같은 폴더의 9개 화면, [FamilyInvitation](../KIRI/KIRI/Models/FamilyInvitation.swift) | 닉네임/역할/가족명/코드/조회중/참여확인/공유 확장. KIRI24·가족명 mock, familyId/token/만료/owner 모델 없음 |
| C04 | [FamilyHomeView](../KIRI/KIRI/Features/Home/FamilyHomeView.swift), [BrowseHomeView](../KIRI/KIRI/Features/Home/BrowseHomeView.swift), [HomeView](../KIRI/KIRI/Features/Home/HomeView.swift) | 홈/알림/고정 요청 상세만 route 존재. 배너·추천·질문 액션 없음. 일정 수락은 home 복귀만 |
| C05 | [FamilyMemberItem](../KIRI/KIRI/Features/Home/Components/FamilyMemberItem.swift), [QuestionCard](../KIRI/KIRI/Features/Home/Components/QuestionCard.swift), [PlaceCard](../KIRI/KIRI/Features/Home/Components/PlaceCard.swift) | 표시용 아바타/완료 질문/추천 카드. 기존 타입에 상태·액션 확장 우선 |
| C06 | [MissionView](../KIRI/KIRI/Features/Mission/MissionView.swift), [MissionPlaceCard](../KIRI/KIRI/Features/Mission/MissionPlaceCard.swift) | 검색·6종 카테고리·상세·북마크 연결. 지역/시간 TODO, 5개 상수 데이터·중복 샘플 |
| C07 | [MissionActivityDetailView](../KIRI/KIRI/Features/Mission/MissionActivityDetailView.swift) | 목록에서 fullScreenCover 연결. 이미지 placeholder·장소/지역·태그·저장만 있어 상세 섹션 확장 대상 |
| C08 | [MissionBucketStore](../KIRI/KIRI/Features/Mission/MissionBucketStore.swift) | UserDefaults title/placeName 키. user/mission/family ID·상태·저장일·일정 관계 없음. 서버 버킷 아님 |
| C09 | [RecordBucketListView](../KIRI/KIRI/Features/Record/Components/RecordBucketListView.swift) | 저장자 필터/리스트 재사용. 신규 저장은 invitation=nil. bucketCard의 isCompleted guard가 완료 항목 재참여를 막음 |
| C10 | [RecordCalendarView](../KIRI/KIRI/Features/Record/Components/RecordCalendarView.swift) | ActivityState는 pendingSchedule/confirmedSchedule/completed뿐. calendarActivities=[], 날짜 탭은 첫 항목만. 사진/추가개수 필드는 실제 렌더링 미연결 |
| C11 | [RecordView](../KIRI/KIRI/Features/Record/RecordView.swift), [ScheduleDetailView](../KIRI/KIRI/Features/Record/Schedule/ScheduleDetailView.swift), [InvitationView](../KIRI/KIRI/Features/Record/Invitation/InvitationView.swift), [InvitationSendMethodSheet](../KIRI/KIRI/Features/Record/Invitation/InvitationSendMethodSheet.swift), [InvitationRequestView](../KIRI/KIRI/Features/Record/Request/InvitationRequestView.swift), [AddScheduleSheet](../KIRI/KIRI/Features/Record/Request/AddScheduleSheet.swift) | 초대 미리보기/방법/수락 확인은 존재. AddScheduleSheet는 일정 작성기가 아님. 보내기는 성공 배너/닫기뿐. 지난날 미작성 일정은 안내만 있어 리뷰 진입 없음 |
| C12 | [TodayActivityView](../KIRI/KIRI/Features/Record/Schedule/TodayActivityView.swift), [ConditionAdjustmentSheet](../KIRI/KIRI/Features/Record/Schedule/ConditionAdjustmentSheet.swift), [ScheduleScreenPreview](../KIRI/KIRI/Features/Record/Schedule/ScheduleScreenPreview.swift) | 당일 3영역·조건 정렬·필수 활동 최대3/준비물 최대4. 풍부한 mock은 Preview에만 있음. 메인은 나1명/추천 빈 배열 |
| C13 | [ActivityReviewWriteView](../KIRI/KIRI/Features/Record/Review/ActivityReviewWriteView.swift), [ActivityReviewCompleteView](../KIRI/KIRI/Features/Record/Review/ActivityReviewCompleteView.swift), [RecordView](../KIRI/KIRI/Features/Record/RecordView.swift) | 사진1장+글+별점+예/아니오 가드, 수정/삭제 경로 존재. Draft는 메모리, key는 날짜+제목. 사용자/활동 ID 없음 |
| C14 | [ReviewDetailView](../KIRI/KIRI/Features/Record/Review/ReviewDetailView.swift), [FamilyReviewCard](../KIRI/KIRI/Features/Record/Components/FamilyReviewCard.swift), [ScheduleParticipantTooltip](../KIRI/KIRI/Features/Record/Components/ScheduleParticipantTooltip.swift) | 인원확인 TODO. FamilyReviewCard와 Tooltip은 Preview 외 호출 없음. 대표사진/날짜별 갤러리 구성 시 기존 컴포넌트 재사용 |
| C15 | [NotificationView](../KIRI/KIRI/Features/Home/Notification/NotificationView.swift) | 고정 목록·로컬 읽음 Set. opensInvitation만 이동, 진입 자동읽음은 없음. API 로딩/오류·대상 ID 없음 |
| C16 | [MyPageView](../KIRI/KIRI/Features/MyPage/MyPageView.swift), [FamilySettingsView](../KIRI/KIRI/Features/MyPage/FamilySettingsView.swift), [NicknameEditView](../KIRI/KIRI/Features/MyPage/NicknameEditView.swift), [FamilyNameEditView](../KIRI/KIRI/Features/MyPage/FamilyNameEditView.swift) | 가족 설정·이름 수정·로컬 로그아웃 연결. 나머지 TODO. 엄마2명 샘플, 권한/유일성 검증 없음 |
| C17 | [KIRIColor](../KIRI/KIRI/Core/DesignSystem/KIRIColor.swift), [KIRITypography](../KIRI/KIRI/Core/DesignSystem/KIRITypography.swift), [공통 컴포넌트](../KIRI/KIRI/Core/Components) | 색/폰트/간격/라운드와 Back/PrimaryButton/TextField/CodeInput/SearchField/Chip/TopTab/TabBar/ShareSheet/ValidationGuidance 재사용. 폰트9종 등록 |
| C18 | [APIClient](../KIRI/KIRI/Core/Network/APIClient.swift), [APIEndpoint](../KIRI/KIRI/Core/Network/APIEndpoint.swift), [APIConfig](../KIRI/KIRI/Core/Network/APIConfig.swift), [APIError](../KIRI/KIRI/Core/Network/APIError.swift) 및 전체 Swift 호출 검색 | 네트워크 기반만 있고 Features 호출부 없음. 도메인 서비스·추출/배정/수집/권한/날씨·알림 이벤트 계약 미연결 |

실제 빌드 프로젝트는 `KIRI/KIRI.xcodeproj`, scheme `KIRI`다. 루트 `KIRI.xcodeproj`는 workspace 참조만 있어 빌드 프로젝트와 다르다. iOS 26.2·Swift language mode 5.0·MainActor 기본 격리, 별도 테스트 타깃과 패키지 의존성은 없다. ContentView는 앱 진입점이 아닌 Hello world 템플릿이다.

## 3. 최신 명세로 바로잡은 정책·디자인 차이

| 항목 | 최신 기준 및 분석 결정 |
| --- | --- |
| 우선순위 | 공용 초대/가족 관리/우리 집 위치/튜토리얼은 P0. 이전 문서의 P1/P2 또는 누락을 바로잡음. 필터·설정 일부는 명세대로 P1 유지 |
| 가족·프로필 | 엄마/아빠는 가족당 각각1명, 아들/딸 복수. 활성 가족은 계정당1개. 닉네임은 MY-01 기준 서비스 전체 유일, 가족명도 전역 유일. 초대 전/대기 가상 구성원 금지 |
| 고정 캐릭터 | 역할별 KIRI 기본 캐릭터 사용. 사용자 프로필 사진 업로드나 캐릭터 선택 기능을 새로 만들지 않음. 현재 두 공통 아바타는 4역할 매핑과 다름 |
| 초대 | 공용 링크+코드 한 활성 세트, 발급 후7일, 수동 재발급. 링크는 코드 자동 적용, 기존 회원에게 약관/기본정보 반복 금지, 이미 구성원이면 홈 |
| 둘러보기 | 질문/콕/가족 버킷·일정·기록 제한. Home만 분기하는 현 코드는 부족. 실제 서버 권한 검증은 별도이며 UI 숨김만으로 대체 불가 |
| 내 취향 설정 | MY-02는 **활동(최대3)/공간/활동량/비용/활동시간** 선택형5항목. Figma `8596:18240` 음식 텍스트 질문과 ‘취향테스트’ 명칭을 그대로 구현하지 않음. 혼잡/분위기/거주지역/이동거리 수집 제외 |
| 온보딩 제외 | 취향·우리 집 위치는 마이페이지 선택 기능. 과거 Figma 관심사/거리/가족 수/맞춤 질문을 필수 온보딩에 추가하지 않음. 이름 월1회 수정 문구는 최신 명세에 없어 제한 기능을 임의 확정하지 않음 |
| 데일리 질문 | 가족 생성 첫7일 고정 순서, 이후 검수 풀. 가족별 KST 일1개, 개인별 답변1개, 텍스트만·당일 수정. 사진·선택형·사용자 진입 즉시 AI 질문 생성 금지 |
| 콕 | 답변 완료자에게도 가능, 본인 금지, 동일 발신자→수신자 당일1회. 링/답변 상태는 변경하지 않음. 미답변만 보내는 UI는 정책 불일치 |
| 주간 미션 | 가족 공통 주1개, 월요일00:00~일요일23:59 KST. 질문과 플립 양면으로 공존. 주중 취향 변경으로 교체하지 않으며 외부 취소/종료만 예외 |
| 버킷 | 개인 (user_id, mission_id) 저장, 가족 통합 조회. 서로 다른 저장자 허용. 유효 리뷰 후 배지는 ‘완료’, 완료 후 새 일정 재참여 가능. 현 ‘종료된 일정’ 및 isCompleted 탭 차단을 유지하면 안 됨 |
| 일정 생성 | 날짜/시간·제안 대상 최소1명 필수, 본인은 선택 대상이 아닌 자동 ACCEPTED. 가족에게 한 줄은 선택. 미리보기는 응답 레코드 생성 전이며 실제 전송 시 생성 |
| 응답 상태 | 개인: PENDING=미응답 / ACCEPTED=수락 / DECLINED=거절 / RECONFIRM_REQUIRED=재확인 필요. 수락/거절 버튼만. MAYBE·고민중·대기 선택 없음 |
| 일정 상태·마감 | 제안자 외 수락1명 이상이면 CONFIRMED, 0명은 마감 전 PENDING_RESPONSE·마감 후 NOT_CONFIRMED. 생성 시 시작까지24시간 초과면 시작24시간 전 마감, 이하이면 시작시각 마감. 미응답을 거절로 바꾸지 않음 |
| 수정/취소 | 제안자 핵심 변경→영향받는 수락자 재확인, 메모만 변경→유지. 시작 후 핵심 수정 금지. 취소와 완료 구분, 완료 취소 금지. 다른 일정/완료 이력을 검사하여 버킷 상태 결정 |
| 가족 조회·응답 권한 | 가족은 초대되지 않은 일정도 조회 가능. 응답은 초대 대상만, 당일 활동은 확정 최종 참여자만. 가족 전체 자동 초대 또는 비참여자 완전 조회 차단으로 만들지 않음 |
| 당일/조건 | 주변 추천 기준은 일정 장소 좌표, 조건은 주변 후보 정렬에만 적용. 신뢰할 혼잡 정보 없으면 미적용 안내. 날씨 실패 시 날씨 준비물만 제외. 메인 미션 교체·AI 이동경로 생성 금지 |
| 완료·재참여 | 최초 유효 리뷰(사진1장+글+별점1~5+예/아니오)로 일정/버킷/주간 완료. 시간 경과 자동 완료 금지. 다른 참여자 후속 리뷰 및 과거 활동 작성 진입 필요. 재참여는 새 일정·별도 기록 |
| 캘린더 | CAL-04는 하루 활동 목록 필수. 첫 항목만 열기 및 기존 주석의 별도 목록 없음 판단 폐기. CAL-06 전원 답변 캐릭터 블록 추가, 활동 사진과 동시 표시는 디자인 미정 |
| 대표사진 | 최초 유효 리뷰 첫 사진을 활동 대표로 고정, 다음 리뷰로 자동 변경 금지. 활동 전체 사진 중1장 선택, 삭제 시 대체/마커. LOG-03(P0)·LOG-09(P1)는 같은 구현 |
| 설정·탈퇴 | 가족명은 현재 owner만 변경, 탈퇴 시 가장 먼저 참여한 잔여 구성원에게 승계. 개인정보 삭제와 과거 공동 기록 보존/익명화 분리. 마지막 구성원은 공동 데이터 삭제 여부 최종 확인 |
| 알림 | 인앱 먼저·푸시 별도, 푸시 실패/권한OFF가 핵심 상태를 롤백하지 않음. 조회만으로 모두읽음 아님. 삭제 기능 없음. Figma 정기 알림 시각 선택은 최신 MY-06에 없어 보류 |
| 건의함 | 필수 자유글·선택 사진, 실패 초안 유지. 질문별 신고는 만들지 않고 통합. 리뷰 사진 필수 검증을 그대로 재사용하지 않음 |
| 추천/출처 | KIRI Pick·가족 피드·가족 주간 배정 구분. 명시 취향/실제 행동 우선, 지정된 질문만 약한 신호. 없는 운영정보/가격/혼잡도 생성 금지, 허용 이미지와 출처만 사용 |

### 확정되지 않은 사항의 처리

- CAL-06은 대표사진과 전원 답변 캐릭터가 같은 날짜에 있을 때 최종 표현을 디자인과 검토하도록 명세에 명시되어 있다. 질문·홈 플로우(F2~F3)에 배치하되 이 조합의 시각 완료 판정은 보류한다.
- MY-02 최신5문항 배치, FAM-06 튜토리얼, FAM-D 상세/취향 요약, CAL-04 하루 목록, MIS-05/06 필터 상세의 현행 전용 디자인은 지정 페이지에서 확인하지 못했다. 공통 컴포넌트 기반으로 명세 UI를 작성하되 과거 시안을 정책 근거로 삼지 않는다.
- 기존 코드/Figma의 사진 최대10장, 글500자, 가족 메시지100자 및 월1회 이름 수정은 CSV에서 확정된 제약이 아니다. 기존 UI/Figma 제약의 출처로 별도 기록하며 서버 제한으로 단정하지 않는다.
- 금칙어 목록·이름 형식 최종 허용 범위, 최소 예약 간격/과거 날짜 허용, NOTI-05 정확한 발송 시각·횟수, 집 위치 변경 권한 상세 역할, 튜토리얼 최초 재진입 방식은 계약/디자인 확인 대상이다. 독립 UI 개발 순서 전체를 막지는 않는다.
- LOG-03은 P0에서 이미 대표사진 선택 변경을 요구하고 LOG-09는 같은 정책을 P1로 상세화한다. 우선순위를 변경하지 않고 **P0 요구를 충족하는 한 구현**에 연결한다. HOME-04(P1) 상세도 Q-03/Q-04(P0)의 진입·조작과 함께 구현한다.

## 4. 기능 ID별 전수 매핑

CSV 원본 ID·명칭·우선순위를 사용한다. C 번호는 2절 코드 근거, U/B 번호는 5절 개발 단계다. Figma ‘연관’은 출력/인접 화면만 존재하며 정책 구현 증거가 아니다. ‘없음’은 지정 페이지에서 전용 프레임 미확인, ‘비화면’은 전용 UI 비대상이다.

기존 전수 매핑 행에 남아 있는 `U0~U6` 표기는 최초 감사 당시의 ID 그룹 식별자다. 개발 순서는 이 표기의 우선순위를 따르지 않으며, 현재 작업 순서는 5절의 Figma 플로우 `F1~F9`를 따른다.


### 4.1. 진입·인증·온보딩·가족

| 기능 ID · 기능명 | 원본 우선순위 / 단계 | UI / 기능 상태 | 코드 근거 · 현재 동작 | Figma 대조 | 미구현 UI·정책·예외 처리 |
| --- | --- | --- | --- | --- | --- |
| ENT-01 · 세션 확인 | P0 / U0 | UI 부분 구현 / 기능 부분 구현 | C01 — AppRouter가 로컬 인증/온보딩 Bool과 userMode로 분기한다. | [8095:62668](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8095-62668) | 브랜드 스플래시, 세션 만료·복구 실패, 미완료 단계 복원 및 초대 컨텍스트 유지가 필요. 실제 세션 검증은 미연동. |
| AUTH-01 · 소셜 로그인/가입 | P0 / U0 | UI 부분 구현 / 기능 부분 구현 | C02 — 소셜 버튼 존재. Kakao/Google은 즉시 약관, Apple은 시스템 인증 성공 후 약관으로 이동한다. | [8095:62717](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8095-62717) | 신규/기존 회원 분기, 취소·실패 안내/재시도와 소셜 식별값 중복 방지 연동 필요. 기존 UI 재사용. |
| AUTH-02 · 필수 약관 동의 | P0 / U0 | UI 구현 완료(로컬) / 기능 부분 구현 | C02 — 필수 체크 가드·전체동의·본문 시트·다음 동작은 구현되어 있다. | [8296:13599](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8296-13599) | 개인별 약관 버전/시각 저장, 실패 시 유지·재시도, 초대 흐름 복귀 미연동. 체크 UI 완료와 기능 전체 완료는 다름. |
| ONB-01 · 가족 역할/닉네임 설정 | P0 / U0 | UI 부분 구현 / 기능 부분 구현 | C03 — 4종 역할과 2~10자 닉네임 입력·전환은 있다. 프로필은 온보딩 내부 State뿐이다. | [7883:23313](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7883-23313),[8098:14575](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8098-14575) | 엄마/아빠 각 1명 제한·역할 충돌 복귀, 닉네임 중복/금칙어 오류, 프로필 전달 필요. MY-01의 서비스 전체 닉네임 유일성 적용. |
| ONB-04 · 역할별 KIRI 캐릭터 매핑 | P0 / U0 | UI 미구현 / 기능 미구현 | C03,C05 — FamilyMemberItem은 나/다른 가족의 두 이미지뿐이고 역할별 매핑은 없다. | [7883:23313](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7883-23313) | 4종 고정 KIRI 캐릭터와 역할 누락 안내 필요. 프로필 사진 업로드/자유 캐릭터 변경은 만들지 않음. 역할별 최종 에셋 매핑 확인 필요. |
| ONB-02 · 가족 연결 방식 선택 | P0 / U0 | UI 부분 구현 / 기능 부분 구현 | C03,C01 — 생성/코드/둘러보기 3개 경로와 invitation 있을 때 선택 단계 생략 분기는 있다. | [7883:23399](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7883-23399) | 외부 초대 진입 미연결, 둘러보기에서 가족 공동 기능 실행 시 연결 유도 누락. |
| ONB-03 · 둘러보기 모드 | P0 / U0 | UI 부분 구현 / 기능 부분 구현 | C01,C04 — BrowseHomeView 분기와 공개 미션 탐색은 있다. 가족공간 시작 문구는 무동작이다. | [8450:19981](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8450-19981),[8451:22900](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8451-22900) | 가족 버킷·일정·기록 접근 차단/연결 CTA 필요. userMode가 홈에만 전달되므로 다른 탭은 제한되지 않음. |
| ONB-05 · 홈 진입 | P0 / U0 | UI 부분 구현 / 기능 부분 구현 | C01,C03 — 모드 저장 후 홈 진입한다. 닉네임/역할/가족 실제 데이터는 저장·검증하지 않는다. | [8347:7411](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8347-7411) | 필수 정보 누락 단계 복귀, 가족 생성/참여 재시도 상태, 중복 방지 결과 처리 필요. |
| FAM-01 · 가족명 설정 | P0 / U0 | UI 부분 구현 / 기능 부분 구현 | C03 — 가족명 형식 검사 후 고정 코드 생성으로 진행한다. | [8098:72650](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8098-72650) | 서비스 전체 가족명 중복 오류, 생성자 역할/닉네임 연결, 로딩 실패·재시도 필요. |
| FAM-02 · 공용 초대 링크 생성 | P0 / U0 | UI 부분 구현 / 기능 부분 구현 | C03 — 고정 KIRI24의 복사와 텍스트 시스템 공유가 있다. URL·token·familyId는 없다. | [8098:72786](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8098-72786),[8286:76347](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8286-76347) | 링크+코드 동시 제공, 7일 만료 표시, 공유 진입 연결 필요. 링크에 역할을 고정하지 않음. |
| FAM-03 · 공용 초대 링크 만료/재발급 | P0 / U0 | UI 미구현 / 기능 미구현 | C03,C16 — 재발급 화면/데이터/액션 없음. | [8582:18039](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8582-18039) | 만료/유효/수동 재발급/실패 상태 필요. 자동 재발급 금지, 새 1세트 활성화와 기존 링크·코드 즉시 폐기. |
| FAM-04 · 공용 초대 링크 진입 | P0 / U0 | UI 부분 구현 / 기능 부분 구현 | C01,C03 — receiveInvitation 및 pendingInvitation 분기만 있고 실제 외부 호출부가 없다. | [8159:12141](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8159-12141),[8286:76347](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8286-76347) | 딥링크 수신→인증 보존→확인, 기존회원 단계 생략·이미 구성원 홈·만료 안내 필요. 코드 재입력 및 가상 대기 구성원 생성 금지. |
| FAM-05 · 초대코드/공용 링크 가족 참여 | P0 / U0 | UI 부분 구현 / 기능 부분 구현 | C03 — 가족 확인 화면과 참여→family 전환 존재. member 생성·최종 역할 검증 없음. | [8267:34617](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8267-34617) | 엄마/아빠 동시 점유 시 역할 재선택, 다른 가족 소속 계정 차단, 이미 참여 처리 필요. 계정당 활성 가족 1개. |
| FAM-07 · 초대코드 직접 입력 | P0 / U0 | UI 부분 구현 / 기능 부분 구현 | C03 — 6자리 형식 검증→고정 가족 조회→참여 확인이 연결되어 있다. | [8159:12141](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8159-12141) | 없는/만료/폐기 코드 오류·재입력, 이미 구성원 홈, 실제 대상 확인 필요. 코드 입력만으로 참여 확정하지 않음. |
| FAM-06 · 간단 튜토리얼 | P0 / U0 | UI 미구현 / 기능 미구현 | C03,C04 — 튜토리얼 및 이력 저장·재진입 경로 없음. | 없음 | 답변 모아보기·질문카드·추천 중심 단계 안내, 캘린더 설명, 건너뛰기/최초 재진입 UI 필요. 전용 Figma 프레임 미확인. |
| FAM-D-01 · 구성원/최근 활동/다가오는 일정 | P1 / U6 | UI 미구현 / 기능 미구현 | C04,C10,C16 — 구성원·캘린더는 별도 화면에 있으나 가족공간 상세 통합 화면/진입 없음. | 연관:[8347:7411](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8347-7411),[8216:3570](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8216-3570) | 활성 구성원·최근 완료·다가오는 일정과 영역별 빈 상태를 기존 구성요소로 조합. 전용 상세 디자인 미확인. |
| FAM-D-02 · 가족 취향 요약 | P1 / U6 | UI 미구현 / 기능 미구현 | C04,C16 — 가족 취향 요약 모델·태그·진입 없음. | 없음 | 누적 신호 요약 카드와 아직 알아가는 중 상태 필요. 원본 답변으로 취향을 단정하지 않음. |

### 4.2. 홈·질문

| 기능 ID · 기능명 | 원본 우선순위 / 단계 | UI / 기능 상태 | 코드 근거 · 현재 동작 | Figma 대조 | 미구현 UI·정책·예외 처리 |
| --- | --- | --- | --- | --- | --- |
| HOME-01 · 스토리형 가족 상태 바 | P0 / U1 | UI 부분 구현 / 기능 부분 구현 | C04,C05 — 아바타/링 표시가 있으나 모두 고정 답변 완료. 본인 링은 hasAnswered와 무관하다. | [8347:7411](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8347-7411),[8153:9957](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8153-9957) | 가족별 실제 답변 여부·질문 미생성 기본 상태 반영. 본인/타인 모두 답변 상태 기준으로 갱신. |
| HOME-02 · 질문 상태 전환 | P0 / U1 | UI 부분 구현 / 기능 부분 구현 | C04,C05 — hasAnswered 표시 파라미터만 있고 답변 저장 이벤트/상태 모델 없음. | [8070:11636](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8070-11636),[8159:12976](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8159-12976) | 구성원별 UNANSWERED/ANSWERED 즉시 갱신·중복 이벤트 처리. 콕 발송 상태는 별도로 유지. |
| HOME-03 · 오늘/다가오는 일정 상태 | P1 / U6 | UI 미구현 / 기능 미구현 | C04,C11 — 홈 일정 배너·일정 선택 라우트가 없다. | [8012:10311](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8012-10311) | 응답/재확인 필요 우선, D-7~D-1 확정 1개·당일 1개, 시작시각 우선 선택. 취소/미확정/완료 제외. |
| HOME-04 · 가족 질문 상태 상세 | P1 / U1 | UI 미구현 / 기능 미구현 | C05 — 스토리 프로필에 탭/상세 액션 없음. | [8070:11636](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8070-11636),[8159:12976](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8159-12976) | 답변 있음/없음 상세, 본인 콕 숨김·당일 콕 보냄·권한 없음 필요. Q-03/Q-04와 같은 화면으로 구현. |
| HOME-05 · 앞뒤 플립 카드 | P0 / U1 | UI 미구현 / 기능 미구현 | C04,C05 — QuestionCard는 답변완료 텍스트 전용이다. | [8012:9925](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8012-9925),[8460:8451](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8460-8451) | 앞면 오늘 질문+뒷면 주간 미션 공존 플립, 미션 비노출 시 탐색 CTA 필요. 플립이 답변·완료 데이터를 바꾸면 안 됨. |
| HOME-REC-01 · 주간 미션 배정 | P0 / U1 | UI 미구현 / 기능 미구현 | C04 — 주간 미션 카드/배정 모델 없음. | [8347:7734](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8347-7734),[8012:9925](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8012-9925) | 가족 공통 주 1개·월요일 KST 00:00 시작, 후보 없음/데이터 부족 UI 필요. 배정 서버 로직은 별도 계약. |
| HOME-REC-02 · 주간 미션 유지/갱신 | P0 / U1 | UI 미구현 / 기능 미구현 | C04 — 주간 식별자·유지/갱신/취소 대체 처리 없음. | [8460:8451](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8460-8451),[8460:8707](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8460-8707) | 같은 주 카드 유지, 취향 변경은 다음 주 반영, 취소/종료 때만 대체. 후보 없으면 탐색 유도. |
| HOME-REC-03 · 주간 미션 완료 상태 | P1 / U6 | UI 미구현 / 기능 미구현 | C04,C13 — 리뷰→주간 미션 연결 없음. | [8460:8707](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8460-8707) | 연결 일정의 최초 유효 리뷰로 완료 표시. 시간 경과/단독 완료 버튼으로 처리하지 않음. |
| Q-01 · 질문 배정 | P0 / U1 | UI 미구현 / 기능 미구현 | C04,C05 — 질문/답변 고정 문자열만 있다. | [8347:7411](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8347-7411) | 가족 생성일 기준 첫 7일 고정 질문, 8일차 검수 풀, familyId+KST 날짜당 1개. 신규 참여자는 같은 질문, browse 배정 금지. 배정 대기/실패 상태 필요. |
| Q-02 · 텍스트 답변 작성/수정 | P0 / U1 | UI 미구현 / 기능 미구현 | C05 — 질문 입력/저장/수정 화면 없음. | [8187:14904](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8187-14904),[8187:15072](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8187-15072),[8187:15113](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8187-15113) | 텍스트만, 공백 금지, 개인당 질문별 1답변 갱신, 당일 작성/수정·지난날 읽기 전용, 저장 실패 시 기존값 유지. |
| Q-03 · 가족 답변 열람 | P0 / U1 | UI 미구현 / 기능 미구현 | C05,C10 — 가족 질문 상세·날짜별 과거 답변 조회 경로 없음. | [8070:11636](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8070-11636),[8159:12976](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8159-12976) | 오늘/과거 답변·미답변·탈퇴자 익명화·가족 전용 조회. 과거 신규 작성/수정 차단. |
| Q-04 · 답변 재촉 | P0 / U1 | UI 미구현 / 기능 미구현 | C05,C15 — 알림 샘플의 콕 문구만 있고 발송 액션 없음. | [8070:11636](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8070-11636),[8159:12976](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8159-12976) | 발신자→수신자 KST 당일 1회, 답변자도 가능, 본인 금지. 애니메이션/토스트/재시도, 푸시 실패와 요청 실패 구분. |
| Q-05 · 질문/답변 형식 | P0 / U1 | UI 부분 구현 / 기능 부분 구현 | C05 — 현재 표시 질문은 텍스트이나 작성 폼/유효 질문 검증 없음. | [8187:14904](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8187-14904) | Q-02와 동일 TEXT 폼 사용. 사진/선택형 질문 UI 추가 금지. 비어 있거나 비활성 질문 대체 상태 필요. |

### 4.3. 취향 신호

| 기능 ID · 기능명 | 원본 우선순위 / 단계 | UI / 기능 상태 | 코드 근거 · 현재 동작 | Figma 대조 | 미구현 UI·정책·예외 처리 |
| --- | --- | --- | --- | --- | --- |
| TASTE-01 · 텍스트 질문 취향 신호 반영 | P0 / B0 | UI 비화면 / 기능 연동 미구현·서버 미검증 | C04,C18 — 텍스트 답변 신호 추출/수정·제거 모델이나 호출부 없음. | 비화면 | tasteSignalEnabled 질문만 약한 보조 신호. 모호한 답변은 무신호, 감정·관계·성격 추론 금지. 전용 화면 추가 대상 아님. |
| TASTE-02 · 탐색 행동 반영 | P0 / B0 | UI 비화면 / 기능 연동 미구현·서버 미검증 | C06,C08,C18 — 상세 이동·북마크는 있으나 행동 신호 기록 없음. | 연관:[7948:1685](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7948-1685) | 행동 이벤트 계약 필요. 단일 조회/저장으로 명시 취향을 뒤집지 않음. 신규 UI 없이 기존 액션에 연결. |
| TASTE-03 · 활동 완료 반영 | P0 / B0 | UI 비화면 / 기능 연동 미구현·서버 미검증 | C13,C18 — 유효 로컬 Draft는 있으나 참여자·활동 속성 신호 없음. | 연관:[8079:12515](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8079-12515) | 완료/정정 이벤트 연결, 조회/저장보다 강한 실제 행동 신호. 리뷰 저장과 후처리를 분리. |
| TASTE-05 · 재참여 의향 반영 | P0 / B0 | UI 비화면 / 기능 연동 미구현·서버 미검증 | C13,C18 — 재참여 Bool을 Draft에만 보관한다. | 연관:[8012:10942](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8012-10942) | 사용자/활동별 보조 신호 저장·수정. 신호 후처리 실패가 유효 리뷰 완료를 막지 않도록 처리. |

### 4.4. 미션·외부 콘텐츠

| 기능 ID · 기능명 | 원본 우선순위 / 단계 | UI / 기능 상태 | 코드 근거 · 현재 동작 | Figma 대조 | 미구현 UI·정책·예외 처리 |
| --- | --- | --- | --- | --- | --- |
| MIS-01 · 기본 피드 진입 | P0 / U2 | UI 부분 구현 / 기능 부분 구현 | C06 — 탭→로컬 5개 미션 카드 표시. | [7948:1685](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7948-1685) | 활성 콘텐츠 피드·로딩/실패/빈 상태·Pick 없음 대체 필요. 화면은 재사용. |
| MIS-02 · 가족 단위 기본 추천 정렬 | P0 / U2 | UI 부분 구현 / 기능 부분 구현 | C06,C04 — 고정 배열 첫 카드에 추천 표시만 있음. 가족 정보·거리·정렬 없음. | [7948:1685](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7948-1685) | 가족 단위 추천 스냅샷, 데이터 부족 대체, 전체에서 Pick 우선. 주간 배정과 탐색 정렬 구분. |
| MIS-04 · 카테고리 필터 | P0 / U2 | UI 부분 구현 / 기능 부분 구현 | C06 — 전체+명세와 같은 6개 카테고리 필터가 동작한다. | [7948:1685](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7948-1685),[8451:22069](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8451-22069) | 0건 안내·필터 완화 필요. 미선택 Pick 우선/선택 카테고리 우선 상태 검증. |
| MIS-03 · 전체 미션/플레이스 피드 | P0 / U2 | UI 부분 구현 / 기능 부분 구현 | C06 — 동일 MissionView에서 검색/전체 탐색 가능. | [7948:1685](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7948-1685),[8495:9657](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8495-9657) | 운영기간·활성/취소·가족 접근 조건, 0건/실패 표시 필요. 별도 플레이스 목록 중복 생성 금지. |
| MIS-05 · 지역/거리 필터 | P1 / U6 | UI 미구현 / 기능 미구현 | C06,C16 — 지역·거리 버튼은 TODO. | [7948:1685](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7948-1685) | 시군구·1/3/5/10km, 기본 가족 집 위치, 선택 지역 또는 허용된 현재 위치. 집 없음 안내와 권한 실패 필요. 상세 필터 시안 미확인. |
| MIS-06 · 날짜/시간/가격 필터 | P1 / U6 | UI 미구현 / 기능 미구현 | C06 — 날짜·시간 버튼 TODO, 가격 필터 없음. | [7948:1685](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7948-1685) | 기간/운영시간/가격 입력·적용/초기화·결과 없음. 정보 부족은 정보 확인 필요로 표시. 상세 시안 미확인. |
| MIS-12 · 사용자 평균 별점 표시 | P0 / U2 | UI 부분 구현 / 기능 부분 구현 | C07 — 주입받은 임의 rating 숫자 표시, nil이면 숨김. | [8451:22353](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8451-22353) | 활동 전체 사용자 유효 별점 평균과 평가 없음 안내. 가족 평균과 구분, 0.0을 무평가 대용으로 쓰지 않음. |
| MIS-07 · 미션/플레이스 상세 조회 | P0 / U2 | UI 부분 구현 / 기능 부분 구현 | C07 — 활동 상세 진입·장소/지역·태그·북마크만 있음. | [8451:22353](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8451-22353) | 원본 설명·기간/시간/가격·출처/위치·예상 정보·추천 근거·평균 별점 및 미제공 상태 추가. AI 문구로 사실을 보충하지 않음. |
| MIS-08 · 추천/KIRI Pick 이유 | P1 / U6 | UI 부분 구현 / 기능 부분 구현 | C06,C07 — 끼리추천 배지만 있고 실제 Pick/가족 추천 이유는 없다. | [8451:22353](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8451-22353) | 운영 Pick 문구와 가족 취향/거리 근거 구분, 근거 없을 때 일반 소개. 주간 미션과 같은 개념으로 취급 금지. |
| MIS-10 · 핫한 곳 우선 노출 | P1 / U6 | UI 부분 구현 / 기능 부분 구현 | C06 — 추천 샘플이 우연히 배열 첫 항목이다. | [7948:1685](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7948-1685) | 운영값 기반 Pick 순서·유효기간/비노출 처리 필요. 종료·취소 Pick 제외. |
| MIS-09 · 버킷리스트 저장 | P0 / U2 | UI 부분 구현 / 기능 부분 구현 | C08,C09 — title+placeName 키 UserDefaults 저장·해제와 버킷 표시 연결. | [8451:22229](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8451-22229),[8103:73442](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8103-73442) | (user_id, mission_id) 중복 방지·저장자별 별도 항목·완료 상태/배지·재참여 일정 필요. 현재 완료 카드 탭 차단은 정책 위반. |
| MIS-11 · 활동 조건 커스텀 추천 | P0 / U4 | UI 부분 구현 / 기능 부분 구현 | C12 — 4조건 선택/적용 및 거리·휴식·비용·혼잡 점수 정렬 존재. | [7905:10295](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7905-10295) | 조건 미적용/근거 없는 혼잡도 안내 필요. 메인 mock은 후보가 비어 효과 확인 불가. 주변만 재정렬하고 메인 미션/경로 변경 금지. |
| MIS-13 · 미션 자동 생성 | P0 / B0 | UI 비화면 / 기능 연동 미구현·서버 미검증 | C06,C18 — 수동 샘플뿐, 외부 원본 자동 가공 계약 없음. | 연관:[7948:1685](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7948-1685) | 원본 정규화→미션 생성/6종 매핑, 필수 원본 누락은 검수로 격리. iOS 신규 생성 화면 필요 없음. |
| MIS-14 · 미션명 자동 생성 | P0 / B0 | UI 비화면 / 기능 연동 미구현·서버 미검증 | C06,C18 — 미션명은 상수이며 자동 생성 없음. | 연관:[7948:1685](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7948-1685) | 유형별 행동형 템플릿 우선·AI 문법 보정만, 원본 고유명사 보존. 클라이언트에서 임의 제목 생성 금지. |
| EXT-01 · 수집 소스 | P0 / B0 | UI 비화면 / 기능 연동 미구현·서버 미검증 | C18 — 외부 수집 서비스/호출부 없음. | 비화면 | 공공/제휴/공식 소스 계약. 허용 소스만 수집, 일부 소스 실패가 전체 카탈로그를 비우지 않음. |
| EXT-03 · 일일 전체 정합성 검사 | P1 / B1 | UI 비화면 / 기능 연동 미구현·서버 미검증 | C18 — 일일 정합성 작업/상태 계약 없음. | 비화면 | 하루 1회 기간·취소·중복/주요 필드 검증, 접근 불가 시 확인 필요 유지. iOS 화면 추가 대상 아님. |
| EXT-02 · 주기적 증분 동기화 | P0 / B0 | UI 비화면 / 기능 연동 미구현·서버 미검증 | C18 — 증분 동기화/커서/스케줄러 없음. | 비화면 | 6시간 주기·마지막 성공 지점 보존·재시도. 실패 소스 때문에 기존 정상 미션 삭제 금지. |
| EXT-04 · 중복 통합 | P0 / B0 | UI 비화면 / 기능 연동 미구현·서버 미검증 | C06,C18 — 중복 원본 통합 없음. 동일 장소/제목 샘플 3개 존재. | 비화면 | 원본 ID 우선 통합, 낮은 확신은 검토·오병합 복구. 사용자별 버킷 중복 정책과 별개. |
| EXT-05 · 종료/취소 처리 | P0 / B0 | UI 비화면 / 기능 연동 미구현·서버 미검증 | C06,C10,C18 — 취소 알림 샘플만 있고 외부 상태 반영 없음. | 연관:[8459:8069](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8459-8069) | 종료/취소 신규 추천 제외·기존 스냅샷 유지·중요 변경 안내 계약. 원본 일시 누락을 취소/완료로 간주하지 않음. |
| EXT-06 · 외부 이미지 사용 정책 | P0 / B0 | UI 비화면 / 기능 연동 미구현·서버 미검증 | C07,C14,C18 — 카드 placeholder·리뷰 AsyncImage는 있으나 외부 이미지 출처/사용권 계약 없음. | 연관:[7948:1685](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7948-1685) | 허용된 이미지·원본 출처와 비노출/대체 상태 필요. 불명확한 외부 사진은 KIRI 기본 이미지, 임의 수집 금지. |

### 4.5. 일정·당일 활동·날씨

| 기능 ID · 기능명 | 원본 우선순위 / 단계 | UI / 기능 상태 | 코드 근거 · 현재 동작 | Figma 대조 | 미구현 UI·정책·예외 처리 |
| --- | --- | --- | --- | --- | --- |
| PLAN-01 · 일정 작성 시작 | P0 / U3 | UI 미구현 / 기능 미구현 | C09,C11 — 버킷 신규 저장 항목은 invitation=nil로 무동작. 일정 작성 화면 없음. | [8264:21250](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8264-21250),[8347:5904](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8347-5904) | 날짜/시간·본인 제외 최소 1명 초대 필수, 제안자 자동 ACCEPTED, 가족 한 줄 선택. 저장자와 제안자 구분. |
| PLAN-02 · 일정 가능 범위 검증 | P0 / U3 | UI 미구현 / 기능 미구현 | C09,C11 — 일정 날짜/시간 입력·검증 없음. | [8286:68142](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8286-68142) | 이벤트 기간 밖 선택 차단, 상시 장소 자유 선택, 원본 부족 시 공식 출처 확인 경고. 과거 날짜/최소 예약시간은 별도 확정 필요. |
| PLAN-08 · 초대장 만들기/미리보기 | P0 / U3 | UI 부분 구현 / 기능 부분 구현 | C11 — InvitationView 미리보기는 고정 샘플에서 열린다. | [8103:74562](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8103-74562) | 작성값 전달·누락 필드 이동, 제안자/대상 구분 필요. 미리보기만으로 응답 레코드 생성 금지. |
| PLAN-09 · 초대장 발송 방법 선택 | P0 / U3 | UI 부분 구현 / 기능 부분 구현 | C11 — 발송 방법 시트 존재. 앱은 성공 배너만, Kakao는 닫기만 수행. | [8286:69073](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8286-69073),[8286:75889](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8286-75889) | 로컬 일정/인앱 알림과 외부 공유를 연결. 공유 취소/푸시 실패로 일정 삭제·수락 변경 금지. mock 발송임을 명시. |
| PLAN-03 · 활동 제안 전송 | P0 / U3 | UI 미구현 / 기능 미구현 | C11,C15 — 일정/사용자 응답 생성 없이 배너만 표시. | 연관:[8103:74562](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8103-74562),[8286:75889](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8286-75889) | 제안자 ACCEPTED·선택 대상만 PENDING, 재전송 중복 방지, 24시간 기준 응답 마감 계산·표시 필요. |
| PLAN-04 · 일정 초대 수락/거절 | P0 / U3 | UI 부분 구현 / 기능 부분 구현 | C11 — 수락 확인 시트/거절 버튼은 있으나 복귀만 한다. | [7883:23898](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7883-23898),[8103:74725](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8103-74725) | 앱 내 수락/거절 저장·마감 전 변경, 마감 이후/초대 안 된 사용자 차단. 미응답은 상태이며 선택 버튼 아님. |
| PLAN-05 · 일정 확정 상태 계산 | P0 / U3 | UI 미구현 / 기능 미구현 | C10,C11 — 예정/확정/완료 enum만 있고 응답 집계·마감 계산 없음. | 연관:[8450:21636](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8450-21636),[8495:10372](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8495-10372) | 제안자 외 1명 ACCEPTED면 즉시 확정. 0명이면 마감 전 응답 대기/마감 후 미확정, 변경 시 재계산. 모두 수락 요구 금지. |
| PLAN-06 · 일정 수정 | P1 / U6 | UI 미구현 / 기능 미구현 | C11 — 일정 편집·재확인 UI/모델 없음. | [8495:10210](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8495-10210) | 제안자만 핵심 수정·영향받는 수락자 재확인 필요·새 마감, 메모만 변경 시 유지. 시작 후 핵심 수정 금지. |
| PLAN-07 · 일정 취소 | P0 / U3 | UI 미구현 / 기능 미구현 | C11 — 확정/대기 일정 취소 상태·확인 액션 없음. | 연관:[8495:10210](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8495-10210),[8459:8069](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8459-8069) | 제안자 취소 확인, CANCELLED 배지/알림·홈 제외. 완료 취소 금지, 다른 유효/완료 이력 없는 버킷만 SAVED 복귀. |
| DAY-01 · 약속 당일 화면 | P0 / U4 | UI 부분 구현 / 기능 부분 구현 | C12,C11 — 오늘·confirmed·isCurrentUserConfirmed 가드와 3영역 화면 있음. 루트는 나 1명 확정 mock이다. | [8264:21631](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8264-21631),[8450:21636](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8450-21636) | 실제/명시적 mock 최종 참여자·취소/미확정 상태와 홈 진입 연결. 현재 1인 확정 샘플은 PLAN-05 기준과 불일치. |
| DAY-02 · 필수 활동 | P0 / U4 | UI 부분 구현 / 기능 부분 구현 | C12 — requiredActivities.prefix(3) 표시/빈 상태 있음. 메인에서는 빈 배열. | [8264:21631](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8264-21631) | 근거 있는 2~3개 데이터와 출처 계약, 근거 부족은 범용 활동. 새 미션처럼 별도 완료 흐름을 만들지 않음. |
| DAY-03 · 필수템 추천 | P0 / U4 | UI 부분 구현 / 기능 부분 구현 | C12 — 준비물 4개까지 title/reason 표시 가능. 메인에서는 비어 있음. | [8264:21631](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8264-21631) | 공식 준비물→안전/날씨→편의 규칙·이유, 날씨 실패 시 날씨 항목 제외. 임의 준비물 생성 금지. |
| DAY-04 · 근처 놀거리 추천 | P0 / U4 | UI 부분 구현 / 기능 부분 구현 | C12 — 추천 배열 정렬/빈 상태 UI 있음. | [8264:21631](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8264-21631),[8451:22353](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8451-22353) | 일정 장소 좌표 기준 후보·메인 원본/장소 제외·종료/시간대/위치 검증 필요. GPS 기반으로 바꾸지 않음. |
| DAY-05 · 예상 활동 정보 | P0 / U4 | UI 부분 구현 / 기능 부분 구현 | C12,C11 — 걸음수·시간 문자열 표시, 메인은 정보 없음이다. | [8264:21631](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8264-21631) | 공식 소요시간/거리 우선, 근거 부족 시 범위/단계 표시. 행사 운영시간을 체류시간으로 쓰지 않음. |
| WTH-01 · 날씨 조회 | P0 / B0 | UI 비화면 / 기능 연동 미구현·서버 미검증 | C12,C18 — 날씨 조회/캐시·위치/시간/예보범위 모델 없음. | 연관:[8264:21631](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8264-21631) | 일정 장소·시간 확정+예보 범위에서만 조회. 실패해도 당일 UI 제공, 날짜 없는 버킷 날씨 추정 금지. 독립 날씨 화면 요구 아님. |

### 4.6. 캘린더·기록

| 기능 ID · 기능명 | 원본 우선순위 / 단계 | UI / 기능 상태 | 코드 근거 · 현재 동작 | Figma 대조 | 미구현 UI·정책·예외 처리 |
| --- | --- | --- | --- | --- | --- |
| CAL-01 · 월간 조회 | P0 / U3 | UI 부분 구현 / 기능 부분 구현 | C10,C01 — 월 이동·일정/버킷 탭 존재. 오늘 데모만 공급. | [7883:25337](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7883-25337),[8105:76303](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8105-76303) | 월별 가족 공동 데이터·browse 연결 유도 필요. 비초대 가족도 조회 가능하되 응답 UI 숨김. |
| CAL-02 · 미래 일정 표시 | P0 / U3 | UI 부분 구현 / 기능 부분 구현 | C10,C11 — 예정/확정/완료 표시만 존재. | [7883:25337](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7883-25337),[8495:10372](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8495-10372) | 일정 상태와 개인 미응답/수락/거절/재확인 필요를 분리, 취소 표현·비초대자 가족 일정 조회 필요. 고민중/MAYBE 금지. |
| CAL-03 · 완료 날짜 대표사진 | P0 / U5 | UI 부분 구현 / 기능 부분 구현 | C10,C14 — 완료 셀은 photo.fill 아이콘. 대표사진 URL 필드는 사용되지 않는 빈 데이터에만 있다. | [7883:25337](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7883-25337),[7903:1926](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7903-1926) | 날짜 대표 썸네일·같은 날 추가 활동 수·사진 없음 마커 연결. LOG-03/09와 같은 대표사진 상태 사용. |
| CAL-04 · 하루 활동 목록 | P0 / U3 | UI 미구현 / 기능 미구현 | C10 — selectDay가 첫 일정/리뷰만 열어 하루 목록이 없다. | 연관:[7883:25337](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7883-25337) | 날짜별 시간순 복수 활동/빈 날짜 화면 필요. 이전 코드 주석의 별도 목록 없음 판단은 최신 명세로 폐기. |
| CAL-05 · 가족 버킷리스트 조회 | P0 / U2 | UI 부분 구현 / 기능 부분 구현 | C09,C08 — 전체/엄마/아빠/딸 필터·고정 샘플+로컬 저장 항목 있음. | [8103:73442](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8103-73442),[8103:74308](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8103-74308) | member ID 기반 동적 필터·저장일/저장자/연결·완료 상태, 탈퇴자 익명화, 취소/종료 새 일정 제한. 완성된 항목도 재참여 가능. |
| LOG-01 · 완료 처리 | P0 / U5 | UI 부분 구현 / 기능 부분 구현 | C13,C10,C08 — 4개 필수 입력을 검증한 Draft로 오늘 캘린더 완료 표시. | [8079:12515](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8079-12515) | 최초 유효 리뷰→일정/버킷/주간 완료 공동 반영, 다른 참여자 추가 리뷰 필요. 지난 활동 신규 작성 진입도 누락. |
| CAL-06 · 질문 전원 답변 날짜 표시 | P0 / U1 | UI 미구현 / 기능 미구현 | C10,C05 — 캘린더에 질문/가족 전원 답변 모델·캐릭터 블록 없음. | 연관:[7883:25337](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7883-25337) | 해당 날짜 전원 답변 시 KIRI 블록. 활동 사진과 동시 표시 방식은 명세 자체 디자인 검토 항목으로 남김. |
| LOG-02 · 사진 여러 장 업로드 | P0 / U5 | UI 부분 구현 / 기능 부분 구현 | C13 — 사진 최대 10장 로컬 선택·삭제·최소1장 검증 구현, 일부 로딩 실패는 조용히 건너뜀. | [8012:10942](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8012-10942) | 사진별 성공/실패·재시도·기록 연결 필요. 최초 리뷰 첫 사진만 자동 대표, 후속 리뷰로 자동 교체 금지. 10장 상한은 명세 미확정. |
| LOG-03 · 대표사진 지정 | P0 / U5 | UI 부분 구현 / 기능 부분 구현 | C13,C14,C10 — 각 로컬 리뷰의 첫 사진을 그려 주지만 활동별 대표사진 식별자는 없다. | [8763:17631](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8763-17631) | 최초 유효 리뷰 첫 사진 기본값·선택 변경·삭제 대체·카드/캘린더 반영. LOG-09와 중복 개발하지 않음. |
| LOG-05 · 함께한 가족/장소 연결 | P0 / U5 | UI 부분 구현 / 기능 부분 구현 | C13,C11 — 날짜+제목 문자열 키와 일정 표시 정보만 연결한다. | [7903:1926](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7903-1926) | activity/schedule/member/mission ID 및 당시 참여자·장소 스냅샷 보존. 외부 정보 변경/탈퇴로 공동 기록 삭제 금지. |
| LOG-04 · 짧은 기록 작성 | P0 / U5 | UI 부분 구현 / 기능 부분 구현 | C13 — 500자 텍스트·공백 검증·초기 Draft 수정·임시 저장 연결. | [8012:10942](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8012-10942) | 사용자별 활동당 1리뷰·실패 유지·다른 참여자 분리·재진입 필요. 현재 날짜+제목 키로 재참여/다중 사용자 구분 불가. |
| LOG-06 · 그날 사진 연속 보기 | P0 / U5 | UI 부분 구현 / 기능 부분 구현 | C13,C14,C10 — 자기 리뷰 다중 썸네일은 있지만 날짜 내 활동별 연속 탐색 없음. | 연관:[7903:1926](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7903-1926),[8079:12515](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8079-12515) | 활동 헤더·시간/등록순 사진·활동 전환, 사진 없는 기록 표시. 사진을 날짜 단위로 무차별 합치지 않음. |
| LOG-08 · 가족별 리뷰 모아보기 | P0 / U5 | UI 부분 구현 / 기능 부분 구현 | C13,C14 — 내 리뷰+다른 가족 빈 상태만. FamilyReviewCard는 Preview 전용이다. | [8079:13084](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8079-13084),[8079:12515](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8079-12515) | 참여자별 사진·글·별점·의향, 가족 전용/탈퇴자 익명화. 기존 카드 확장 후 연결. |
| LOG-09 · 활동 대표사진 설정/변경 | P1 / U5 | UI 부분 구현 / 기능 부분 구현 | C13,C14,C10 — 내 리뷰 첫 사진 표시만 있고 활동 전체 사진 선택 화면 없음. | [8763:17631](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8763-17631),[8763:17548](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8763-17548) | LOG-03과 같은 활동 대표사진 1장 선택/변경, 원본 보존·삭제 fallback. P1이지만 P0 LOG-03에 포함된 선택 변경을 함께 구현. |
| LOG-10 · 재참여 의향 입력 | P0 / U5 | UI 구현 완료(로컬) / 기능 부분 구현 | C13 — 예/아니오 필수 선택·기존 Draft 로드/수정 UI 구현. | [8012:10942](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8012-10942) | 사용자/활동별 저장·실패 시 다른 입력 유지/재시도 미연동. 입력 UI 재작성 대신 저장 상태 보완. |
| LOG-11 · 활동 별점 입력 | P0 / U5 | UI 구현 완료(로컬) / 기능 부분 구현 | C13 — 1~5 정수 선택·범위/필수 검증·초기값 수정 UI 구현. | [8012:10942](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8012-10942) | 사용자별 영속 저장·유효 평가 집계 계약 연결. MIS-12 평균은 별개. |

### 4.7. 추천

| 기능 ID · 기능명 | 원본 우선순위 / 단계 | UI / 기능 상태 | 코드 근거 · 현재 동작 | Figma 대조 | 미구현 UI·정책·예외 처리 |
| --- | --- | --- | --- | --- | --- |
| REC-01 · 활동 완료 기반 갱신 | P0 / B0 | UI 비화면 / 기능 연동 미구현·서버 미검증 | C13,C18 — 완료 후 추천 STALE/재계산 호출부 없음. | 비화면 | 완료 신호 갱신·후처리 실패 큐, 활동 완료는 보존. 추천 실패 화면과 데이터 계약 필요. |
| REC-04 · 외부 후보 최신화와 개인화 분리 | P0 / B0 | UI 비화면 / 기능 연동 미구현·서버 미검증 | C06,C18 — 전체 카탈로그와 개인화 스냅샷 구분 없음. | 비화면 | 외부 최신화는 즉시 탐색 반영, 개인화는 유지하며 취소/만료 슬롯만 대체. 신규 화면 필요 없음. |
| REC-05 · 장기 미활동 보완 갱신 | P1 / B1 | UI 비화면 / 기능 연동 미구현·서버 미검증 | C04,C06,C18 — 추천 생성시각·7일 만료/재계산 없음. | 비화면 | 7일 이상 오래된 스냅샷은 다음 진입 시 보완, 실패 시 유효 후보 유지. 주간 미션 유지 규칙과 구분. |
| REC-06 · 재참여 의향 기반 추천 보정 | P0 / B0 | UI 비화면 / 기능 연동 미구현·서버 미검증 | C13,C18 — 재참여 의향 Bool을 추천에 사용하는 경로 없음. | 비화면 | 다음 추천부터 누적 신호로 보정, 단일 아니오를 절대 제외 규칙으로 사용 금지. |

### 4.8. 마이페이지

| 기능 ID · 기능명 | 원본 우선순위 / 단계 | UI / 기능 상태 | 코드 근거 · 현재 동작 | Figma 대조 | 미구현 UI·정책·예외 처리 |
| --- | --- | --- | --- | --- | --- |
| MY-01 · 내 프로필 조회/수정 | P1 / U6 | UI 부분 구현 / 기능 부분 구현 | C16,C03 — 프로필 고정값·연필 TODO. 가족 관리에서 닉네임 수정만 임시 반영. | [8213:3062](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8213-3062),[8216:3462](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8216-3462) | 프로필 진입 연결·전역 닉네임 중복·역할 캐릭터·허용 항목 편집 필요. 사진 업로드 금지, 월1회 문구는 명세 근거 없음. |
| MY-02 · 내 취향/활동 선호 설정 | P1 / U6 | UI 미구현 / 기능 미구현 | C16 — 취향테스트 버튼은 TODO, Figma 상세는 음식 텍스트 질문 시안이다. | 정책차이:[8596:18240](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8596-18240),[8213:3062](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8213-3062) | 내 취향 설정: 활동 최대3개/공간/활동량/비용/활동시간 5항목. 온보딩 필수 아님. 혼잡/분위기/지역/이동거리 질문 제외. |
| MY-03 · 가족 구성원 관리 | P0 / U0 | UI 부분 구현 / 기능 부분 구현 | C16 — 가족 관리 목록·이름 편집 존재. 엄마 2명 포함 고정 샘플이다. | [8216:3570](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8216-3570) | 실제 참여 완료 구성원·역할·닉네임 조회, 엄마/아빠 각1명 데이터, browse/탈퇴 제한. 초대 대기 가상 구성원 금지. |
| MY-04 · 가족명 변경 | P1 / U6 | UI 부분 구현 / 기능 부분 구현 | C16 — 가족명 편집은 누구나 진입 가능한 Binding 갱신이다. | [8216:3638](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8216-3638) | 현재 owner만 변경·전체 중복 오류, owner 탈퇴 시 가장 이른 참여자 승계·마지막 구성원 종료. 월1회 제한은 미명세. |
| MY-05 · 공용 초대 링크/초대코드 관리 | P0 / U0 | UI 부분 구현 / 기능 부분 구현 | C16,C03 — 설정 관리 진입은 TODO. 온보딩 코드 복사/공유 UI는 재사용 가능. | [8582:18039](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8582-18039),[8286:76347](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8286-76347) | 현재 링크+코드·7일 만료·수동 재발급 화면, 기존 폐기 및 인증 후 초대 복귀 필요. FAM-02/03과 한 구현으로 묶기. |
| MY-06 · 알림 설정 | P1 / U6 | UI 미구현 / 기능 미구현 | C16 — 알림 설정 버튼 TODO, OS 권한 조회 없음. | [8599:18423](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8599-18423) | 앱 푸시 on/off·OS 권한 꺼짐/설정 이동 안내. 푸시 OFF여도 인앱/핵심 상태 유지. 시각 선택은 최신 명세에 없어 보류. |
| MY-07 · 로그아웃 | P1 / U6 | UI 구현 완료(로컬) / 기능 부분 구현 | C16,C01 — 시스템 확인 alert→로컬 세션 제거→로그인 복귀 연결. | [8599:76698](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8599-76698) | 실제 기기 세션 종료 연동은 미구현. 가족/계정 삭제 금지, 계정별 로컬 캐시 분리 필요. Figma 커스텀 팝업은 시각 QA 잔여. |
| MY-09 · 건의함 | P1 / U6 | UI 미구현 / 기능 미구현 | C16,C13 — 건의함 버튼 TODO. 리뷰 사진 선택은 재사용 후보다. | [8599:76071](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8599-76071),[8763:17857](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8763-17857) | 필수 자유글+선택 이미지/대상 식별값, 빈 내용 차단·실패 초안 유지. 리뷰의 사진 필수 조건을 복사하면 안 됨. |
| MY-08 · 회원 탈퇴 | P1 / U6 | UI 미구현 / 기능 미구현 | C16 — 탈퇴 안내/확인/결과·owner/일정 후처리 없음. | [8599:76808](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8599-76808) | 개인정보 삭제·가족 관계 해제·미래 일정 참여 제거, 유일 참여 일정 취소, 마지막 구성원 공동 데이터 삭제 최종 확인, 과거 기록 익명화. |
| MY-10 · 우리 집 위치 설정 | P0 / U0 | UI 미구현 / 기능 미구현 | C16 — 주소 설정 버튼 TODO. 주소/좌표 데이터 없음. | [8556:9691](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8556-9691),[8556:10046](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8556-10046),[8556:9605](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8556-9605),[8582:18082](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8582-18082) | 가족 공통 위치 1개·권한별 등록/수정·검색/좌표 실패·미등록 안내. 온보딩에 넣지 않고 미등록도 서비스 허용. |
| MY-11 · 약관/개인정보/버전 정보 | P1 / U6 | UI 부분 구현 / 기능 부분 구현 | C16,C02 — 설정 버튼 TODO. 가입 약관 본문 시트만 존재한다. | [8599:76117](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8599-76117),[8599:76457](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8599-76457),[8599:76529](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8599-76529) | 설정용 정책 목록·본문/버전·라이선스·재시도 연결. AndroidX 예시를 iOS 실제 의존성처럼 복사 금지. |

### 4.9. 알림·시스템

| 기능 ID · 기능명 | 원본 우선순위 / 단계 | UI / 기능 상태 | 코드 근거 · 현재 동작 | Figma 대조 | 미구현 UI·정책·예외 처리 |
| --- | --- | --- | --- | --- | --- |
| NOTI-01 · 알림함 조회 | P0 / U3 | UI 부분 구현 / 기능 부분 구현 | C15 — 고정 목록/필터/읽음 수 표시. 수신자 ID·생성시각 정렬·조회 상태 없음. | [8459:8069](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8459-8069) | 최신순·로딩·0건·조회 실패/다시 시도·권한 소멸 대상 안내. 알림 삭제 기능 추가 금지. |
| NOTI-02 · 읽음/딥링크 | P0 / U3 | UI 부분 구현 / 기능 부분 구현 | C15,C04 — 선택 시 읽음, opensInvitation=true만 고정 요청으로 이동한다. | [8459:8069](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8459-8069) | type+targetId 기반 질문/일정/기록/가족 라우팅, 삭제/권한 없음 안내. 알림함 진입만으로 자동 모두읽음 금지. |
| NOTI-03 · 모두 읽음 | P1 / U6 | UI 구현 완료(로컬) / 기능 부분 구현 | C15 — 모두읽음은 로컬 ID Set 변경, 알림 원본은 삭제하지 않는다. | [8459:8069](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8459-8069) | 사용자별 읽음 저장·부분 실패 처리/재시도 필요. 로컬 UI는 재사용. |
| NOTI-04 · 일정 알림 | P0 / U3 | UI 부분 구현 / 기능 부분 구현 | C15,C11 — 일정 알림 샘플과 요청 상세만 있고 상태 이벤트 발생 없음. | [8459:8069](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8459-8069),[7883:23898](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7883-23898) | 초대/마감전 PENDING 1회/최초확정/재확인/취소/D-1/당일 알림 계약·각 상태 라우트. 수락/거절자 미응답 재촉 금지. |
| NOTI-05 · 콘텐츠 리마인드 | P1 / U6 | UI 부분 구현 / 기능 부분 구현 | C15,C04 — 미션/질문 관련 표시 샘플뿐 배정/리마인드 처리 없음. | [8459:8069](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8459-8069) | 정의된 목적별 횟수 제한, 푸시 OFF에서도 인앱 유지. 정확한 발송 시각/횟수는 명세 미확정. |
| SYS-01 · 가족 데이터 권한 | P0 / B0 | UI 비화면 / 기능 연동 미구현·서버 미검증 | C01,C18 — APIClient는 토큰 헤더만 처리, 활성 가족 권한 모델 없음. browse도 기록 진입 가능. | 연관:[8451:22900](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8451-22900) | 서버 활성 memberId/familyId 검증 계약과 클라이언트 접근 거부/연결 유도 필요. UI 가드만으로 서버 권한 완료 주장 금지. |
| SYS-02 · 알림 이벤트 생성 | P0 / B0 | UI 비화면 / 기능 연동 미구현·서버 미검증 | C15,C18 — 고정 알림 데이터만 존재, 이벤트 키/수신자/targetId·푸시 없음. | 연관:[8459:8069](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8459-8069) | 인앱 이벤트 먼저 저장·멱등 키·푸시 독립 실패. 기능 상태/인앱 기록을 푸시 실패로 롤백하지 않음. |


## 5. Figma 사용자 플로우 기준 개발 순서

P0/P1은 구현 순서를 결정하지 않는다. 모든 기능 ID를 구현 대상으로 두고, Figma `끼리 UI` 페이지의 화면 연결과 상태 프레임을 기준으로 다음 플로우를 진행한다. 각 단계는 C01~C18의 기존 화면을 확장하며, 동일 목적의 새 화면/스토어를 중복 생성하지 않는다.

| 플로우 | Figma 기준 화면 연결 | 구현 범위와 완료 기준 |
| --- | --- | --- |
| F1 진입·로그인·온보딩 | `8095:62668` → `8095:62717` → `8296:13599` → `8098:73065` → `7883:23313` → `7883:23399` | 스플래시·소셜 로그인·약관·닉네임·역할·가족 생성/참여를 연결한다. 이번 작업은 로그인 `8159:13178`을 구현했다. 명세의 Apple 로그인은 Figma 기준 프레임에 없어 현재 버튼을 유지하고 차이로 기록한다. |
| F2 가족 초대·가족 홈 | `8582:18039` → `8347:7411` → `8070:11636` | 공용 초대 링크/코드, 홈 진입, 질문 카드·콕·가족 상태를 연결한다. |
| F3 질문·주간 미션 | `8187:14904` → `8012:9925` → `8012:10311` | 질문 입력/수정과 플립 상태, 일정 배너·전원 답변 상태를 연결한다. |
| F4 미션·버킷 | `7948:1685` → `8451:22353` → `8534:8734` | 미션 목록·상세·저장·저장자 필터와 완료 후 재참여를 기존 뷰/스토어에 연결한다. |
| F5 일정 생성·초대 응답 | `8264:21250` → `8286:68142` → `8286:67882` → `7883:23898` → `8286:69073` | 날짜·시간·참여자 선택, 미리보기, 전송 방식, 수락/거절·마감 상태를 연결한다. |
| F6 캘린더·당일 활동 | `7883:25337` → `8450:21636` → `8264:21631` → `7905:10295` | 월간·하루 목록, 참여자 확인, 활동·조건·날씨 상태를 연결한다. |
| F7 기록·리뷰 | `8012:10942` → `8079:13084` → `7903:1926` → `8079:12515` | 기록 작성/수정, 사진 선택, 가족 리뷰, 완료 화면을 연결한다. |
| F8 마이페이지·가족 관리 | `8213:3062` → `8216:3570` → `8556:9605` → `8596:18240` | 설정·가족 관리·우리 집 위치·취향 화면을 최신 명세와 대조해 구현한다. Figma의 취향 화면 내용과 최신 5항목 명세가 달라 보고 후 확정한다. |
| F9 계정·알림·예외 상태 | `8459:8069` → `8599:18423` → `8599:76808` → `8599:76071` | 알림함·푸시 설정·탈퇴·건의함과 각 로딩/빈/실패/권한 상태를 연결한다. |

### 이번 화면 구현 기록: 로그인

기준 프레임은 [로그인/회원가입 `8159:13178`](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8159-13178)이다. 기존 `LoginView`의 텍스트 KIRI 로고를 Figma 제공 로고 자산으로 교체하고, 캐릭터 72×72, 로고 150×54, 버튼 354×54, 버튼 간격 12pt, Google 버튼 테두리를 반영했다. 카카오·Google 버튼은 기존 로컬 콜백을 유지한다.

Figma 기준 프레임에는 카카오·Google 두 버튼만 있지만 최신 기능명세서는 Apple 로그인을 필수로 요구한다. Apple 버튼은 삭제하거나 임의로 Figma 안에 재배치하지 않고 세 번째 로컬 버튼으로 유지했으며, 이 부분은 디자인 일치 미완료로 남긴다. Figma의 로그인 프레임에는 실패/취소 상태가 별도 표시되지 않아 현재 코드의 로컬 상태 연결 범위와 서버 오류 처리는 후속 계약 대상이다.

### 이번 화면 구현 기록: 둘러보기 홈

기준 프레임은 [홈/초기 `8450:19981`](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8450-19981)이다. 기존 `BrowseHomeView`의 소개 문구·설명형 카드·SF Symbol 목록을 제거하고, Figma의 `끼리네 가족` 상단 제목, `가족공간 만들러 가기` 액션 카드, `엄마와 함께라면 여기!` 및 `오늘 가을분위기를 느끼고 싶다면` 가로 장소 카드 섹션으로 교체했다. `PlaceCard`는 기존 컴포넌트를 유지한 채 Figma 카드 크기(251×284), 이미지 영역(144), 별점·인용 아이콘·텍스트 토큰을 지원하도록 확장했다.

둘러보기에서는 질문 답변, 콕, 가족 답변 모아보기, 가족 미션 완료, 가족 버킷·일정·기록을 생성하거나 저장하지 않는다. CTA의 실제 가족 생성/참여 전환은 현재 앱 라우터에 전용 진입 경로가 없어 후속 연결 대상이며, 화면에는 Figma에 없는 안내 모달을 임의로 추가하지 않았다. 공개 장소 추천은 로컬 샘플이며 서버 데이터로 표시하지 않는다.

### 비화면 기능과 UI 의존성

B0는 비화면 기능 17개로, UI 우선 방침 때문에 서버 구현을 뒤로 분리한 것이다. 관련 Figma 플로우 시작 시 필요한 ID·상태·권한·실패 응답 계약을 먼저 정하고, **mock임을 구분하는 로컬 데이터**로 UI를 완성한다. 실제 발급·전송·추천·저장 성공처럼 표시하는 방식은 사용하지 않는다. 운영 출시 전 서버 계약과 실제 동작 검증은 필수다.

B0 내부 의존성은 SYS 권한/이벤트 → 외부 수집·증분·중복/이미지·미션 생성 → 종료/무효화 전파 → 날씨 → 취향 집계/추천이다. F1의 가족 권한, F4의 피드/버킷, F5~F7의 상태 전파, F6의 날씨가 관련 UI 전제다. B1의 일일 정합성 보정과 7일 초과 취향 스냅샷은 해당 화면의 상태를 완성하기 위한 데이터 계약으로 함께 관리한다.

### 플로우별 기능 ID 추적표

각 ID는 아래 표에 정확히 한 번 배정했다. 세부 정책·누락은 4절을 따른다.

| 단계 | 기능 수 | 원본 기능 ID |
| --- | ---: | --- |
| F1 | 18 | ENT-01, AUTH-01, AUTH-02, ONB-01, ONB-02, ONB-03, ONB-04, ONB-05, FAM-01, FAM-02, FAM-03, FAM-04, FAM-05, FAM-06, FAM-07, MY-03, MY-05, MY-10 |
| F2 | 12 | HOME-01, HOME-02, HOME-05, HOME-REC-01, HOME-REC-02, Q-01, Q-02, Q-03, Q-04, Q-05, CAL-06, HOME-04 |
| F3 | 8 | MIS-01, MIS-02, MIS-03, MIS-04, MIS-07, MIS-09, MIS-12, CAL-05 |
| F4 | 14 | PLAN-01, PLAN-02, PLAN-03, PLAN-04, PLAN-05, PLAN-07, PLAN-08, PLAN-09, CAL-01, CAL-02, CAL-04, NOTI-01, NOTI-02, NOTI-04 |
| F5 | 6 | DAY-01, DAY-02, DAY-03, DAY-04, DAY-05, MIS-11 |
| F6 | 11 | LOG-01, LOG-02, LOG-03, LOG-04, LOG-05, LOG-06, LOG-08, LOG-10, LOG-11, CAL-03, LOG-09 |
| F7 | 19 | FAM-D-01, FAM-D-02, HOME-03, HOME-REC-03, MIS-05, MIS-06, MIS-08, MIS-10, PLAN-06, MY-01, MY-02, MY-04, MY-06, MY-07, MY-08, MY-09, MY-11, NOTI-03, NOTI-05 |
| B0 | 17 | TASTE-01, TASTE-02, TASTE-03, TASTE-05, MIS-13, MIS-14, EXT-01, EXT-02, EXT-04, EXT-05, EXT-06, WTH-01, REC-01, REC-04, REC-06, SYS-01, SYS-02 |
| B1 | 2 | EXT-03, REC-05 |


## 6. 검증 결과와 한계

- CSV 107개 ID와 4절 표를 일대일 대조하고 원본 명칭·P0/P1을 유지했다. 단계 배정도 107개 ID에 중복/누락이 없다.
- 코드 근거의 로컬 경로, Figma 대응 노드 존재, UI 분류 합계, CSV 원본 해시를 확인했다. Figma 노드 존재가 기능 동작이나 최신 정책 충족을 증명하지는 않는다.
- 이번 작업에서 로그인 SwiftUI와 Figma 정적 자산을 수정했으므로 xcodebuild를 실행했다. 컴파일 단계까지 진행되었으나 CoreSimulatorService가 사용할 시뮬레이터 런타임을 제공하지 않아 asset catalog 단계에서 실패했다. 오류는 코드 문법이 아니라 `No available simulator runtimes for platform iphonesimulator`이다.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project KIRI/KIRI.xcodeproj -scheme KIRI \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -configuration Debug -derivedDataPath /tmp/KIRIImplementationAudit \
  CODE_SIGNING_ALLOWED=NO build
```

현재 로그: `/tmp/kiri-login-build.log`. 기존 경고는 Info-Debug.plist의 Copy Bundle Resources 포함이다. 시뮬레이터 서비스가 복구되면 동일 명령을 다시 실행하고, 그 뒤 실제 시뮬레이터 화면과 Figma를 비교한다. 이전 코드 기준 성공 로그는 `/tmp/kiri-implementation-audit-build.log`에 남아 있다.

코드상 연결 여부와 로컬 상태 전이를 검토했으나, 모든 화면의 시뮬레이터 터치·실기기·픽셀 비교·서버 인증/권한 테스트는 수행하지 않았다. 따라서 표의 ‘로컬 완료’와 과거 빌드 성공을 운영 기능 검증으로 확대 해석하지 않는다. 문서는 `git diff --check`로 형식을 검증한다.

## 7. 이번 변경 파일

| 파일 | 처리 |
| --- | --- |
| `docs/IMPLEMENTATION_STATUS.md` | Figma 사용자 플로우 기준 순서, 로그인 구현 프레임·차이·빌드 결과를 반영. 기존 107개 ID·Figma/Swift 인벤토리 보존 |
| `docs/specs/KIRI_FEATURE_SPEC_LATEST.csv` | 읽기 전용 기준 자료. 원본 미변경, 미스테이징 |
| `KIRI/KIRI/Features/Auth/LoginView.swift` | Figma 로그인 프레임 레이아웃·로고/캐릭터·버튼 스타일과 로컬 로그인 동작 수정 |
| `KIRI/KIRI/Assets.xcassets/kiri_logo.imageset`, `kiri_character.imageset` | Figma에서 제공된 로그인 정적 자산을 로컬 번들에 추가 |
| `KIRI/KIRI/Features/Home/BrowseHomeView.swift` | Figma `8450:19981` 둘러보기 홈 레이아웃·공개 추천 UI로 교체 |
| `KIRI/KIRI/Features/Home/Components/PlaceCard.swift` | 기존 장소 카드에 Figma 이미지·별점·인용 아이콘과 카드 규격 지원 추가 |
| `KIRI/KIRI/Assets.xcassets/browse_*` | 둘러보기 장소 이미지 및 Figma 아이콘을 로컬 번들에 추가 |

커밋·푸시는 수행하지 않았다. 이후 구현도 파일별 변경을 보고한 뒤 커밋하며, 커밋 메시지는 요청한 `[Feat] : 설명` / `[Fix] : 설명` 형식을 따른다.



## 부록 A. Figma 화면 프레임 인벤토리

지정된 끼리 UI 페이지 바로 아래의 100개 화면 프레임을 묶어 나열했다. 같은 이름이라고 같은 구현 상태로 단정하지 않으며 4절 기능 ID별 정책·진입 경로 판정을 우선한다. 최신 CSV에 없는 과거 시안도 인벤토리에는 남기되 개발 요구사항으로 자동 채택하지 않는다. 제목용 Frame, 논의사항, 화면설계서 사본은 신규 구현 화면 수에 포함하지 않는다. 상세 시각 QA 미완료 상태다.

| Figma 화면명 / 실제 내용 | 상태별 원본 노드 |
| --- | --- |
| 요청받았을 때 | [7883:23898](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7883-23898), [8103:74725](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8103-74725) |
| 요청방법 선택 | [8286:69073](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8286-69073) |
| 요청할 때 | [8103:74562](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8103-74562) |
| 기록 | [7883:25337](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7883-25337), [8105:76303](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8105-76303) |
| 버킷리스트 | [8103:73442](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8103-73442), [8103:74308](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8103-74308) |
| 앱으로보내기 | [8286:75889](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8286-75889) |
| 플레이스/리뷰집 | [8079:13084](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8079-13084) |
| 시계클릭시/인원확인 | [8286:69561](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8286-69561) |
| 약속당일 | [8264:21631](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8264-21631), [8448:17769](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8448-17769), [8448:18068](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8448-18068) |
| 약속이후/기록작성 | [8012:10942](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8012-10942) |
| 약속당일 (실제 내용: 컨디션 조정) | [7905:10295](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7905-10295) |
| 플레이스 | [7948:1685](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7948-1685), [8495:9657](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8495-9657), [8451:22069](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8451-22069), [8451:22229](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8451-22229) |
| 플레이스 (실제 내용: 설정) | [8213:3062](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8213-3062) |
| 닉네임수정 | [8216:3462](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8216-3462) |
| 가족명수정 | [8216:3638](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8216-3638) |
| 홈/초기 | [8347:7411](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8347-7411), [8347:7734](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8347-7734), [8450:19981](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8450-19981), [8451:22900](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8451-22900) |
| 홈/배너 | [8153:9957](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8153-9957) |
| 홈/콕찌르기 | [8070:11636](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8070-11636) |
| 홈/미션완성/플립 | [8012:9925](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8012-9925), [8460:8451](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8460-8451), [8460:8707](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8460-8707) |
| 홈/미션완성/약속당일 | [8012:10311](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8012-10311) |
| 사진 클릭시 화면 | [7903:1926](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7903-1926), [8763:17548](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8763-17548), [8763:17749](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8763-17749) |
| 기록완료화면 | [8079:12515](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8079-12515) |
| 온보딩_관계대상 선택 (실제 내용: 관심사) | [7883:23342](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7883-23342) |
| 온보딩_물리적거리 | [7883:23383](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7883-23383) |
| 온보딩_물리적거리 (실제 내용: 가족 구성원 수) | [8040:11123](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8040-11123) |
| 스플래시 | [8095:62668](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8095-62668), [8159:13167](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8159-13167), [8232:12374](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8232-12374) |
| 로그인/회원가입 | [8095:62717](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8095-62717), [8159:13178](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8159-13178), [8232:12385](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8232-12385) |
| 알림함 | [8459:8069](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8459-8069) |
| 약관동의 | [8296:13599](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8296-13599), [8159:13189](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8159-13189), [8296:13525](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8296-13525) |
| 온보딩_맞춤질문 | [7883:23436](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7883-23436) |
| 사진 클릭시 화면 (실제 내용: 사진 변경 선택) | [8763:17631](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8763-17631) |
| 가족관리 | [8216:3570](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8216-3570) |
| 우리집위치/O | [8556:9605](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8556-9605) |
| 우리집 위치/X | [8556:9691](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8556-9691) |
| 공용초대링크 | [8582:18039](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8582-18039) |
| 취향테스트 | [8596:18240](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8596-18240) |
| 건의함 | [8599:76071](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8599-76071), [8763:17857](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8763-17857) |
| 계정정보 | [8599:76117](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8599-76117) |
| 로그아웃 | [8599:76698](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8599-76698) |
| 회원탈퇴 | [8599:76808](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8599-76808) |
| 이용약관 | [8599:76457](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8599-76457) |
| 오픈라이선스 | [8599:76529](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8599-76529) |
| 우리집 위치/X/우편번호 입력완료 | [8556:9927](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8556-9927) |
| 주소검색화면 | [8556:10046](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8556-10046) |
| 우리집위치/O/수정 | [8582:18082](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8582-18082) |
| 푸시알림 | [8599:18423](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8599-18423) |
| 홈/콕찌르기/답변X | [8159:12976](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8159-12976) |
| 온보딩_역할선택 | [7883:23313](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7883-23313), [8232:12407](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8232-12407), [8159:11948](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8159-11948), [8098:73036](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8098-73036) |
| 온보딩_닉네임 작성 | [8098:14575](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8098-14575), [8232:12444](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8232-12444), [8159:11977](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8159-11977), [8098:73065](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8098-73065), [8098:72612](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8098-72612), [8232:12475](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8232-12475), [8159:12000](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8159-12000), [8098:73088](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8098-73088) |
| 홈/질문카드클릭 | [8187:14904](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8187-14904), [8187:15072](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8187-15072), [8187:15113](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8187-15113) |
| 온보딩_가족초대 | [7883:23399](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7883-23399), [8098:72650](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8098-72650), [8098:72709](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8098-72709), [8098:72786](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8098-72786) |
| 가족초대 | [8286:76347](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8286-76347) |
| 온보딩_가족코드입력 | [8159:12141](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8159-12141) |
| 요청작성_1 | [8264:21250](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8264-21250) |
| 일정선택 | [8286:68142](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8286-68142) |
| 가족 구성원 선택/6명 | [8286:67882](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8286-67882), [8347:5904](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8347-5904) |
| 가족 구성원 선택/4명 | [8347:6216](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8347-6216) |
| 시계클릭/당일 | [8450:21636](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8450-21636) |
| 일정변경 | [8495:10210](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8495-10210) |
| 플레이스/세부미션 | [8451:22353](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8451-22353) |
| 시계클릭/다른날 | [8495:10372](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8495-10372) |
| 버킷리스트 (활동 상세 상태) | [8534:8734](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8534-8734) |

## 부록 B. 전체 Swift 파일 인벤토리

경로는 `KIRI/KIRI/` 기준. 줄 수는 분석 기준 커밋의 값이다. Preview 타입은 앱 화면으로 집계하지 않는다.

| 파일 | 줄 수 | 주요 선언 |
| --- | ---: | --- |
| `App/AppRouter.swift` | 117 | AppRouter |
| `App/MainTabView.swift` | 67 | MainTabView |
| `App/RootView.swift` | 46 | RootView |
| `ContentView.swift` | 24 | ContentView |
| `Core/Components/KIRIBackButton.swift` | 43 | KIRIBackButton |
| `Core/Components/KIRIChip.swift` | 74 | KIRIChip, KIRIChipButtonStyle |
| `Core/Components/KIRICodeInput.swift` | 151 | KIRICodeInput, KIRICodeInputPreview |
| `Core/Components/KIRIPrimaryButton.swift` | 150 | KIRIPrimaryButton, KIRIPrimaryButtonStyle |
| `Core/Components/KIRISearchField.swift` | 107 | KIRISearchField, KIRISearchFieldPreview |
| `Core/Components/KIRIShareSheet.swift` | 24 | KIRIShareSheet |
| `Core/Components/KIRITabBar.swift` | 203 | KIRITabBar, KIRITabButtonStyle |
| `Core/Components/KIRITextField.swift` | 287 | KIRITextField, KIRITextFieldPreview |
| `Core/Components/KIRITopTab.swift` | 93 | KIRITopTab, KIRITopTabPreviewItem |
| `Core/Components/KIRIValidationGuidance.swift` | 39 | KIRIValidationGuidance |
| `Core/DesignSystem/KIRIColor.swift` | 327 | KIRIColor |
| `Core/DesignSystem/KIRIRadius.swift` | 10 | KIRIRadius |
| `Core/DesignSystem/KIRISpacing.swift` | 15 | KIRISpacing |
| `Core/DesignSystem/KIRITypography.swift` | 131 | KIRITypography |
| `Core/Network/APIClient.swift` | 129 | APIClient |
| `Core/Network/APIConfig.swift` | 13 | APIConfig |
| `Core/Network/APIEndpoint.swift` | 29 | HTTPMethod, APIEndpoint |
| `Core/Network/APIError.swift` | 37 | APIError |
| `Core/Storage/AppSessionStore.swift` | 73 | AppSessionStore |
| `Features/Auth/AuthFlowView.swift` | 141 | AuthFlowView, SocialLoginProvider |
| `Features/Auth/LoginView.swift` | 231 | LoginView, SocialLoginButtonContent |
| `Features/Auth/Social/AppleSignInButton.swift` | 0 | 빈 파일 |
| `Features/Auth/TermsAgreementView.swift` | 501 | TermsAgreementView, TermAgreementRow, AgreementCheckbox, TermType, TermDetailView |
| `Features/Home/BrowseHomeView.swift` | 143 | BrowseHomeView |
| `Features/Home/Components/FamilyMemberItem.swift` | 71 | FamilyMemberItem |
| `Features/Home/Components/PlaceCard.swift` | 90 | PlaceCard |
| `Features/Home/Components/QuestionCard.swift` | 49 | QuestionCard |
| `Features/Home/FamilyHomeView.swift` | 390 | FamilyHomeView |
| `Features/Home/HomeView.swift` | 27 | HomeView |
| `Features/Home/Notification/NotificationView.swift` | 468 | NotificationView |
| `Features/Mission/MissionActivityDetailView.swift` | 188 | MissionActivityDetailView |
| `Features/Mission/MissionBucketStore.swift` | 51 | MissionBucketStore |
| `Features/Mission/MissionPlaceCard.swift` | 290 | MissionPlaceCard, MissionPlaceTag, MissionPlaceCardPreview |
| `Features/Mission/MissionView.swift` | 275 | MissionView |
| `Features/MyPage/FamilyNameEditView.swift` | 112 | FamilyNameEditView |
| `Features/MyPage/FamilySettingsView.swift` | 194 | FamilySettingsView, FamilyMember |
| `Features/MyPage/MyPageView.swift` | 408 | MyPageView |
| `Features/MyPage/NicknameEditView.swift` | 112 | NicknameEditView |
| `Features/Onboarding/FamilyCodeInputView.swift` | 114 | FamilyCodeInputView |
| `Features/Onboarding/FamilyCodeLoadingView.swift` | 38 | FamilyCodeLoadingView |
| `Features/Onboarding/FamilyCodeView.swift` | 159 | FamilyCodeView |
| `Features/Onboarding/FamilyEntryView.swift` | 118 | FamilyEntryView |
| `Features/Onboarding/FamilyJoinConfirmView.swift` | 100 | FamilyJoinConfirmView |
| `Features/Onboarding/FamilyJoinLoadingView.swift` | 38 | FamilyJoinLoadingView |
| `Features/Onboarding/FamilyNameView.swift` | 122 | FamilyNameView |
| `Features/Onboarding/NicknameView.swift` | 130 | NicknameView |
| `Features/Onboarding/OnboardingFlowView.swift` | 217 | OnboardingFlowView |
| `Features/Onboarding/RoleSelectionView.swift` | 143 | FamilyRole, RoleSelectionView |
| `Features/Record/Components/FamilyReviewCard.swift` | 159 | FamilyReviewCard |
| `Features/Record/Components/RecordBucketListView.swift` | 577 | RecordBucketListView |
| `Features/Record/Components/RecordCalendarView.swift` | 661 | RecordCalendarView |
| `Features/Record/Components/ScheduleParticipantTooltip.swift` | 99 | ScheduleParticipantTooltip |
| `Features/Record/Invitation/InvitationSendMethodSheet.swift` | 197 | InvitationSendMethodSheet |
| `Features/Record/Invitation/InvitationView.swift` | 373 | InvitationView |
| `Features/Record/RecordView.swift` | 366 | RecordView |
| `Features/Record/Request/AddScheduleSheet.swift` | 292 | AddScheduleSheet |
| `Features/Record/Request/InvitationRequestView.swift` | 362 | InvitationRequestView |
| `Features/Record/Review/ActivityReviewCompleteView.swift` | 175 | ActivityReviewCompleteView |
| `Features/Record/Review/ActivityReviewWriteView.swift` | 493 | ActivityReviewWriteView |
| `Features/Record/Review/ReviewDetailView.swift` | 922 | ReviewDetailView |
| `Features/Record/Schedule/ConditionAdjustmentSheet.swift` | 255 | ConditionAdjustmentSheet |
| `Features/Record/Schedule/ScheduleDetailView.swift` | 259 | ScheduleDetailView |
| `Features/Record/Schedule/ScheduleScreenPreview.swift` | 182 | ScheduleScreenPreview |
| `Features/Record/Schedule/TodayActivityView.swift` | 581 | TodayActivityView |
| `KIRIApp.swift` | 10 | KIRIApp |
| `Models/FamilyInvitation.swift` | 7 | FamilyInvitation |
