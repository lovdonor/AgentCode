# 팀에이전트 워크플로우 체크리스트

> **소통 규칙** — 모든 메시지는 `send-msg.sh` 로 보내고, 각 역할은 **자기 역할 수신함**
> (`bash .ai/core/skills/team-agent/scripts/check-inbox.sh <자기 역할>`)만 확인한다.
> 소통 경로는 리더 허브 단일 통로다 (skill.md 「역할 간 소통 경로 (단일 통로 원칙)」):
> `leader → developer → leader → reviewer → leader → tester → leader`

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
- [ ] `developer` 에게 구현 지시 메시지 전송 (구현 범위·브랜치명 명시)
- [ ] `.team/status/task.md` 업데이트

## Phase 2 — 구현 (developer)

- [ ] 자기 수신함 확인 (`check-inbox.sh developer`) 및 requirements.md 검토
- [ ] `feature/<task>` 브랜치 생성
- [ ] 구현 완료
- [ ] 빌드 검증 수행, 실행 명령·결과(에러/경고 수) 기록 — 빌드 검증 정본은 developer (skill.md 「빌드 검증 책임 분담」)
- [ ] `.team/status/progress.md` 업데이트 (`developer: done`)
- [ ] **`leader` 에게 완료 보고** 메시지 전송 (브랜치명·변경 요약·빌드 기록 포함)

## Phase 3 — 코드 리뷰 (leader → reviewer)

- [ ] (leader) developer 보고에서 빌드 기록 확인 — 없으면 보완 요구
- [ ] (leader) `reviewer` 에게 리뷰 요청 메시지 전송 ("빌드 재실행 불요" 명시)
- [ ] (reviewer) 자기 수신함 확인 (`check-inbox.sh reviewer`)
- [ ] (reviewer) 코드 리뷰 수행
  - [ ] 코딩 표준 준수 여부
  - [ ] 보안 취약점 점검
  - [ ] 로직 오류 검토
  - [ ] 성능 이슈 검토
- [ ] (reviewer) `.team/shared/review-result.md` 작성
- [ ] (reviewer) **`leader` 에게만 결과 보고** — `developer`·`tester` 직접 전달 금지

## Phase 4 — 리뷰 판정 및 테스트 (leader → tester)

- [ ] (leader) 자기 수신함 확인 후 review-result.md 점검·선별
  - critical / major → 사용자 확인 후 반영 방향 확정
  - minor / suggestion → 리더 자체 판단
- [ ] (leader) 결과에 따라 분기:
  - 재작업 필요 → `developer` 에게 재작업 지시 (Phase 2 로 복귀)
  - 통과(GO) → `tester` 에게 테스트 요청 메시지 전송
- [ ] (tester) 자기 수신함 확인 (`check-inbox.sh tester`)
- [ ] (tester) 테스트 케이스 작성 (없는 경우)
- [ ] (tester) 테스트 실행
  - [ ] 단위 테스트
  - [ ] 통합 테스트
  - [ ] 엣지 케이스 검증
- [ ] (tester) `.team/shared/test-result.md` 작성
- [ ] (tester) **`leader` 에게만 결과 보고** — 버그 리포트도 `leader` 에게, `developer` 직접 전달 금지

## Phase 5 — 최종 검토 (leader)

- [ ] 자기 수신함 확인 (`check-inbox.sh leader`) 후 test-result.md 점검
- [ ] 결과에 따라 분기:
  - 버그 있음 → `developer` 에게 수정 지시 (Phase 2 로 복귀, 수정 완료 후 `tester` 에게 재테스트 요청)
  - 통과 → 최종 검토 진행
- [ ] 전체 결과물 최종 검토
  - [ ] 요구사항 충족 여부 확인
  - [ ] 문서 완성도 확인
  - [ ] 브랜치 머지 결정
- [ ] 사용자에게 최종 결과 보고
- [ ] `.team/status/task.md` 상태를 `completed`로 업데이트
