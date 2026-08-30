# 스킬: team-agent — 멀티 에이전트 팀 개발 (tmux / Orca)

## 개요

프로젝트당 역할별 터미널 4개(`leader`, `developer`, `reviewer`, `tester`)를 열고,
리더·개발자·코드점검자·테스터가 파일 기반 메시지 버스(`.team/`)를 통해 협력하여 개발 워크플로우를 완수한다.

역할 터미널을 여는 **터미널 백엔드**는 두 가지이며, 협업 프로토콜(메시지·역할·워크플로우)은 백엔드와 무관하게 동일하다:

| 백엔드 | 역할 터미널 | 역할 식별 | 알림 전달 |
|---|---|---|---|
| `tmux` | 세션 `team-agent-<프로젝트명>` 의 단일 창 `team` 에 pane 4개 (tiled) | pane 타이틀 = 역할명 | `tmux send-keys` |
| `orca` | Orca 워크트리에 터미널 탭 4개 | 탭 타이틀 = 역할명, `ORCA_TERMINAL_HANDLE` | `orca terminal send` |

역할 → 터미널 매핑은 `.team/status/role-map.sh`(`TARGET_<역할>=<pane ID | term 핸들>`)에, 선택된 백엔드는 `.team/status/backend` 에 기록된다.

---

## 팀 구성

| 역할 | 터미널 타이틀 | 에이전트 | 책임 |
|------|-------------|---------|------|
| 리더 | `leader` | Claude Code | 요구사항 분석, 작업 분배, 최종 검토 |
| 개발자 | `developer` | Claude Code | 구현, 코드 작성 |
| 코드점검자 | `reviewer` | Codex | 코드 리뷰, 보안·품질 검사 |
| 테스터 | `tester` | Antigravity | 테스트 작성·실행, 버그 리포트 |

---

## 사전 요구사항

- 터미널 백엔드 중 하나: **tmux** 설치 또는 **Orca** 앱 실행 중(`orca status` 의 `runtimeReachable: true`) + 프로젝트가 Orca 에 등록됨(`orca repo add <경로>`)
- 각 에이전트 CLI 사용 가능 (`claude`, `codex`, `agy`)
- 프로젝트 루트에서 스크립트 실행

---

## 터미널 백엔드 선택

`setup.sh` 가 아래 순서로 백엔드를 정하고 `.team/status/backend` 에 기록한다. 이후 `send-msg.sh`/`status.sh`/`whoami.sh` 는 기록된 백엔드를 그대로 쓴다.

1. 환경변수 `TEAM_AGENT_BACKEND=tmux|orca` (명시)
2. `.team/status/backend` (이미 구성된 팀)
3. 자동 감지 — 현재 셸이 Orca 터미널(`ORCA_TERMINAL_HANDLE` 존재)이고 Orca 런타임이 살아 있으면 `orca`, 아니면 `tmux`

```bash
# 자동 감지
bash .ai/core/skills/team-agent/scripts/setup.sh

# 명시
TEAM_AGENT_BACKEND=orca bash .ai/core/skills/team-agent/scripts/setup.sh
TEAM_AGENT_BACKEND=tmux bash .ai/core/skills/team-agent/scripts/setup.sh

# 검증용: 터미널만 열고 에이전트 CLI 는 기동하지 않음
TEAM_AGENT_NO_LAUNCH=1 bash .ai/core/skills/team-agent/scripts/setup.sh
```

백엔드 구현은 `scripts/backend/{common,tmux,orca}.sh` 에 있다. 새 백엔드를 추가하려면 `backend/<name>.sh` 에
`be_name / be_available / be_open_roles / be_notify / be_status / be_self_role / be_attach_hint` 7개 함수를 구현하고 `common.sh` 의 `TEAM_BACKENDS` 에 등록한다.

---

## 초기 설정

```bash
# 역할 터미널 + .team/ 초기화 (백엔드 자동 감지)
bash .ai/core/skills/team-agent/scripts/setup.sh
```

실행 결과:
- 역할 터미널 4개 생성: `leader`, `developer`, `reviewer`, `tester` (tmux: 세션 `team-agent-<프로젝트명>` 창 `team` 의 pane / orca: 워크트리의 터미널 탭)
- 각 터미널에서 역할별 에이전트 CLI 기동 (`claude` / `claude` / `codex` / `agy`)
- `.team/inbox/`, `.team/status/`, `.team/shared/` 디렉토리 초기화
- `.team/status/role-map.sh`, `.team/status/backend` 기록

이미 구성된 팀에서 다시 실행하면 살아있는 역할 터미널은 재사용한다(tmux: 세션/pane 유지, orca: 핸들이 live 면 재사용).

### 내 역할 확인

```bash
bash .ai/core/skills/team-agent/scripts/whoami.sh   # → leader | developer | reviewer | tester
```

에이전트는 작업 시작 전에 이 명령으로 자기 역할을 확인한다(tmux: pane ID, orca: `ORCA_TERMINAL_HANDLE` 을 role-map 과 대조). 판별이 안 되면 터미널 타이틀을 확인한다.

---

## 메시지 디렉토리 구조

```
.team/
├── inbox/
│   ├── leader.md      ← 리더 수신함
│   ├── developer.md   ← 개발자 수신함
│   ├── reviewer.md    ← 코드점검자 수신함
│   └── tester.md      ← 테스터 수신함
├── status/
│   ├── task.md        ← 현재 태스크 및 단계
│   ├── progress.md    ← 역할별 진행 상황
│   ├── backend        ← 선택된 터미널 백엔드 (tmux | orca)
│   └── role-map.sh    ← 역할 → 터미널 타깃 (setup.sh 자동 생성)
└── shared/
    ├── requirements.md  ← 리더 작성 요구사항
    ├── design.md        ← 설계 결정 사항
    └── review-result.md ← 코드점검 결과
```

---

## 메시지 프로토콜

### 메시지 전송

```bash
bash .ai/core/skills/team-agent/scripts/send-msg.sh <수신자> <발신자> "<메시지>"
```

예시 (모든 경로는 리더 허브를 경유한다 — 아래 「역할 간 소통 경로」 참조):
```bash
# 리더 → 개발자: 구현 지시
bash .ai/core/skills/team-agent/scripts/send-msg.sh developer leader "auth 모듈 구현 시작. requirements.md 참조"

# 개발자 → 리더: 구현 완료 보고 (빌드 검증 기록 포함)
bash .ai/core/skills/team-agent/scripts/send-msg.sh leader developer "auth 구현 완료. 빌드 에러0/경고0. 검증 요청"

# 리더 → 코드점검자: 리뷰 요청
bash .ai/core/skills/team-agent/scripts/send-msg.sh reviewer leader "auth 리뷰 요청. feature/auth 브랜치, 빌드 재실행 불요"

# 코드점검자 → 리더: 리뷰 결과 보고 (developer 직접 전달 금지)
bash .ai/core/skills/team-agent/scripts/send-msg.sh leader reviewer "리뷰 완료. review-result.md 참조. 판정: GO"

# 리더 → 테스터: 테스트 요청 / 테스터 → 리더: 결과 보고
bash .ai/core/skills/team-agent/scripts/send-msg.sh tester leader "auth 검증 요청. DoD 기준 test-result.md 기록"
bash .ai/core/skills/team-agent/scripts/send-msg.sh leader tester "테스트 PASS. test-result.md 갱신 완료"
```

### 수신함 확인

```bash
bash .ai/core/skills/team-agent/scripts/check-inbox.sh <역할>
```

예시:
```bash
bash .ai/core/skills/team-agent/scripts/check-inbox.sh developer
```

### 팀 상태 확인

```bash
bash .ai/core/skills/team-agent/scripts/status.sh
```

---

## 표준 워크플로우 (리더 허브 모델)

```
[1] 사용자 → leader: 요구사항 전달
[2] leader: requirements.md 작성 → developer 에게 구현 지시
[3] developer: 구현 + 빌드 검증(정본, 결과 기록) → leader 에게 완료 보고
[4] leader → reviewer: 리뷰 요청
    reviewer: 코드 리뷰 → review-result.md 작성 → leader 에게 결과 보고
    - 이슈 있음 → leader 가 점검·선별 후 developer 에게 재작업 지시 (3으로 복귀)
    - 통과(GO)  → leader → tester: 테스트 요청
[5] tester: 테스트 실행 → test-result.md 작성 → leader 에게 결과 보고
    - 버그 발견 → leader 가 developer 에게 수정 지시 (3으로 복귀)
    - 통과      → leader 최종 검토
[6] leader: 사용자에게 결과 보고
```

---

## 역할 간 소통 경로 (단일 통로 원칙)

리더가 모든 소통의 **허브(hub)** 다. 역할 간 **직접 통보는 금지**한다 —
reviewer/tester 의 직접 지시와 리더 지시가 충돌하는 **판단 이중화**를 방지한다.

| 시점 | 송신자 → 수신자 |
|---|---|
| 요구사항 확정 후 구현 지시 | leader → developer |
| 구현 완료 보고 | developer → leader |
| 리뷰 요청 | leader → reviewer |
| 리뷰 결과 보고 | reviewer → leader (**developer 직접 전달 금지**) |
| 재작업 지시 | leader → developer |
| 테스트 요청 | leader → tester |
| 테스트 결과 / 버그 리포트 | tester → leader (**developer 직접 전달 금지**) |
| 버그 재작업 지시 | leader → developer |

리더는 reviewer·tester 의 보고를 점검·선별하고, 필요 시 사용자 확인을 거친 뒤
developer 에게 지시한다. developer 는 reviewer·tester 로부터 직접 메시지를 받으면
처리하지 않고 그 사실을 리더에게 보고한다.

---

## 빌드 검증 책임 분담 (중복 빌드 금지)

동일한 빌드 검증(컴파일·링크·경고 확인·정적 체크)을 개발자·코드점검자·테스터가
각자 반복하면 시간·자원 낭비다. **빌드 검증의 정본 담당은 개발자 1인**으로 한다.

| 역할 | 빌드 검증 책임 |
|------|--------------|
| 개발자 | **정본 수행** — 구현·재작업 완료 보고 전에 빌드 검증을 수행하고, 실행한 명령과 결과(에러/경고 수)를 보고서·DoD 자체검토에 반드시 기록한다. |
| 코드점검자 | **재실행하지 않음** — 개발자 보고의 빌드 기록 확인으로 갈음하고 코드 리뷰(정합성·범위·설계·보안)에 집중한다. |
| 테스터 | **재검증 생략** — 개발자가 빌드한 산출물 기준으로 기능·정적·런타임 검증과 패키징을 수행한다. 산출물 존재와 타임스탬프(변경 소스보다 최신)만 확인한다. |
| 리더 | 지시 메시지에 "빌드 재실행 불요"를 명시하고, 개발자 보고에 빌드 기록이 없으면 보완을 요구한다. |

**예외 (재현이 허용되는 경우)** — 아래에 한해 재실행하고 사유를 결과 문서에 기록한다:
1. 개발자 보고에 빌드 기록이 없거나 불충분할 때 (리더가 보완 요구 후에도 미비하면 직접 재현).
2. 리뷰 중 빌드 결과를 뒤집을 수 있는 결함(헤더/시그니처/매크로 불일치 등)이 의심될 때 — 해당 부분만.
3. 리더가 clean 재빌드·패키징 직전 검증을 명시적으로 지시했을 때.

---

## 메시지 포맷 규칙

각 에이전트는 수신함 메시지를 처리할 때 아래 포맷을 따른다.

```markdown
---
from: <발신자 역할>
to: <수신자 역할>
time: <YYYY-MM-DD HH:MM>
status: pending | in-progress | done | blocked
---

<메시지 본문>
```

---

## 블로커 처리 규칙

1. 작업이 블로킹되면 `status: blocked` 로 메시지를 보내 리더에게 즉시 보고한다.
2. 리더는 블로커를 분석하여 우선순위를 재조정하거나 다른 역할에 지원을 요청한다.
3. 블로커 해소 전까지 해당 단계는 진행하지 않는다.

---

## 브랜치 전략 (팀 개발 시 권장)

| 역할 | 브랜치 패턴 |
|------|-----------|
| 개발자 | `feature/<task-name>` |
| 코드점검자 | PR 리뷰 (브랜치 직접 수정 금지) |
| 테스터 | `test/<task-name>` (테스트 코드만) |
| 리더 | `main` / `dev` 머지 결정 |
