# KIRI iOS 구현 현황

검증일: 2026-10-10 (Asia/Seoul)  
기준 브랜치: `develop`  
기준 커밋: `81620ed46e28c28d804affc6cd926edcd7fbceb2` — `[Feat] : 미션 북마크와 기록 버킷 연동`

## 1. 검증 범위와 판정 기준

- 저장소 내 Swift **70개 파일, 13,079줄**을 대상으로 파일 목록, 타입·상태·액션, 호출 지점, 화면 전환, 저장 경로를 조사했다. 주요 화면은 본문과 콜백 구현까지 추적했다.
- 시작 시 `develop...origin/develop`, 작업 트리 clean. 로컬에 기록된 원격 추적 브랜치와 일치한다. 이번 분석에서 fetch/pull은 하지 않았으므로 GitHub 최신 커밋과의 일치를 보장하지 않는다.
- 기존 `docs/IMPLEMENTATION_STATUS.md`와 저장소 내부 `AGENTS.md`는 없었다. README를 참고하되 현재 코드로 재검증했다.
- [Figma 끼리 UI 페이지](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7883-11018)의 전체 메타데이터를 조회했다. 페이지 바로 아래 폭 390·높이 600 이상인 화면 프레임은 **100개**이며, 동일 화면의 상태·이전 시안이 포함된다. 하위 화면설계서 사본도 확인했으며 별도 신규 화면으로 중복 집계하지 않는다.
- Figma 페이지 목록, `끼리 화면설계서`(`7926:1508`, 조회 결과 빈 canvas), `KIRI / Foundations`(`8438:5291`)도 확인했다. 과거 HALO·와이어프레임·발표자료 페이지를 현재 구현 요구사항에 합산하지 않았다.
- 시각 참조는 질문 입력(`8187:14904`), 일정 등록(`8264:21250`), 설정(`8213:3062`), 세부미션(`8451:22353`)의 스크린샷을 직접 확인했다. 나머지 화면은 레이어 구조·텍스트와 코드 기준 비교다. **100개 화면 모두에 대한 픽셀 QA를 완료한 것은 아니다.**
- `xcodebuild` Debug / iOS Simulator 빌드 성공. 이번 작업에서는 시뮬레이터 터치 조작, 사진 선택, 공유 시트, Apple 인증, 키보드·기기별 렌더링을 실행 검증하지 않았다. 아래 동작 판정은 코드 경로 검증이며 런타임 QA와 구분한다.

| 판정 | 의미 |
| --- | --- |
| 구현 완료 | 표에 명시한 좁은 UI 범위의 표시·입력·전환·로컬 콜백이 코드상 연결됨. 서버 연동 완료나 픽셀 일치를 의미하지 않음 |
| 부분 구현 | 화면 또는 재사용 가능한 구성요소는 있으나 필요한 상태·진입점·콜백·화면 간 데이터 반영이 빠짐 |
| 미구현 | 대응 UI/액션이 없거나 표시만 있고 해당 흐름을 수행할 수 없음 |

백엔드 미연동만을 이유로 모든 UI를 미구현으로 분류하지 않았다. 기존 화면과 미구현 하위 흐름을 분리했으며, Figma의 오래된 문구·중복 시안은 확정 요구사항과 구분했다.

## 2. 프로젝트·Git 분석

| 항목 | 현재 상태 |
| --- | --- |
| 원격 | `https://github.com/KIRI-Team/KIRI-iOS.git` |
| 실제 빌드 프로젝트 | `KIRI/KIRI.xcodeproj`, scheme/target `KIRI` |
| 루트 `KIRI.xcodeproj` | workspace 참조 파일만 있음. `project.pbxproj`가 없으므로 실제 빌드 경로와 혼동 금지 |
| 타깃 | iOS 26.2, iPhone/iPad, Swift language mode 5.0, default actor isolation MainActor |
| 소스 등록 | `PBXFileSystemSynchronizedRootGroup`로 `KIRI/KIRI` 폴더 동기화 |
| 구조 | App → Core / Features / Models. 별도 서비스·ViewModel 분리는 거의 없고 View 내 로컬 상태 중심 |
| 상태 관리 | AppRouter/AppSessionStore는 Observation, MissionBucketStore는 Combine ObservableObject |
| 의존성 | 프로젝트의 packageProductDependencies 비어 있음. Apple 시스템 프레임워크 사용 |
| 테스트 | 별도 테스트 소스·테스트 타깃 없음 |
| 중복 | 같은 파일명을 가진 Swift 파일 없음. 주석의 `NicknameView 2.swift` 등은 실제 중복 파일이 아님 |
| 비활성 파일 | ContentView는 Hello world 템플릿으로 앱 진입점 아님. AppleSignInButton.swift는 0줄. 실제 Apple 버튼은 LoginView 안에 있음 |
| 기존 문서 차이 | README의 Home/Mission/Record/MyPage를 ‘다음 작업’으로 둔 설명은 오래됨. API 계층도 이미 존재함. AuthEntryView/SignUpView는 현재 파일 목록에 없음 |

### 앱 진입과 실제 연결

```text
KIRIApp → RootView → AppRouter의 저장된 세션 상태
  authentication → AuthFlowView → LoginView → TermsAgreementView
  onboarding → NicknameView → RoleSelectionView → FamilyEntryView
    생성 → FamilyNameView → FamilyCodeLoadingView → FamilyCodeView → family
    참여 → FamilyCodeInputView → FamilyJoinLoadingView → FamilyJoinConfirmView → family
    둘러보기 → browse
  main → MainTabView
    홈 → HomeView → FamilyHomeView 또는 BrowseHomeView
      FamilyHome → NotificationView → InvitationRequestView → AddScheduleSheet
    미션 → MissionView → MissionActivityDetailView
    기록 → RecordView
      캘린더 → ScheduleDetailView → TodayActivityView → 기록 작성/완료·컨디션 조정
      저장한 기록 → ReviewDetailView → 기록 수정/삭제 확인
      버킷의 일부 고정 샘플 → InvitationView → InvitationSendMethodSheet
    마이페이지 → MyPageView → FamilySettingsView → 이름 수정 화면
      로그아웃 → AppRouter.logout → 인증 화면
```

- `MainTabView`는 `TabView`가 아닌 switch로 탭 콘텐츠를 교체한다. View 내부 `@State`는 탭 재진입 시 유지된다고 가정하면 안 된다. 기록·편집 상태의 탭 왕복 QA가 필요하다.
- `userMode`는 Home에만 전달한다. 미션·기록·마이페이지에는 둘러보기 제한이 연결되지 않았다.
- `AppRouter.receiveInvitation`과 pendingInvitation 분기는 있지만 호출부, `onOpenURL`, Universal Link 처리가 없다. 외부 초대 수신 완료로 분류하지 않는다.

## 3. 화면별 구현 상태

경로는 `KIRI/KIRI/` 기준이다. Figma 링크는 대표 노드이며 동일 화면의 상태별 노드는 부록에 함께 나열한다.

### 인증·온보딩

| 화면 / 범위 | 판정 | 코드·진입 경로와 확인 사항 | Figma |
| --- | --- | --- | --- |
| 브랜드 스플래시 | 미구현 | KIRIApp은 RootView로 바로 진입. 자동 생성 LaunchScreen 설정만 있고 브랜드 스플래시 화면 없음 | [8095:62668](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8095-62668) |
| 로그인/회원가입 진입 | 부분 구현 | Auth/LoginView·AuthFlowView. Kakao/Google은 SDK 없이 약관으로 이동. Apple 시스템 인증 성공 후 약관으로 이동하나 서버 세션 생성 없음. 실패는 print뿐이며 최초 뒤로가기 콜백은 비어 있음 | [8095:62717](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8095-62717) |
| 약관 체크·전체동의·본문 시트 | 구현 완료 | TermsAgreementView. 필수 3개 충족 시 다음, 위치 동의는 선택, 항목별 본문 시트/닫기 연결. 내용·동의는 로컬, 최신 정책 문서와 서버 저장은 별도 | [8296:13599](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8296-13599) |
| 닉네임 입력 | 부분 구현 | Onboarding/NicknameView. 2~10자 검증·허용문자 정제·다음 연결. 첫 단계 뒤로가기는 무동작. 입력 오류를 표시하는 대신 정제하며 입력값은 온보딩 밖으로 전달되지 않음 | [8098:14575](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8098-14575) |
| 가족 역할 선택 UI | 구현 완료 | RoleSelectionView. 4개 역할 선택, 선택 전 다음 비활성, 이전/다음 연결. 선택한 역할의 프로필 반영은 미구현 | [7883:23313](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7883-23313) |
| 가족공간 생성/참여/둘러보기 선택 | 구현 완료 | FamilyEntryView의 3개 콜백 모두 OnboardingFlowView에서 연결 | [7883:23399](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7883-23399) |
| 가족명 입력·코드 생성 중·코드 표시 | 부분 구현 | FamilyNameView/FamilyCodeLoadingView/FamilyCodeView. 입력→1.2초 로딩→고정 KIRI24 표시. 복사·시스템 공유·나중에 하기 연결. 문구/구성은 디자인과 차이, 발급 실패·재시도 상태 없음 | [8098:72650](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8098-72650), [8098:72709](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8098-72709), [8098:72786](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8098-72786) |
| 가족코드 입력·조회 중·참여 확인 | 부분 구현 | FamilyCodeInputView/FamilyJoinLoadingView/FamilyJoinConfirmView. 6자리 영숫자 검증 후 모든 유효 형식에 고정 가족을 반환. 없는 코드·만료·재시도 UI 없음. 참여는 userMode 전환만 수행 | [8159:12141](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8159-12141), 설계서 사본 `8267:34617` |
| 관심사·물리적 거리·가족 수·맞춤 질문 | 미구현 | OnboardingFlowView.Step와 대응 View 없음. 이름과 내용이 어긋나는 초기 시안이므로 현행 온보딩에 넣을지 먼저 디자인 기준 확정 필요 | `7883:23342`, `7883:23383`, `8040:11123`, `7883:23436` |

### 홈·질문·알림

| 화면 / 범위 | 판정 | 코드·진입 경로와 확인 사항 | Figma |
| --- | --- | --- | --- |
| 가족 홈 기본 화면 | 부분 구현 | Home/FamilyHomeView. 배너·답변 아바타·완료 질문·추천 카드·알림 진입 존재. 이름/답변 고정. 배너·아바타·질문·추천 카드는 해당 액션이 없고 가족 초대는 TODO | [8153:9957](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8153-9957), `8347:7411` |
| 둘러보기 홈 / 가족 미참여 상태 | 부분 구현 | BrowseHomeView는 별도 설명 카드 화면. ‘가족공간 시작하기’는 Text/HStack일 뿐 진입 액션 없음. Figma의 질문·추천 중심 초기 화면과 구조 다름 | `8450:19981`, `8451:22900`, 설계서 사본 `8266:30765` |
| 오늘 질문 입력·입력 후·팝업 | 미구현 | QuestionCard는 답변완료 표시 전용. 작성 화면·작성 상태·제출·재진입 없음. 기존 KIRITextField/KIRIPrimaryButton 재사용 가능 | [8187:14904](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8187-14904), `8187:15072`, `8187:15113` |
| 가족 답변 확인·미응답·콕 찌르기 | 미구현 | FamilyMemberItem은 정적 이미지/이름/테두리. 선택·답변 보기·콕 보내기·상태 변경 없음 | `8070:11636`, `8159:12976` |
| 주간 미션 카드·플립·이미 완료 상태 | 미구현 | FamilyHomeView에 주간 미션 데이터·플립·완료 상태 분기 없음 | `8347:7734`, `8012:9925`, `8460:8451`, `8460:8707` |
| 약속 당일 홈 배너 | 미구현 | TodayActivityView는 기록에서만 진입. 홈 일정 배너 및 해당 라우트 없음 | `8012:10311` |
| 홈에서 가족 초대 | 부분 구현 | FamilyHomeView:188 TODO. 코드 복사/공유 가능한 FamilyCodeView는 온보딩에 이미 있음. 별도 복제보다 현재 가족 데이터로 재사용 | `8286:76347` |
| 알림함·필터·읽음·초대 상세 | 부분 구현 | NotificationView. 카테고리/모두읽음/개별읽음 로컬 구현. opensInvitation만 상세 이동, 질문·콕·미션·기록 알림은 읽음 표시만 변경. 읽음 상태 영속화 없음 | [8459:8069](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8459-8069) |

### 미션·버킷·일정·기록

| 화면 / 범위 | 판정 | 코드·진입 경로와 확인 사항 | Figma |
| --- | --- | --- | --- |
| 미션 목록·검색·카테고리 | 부분 구현 | MissionView/MissionPlaceCard. 로컬 5개 항목 검색·카테고리 필터·상세 이동 존재. 사진은 placeholder. 날짜·시간/지역·거리 버튼 TODO, 검색 결과 없음 안내 없음 | [7948:1685](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=7948-1685), `8495:9657`, `8451:22069` |
| 날짜·시간 / 지역·거리 필터 | 미구현 | MissionView.filterButton 액션 비어 있음. 목록에 제어는 있으나 펼침 상세 시안·최종 항목은 추가 확인 필요 | `7948:1685`, `8495:9657` |
| 북마크 저장·기록 버킷 반영 | 부분 구현 | MissionBucketStore.shared의 UserDefaults 저장/삭제 및 두 화면 갱신 연결. Figma 저장 확인 팝업 없이 즉시 토글. 동일 title/placeName의 샘플 3개가 동일 키 사용 | [8451:22229](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8451-22229) |
| 활동 상세·추천 활동/리뷰집 | 부분 구현 | MissionActivityDetailView가 실제 목록에 연결됨. 현재 표지 placeholder·장소/지역·태그·북마크만 표시. Figma의 참여상태·시간/걸음수·추천 활동/맞춤템·주변 사진 카드·리뷰집 없음. TodayActivityView의 유사 섹션을 검토하여 확장 | [8451:22353](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8451-22353), `8079:13084`, `8534:8734` |
| 버킷 목록·가족별 필터 | 부분 구현 | RecordBucketListView. 로컬 저장 항목+고정 샘플, 가족 필터 존재. 새 저장 항목은 invitation=nil이라 탭해도 무동작. 고정 콘서트 샘플은 한강 축제 초대장을 열어 데이터도 불일치 | `8103:73442`, `8103:74308` |
| 버킷 항목 액션 시트(일정 잡기/삭제) | 미구현 | bucketCard는 일부 샘플의 InvitationView로 바로 연결. Figma의 액션 시트 없음. 북마크 해제 기능은 미션에서만 제공 | [8103:74308](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8103-74308) |
| 일정 등록·가족에게 한 줄 | 미구현 | 날짜·구성원·100자 메시지를 입력하는 화면 없음. **AddScheduleSheet는 수락 확인용이므로 일정 작성 화면이 아님** | [8264:21250](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8264-21250) |
| 일정 날짜/시간 선택 시트 | 미구현 | Calendar는 조회/이동 UI이며 예약 시간 선택 기능 없음. DatePicker 및 해당 라우트 없음 | `8286:68142` |
| 가족 구성원 선택(4/6명 상태) | 미구현 | 선택 가능한 참여자 시트 없음. ScheduleParticipantTooltip은 표시 전용이고 앱 호출도 없음 | `8286:67882`, `8347:5904`, `8347:6216` |
| 초대장 미리보기·발송 방식 선택 | 부분 구현 | InvitationView/InvitationSendMethodSheet 존재·샘플에서 진입. 자세히 보러가기 TODO. 앱 발송은 배너만, Kakao는 복귀만 수행. 일정 작성 결과로 생성되는 초대장은 없음 | `8103:74562`, `8286:69073`, `8286:75889` |
| 받은 요청·캘린더 추가 확인 | 부분 구현 | 홈 알림→InvitationRequestView→AddScheduleSheet 표시/닫기/확인 연결. 상세 버튼 TODO. 확인은 home 복귀뿐, 일정 상태·캘린더 갱신 없음. 거절도 화면 복귀만 | `7883:23898`, `8103:74725` |
| 기록 캘린더·다가오는 약속 | 부분 구현 | RecordCalendarView 월 이동·날짜 선택·예정/확정/완료 표시 분기 있음. 실제 루트 데이터는 오늘 날짜의 데모 일정과 그 기록뿐. calendarActivities는 빈 배열. 디자인의 요청 배너·완료 사진 썸네일/복수 기록 표시 없음 | `7883:25337`, `8105:76303` |
| 예정/다른 날 일정 상세 | 부분 구현 | ScheduleDetailView 날짜 상태 분기 구현. 예정일의 AI/추억은 안내 placeholder. 메인 캘린더에는 미래 샘플 공급이 없어 일반 진입으로 예정 상태를 재현하기 어려움 | `8286:69561`, `8495:10372` |
| 약속 당일 상세 | 부분 구현 | 오늘 데모→ScheduleDetailView→TodayActivityView 도달 가능. 참여자 표시·작성·컨디션 이동 있음. 실제 진입 데이터는 참여자 나 1명·추천/준비물 빈 배열. 풍부한 mock은 ScheduleScreenPreview에만 있음 | `8264:21631`, `8448:17769`, `8448:18068`, `8450:21636` |
| 컨디션 조정 선택·적용 UI | 구현 완료 | TodayActivityView→ConditionAdjustmentSheet. 4종 복수선택·적용·복귀·로컬 추천 정렬 연결. 메인 mock에 추천이 없어 적용 결과를 시각 비교할 수 없음. AI 서버 재추천은 아님 | `7905:10295` |
| 일정 변경 | 미구현 | Figma 일정변경 상태에 대응하는 편집/재확정 경로 없음. 컨디션 조정과 별개 | `8495:10210` |
| 활동 기록 작성·수정 폼 | 구현 완료 | ActivityReviewWriteView. PhotosPicker(최대 10장)·사진 삭제·500자 제한·별점·재참여·필수 검증·초기 Draft 반영·콜백 연결. 사진 로딩 실패 안내 및 실제 피커 QA는 남음 | [8012:10942](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8012-10942) |
| 기록 완료·가족 리뷰 목록 | 부분 구현 | ActivityReviewCompleteView가 작성 결과·사진·수정 진입 표시. 다른 가족은 빈 상태만. FamilyReviewCard(좋아요 포함)는 Preview 이외 호출 없음 | `8079:12515`, `8079:13084` |
| 기록 상세·수정·삭제 | 부분 구현 | RecordView.savedReviews→ReviewDetailView. 내 로컬 Draft만 메뉴 표시, 수정폼·삭제 확인 연결. 인원확인 TODO, 독립 사진 변경 선택 화면 없음. 대표 사진은 첫 사진으로 고정 | `7903:1926`, `8763:17548`, `8763:17749`, `8763:17631` |

### 마이페이지·설정

| 화면 / 범위 | 판정 | 코드·진입 경로와 확인 사항 | Figma |
| --- | --- | --- | --- |
| 설정 메인 | 부분 구현 | MyPageView. 가족 기본 설정만 NavigationLink 연결, 프로필·취향·주소·링크·계정·건의함·약관·알림 버튼은 TODO. Figma의 내 설정/가족 설정/설정 그룹 순서와 다름 | [8213:3062](https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th?node-id=8213-3062) — 노드명은 ‘플레이스’지만 실제 내용은 설정 |
| 가족 기본 설정 | 부분 구현 | FamilySettingsView. 가족명/내 닉네임 수정 연결, 가족 6명 고정. 부모 View의 State에만 반영, 홈/프로필/온보딩 데이터와 공유 안 됨 | `8216:3570` |
| 닉네임·가족명 수정 | 부분 구현 | NicknameEditView/FamilyNameEditView. 검증·Binding 갱신·dismiss 있음. 월 1회 문구만 있고 제한 상태 없음. 프로필 연필에서는 진입 불가. 가족명 생성은 공백 불허, 수정은 허용 | `8216:3462`, `8216:3638` |
| 취향 테스트 | 미구현 | 홈 배너·MyPage TODO, 대응 입력 화면 없음. 질문 입력과 공통 폼 재사용 후보이나 질문 저장 의미는 별도 | `8596:18240` |
| 우리집 주소 없음/있음/등록/수정 | 미구현 | 대응 View/저장 상태 없음 | `8556:9691`, `8556:9605`, `8556:9927`, `8582:18082` |
| 주소 검색 | 미구현 | 검색·결과 선택·우편번호/상세주소 반영 화면 없음 | `8556:10046` |
| 공용초대링크 관리·만료·리셋 | 미구현 | FamilyCodeView는 최초 코드 공유용이며 관리/만료/재발급 화면은 없음 | `8582:18039` |
| 알림 설정·정기 알림 시각 | 미구현 | 설정 화면·토글·시간 선택·로컬 설정 없음. NotificationView는 알림함이며 별개 | `8599:18423` |
| 건의함 작성·후속 상태 | 미구현 | 사진 첨부·500자 의견 입력·제출 화면 없음 | `8599:76071`, `8763:17857` |
| 계정 정보·앱 버전 | 미구현 | 대응 화면 없음. 메인 계정 정보 버튼 TODO | `8599:76117` |
| 로그아웃 | 부분 구현 | MyPage 메인의 시스템 alert→세션 초기화 연결. Figma는 계정 정보에서 커스텀 확인 팝업. 북마크 UserDefaults는 logout에서 지워지지 않음 | `8599:76698` |
| 회원탈퇴 안내·확인 | 미구현 | 탈퇴 화면·확인·완료 상태 없음. UI mock과 실제 계정 삭제를 구분해야 함 | `8599:76808` |
| 설정용 이용약관·오픈 라이선스 | 미구현 | 인증의 private TermDetailView는 존재하지만 설정 경로·목록·업데이트 표시는 없음. Figma AndroidX 예시를 iOS 라이선스로 그대로 복사하지 말 것 | `8599:76457`, `8599:76529` |

## 4. 데이터와 동작의 실제 범위

| 대상 | 현재 처리 | 개발 시 필요한 구분 |
| --- | --- | --- |
| 인증 | UserDefaults에 인증 완료 Bool. Kakao/Google은 인증 없이 다음 단계 | UI 시연 상태임을 명시. 서버 로그인 성공으로 간주하지 않기 |
| 이름/역할/가족 | 온보딩 내부 State. 홈/마이페이지는 별도 상수 | 로컬 모델로 화면 간 일관성부터 확보 가능 |
| 가족 생성·조회 | 1.2초 지연, KIRI24/끼리가족 반환 | 실패·없는 코드·만료도 mock 상태로 재현 가능 |
| 북마크 | title/placeName 키로 UserDefaults 영속화 | 계정별 저장 아님. 고정 샘플과 같은 항목 중복 표시 가능 |
| 기록 | RecordView의 `[String: Draft]`, UIImage 메모리 보관 | 앱 재시작에 유지 안 됨. 탭 교체 시 유지도 보장 안 됨 |
| 일정 | 매번 오늘 날짜로 만드는 단일 데모 일정 | 실제 확정 일정/참여자 검증 결과 아님. ‘서버에서 검증된’이라는 주석과 루트 공급값을 구분 |
| 초대 발송 | 앱 버튼은 ‘초대를 발송했습니다!’ 배너, Kakao 버튼은 닫기 | 실제 발송 없음. 현재 문구는 성공 오인 가능성이 있어 우선 보완 대상 |
| 초대 수락 | 화면 복귀만 수행 | 서버 없이도 공유 로컬 일정에 반영해야 UI 흐름 검증 가능 |
| 알림 | 고정 목록 + 로컬 읽음 Set | 푸시 수신·저장·개별 대상 데이터 연결 아님 |
| AI 추천/컨디션 | 전달된 배열을 로컬 점수로 정렬 | API 호출·생성 모델·걸음수/시간 재산출 없음 |
| 네트워크 | APIClient/Config/Endpoint/Error 기본 구조 존재 | Features에서 사용하지 않음. Debug 주소 존재만으로 API 연동 완료가 아님 |

## 5. 재사용해야 할 디자인 시스템과 기존 UI

- 색상: `Core/DesignSystem/KIRIColor.swift`의 Primitive/Semantic/Component 토큰과 기존 호환 alias. Figma Foundations의 기본 회색/초록 팔레트와 주요 hex는 대응한다. 전체 변수 바인딩·상태별 일치는 별도 QA 대상이다.
- 폰트: `KIRITypography`의 Pretendard Regular/Medium/SemiBold. 9개 OTF와 Debug/Release `UIAppFonts` 등록 존재. 토큰 주석의 행간·자간은 Font 자체에 포함되지 않으므로 화면에서 일관 적용 필요.
- 레이아웃: `KIRISpacing`, `KIRIRadius`. 현재 다수 화면의 18/8/16 등 숫자·system font·white opacity가 직접 지정되어 있으므로 신규 화면에서 같은 값을 또 정의하지 않는다.
- 공통 10종: KIRIBackButton, KIRIPrimaryButton, KIRITextField(normal/error/disabled/focus), KIRIValidationGuidance, KIRICodeInput, KIRISearchField, KIRIChip, KIRITopTab, KIRITabBar, KIRIShareSheet.
- 홈: QuestionCard, FamilyMemberItem, PlaceCard는 표시용이다. 기존 타입에 필요한 액션/상태를 추가할지 먼저 검토한다.
- 미션: MissionPlaceCard/MissionActivityDetailView/MissionBucketStore를 확장한다. ‘플레이스’라는 이름의 별도 목록/상세를 중복 생성하지 않는다.
- 일정/기록: InvitationView, InvitationRequestView, 두 확인/발송 시트, TodayActivityView, ConditionAdjustmentSheet, ActivityReviewWriteView/CompleteView, ReviewDetailView가 이미 있다.
- 미연결 재사용 후보: FamilyReviewCard, ScheduleParticipantTooltip. 둘 다 Preview 외 참조가 없으므로 새로 만들기보다 데이터 주입/액션 연결 검토가 먼저다.
- ScheduleScreenPreview는 테스트용 구성 화면이며 실제 앱 네비게이션에 포함되지 않는다. 그 안의 풍부한 추천 mock을 실제 구현 완료 근거로 사용하지 않는다.

## 6. 개발 우선순위

API 구현 대신 mock임이 명확한 로컬 데이터로 화면 입력→전환→결과 반영을 완성한다. 아래는 실행 순서 제안이며 이번 분석에서 앱 코드는 수정하지 않았다.

| 순서 | 우선순위 | 작업 | 재사용 / 완료 기준 |
| --- | --- | --- | --- |
| 1 | P0 | 질문 답변 입력·저장·완료 카드·재진입, 가족 답변/미응답/콕 UI | 기존 QuestionCard·FamilyMemberItem + 공통 입력/버튼 확장. 홈에서 실제 진입하고 로컬 답변이 반영되며 mock 콕 상태 확인 |
| 2 | P0 | 버킷 액션 → 일정 등록 → 날짜/시간 → 참여자 → 초대장 | MissionBucketStore/RecordBucketListView/InvitationView 재사용. 새로 저장한 항목도 전 구간 이동, 선택값·100자 메시지가 같은 초대장에 유지 |
| 3 | P0 | 받은 요청 수락/거절·일정 갱신·발송 표시 정리 | 기존 InvitationRequestView/AddScheduleSheet/RecordCalendarView 연결. 실제 서버 없이도 로컬 일정 변화 확인, 발송 성공 오인 문구 제거 |
| 4 | P1 | 세부미션 추천 활동·리뷰집, 날짜/지역 필터, 북마크 확인 | 기존 MissionActivityDetailView에 Figma 섹션 추가, TodayActivityView/FamilyReviewCard 재사용 검토. 사진·빈 상태·필터 적용/초기화 확인 |
| 5 | P1 | 홈의 주간 미션·플립·완료·약속 당일 배너, 추천 상세·가족 초대, 둘러보기 진입 | FamilyHomeView/HomeView/AppRouter/FamilyCodeView 확장. 상태별 도달 경로와 browse 제한 일관성 확인 |
| 6 | P1 | 설정 그룹 정렬·프로필 편집 연결·취향 테스트·알림 설정 | MyPageView/기존 이름 편집 재사용. 질문 폼 공유 가능성 검토. 설정값은 mock 로컬 상태로 유지 |
| 7 | P1 | 주소 검색/등록/수정·공용초대링크 관리 | 공통 검색/입력/코드/공유 재사용. 주소 미등록/등록 상태, 만료·리셋 상태를 mock으로 확인 |
| 8 | P1 | 계정 정보·약관/라이선스·건의함·탈퇴 안내 UI | Terms 본문 UI와 리뷰 사진 입력의 재사용 검토. mock 제출/탈퇴를 실제 처리로 표시하지 않기 |
| 9 | P1 | 기록 사진 변경·가족 리뷰·참여자 확인·일정 변경·캘린더 요청/사진 상태 | 기존 리뷰/툴팁/캘린더 확장. 오늘/예정/지난날, 내 기록/다른 가족, 사진 1/여러 장 상태 확인 |
| 10 | P2 | 브랜드 스플래시·온보딩 오류·입력 정책·기기별 디자인 QA | 기존 온보딩 확장. 초기 관심사/거리/가족 수 시안의 채택 여부는 현행 디자인과 확인 후 결정 |

P0는 핵심 사용자 흐름을 막는 누락이다. 신규 미구현 UI를 우선 만들되 그 UI를 실제로 검증하는 데 필요한 기존 연결 보완은 같은 작업에 포함한다. 이미 구현된 기록 작성·북마크·가족 이름 편집을 처음부터 다시 만들지 않는다.

## 7. 빌드·검증 결과 및 남은 QA

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project KIRI/KIRI.xcodeproj -scheme KIRI \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -configuration Debug -derivedDataPath /tmp/KIRIImplementationAudit \
  CODE_SIGNING_ALLOWED=NO build
```

- 결과: **BUILD SUCCEEDED**. 로그: `/tmp/kiri-implementation-audit-build.log` (로컬 임시 파일).
- 최초 샌드박스 실행은 CoreSimulatorService 접근 문제로 asset catalog 컴파일 실패. 승인된 샌드박스 외 실행에서 성공했다. 앱 소스 오류를 수정하여 성공한 것이 아니다.
- 남은 기존 경고: Info-Debug.plist가 Copy Bundle Resources에 포함됨. 프로젝트의 동기화 예외에는 Info.plist만 등록됨. 후속 설정 정리 대상이며 이번 문서 작업에서 변경하지 않았다.
- AppIntents.framework 의존성이 없어 메타데이터 추출을 건너뛴다는 경고도 있음.
- 코드 분석으로 확인: 주요 라우트, 무동작 버튼, Preview 전용 컴포넌트, mock 저장 범위, API 호출 미연결, 중복 파일 여부.
- 미실행: 실제 터치 기반 end-to-end, Apple/Kakao/Google 인증, 네트워크, 사진·공유 시트, 앱 재시작/탭 왕복 상태 유지, 작은 화면/iPad/회전/키보드/접근성 QA, Release/실기기 빌드. 후속 구현마다 해당 동작과 xcodebuild를 확인해야 한다.

## 8. 이번 변경 내역 / 커밋 전 보고

| 파일 | 변경 |
| --- | --- |
| `docs/IMPLEMENTATION_STATUS.md` | 현재 코드 기반 구현 현황, Figma 매핑, 미구현·부분 구현 구분, 우선순위, 재사용 대상, 빌드 근거 및 검증 한계 신규 기록 |

Swift·프로젝트 설정·README 변경 없음. 커밋·push 없음. 향후 구현 커밋은 사용자가 지정한 `[Feat] : 설명`, `[Fix] : 설명` 형식을 사용하고 파일별 변경 내용을 먼저 보고한다.


## 부록 A. Figma 화면 프레임 인벤토리

지정된 끼리 UI 페이지 바로 아래의 100개 화면 프레임을 묶어 나열했다. 같은 이름이라고 같은 구현 상태로 단정하지 않으며 위 표의 실제 콘텐츠·진입 경로 판정을 우선한다. 제목용 Frame, 논의사항, 화면설계서 사본은 신규 구현 화면 수에 포함하지 않는다. 상세 시각 QA 미완료 상태다.

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
