# KIRI iOS

> 우리 가족만의 취향, 우리 가족만의 시간

KIRI는 가족이 서로의 취향과 생각을 알아가고, 함께할 활동을 발견하고 기록할 수 있도록 돕는 가족 서비스입니다.

이 저장소는 **KIRI iOS 애플리케이션**을 관리합니다.

- Platform: iOS
- UI: SwiftUI
- Language: Swift
- Target Release: 2026.11.22
- Branch: `develop`

---

## 1. Tech Stack

| Category | Technology |
| --- | --- |
| Language | Swift |
| UI | SwiftUI |
| Architecture | Feature-based Structure |
| Navigation | AppRouter |
| Local State | Swift Observation (`@Observable`) |
| Local Storage | UserDefaults |
| UIKit Bridge | UIViewControllerRepresentable |
| IDE | Xcode |

현재 Server API 연결 전 단계에서는 Mock 데이터를 사용합니다.

실제 인증 및 API 연동이 시작되면 네트워크 계층과 인증 토큰 저장 구조를 별도로 추가합니다.

---

## 2. Project Structure

```text
KIRI-iOS
├── README.md
│
└── KIRI
    └── KIRI
        ├── App
        │   ├── AppRouter.swift
        │   ├── MainTabView.swift
        │   └── RootView.swift
        │
        ├── Core
        │   ├── Components
        │   │   ├── KIRIBackButton.swift
        │   │   ├── KIRIPrimaryButton.swift
        │   │   ├── KIRIShareSheet.swift
        │   │   └── KIRITextField.swift
        │   │
        │   ├── DesignSystem
        │   │   ├── KIRIColor.swift
        │   │   ├── KIRIRadius.swift
        │   │   ├── KIRISpacing.swift
        │   │   └── KIRITypography.swift
        │   │
        │   └── Storage
        │       └── AppSessionStore.swift
        │
        ├── Features
        │   ├── Auth
        │   │   ├── AuthEntryView.swift
        │   │   ├── AuthFlowView.swift
        │   │   ├── LoginView.swift
        │   │   ├── SignUpView.swift
        │   │   └── TermsAgreementView.swift
        │   │
        │   ├── Home
        │   │   └── HomeView.swift
        │   │
        │   ├── Mission
        │   │   └── MissionView.swift
        │   │
        │   ├── MyPage
        │   │   └── MyPageView.swift
        │   │
        │   ├── Onboarding
        │   │   ├── FamilyCodeInputView.swift
        │   │   ├── FamilyCodeLoadingView.swift
        │   │   ├── FamilyCodeView.swift
        │   │   ├── FamilyEntryView.swift
        │   │   ├── FamilyJoinConfirmView.swift
        │   │   ├── FamilyJoinLoadingView.swift
        │   │   ├── FamilyNameView.swift
        │   │   ├── NicknameView.swift
        │   │   ├── OnboardingFlowView.swift
        │   │   └── RoleSelectionView.swift
        │   │
        │   └── Record
        │       └── RecordView.swift
        │
        ├── Models
        │   └── FamilyInvitation.swift
        │
        ├── ContentView.swift
        └── KIRIApp.swift
```

---

# 3. Directory Convention

## `App`

애플리케이션 전체 흐름을 관리합니다.

```text
AppRouter.swift
```

앱의 최상위 상태와 화면 전환을 관리합니다.

현재 주요 상태:

```swift
authentication
onboarding
main
```

사용자 이용 상태:

```swift
family
browse
```

Feature 내부의 세부 화면 이동을 모두 `AppRouter`에 넣지 않습니다.

앱 전체 수준의 상태 전환만 관리합니다.

---

## `Core`

특정 Feature에 종속되지 않고 여러 화면에서 재사용할 수 있는 코드를 관리합니다.

### Components

공통 UI 컴포넌트입니다.

예:

```text
KIRIPrimaryButton
KIRITextField
KIRIBackButton
KIRIShareSheet
```

2개 이상의 Feature에서 사용할 가능성이 높은 UI는 `Core/Components`에 배치합니다.

특정 화면에서만 사용하는 작은 View는 해당 Feature 내부에 둡니다.

### DesignSystem

KIRI 전체 디자인 기준을 관리합니다.

```text
KIRIColor
KIRITypography
KIRISpacing
KIRIRadius
```

화면에서 색상, 여백, Radius 등을 임의로 반복 선언하기보다 DesignSystem에 정의된 값을 우선 사용합니다.

### Storage

앱 내부 로컬 저장을 관리합니다.

현재:

```text
AppSessionStore.swift
```

`UserDefaults`에는 로그인 여부, 온보딩 완료 여부 등 단순 앱 상태만 저장합니다.

비밀번호, Access Token, Refresh Token 등의 민감정보는 `UserDefaults`에 저장하지 않습니다.

---

## `Features`

사용자 기능 단위로 코드를 분리합니다.

```text
Auth
Home
Mission
Record
MyPage
Onboarding
```

새로운 기능이 추가되면 가능한 한 Feature 단위로 분리합니다.

예:

```text
Features
└── Question
    ├── QuestionView.swift
    ├── QuestionAnswerView.swift
    └── QuestionResultView.swift
```

화면이 늘어난다는 이유만으로 모든 View를 하나의 폴더에 넣지 않습니다.

---

## `Models`

여러 화면이나 기능에서 공유되는 데이터 모델을 관리합니다.

현재:

```text
FamilyInvitation.swift
```

특정 Feature에서만 사용하는 단순 모델은 해당 Feature 내부에 둘 수 있습니다.

---

# 4. Application Flow

현재 앱의 기본 진입 구조입니다.

```text
KIRIApp
   ↓
RootView
   ↓
AppRouter
   │
   ├── Authentication
   │      ↓
   │   AuthFlow
   │      ↓
   │   로그인 / 회원가입
   │
   ├── Onboarding
   │      ↓
   │   닉네임
   │      ↓
   │   가족 역할
   │      ↓
   │   가족 진입 방식
   │
   └── Main
          ↓
       MainTabView
```

Main Tab은 다음 네 개로 구성합니다.

```text
홈
미션
기록
마이
```

---

# 5. Authentication Flow

현재 인증 화면 흐름은 다음과 같습니다.

```text
Auth Entry
   │
   ├── 로그인
   │      ↓
   │   Login
   │
   └── 회원가입
          ↓
       Sign Up
          ↓
       약관 동의
```

현재 Server API 연결 전이므로 실제 인증은 Mock 상태입니다.

향후 Server 연동 시 로그인 결과에 따라:

```text
로그인
 ↓
온보딩 미완료 → Onboarding
온보딩 완료   → Main
```

으로 분기합니다.

---

# 6. Onboarding Flow

기본 온보딩:

```text
닉네임
 ↓
가족 역할 선택
 ↓
가족 진입 방식
```

가족 역할은 현재 다음 네 가지로 구분합니다.

```text
엄마
아빠
아들
딸
```

---

## 가족공간 생성

```text
가족공간 만들기
 ↓
가족명 입력
 ↓
가족 생성
 ↓
가족코드 발급
 ↓
초대하기
 ↓
Main
```

가족코드는 Server API 연결 전까지 Mock 데이터를 사용합니다.

---

## 가족코드 참여

```text
가족코드 입력
 ↓
가족 조회
 ↓
가족공간 확인
 ↓
가족공간 참여
 ↓
Main
```

---

## 초대링크 참여

목표 플로우:

```text
초대링크
 ↓
KIRI 실행
 ↓
로그인 / 회원가입
 ↓
기본정보 입력
 ↓
초대받은 가족 조회
 ↓
가족공간 확인
 ↓
참여
```

초대정보는 `FamilyInvitation`을 사용합니다.

로그인/회원가입 과정에서 초대정보가 사라지지 않도록 `AppRouter`의 `pendingInvitation`에서 관리합니다.

실제 Universal Link는 도메인 확정 후 연결합니다.

임의의 URL을 코드에 하드코딩하지 않습니다.

---

# 7. Family / Browse Mode

KIRI는 Main 진입 사용자를 두 상태로 구분합니다.

```swift
enum UserMode {
    case family
    case browse
}
```

### Family

가족공간을 만들었거나 기존 가족공간에 참여한 사용자입니다.

가족 기반 기능을 정상적으로 사용할 수 있습니다.

### Browse

아직 가족공간에 참여하지 않고 서비스를 먼저 둘러보는 사용자입니다.

가족공간을 전제로 하는 기능은 제한될 수 있습니다.

특히 둘러보기 상태에서는 가족 질문을 배정하거나 답변을 입력하지 않습니다.

향후 Home, Mission, Record 등의 화면은 `UserMode`에 따라 UI와 기능을 분기할 수 있습니다.

---

# 8. Session

현재 앱 실행 상태는 `AppSessionStore`에서 관리합니다.

저장하는 값:

```text
isAuthenticated
isOnboardingCompleted
userMode
```

따라서 온보딩을 완료한 사용자는 앱을 종료했다 다시 실행해도 Main으로 복귀할 수 있습니다.

로그아웃 시 저장된 세션 상태를 초기화합니다.

현재 세션 저장은 Server 인증 전 개발 단계의 임시 구조입니다.

실제 인증 도입 후 인증 토큰은 Keychain 기반 저장 구조로 분리합니다.

---

# 9. UI Convention

## DesignSystem 우선 사용

색상을 직접 반복 선언하지 않습니다.

```swift
.foregroundStyle(KIRIColor.textPrimary)
```

Typography:

```swift
.font(KIRITypography.title)
```

Spacing:

```swift
.padding(.horizontal, KIRISpacing.horizontal)
```

Radius:

```swift
.clipShape(
    RoundedRectangle(
        cornerRadius: KIRIRadius.large
    )
)
```

---

## 공통 컴포넌트 재사용

동일한 형태의 버튼을 화면마다 새로 만들지 않습니다.

```swift
KIRIPrimaryButton(...)
```

입력 필드:

```swift
KIRITextField(...)
```

뒤로가기:

```swift
KIRIBackButton(...)
```

반복되는 UI가 발생하면 공통화가 필요한지 먼저 확인합니다.

---

# 10. Swift Naming Convention

Type:

```text
PascalCase
```

예:

```swift
FamilyCodeView
AppSessionStore
FamilyInvitation
```

Property / Function:

```text
camelCase
```

예:

```swift
familyCode
selectedRole
enterFamilyMode()
```

Boolean:

가능한 한 상태를 읽을 수 있는 형태로 작성합니다.

```swift
isAuthenticated
isValid
isShareSheetPresented
hasPendingInvitation
```

View 파일은 기본적으로 View 이름과 파일 이름을 동일하게 유지합니다.

```text
FamilyCodeView.swift
→ FamilyCodeView
```

---

# 11. View Convention

하나의 화면이 지나치게 커지지 않도록 구성합니다.

권장 형태:

```swift
struct ExampleView: View {
    // MARK: - Properties

    // MARK: - Body

    var body: some View {
        ...
    }

    // MARK: - Subviews

    private var header: some View {
        ...
    }

    // MARK: - Actions

    private func handleAction() {
        ...
    }
}
```

작은 UI는 `private var`로 분리할 수 있습니다.

재사용성이 생기면 별도 View 또는 `Core/Components`로 분리합니다.

---

# 12. Mock / API Convention

Server API 연결 전 임시 로직은 반드시 TODO를 남깁니다.

```swift
// TODO: 가족공간 생성 API 연결 후 제거
```

Mock 데이터임을 알 수 없는 형태로 값을 남기지 않습니다.

예:

```swift
createdFamilyCode = "KIRI24"
```

를 사용하는 경우 해당 코드 근처에 Mock임을 명시합니다.

Server API 연결 후에는 Mock 로직을 제거합니다.

---

# 13. File Creation Convention

새로운 파일이나 폴더는 터미널에서 먼저 생성합니다.

폴더:

```bash
mkdir -p KIRI/KIRI/Features/Example
```

파일:

```bash
touch KIRI/KIRI/Features/Example/ExampleView.swift
```

### 중요

터미널에서 `touch`로 파일을 생성했다면 Xcode에서 동일한 이름의 `New File`을 다시 생성하지 않습니다.

잘못 생성하면 다음과 같은 중복 파일이 생길 수 있습니다.

```text
ExampleView.swift
ExampleView 2.swift
```

중복 파일 확인:

```bash
find KIRI/KIRI -type f \( -name "* 2.swift" -o -name "* 3.swift" -o -name "* 4.swift" \) -print
```

새 파일이 Xcode에서 바로 보이지 않더라도 먼저 실제 파일 존재 여부를 확인합니다.

```bash
find KIRI/KIRI -type f -name "*.swift" | sort
```

---

# 14. Git Branch Convention

기본 브랜치:

```text
main
develop
```

### `main`

배포 가능한 안정 버전을 관리합니다.

직접 개발하지 않습니다.

### `develop`

현재 개발 내용을 통합하는 브랜치입니다.

기능 개발은 팀의 Git 전략에 따라 별도 브랜치를 생성한 뒤 `develop`으로 병합합니다.

---

# 15. Commit Convention

커밋 메시지는 다음 형식을 사용합니다.

```text
[Type] : 설명
```

예:

```text
[Feat] : 가족공간 참여 플로우 구현
[Fix] : 온보딩 화면 전환 오류 수정
[Refactor] : 인증 상태 관리 구조 개선
[Design] : 가족코드 화면 UI 수정
[Chore] : Xcode 사용자 설정 파일 정리
[Docs] : iOS 프로젝트 README 작성
```

주요 Type:

| Type | 설명 |
| --- | --- |
| Feat | 새로운 기능 |
| Fix | 버그 수정 |
| Refactor | 코드 구조 개선 |
| Design | UI/디자인 수정 |
| Docs | 문서 |
| Chore | 설정 및 기타 작업 |
| Test | 테스트 |

Type의 첫 글자는 대문자로 작성합니다.

---

# 16. Development Workflow

작업 시작 전:

```bash
git checkout develop
git pull origin develop
```

현재 상태 확인:

```bash
git status
```

개발 후 Xcode에서:

```text
⌘ + B
```

빌드가 정상적으로 완료되는지 확인합니다.

중복 Swift 파일 확인:

```bash
find KIRI/KIRI -type f \( -name "* 2.swift" -o -name "* 3.swift" -o -name "* 4.swift" \) -print
```

변경 내용 확인:

```bash
git status
```

커밋:

```bash
git add -A
git commit -m "[Type] : 작업 내용"
```

Push:

```bash
git push origin develop
```

---

# 17. Current Development Status

## 완료

- 프로젝트 기본 구조
- DesignSystem 기본 구성
- Main Tab 구조
- 로그인/회원가입 UI
- 약관 동의 UI
- 닉네임 입력
- 가족 역할 선택
- 가족공간 진입 방식 선택
- 가족공간 생성 플로우
- 가족코드 발급 Mock
- 가족코드 복사
- iOS System Share Sheet
- 가족코드 입력
- 가족공간 조회 Mock
- 가족공간 참여 확인
- Family / Browse 상태 분리
- 초대정보 모델 및 pending invitation 구조
- 앱 세션 로컬 저장
- 앱 재실행 상태 복구
- 로그아웃 및 세션 초기화

## Mock / Server 연동 필요

- 로그인 API
- 회원가입 API
- 약관 동의 API
- 사용자 정보 저장 API
- 닉네임 중복 확인
- 가족명 중복 확인
- 가족공간 생성 API
- 가족코드 발급 API
- 가족코드 조회 API
- 가족공간 참여 API
- 초대링크 검증
- Universal Link
- 실제 사용자 세션 / 토큰 관리

## 다음 주요 작업

- Home 화면 구현
- Family / Browse Home 분기
- 질문 기능
- 미션 기능
- 기록 / 가족 캘린더
- 마이페이지
- Server API 연결
- Universal Link
- 실제 인증 세션
- 디자인 QA

---

# 18. Release Goal

KIRI 1.0 목표:

**2026.11.22**

- Android 기존 서비스 업데이트
- iOS 신규 출시

iOS는 단순 화면 구현이 아니라 실제 App Store 출시 가능한 상태를 목표로 개발합니다.

---

## KIRI Team

KIRI는 가족이 서로를 조금 더 알아가고, 함께할 시간을 만들 수 있도록 개발하고 있습니다.
