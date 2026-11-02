# KIRI iOS UI 파일 가이드

이 문서는 Figma를 보면서 SwiftUI 화면을 수정할 때 변경 지점을 찾는 안내서입니다. UI만 바꿀 때는 `Features`와 `Core/Components`, 디자인 토큰을 우선 확인하고 인증·API 계약 파일은 필요할 때만 수정합니다.

## 디렉터리 구조

- `KIRI/App`: 앱 시작점, 라우팅, 탭 구성
- `KIRI/Core/Components`: 공통 버튼·텍스트 필드·이미지·탭바
- `KIRI/Core/DesignSystem`: 색상, 폰트, 간격, 반경
- `KIRI/Core/Network`: API endpoint, DTO, 인증 요청
- `KIRI/Core/Storage`: 토큰과 계정별 세션 저장
- `KIRI/Features/{Auth,Onboarding,Home,Mission,Record,MyPage}`: 화면과 화면별 컴포넌트
- `KIRI/Assets.xcassets`: 로컬 이미지·아이콘

## 화면 매핑

| 화면 | 메인 파일 | 관련 컴포넌트 | Figma 노드 | 주요 수정 지점 |
|---|---|---|---|---|
| 스플래시 | `Features/Auth/SplashView.swift` | `KIRIApp.swift` | Handoff 인증 영역 | 로고 크기·배경 |
| 로그인 | `Features/Auth/LoginView.swift` | 소셜 로그인 버튼 | Handoff 인증 영역 | 버튼 높이·간격 |
| 약관 | `Features/Auth/TermsAgreementView.swift` | `KIRIPrimaryButton` | `9817:14022` | 약관 행·동의 버튼 |
| 온보딩 | `Features/Onboarding/OnboardingFlowView.swift` | Nickname/Role/Family | Handoff 온보딩 | 단계 라우팅 |
| 역할 선택 | `Features/Onboarding/RoleSelectionView.swift` | role assets | `9817:14090` | 카드 프레임·선택 색상 |
| 가족공간 생성 | `Features/Onboarding/FamilyNameView.swift` | `FamilyEntryView` | Handoff 온보딩 | 입력·CTA |
| 가족 초대 | `Features/Onboarding/FamilyCodeView.swift` | Share sheet | Handoff 온보딩 | 코드 카드 |
| 홈 | `Features/Home/FamilyHomeView.swift` | `QuestionCard`, `FamilyMemberItem`, `PlaceCard` | `9898:15398` | 질문·가족·추천 카드 |
| 홈 튜토리얼 | `Features/Home/HomeTutorialView.swift` | `FamilyHomeView` | `9898:14575`, `14658`, `14758` | 강조 위치·딤·안내 |
| 답변 모아보기 | `Features/Home/HomeInteractionViews.swift` | `FamilyMemberItem` | 홈 후속 프레임 | 답변 상태 |
| 미션 목록 | `Features/Mission/MissionView.swift` | `MissionPlaceCard` | `7948:1685` | 필터 버튼·카드 |
| 미션 필터 | `Features/Mission/MissionView.swift` | `MissionFilterView` | `9404:20244` | 칩·적용 버튼 |
| 미션 상세 | `Features/Mission/MissionActivityDetailView.swift` | `KIRIContentImage` | 미션 상세 Handoff | 이미지·하단 CTA |
| 기록탭 | `Features/Record/RecordView.swift` | Calendar/Bucket child views | `9898:18872` | 탭 전환·상태 |
| 캘린더 | `Features/Record/Components/RecordCalendarView.swift` | schedule detail | `9898:18872` 주변 | 월 헤더·날짜 셀 |
| 버킷리스트 | `Features/Record/Components/RecordBucketListView.swift` | `KIRIChip` | 기록탭 버킷 프레임 | 필터·카드·빈 상태 |
| 일정 생성 | `Features/Record/Request/AddScheduleSheet.swift` | participant controls | 기록탭 후속 화면 | 날짜·시간·초대 |
| 일정 상세 | `Features/Record/Schedule/ScheduleDetailView.swift` | `TodayActivityView` | 기록탭 후속 화면 | 상세 카드·액션 |
| 리뷰 작성 | `Features/Record/Review/ActivityReviewWriteView.swift` | `FamilyReviewCard` | 기록탭 리뷰 프레임 | 별점·사진·저장 |
| 마이페이지 | `Features/MyPage/MyPageView.swift` | support views | `9901:25866` | 프로필·메뉴 |
| 가족 설정 | `Features/MyPage/FamilySettingsView.swift` | role/profile assets | `8216:3570` | 가족 카드·초대 |
| 닉네임 변경 | `Features/MyPage/NicknameEditView.swift` | `KIRITextField` | 마이페이지 후속 | 입력·저장 |
| 알림 | `Features/Home/Notification/NotificationView.swift` | tab bar | `9193:12072` | 목록·빈 상태 |

### 기록탭 운영 데이터 경계

`RecordBucketListView`의 운영 목록은 `AuthService.bucketItems(memberId:cursor:size:)` 응답만
사용합니다. 서버 응답이 비어 있으면 빈 상태를 보여주며, 과거의 하드코딩 버킷과
`MissionBucketStore` 로컬 목록을 화면에 합치지 않습니다.

`RecordCalendarView`의 날짜 그리드는 서버 일정과 독립적으로 항상 월 1일부터 마지막 날까지
생성합니다. 셀 ID는 `day-year-month-day` 형식이고 앞쪽 빈 셀은 `empty-index` 형식이라
월을 이동해도 날짜 셀 identity가 충돌하지 않습니다. `RecordView`에서 데모 일정과 임시
오늘 활동 콘텐츠를 주입하지 않으므로 API 데이터가 없을 때 일정이 임의로 나타나지 않습니다.

현재 캘린더·일정·리뷰 API Service 계약은 `AuthService`에 존재하지만, 화면에서 실제 서버
일정을 로드하는 ViewModel 연결은 별도 작업 대상입니다. 이 상태에서는 로컬 Preview와
실서비스 데이터를 혼동하지 않도록 하며, 화면 검증 시 빈 상태를 정상 결과로 판정합니다.

## 공통 UI 수정 위치

- 색상: `Core/DesignSystem/KIRIColor.swift`
- 폰트: `Core/DesignSystem/KIRITypography.swift`
- 여백: `Core/DesignSystem/KIRISpacing.swift`
- 카드 반경: `Core/DesignSystem/KIRIRadius.swift`
- 원격 이미지 비율·클리핑: `Core/Components/KIRIContentImage.swift`
- 기본 CTA: `Core/Components/KIRIPrimaryButton.swift`
- 상단 뒤로가기: `Core/Components/KIRIBackButton.swift`
- 하단 탭바: `Core/Components/KIRITabBar.swift` 및 `App/MainTabView.swift`

화면별 고유 레이아웃은 해당 Feature 파일의 `body`와 private computed view를 수정합니다. 공통 컴포넌트를 변경하면 홈·미션·기록·마이페이지에 동시에 영향을 주므로 Figma의 공통 컴포넌트인지 먼저 확인합니다.

## API와 화면의 관계

`APIEndpoint`가 경로·메서드·인증 여부를 정의하고, `APIClient`가 공통 헤더와 디코딩을 처리합니다. `AuthService`의 메서드는 View 또는 ViewModel에서 호출되어야 실제 연동입니다. DTO만 추가됐거나 Service 메서드만 존재하는 경우 화면 연동 완료로 보지 않습니다.

기록탭 관련 계약은 다음과 같습니다.

- 버킷 조회: `GET /api/v1/bucket-items`
- 버킷 삭제: `DELETE /api/v1/bucket-items/{bucketItemId}`
- 일정 생성: `POST /api/v1/bucket-items/{bucketItemId}/schedules`
- 캘린더: `GET /api/v1/schedules/calendar`
- 다가오는 일정: `GET /api/v1/schedules/upcoming`
- 일정 수정·응답·취소: `PATCH /api/v1/schedules/{scheduleId}`, `/response`, `/cancel`
- 리뷰: `POST /api/v1/schedules/{scheduleId}/reviews`
- 이미지 URL: `POST /api/v1/images/presigned-url`

## Asset 목록과 교체 방법

| 리소스 | 경로/형식 | 사용처 | 교체 방법 |
|---|---|---|---|
| 앱 로고 | `Assets.xcassets/kiri_logo.imageset` PNG/SVG | Splash/Login | 같은 이름의 원본 이미지 교체 |
| Google/Kakao 로고 | `google_logo`, `kakao_logo` | Login | Asset 이름 유지 |
| 역할 캐릭터 | `role_mom`, `role_dad`, `role_son`, `role_daughter` | RoleSelection/FamilyMemberItem | 원본 비율 유지 후 SwiftUI frame 조정 |
| 탭 아이콘 | `figma_home_active`, `figma_calendar_active`, `figma_profile_active` 등 | `KIRITabBar` | 상태별 imageset 교체 |
| 미션 필터 | `mission_filter.imageset` SVG | `MissionView` | SVG 파일 교체 후 Asset 이름 유지 |
| 홈/미션 장소 | `home_*`, `mission_*` | `PlaceCard`, mission cards | 서버 URL과 로컬 Preview를 구분 |
| 캘린더 제스처 | `figma_gesture_tap` | 튜토리얼/Preview | 원본 PNG 교체 |
| 리뷰 Mock | `mock_review_*` | Preview 전용 | 실서비스 경로에 사용하지 않음 |

원격 이미지는 `KIRIContentImage`에서 `scaledToFill`, 고정 `frame`, `clipped`를 함께 확인합니다. Asset 이름을 바꾸면 `Image("...")` 참조도 모두 갱신해야 합니다. 동영상 리소스는 현재 `Assets.xcassets`에서 확인되지 않았으므로 새 동영상은 Figma 원본과 기능 요구를 확인한 뒤 별도 추가합니다.

## UI만 수정할 때 건드리지 않을 파일

API 계약을 바꾸지 않는 UI 작업에서는 `Core/Network/APIClient.swift`, `APIModels.swift`, `AuthService.swift`, `Core/Storage/*`, `App/AppRouter.swift`를 불필요하게 수정하지 않습니다. 기존 사용자 변경이 있는 `AuthFlowView.swift`, `TermsAgreementView.swift`, `project.pbxproj`, `docs/specs`는 작업 전에 상태를 확인하고 해당 작업 범위가 아니면 스테이징하지 않습니다.

## Figma 대조 절차

1. Figma 프레임의 실제 노드와 스크린샷을 확보합니다.
2. 대응 Swift 파일의 body와 하위 컴포넌트를 찾습니다.
3. 프레임 크기·Safe Area·폰트·색상·간격·이미지 비율을 비교합니다.
4. 서버 데이터가 없는 경우 Preview Fixture만 사용하고 실서비스 Mock으로 대체하지 않습니다.
5. Simulator 캡처를 Figma와 같은 해상도로 비교합니다.
6. `git diff --check`와 Debug 빌드를 확인하고 화면 단위로 커밋합니다.
