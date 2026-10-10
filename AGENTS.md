# KIRI iOS 작업 기준

- 프로젝트: KIRI iOS
- 최신 기능명세서: `docs/specs/KIRI_FEATURE_SPEC_2026-10-10.csv`
- `docs/specs/KIRI_FEATURE_SPEC_LATEST.csv`보다 2026년 10월 10일 명세서를 우선한다.
- Figma 원본: https://www.figma.com/design/ZU10sjtVuXOwHG9alXyUzZ/UMC-10th-%ED%8C%80-HALO?node-id=7883-11018
- 기능 및 정책은 최신 명세서, UI 디자인은 Figma를 기준으로 한다.
- 화면 구현 전 해당 Figma 프레임을 직접 확인한다.
- 기존 SwiftUI 아키텍처와 공통 컴포넌트를 재사용한다.
- 실제 API가 없는 기능은 임의로 성공 처리하지 않고 UI/로컬 상태와 미연동 상태를 구분한다.
- SwiftUI 화면 작성 시 ViewBuilder 반환 타입을 확인한다.
- 다중 자식 View를 받는 커스텀 컨테이너는 `@ViewBuilder`를 적절히 사용한다.
- 조건부 View, 제네릭 View, Binding의 타입 추론을 확인한다.
- 기존 공통 컴포넌트의 선언과 사용 방법을 확인한 뒤 재사용한다.
- 컴파일 확인 없이 새로운 공통 컴포넌트를 여러 화면에 확산하지 않는다.
- 기능명세서와 Figma를 준수하되 컴파일 안정성을 우선한다.

## 필수 검증

모든 코드 수정 후 다음 순서를 따른다.

1. 수정 파일 문법 검사
2. 관련 View와 공통 컴포넌트 타입 검사
3. 실제 Xcode 프로젝트 전체 빌드
4. Swift 컴파일 오류가 있으면 수정 후 재빌드
5. Git diff 검토 및 불필요한 변경 확인
6. 최종 검증 결과 보고

실제 빌드가 성공하지 않으면 작업 상태를 `빌드 미검증` 또는 `빌드 실패`로 보고하며, 빌드 성공으로 확정하지 않는다.

작업 완료 조건은 Swift 컴파일 오류 없음, 프로젝트 전체 빌드 성공, 기존 화면 무손상, 새 View 참조 정상 여부 확인이다. API 미연동 기능은 성공한 것처럼 처리하지 않는다.
