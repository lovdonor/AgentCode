# 팀에이전트 워크플로우 체크리스트

## Phase 0 — 환경 초기화

- [ ] 터미널 백엔드 결정 (tmux / Orca — `TEAM_AGENT_BACKEND` 또는 자동 감지)
- [ ] `setup.sh` 실행 → `.team/status/backend` 에 백엔드 기록 확인
- [ ] 역할 터미널 4개 확인: `leader`, `developer`, `reviewer`, `tester` (tmux pane 타이틀 / Orca 탭 타이틀)
- [ ] `.team/` 디렉토리 구조 및 `.team/status/role-map.sh` 확인
- [ ] 각 터미널에서 에이전트 CLI 기동 확인, `whoami.sh` 로 역할 판별 확인

## Phase 1 — 요구사항 정의 (leader)

- [ ] 사용자 요청 수신 및 분석
- [ ] `.team/shared/requirements.md` 작성
  - 목표, 범위, 완료 기준 포함
- [ ] `.team/shared/design.md` 초안 작성 (필요시)
- [ ] `developer`에게 구현 지시 메시지 전송
- [ ] `.team/status/task.md` 업데이트

## Phase 2 — 구현 (developer)

- [ ] `leader` 수신함 확인 및 requirements.md 검토
- [ ] `feature/<task>` 브랜치 생성
- [ ] 구현 완료
- [ ] `.team/status/progress.md` 업데이트 (`developer: done`)
- [ ] `reviewer`에게 리뷰 요청 메시지 전송

## Phase 3 — 코드 리뷰 (reviewer)

- [ ] `developer` 수신함 확인
- [ ] 코드 리뷰 수행
  - [ ] 코딩 표준 준수 여부
  - [ ] 보안 취약점 점검
  - [ ] 로직 오류 검토
  - [ ] 성능 이슈 검토
- [ ] `.team/shared/review-result.md` 작성
- [ ] 결과에 따라 분기:
  - 이슈 있음 → `developer`에게 수정 요청 메시지 전송
  - 통과 → `tester`에게 테스트 요청 메시지 전송

## Phase 4 — 테스트 (tester)

- [ ] `reviewer` 수신함 확인
- [ ] 테스트 케이스 작성 (없는 경우)
- [ ] 테스트 실행
  - [ ] 단위 테스트
  - [ ] 통합 테스트
  - [ ] 엣지 케이스 검증
- [ ] 결과에 따라 분기:
  - 버그 발견 → `developer`에게 버그 리포트 메시지 전송
  - 통과 → `leader`에게 최종 검토 요청 메시지 전송

## Phase 5 — 최종 검토 (leader)

- [ ] `tester` 수신함 확인
- [ ] 전체 결과물 최종 검토
  - [ ] 요구사항 충족 여부 확인
  - [ ] 문서 완성도 확인
  - [ ] 브랜치 머지 결정
- [ ] 사용자에게 최종 결과 보고
- [ ] `.team/status/task.md` 상태를 `completed`로 업데이트
