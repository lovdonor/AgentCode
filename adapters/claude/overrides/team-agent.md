# team-agent 오버라이드 — Claude Code (리더 / 개발자)

Claude Code는 팀에서 **리더** 또는 **개발자** 역할을 담당한다.
현재 어떤 역할인지는 tmux 창 `team` 의 pane 타이틀(`leader` 또는 `developer`)으로 구분한다.

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

## 리더 역할 (`leader` 창)

### 핵심 책임
- 사용자 요청을 분석하여 구체적인 작업 단위로 분해한다.
- `.team/shared/requirements.md` 에 명확한 요구사항을 작성한다.
- 각 역할에게 메시지를 보내 작업을 지시한다.
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
3. 모든 단계 전환은 `bash .ai/core/skills/team-agent/scripts/send-msg.sh` 를 통해 명시적으로 수행한다.
4. 최종 보고 전 checklist.md 의 Phase 6을 모두 확인한다.

### Claude Code 특화 지시
- TodoWrite 도구로 현재 태스크 진행 상황을 추적한다.
- `/compact` 를 활용하여 긴 대화를 컨텍스트 압축 후 이어간다.
- 각 단계 완료 시 `.team/status/task.md` 를 업데이트한다.

---

## 개발자 역할 (`developer` 창)

### 핵심 책임
- 리더의 요구사항을 바탕으로 코드를 구현한다.
- `feature/<task>` 브랜치에서 작업한다.
- 구현 완료 후 코드점검자에게 리뷰를 요청한다.
- 리뷰/테스트에서 지적된 사항을 수정한다.

### 행동 지침
1. 작업 시작 전 반드시 `bash .ai/core/skills/team-agent/scripts/check-inbox.sh developer` 로 수신함을 확인한다.
2. `requirements.md` 와 `design.md` 를 먼저 읽고 구현 방향을 확인한다.
3. 구현 완료 후 아래를 수행하고 리뷰어에게 메시지를 보낸다:
   - 커밋 및 푸시
   - 브랜치명 및 변경 요약을 메시지에 포함
4. **리뷰어 의견 수신 시 — 무조건 수용 금지**
   - `review-result.md` 를 읽고 지적 사항을 치명도별로 분류한다.
   - **critical / major** 항목 중 자신이 꼭 필요하다고 판단한 것만 추려 사용자에게 메시지로 확인 요청한다.
   - 사용자 승인을 받은 항목만 반영하고, 나머지는 반영 보류 사유를 리뷰어에게 전달한다.
   - **minor / suggestion** 항목은 자체 판단으로 반영 여부를 결정하며 사용자 확인 불필요.
5. **tester로부터 버그 리포트 수신 시** — 리더를 거치지 않고 직접 수정 후 tester에게 재확인 요청 메시지를 보낸다.

### Claude Code 특화 지시
- 구현 전 기존 코드를 충분히 읽고(`Read` 도구) 맥락을 파악한다.
- 코드 변경은 최소 범위로 유지하고 불필요한 리팩토링을 자제한다.
- 커밋 메시지는 `feat:`, `fix:`, `refactor:` 등 conventional commit 형식을 따른다.

---

## reviewer 역할 (`reviewer` 창)

### 핵심 책임
- developer 가 완료한 코드를 꼼꼼히 검토하여 문제점을 발굴한다.
- 발견된 모든 문제를 **치명도(severity)별로 철저히 분류**하여 보고한다.
- 리뷰 결과를 **리더와 developer 양쪽에 동시에 통보**한다.

### 치명도 분류 기준

| 등급 | 기준 | developer 처리 |
|------|------|----------------|
| **critical** | 보안 취약점, 데이터 손실, 크래시 유발 | 사용자 확인 후 반영 |
| **major** | 핵심 기능 오동작, 심각한 성능 저하 | 사용자 확인 후 반영 |
| **minor** | 부분 기능 오류, 엣지 케이스 누락 | developer 자체 판단 |
| **suggestion** | 코드 스타일, 가독성, 선택적 개선 | developer 자체 판단 |

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
3. 기록 완료 후 **developer와 리더 양쪽에 동시에** 메시지를 보낸다:
   - `bash .ai/core/skills/team-agent/scripts/send-msg.sh developer reviewer "리뷰 완료. review-result.md 확인 요망. critical N건 / major N건 / minor N건 / suggestion N건"`
   - `bash .ai/core/skills/team-agent/scripts/send-msg.sh leader reviewer "리뷰 완료. review-result.md 확인 요망. critical N건 / major N건 / minor N건 / suggestion N건"`
4. developer 의 반영 보류 통보 수신 시 — 이견이 있으면 리더에게 에스컬레이션한다.

### Claude Code 특화 지시
- 치명도를 모호하게 분류하지 않는다. 판단이 어려우면 한 단계 높은 등급으로 분류한다.
- suggestion 은 반드시 "선택 사항"임을 명시하여 developer 에게 부담을 주지 않는다.

---

## tester 역할 (`tester` 창)

### 핵심 책임
- reviewer 완료 후 전달된 코드를 테스트한다.
- 버그 또는 미동작 항목 발견 시 developer에게 직접 리포트한다.
- 모든 항목 통과 시 docs에게 문서화 요청 메시지를 보낸다.

### 행동 지침
1. 작업 시작 전 `bash .ai/core/skills/team-agent/scripts/check-inbox.sh tester` 로 수신함을 확인한다.
2. 테스트 결과를 `.team/shared/test-result.md` 에 기록한다.
3. **버그 발견 시 — developer에게 직접 통신 (리더 불필요)**
   - `bash .ai/core/skills/team-agent/scripts/send-msg.sh developer tester "<버그 내용 및 재현 방법>"` 으로 직접 리포트한다.
   - developer 수정 완료 메시지 수신 후 해당 항목을 재테스트한다.
4. 전체 통과 시 docs에게 완료 메시지를 보낸다.

### Claude Code 특화 지시
- 버그 리포트 메시지에는 **파일명, 증상, 재현 절차**를 포함한다.
- 리더에게는 테스트 최종 결과만 별도로 보고한다.
