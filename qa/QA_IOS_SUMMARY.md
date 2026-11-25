# iOS 2차 QA 요약

## 대상
- iOS 대상: 669개
- 정책 확인 대기: 11개
- 정책 기준 검증 대상: 658개
- P0/P1: 494 / 175

## 상태
- MAPPED: 655
- STATIC_MISMATCH: 3
- POLICY_PENDING: 11

실제 TC PASS: 0
실제 TC FAIL: 0
실행 기반 통과율: N/A
정책 기준 완전 실행률: 0/658 (0%)

## 실제 실행
- Simulator: iPhone 17 Pro, iOS 26.3.1
- 현재 작업 트리 Debug 앱 빌드·설치·실행 성공
- 로그인 화면 표시 스모크 캡처: `qa/evidence/ios-launch-dismissed.png`, `qa/evidence/ios-relaunch.png`, `qa/evidence/ios-relaunch-login.png`
- 해당 스모크는 원본 TC의 전체 기대 결과를 충족하지 않으므로 PASS TC로 산정하지 않음
- 운영/개발 계정 로그인, API 저장·변경, 회원탈퇴, 외부 인증 완료는 수행하지 않음

## 기능별 대상
- 로그인/회원가입: 18개
- 온보딩: 140개
- 홈: 85개
- 미션/플레이스: 82개
- 일정: 70개
- 약속 당일: 46개
- 기록/캘린더: 74개
- 마이페이지: 124개
- 알림: 30개

## 배포 의견
**검증 부족 / 판단 보류**. iOS Simulator 실행은 가능해졌지만, 테스트 계정·격리 데이터·자동화 테스트가 없어 658개 정책 기준 TC의 전체 기대 결과를 실행하지 못했습니다.

## 정적 검토 결과
기존 1차 `CODE_VERIFIED` 658건은 함수명·파일 존재·컴파일만으로 기대 결과를 입증하지 못하므로 2차 결과에서 `MAPPED`로 재분류했다. 각 행에는 관련 Swift 경로와 미검증 기대 결과를 기록했다. 현재 실행 가능한 자동화 test action이 없고, 로그인 이후 데이터가 필요한 계정·격리 fixture가 없어 정적 검토만으로 PASS/FAIL을 확정하지 않았다. Preview 전용 fixture와 TODO 주석은 운영 경로의 실행 결함으로 확정하지 않고 실제 흐름 미검증으로 남겼다.

## 빌드·테스트 도구
- Debug Simulator build: 성공 (`qa/evidence/build-debug-sim.log`)
- Release Simulator build: 성공 (`qa/evidence/build-release-sim.log`)
- `xcodebuild test`: 실패가 아닌 **스킴에 test action 미구성** (`qa/evidence/xcodebuild-test-escalated.log`)
- Simulator 환경 조사: `qa/evidence/environment-commands.log`

## 명세 버전 제약
로컬에 확인 가능한 1.4 문서는 본문상 10월 15일 기준(파일 수정 10월 19일)이며, CSV 출처 문자열만 11/03을 가리킨다. 실제 11월 03일 원문 판본은 확인하지 못했으므로 정책 및 기대 결과의 최신성은 확정하지 않았다. 해당 판본 제공 후 정책 대기·충돌 TC를 재실행해야 한다.

## 정적 불일치
- `STATIC_MISMATCH` 3건: TC-PLAN-09-002, 003, 004 (BUG-001). 카카오 공유 선택 경로가 TODO이며 실제 공유 호출이 없다. 제품 코드는 QA 중 수정하지 않았다.
- 정적 불일치는 실제 서버 실행 FAIL과 구분했다. 관련 실행은 테스트 계정·수신자 환경 확보 후 회귀해야 한다.
