# QA 환경

- 실행일: 2026-11-25
- 브랜치: develop
- 검증 커밋: de2963215fd7efbda734d299e4ec6b1415517689
- 프로젝트: KIRI iOS (Swift/SwiftUI/Xcode)
- 기준 CSV: `Test Case/test case 421ca1e217c080c1a6e2edf4b390a5c2_all.csv` (881행)
- 중복 CSV: 동일 TC ID·881행, 컬럼 순서만 달라 all 파일을 기준으로 선택
- 실행 명령: `xcodebuild -project KIRI/KIRI.xcodeproj -scheme KIRI -sdk iphonesimulator -configuration Debug build CODE_SIGNING_ALLOWED=NO`
- 빌드 결과: 권한 확장 실행에서 성공 (`qa/evidence/build-debug-escalated.log`)
- Android/백엔드 소스: 현재 저장소에 없음
- 실제 API/DB/배치: 테스트 환경·계정·백엔드 접근 정보가 없어 미실행
- Simulator: CoreSimulatorService 연결 오류로 설치·실행·스크린샷 미실행
- 민감정보: 토큰·키·개인정보를 결과에 기록하지 않음
- 기존 작업자 미커밋 변경: 보존, 제품 코드 수정 없음

## 2차 QA 추가 실행
- 실행일: 2026-11-25
- Simulator: iPhone 17 Pro, iOS 26.3.1, UDID `077B5997-15ED-4CB4-B25D-FA149ED2E3A9`
- 권한 확장 `simctl list`에서 부팅 상태 확인
- 현재 작업 트리 Debug 빌드·설치·실행 성공
- Bundle ID: `com.kiriteam.KIRI`
- 앱 버전: `1.0.1`
- MinimumOSVersion: `17.0`
- 로그인 화면 캡처: `qa/evidence/ios-launch-dismissed.png`
- 실제 계정 로그인·서버 데이터 변경·외부 인증 완료: 미실행
- 로컬 최신 명세: `기능명세서 ver 1.4 ...md` 본문 날짜 2026-10-19. 2026-11-03 판본은 로컬에서 확인하지 못함

초기 1차 기록의 Simulator 미실행 문구는 당시 상태이며, 2차에서는 권한 확장 후 iPhone 17 Pro에서 Debug 앱의 설치·실행과 로그인 화면 캡처까지 완료했다. 2차 실행 증빙은 `qa/evidence/environment-commands.log`, `qa/evidence/build-summary.txt`, `qa/evidence/ios-smoke.md`에 있다. Release 시뮬레이터 빌드도 성공했으나 test action은 스킴에 구성되지 않았다.
