# codex-statusline

Codex CLI 상태표시줄은 `config.toml`의 `[tui]` 설정으로 제어한다.
Claude Code처럼 임의 명령을 연결하는 `statusLine.command` 방식이 아니라,
문서화된 item identifier 목록을 `tui.status_line`과 `tui.terminal_title`에 넣는 방식이다.

## 기본 워크플로우

1. 현재 `~/.codex/config.toml` 내용을 읽는다.
2. 기존 설정을 유지하면서 `[tui]` 테이블에 필요한 키만 최소 범위로 추가하거나 수정한다.
3. 상태표시줄 요청이면 `tui.status_line`, 탭 제목 요청이면 `tui.terminal_title`을 사용한다.
4. 변경 후 사용자가 Codex CLI 세션을 재시작해서 반영되게 안내한다.

## 자주 쓰는 설정

### 상태표시줄

```toml
[tui]
status_line = ["model-with-reasoning", "context-remaining", "current-dir"]
```

- `model-with-reasoning`: 모델명과 reasoning 정보를 표시한다.
- `context-remaining`: 컨텍스트 잔량을 표시한다. 퍼센트 숫자가 아니라 게이지 형태로 보일 수 있다.
- `current-dir`: 현재 작업 디렉터리를 표시한다.

더 단순한 예시:

```toml
[tui]
status_line = ["model-with-reasoning", "current-dir"]
```

### 터미널 제목

```toml
[tui]
terminal_title = ["spinner", "project"]
```

문서 예시 기준으로 `terminal_title`에는 다음 항목들이 사용된다:
- `app-name`
- `project`
- `spinner`
- `status`
- `thread`
- `git-branch`
- `model`
- `task-progress`

## 주의사항

- 공식 문서 기준으로 Codex CLI는 `tui.status_line`을 지원한다.
- 상태표시줄은 문서화된 item identifier를 조합하는 방식이다. 임의 스크립트 출력으로 커스텀하는 훅은 이 스킬 범위에서 다루지 않는다.
- `context-remaining`은 실제 표시가 빈칸 게이지처럼 보여도 정상일 수 있다.
- 토큰 사용량 항목은 공식 문서에서 상태표시줄 item으로 확인되지 않으면 있다고 가정하지 말고, 지원 여부를 먼저 확인한다.
- 사용자가 이미 `[tui]`를 쓰고 있으면 전체를 덮어쓰지 말고 필요한 키만 병합한다.

## 요청별 처리 가이드

- "상태표시줄에 컨텍스트를 보여줘"
  `status_line`에 `context-remaining`을 추가한다.
- "모델명도 같이 보여줘"
  `model-with-reasoning` 또는 `model`을 함께 넣는다.
- "상태줄이 너무 길어"
  `current-dir` 또는 `git-branch`를 제거해서 줄인다.
- "탭 제목도 바꿔줘"
  `terminal_title`을 별도로 설정한다.

## 검증

1. `config.toml`에 `[tui]`와 목표 키가 들어갔는지 다시 읽어서 확인한다.
2. 사용자가 Codex CLI를 재시작한 뒤 하단 상태표시줄 또는 터미널 제목 변경 여부를 확인하게 한다.
3. 기대한 값이 안 보이면 공식 문서의 item identifier 범위 안에서만 조정한다.

## 참고

- Config Reference: `https://developers.openai.com/codex/config-reference`
- Sample Config: `https://developers.openai.com/codex/config-sample`
