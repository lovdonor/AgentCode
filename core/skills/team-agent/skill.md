# 스킬: team-agent — tmux 멀티 에이전트 팀 개발

## 개요

tmux 세션 `team-agent-<프로젝트명>` 의 단일 창 `team` 위에서 5개의 pane을 운영하며,
리더·개발자·코드점검자·테스터·문서관리자가 파일 기반 메시지 버스(`.team/`)를
통해 협력하여 개발 워크플로우를 완수한다.

---

## 팀 구성

| 역할 | pane (타이틀) | 에이전트 | 책임 |
|------|-------------|---------|------|
| 리더 | `leader` | Claude Code | 요구사항 분석, 작업 분배, 최종 검토 |
| 개발자 | `developer` | Claude Code | 구현, 코드 작성 |
| 코드점검자 | `reviewer` | Codex | 코드 리뷰, 보안·품질 검사 |
| 테스터 | `tester` | Gemini | 테스트 작성·실행, 버그 리포트 |
| 문서관리자 | `docs` | Gemini | README, 변경로그, API 문서 작성 |

---

## 사전 요구사항

- tmux 설치
- 각 에이전트 CLI 사용 가능 (`claude`, `codex`, `gemini`)
- 프로젝트 루트에서 스크립트 실행

---

## 초기 설정

```bash
# tmux 세션 및 창 초기화
bash .ai/core/skills/team-agent/scripts/setup.sh
```

실행 결과:
- tmux 세션 `team-agent-<프로젝트명>` 생성 (예: `team-agent-Monsoon`)
- 단일 창 `team` 에 5개 pane 생성 (tiled 레이아웃): `leader`, `developer`, `reviewer`, `tester`, `docs`
- `.team/inbox/`, `.team/status/`, `.team/shared/` 디렉토리 초기화

---

## 메시지 디렉토리 구조

```
.team/
├── inbox/
│   ├── leader.md      ← 리더 수신함
│   ├── developer.md   ← 개발자 수신함
│   ├── reviewer.md    ← 코드점검자 수신함
│   ├── tester.md      ← 테스터 수신함
│   └── docs.md        ← 문서관리자 수신함
├── status/
│   ├── task.md        ← 현재 태스크 및 단계
│   └── progress.md    ← 역할별 진행 상황
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

예시:
```bash
# 리더 → 개발자: 구현 요청
bash .ai/core/skills/team-agent/scripts/send-msg.sh developer leader "auth 모듈 구현 시작. requirements.md 참조"

# 개발자 → 코드점검자: 리뷰 요청
bash .ai/core/skills/team-agent/scripts/send-msg.sh reviewer developer "구현 완료. feature/auth 브랜치 리뷰 요청"

# 코드점검자 → 테스터: 테스트 요청
bash .ai/core/skills/team-agent/scripts/send-msg.sh tester reviewer "리뷰 통과. 테스트 진행 요청"

# 테스터 → 문서관리자: 문서화 요청
bash .ai/core/skills/team-agent/scripts/send-msg.sh docs tester "테스트 통과. 문서화 요청"

# 문서관리자 → 리더: 완료 보고
bash .ai/core/skills/team-agent/scripts/send-msg.sh leader docs "문서화 완료. 최종 검토 요청"
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

## 표준 워크플로우

```
[1] 사용자 → leader: 요구사항 전달
[2] leader: requirements.md 작성 → developer에게 구현 지시
[3] developer: 구현 완료 → reviewer에게 리뷰 요청
[4] reviewer: 코드 리뷰 → review-result.md 작성
    - 이슈 있음 → developer에게 수정 요청 (3으로 복귀)
    - 통과       → tester에게 테스트 요청
[5] tester: 테스트 실행
    - 버그 발견 → developer에게 버그 리포트 (3으로 복귀)
    - 통과      → docs에게 문서화 요청
[6] docs: 문서 작성 완료 → leader에게 최종 검토 요청
[7] leader: 최종 검토 후 사용자에게 결과 보고
```

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
| 문서관리자 | `docs/<task-name>` |
| 리더 | `main` / `dev` 머지 결정 |
