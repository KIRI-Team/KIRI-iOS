# iOS QA 차단 항목

1. **TC별 테스트 계정·격리 데이터 없음**
   - 영향: 정책 대기를 제외한 iOS 658개
   - 필요한 것: dev 테스트 계정 1~2개, 가족 구성·초대·일정·리뷰 데이터 세트, 데이터 초기화 방법
2. **자동화 테스트 타깃 없음**
   - 영향: Unit/UI/E2E 자동 실행 불가
   - 확인: `xcodebuild -list`에서 KIRI 앱 스킴만 확인
3. **백엔드 계약·실서버 접근 정보 없음**
   - 앱의 API 호출 코드 정적 확인은 가능하지만 HTTP 응답·상태 전환은 미검증
4. **정책 11개**
   - `QA_POLICY_PENDING.md`의 정책 기준 확정 필요

시도한 해결:
- 일반 권한 simctl/xcodebuild: CoreSimulatorService·캐시 권한 오류
- 권한 확장 simctl: iPhone 17 Pro 부팅 장치 확인 및 앱 실행 성공
- 권한 확장 Debug 빌드: 성공
5. **테스트 액션 미구성**
   - `xcodebuild test` 실행 결과: `Scheme KIRI is not currently configured for the test action`
   - 영향: Unit/UI/E2E 자동화 결과 0건
6. **11/03 명세 원문 미확인**
   - 로컬 확인 문서는 10/15 기준 ver1.4(파일 날짜 10/19)이며, 11/03 출처 표기만 CSV에 존재
   - 영향: 최신 정책·기대 결과의 확정 및 정책 대기 해소 불가
