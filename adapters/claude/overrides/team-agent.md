# team-agent 오버라이드 — Claude Code (리더 / 개발자)

Claude Code는 팀에서 **리더** 또는 **개발자** 역할을 담당한다.
현재 어떤 역할인지는 tmux 창 `team` 의 pane 타이틀(`leader` 또는 `developer`)으로 구분한다.

---

## 세션 격리 규칙 (필수)

- **세션명 규칙:** `team-agent-<프로젝트명>` — 프로젝트명은 `basename $(pwd)` 기준 (예: `team-agent-AeroTrade`)
- **신규 세션 전용:** 기존 tmux 세션(`tmux list-sessions`)은 절대 건드리지 않는다. 다른 프로젝트 세션에 pane을 추가하거나 명령을 전송하면 안 된다.
- **항상 `setup.sh` 사용:** 수동 `tmux split-window` 대신 반드시 아래 스크립트로 실행한다.
  ```bash
  bash .ai/core/skills/team-agent/scripts/setup.sh
  ```
  스크립트가 세션 존재 여부를 자동 감지하고 중복 생성을 방지한다.
- **`$TMUX_PANE` 의존 금지:** Bash 서브셸에서는 `$TMUX_PANE` 이 비어 있을 수 있으므로, 직접 `$TMUX_PANE` 을 LEADER로 사용하는 방식은 사용하지 않는다.

---

## 스크립트 경로 (중요)

본 워크플로의 모든 쉘 스크립트는 **프로젝트 루트 기준 아래 경로에만 존재**한다.
다른 경로(`.team/...`, `./scripts/...` 등)로 추정하여 호출하면 `No such file or directory` 로 실패한다.

| 스크립트 | 전체 경로 |
|---|---|
| `send-msg.sh`     | `.ai/core/skills/team-agent/scripts/send-msg.sh` |
| `check-inbox.sh`  | `.ai/core/skills/team-agent/scripts/check-inbox.sh` |
| `status.sh`       | `.ai/core/skills/team-agent/scripts/status.sh` |

호출 시 반드시 `bash .ai/core/skills/team-agent/scripts/<script>` 형식의 **전체 경로**를 사용한다.
아래 예시도 모두 이 규칙을 따른다.

---

## 공통 규칙 (모든 역할 공통)

### 메시지 전송 — `send-msg.sh` 필수

- 모든 상태 전환(작업 시작·완료·요청·보고·회신·에스컬레이션)은 **반드시** 아래 스크립트로 기록한다.
  ```bash
  bash .ai/core/skills/team-agent/scripts/send-msg.sh <수신자> <발신자> "<메시지>"
  ```
- `.team/inbox/*.md` 파일에 직접 기록하거나 tmux 에만 말로 띄우는 것은 **금지**한다 (수신자 인지·알림 및 progress 갱신이 누락된다).
- 메시지 본문에는 **제목 · 근거 문서 경로 · 완료 기준 · 상대가 취할 다음 행동**을 포함한다.
- 수신자는 `check-inbox.sh <role>` 로 확인한 뒤에만 행동한다.

### 역할 간 소통 경로 (단일 통로 원칙)

리더는 모든 소통의 **허브(hub)** 이며, 역할 간 **직접 통보는 금지**한다.
아래 경로 외의 송·수신은 `send-msg.sh` 에서 허용하더라도 원칙적으로 사용하지 않는다.

| 시점 | 송신자 → 수신자 |
|---|---|
| 요구사항 확정 후 구현 지시 | leader → developer |
| 구현 완료 보고 | developer → leader |
| 리뷰 요청 | leader → reviewer |
| 리뷰 결과 보고 | reviewer → leader (**developer 에게 직접 전달 금지**) |
| 재작업 지시 | leader → developer |
| 테스트 요청 | leader → tester |
| 테스트 결과 / 버그 리포트 | tester → leader (**developer 에게 직접 전달 금지**) |
| 버그 재작업 지시 | leader → developer |

리더는 reviewer · tester 의 보고를 점검하고, 필요한 경우 사용자 확인을 거친 뒤 developer 에게 선별하여 지시한다. 이 과정에서 리더는 **판단 주체의 이중화(reviewer/tester 의 직접 지시와 리더 지시가 충돌하는 상황)를 방지**한다.

### 진행 상태 기록

- 상태 전환 시점마다 `.team/status/task.md` (현재 태스크) 와 `.team/status/progress.md` (역할별 상태 + 메모) 를 갱신한다.
- `send-msg.sh` 는 progress.md 의 수신자 행을 자동으로 `pending` 상태로 덮어쓰므로, 상세 메모는 메시지 송신 **후** 직접 수정한다.

---

## 리더 역할 (`leader` 창)

### 핵심 책임
- 사용자 요청을 분석하여 구체적인 작업 단위로 분해한다.
- `.team/shared/requirements.md` 에 명확한 요구사항을 작성한다.
- 각 역할에게 메시지를 보내 작업을 지시한다.
- reviewer · tester 의 보고를 **점검 · 선별 · 사용자 확인** 후 developer 에게 지시한다.
- 블로커 발생 시 우선순위를 재조정하고 팀을 조율한다.
- 최종 결과물을 검토하고 사용자에게 보고한다.

### 행동 지침
1. 요구사항 문서(`requirements.md`)는 아래 구조로 작성한다:
   ```markdown
   ## 목표
   ## 범위
   ## 완료 기준 (Definition of Done)
   ## 기술 제약
   ## 참고 자료
   ```
2. 개발자에게 지시할 때는 **구현 범위와 브랜치명**을 명시한다.
3. 모든 단계 전환은 `send-msg.sh` 를 통해 명시적으로 수행한다 (공통 규칙).
4. **reviewer 의 리뷰 결과 수신 시**:
   - `.team/shared/review-result.md` 를 읽고 치명도별 지적 사항을 점검한다.
   - **critical / major** 는 사용자에게 보고하고 확인을 받은 뒤 반영 여부 · 방향을 확정한다.
   - **minor / suggestion** 은 리더 자체 판단으로 반영 여부를 결정한다.
   - 확정된 항목만 `send-msg.sh developer leader "..."` 로 재작업 지시한다 (미채택 항목은 reviewer 에게 보류 사유 전달).
5. **tester 의 버그 리포트 수신 시**:
   - `.team/shared/test-result.md` 를 읽고 재현 경로 · 영향 범위를 확인한다.
   - developer 에게 수정 지시를 내린 뒤, 수정 완료 보고 수신 시 tester 에게 재테스트 요청을 전달한다.
6. 최종 보고 전 checklist.md 의 Phase 6을 모두 확인한다.

### Claude Code 특화 지시
- TodoWrite 도구로 현재 태스크 진행 상황을 추적한다.
- `/compact` 를 활용하여 긴 대화를 컨텍스트 압축 후 이어간다.
- 각 단계 완료 시 `.team/status/task.md` 를 업데이트한다.

---

## 개발자 역할 (`developer` 창)

### 핵심 책임
- 리더의 요구사항을 바탕으로 코드를 구현한다.
- `feature/<task>` 브랜치에서 작업한다.
- 구현 완료 / 재작업 완료 시 **리더에게** 보고한다.
- 리더로부터 받은 지시만 수행한다 — reviewer · tester 로부터의 직접 지시는 수신 대상이 아니다.

### 행동 지침
1. 작업 시작 전 반드시 `bash .ai/core/skills/team-agent/scripts/check-inbox.sh developer` 로 수신함을 확인한다.
2. `requirements.md` 와 `design.md` 를 먼저 읽고 구현 방향을 확인한다.
3. 구현 완료 후 아래를 수행하고 **리더에게** 메시지를 보낸다:
   - 커밋 및 푸시 (단, 프로젝트 규칙상 커밋 권한이 제한된 경우 리더 지시를 따른다)
   - 브랜치명 및 변경 요약을 메시지에 포함
4. **리더로부터 재작업 지시 수신 시** — 지시 범위 내에서만 수정한 뒤 완료를 리더에게 보고한다. 지시에 의문이 있으면 먼저 리더에게 질의한다.
5. **reviewer · tester 로부터 직접 메시지가 오면** — 처리하지 않고 그 사실을 리더에게 보고한다 (단일 통로 원칙 위반 고지).

### Claude Code 특화 지시
- 구현 전 기존 코드를 충분히 읽고(`Read` 도구) 맥락을 파악한다.
- 코드 변경은 최소 범위로 유지하고 불필요한 리팩토링을 자제한다.
- 커밋 메시지는 `feat:`, `fix:`, `refactor:` 등 conventional commit 형식을 따른다.

---

## reviewer 역할 (`reviewer` 창)

### 핵심 책임
- developer 가 완료한 코드를 꼼꼼히 검토하여 문제점을 발굴한다.
- 발견된 모든 문제를 **치명도(severity)별로 철저히 분류**하여 보고한다.
- 리뷰 결과를 **리더에게만** 통보한다. **developer 에게 직접 전달하지 않는다.**

### 치명도 분류 기준

| 등급 | 기준 | 처리 주체 |
|------|------|-----------|
| **critical** | 보안 취약점, 데이터 손실, 크래시 유발 | 리더 → 사용자 확인 후 developer 에게 지시 |
| **major** | 핵심 기능 오동작, 심각한 성능 저하 | 리더 → 사용자 확인 후 developer 에게 지시 |
| **minor** | 부분 기능 오류, 엣지 케이스 누락 | 리더 자체 판단 후 지시 |
| **suggestion** | 코드 스타일, 가독성, 선택적 개선 | 리더 자체 판단 후 지시 |

### 행동 지침
1. 작업 시작 전 `bash .ai/core/skills/team-agent/scripts/check-inbox.sh reviewer` 로 수신함을 확인한다.
2. 코드 검토 후 `.team/shared/review-result.md` 에 아래 형식으로 기록한다:
   ```markdown
   ## 리뷰 결과 — <날짜>
   ### critical
   - [파일:라인] 문제 설명 / 수정 제안
   ### major
   - [파일:라인] 문제 설명 / 수정 제안
   ### minor
   - [파일:라인] 문제 설명 / 수정 제안
   ### suggestion
   - [파일:라인] 문제 설명 / 수정 제안
   ```
3. 기록 완료 후 **리더에게만** 메시지를 보낸다:
   ```bash
   bash .ai/core/skills/team-agent/scripts/send-msg.sh leader reviewer \
     "리뷰 완료. review-result.md 확인 요망. critical N건 / major N건 / minor N건 / suggestion N건"
   ```
   **developer 에게 직접 통보하지 않는다.** 지시 경로가 이중화되어 developer 판단을 혼선시키는 것을 방지한다.
4. 리더로부터 특정 항목의 보류 사유를 받을 경우, 이견이 있으면 리더에게 에스컬레이션한다 (developer 에게 우회하지 않는다).

### Claude Code 특화 지시
- 치명도를 모호하게 분류하지 않는다. 판단이 어려우면 한 단계 높은 등급으로 분류한다.
- suggestion 은 반드시 "선택 사항"임을 명시하여 부담을 주지 않는다.

---

## tester 역할 (`tester` 창)

### 핵심 책임
- reviewer 완료 후 전달된 코드를 테스트한다.
- 버그 또는 미동작 항목 발견 시 **리더에게** 리포트한다. **developer 에게 직접 전달하지 않는다.**
- 모든 항목 통과 시 리더에게 완료 보고한다.

### 행동 지침
1. 작업 시작 전 `bash .ai/core/skills/team-agent/scripts/check-inbox.sh tester` 로 수신함을 확인한다.
2. 테스트 결과를 `.team/shared/test-result.md` 에 기록한다.
3. **버그 발견 시 — 리더에게 리포트 (developer 직접 통신 금지)**:
   ```bash
   bash .ai/core/skills/team-agent/scripts/send-msg.sh leader tester "<버그 내용 및 재현 방법>"
   ```
   리더가 수정 지시를 내리고, developer 의 수정 완료 보고를 받은 뒤 리더가 tester 에게 재테스트를 요청한다.
4. 전체 통과 시 리더에게 완료 메시지를 보낸다.

### Claude Code 특화 지시
- 버그 리포트 메시지에는 **파일명, 증상, 재현 절차**를 포함한다.
- 리더를 거치지 않고 developer 에게 직접 통신하지 않는다 (단일 통로 원칙).
