# Codex 어댑터

## 응답 형식

- Markdown 기반 구조화된 출력을 사용한다.
- 코드 변경 시 파일 경로와 변경 사유를 명시한 뒤 코드 블록으로 제시한다.

## 작업 워크플로우

1. **맥락 파악** — `repo-map.md`로 구조 파악. 관련 파일 탐색.
2. **정책 확인** — 변경 대상에 해당하는 정책 문서 확인.
3. **스킬 참조** — 작업 유형에 맞는 공용 `core/skills` 또는 Codex 전용 스킬을 참조.
4. **변경 실행** — 최소 범위로 변경. 금융 로직 수정 시 `safety-rules.md` 재확인.
5. **검증 보고** — 빌드·테스트 결과 보고.

## Codex 전용 지시

- AGENTS.md를 진입점으로 사용한다.
- 샌드박스 환경에서 동작하므로 네트워크 접근이 제한될 수 있다.
- 변경 사항을 PR 단위로 구성하여 제안한다.

## 오버라이드 규칙

스킬별 Codex 특화 동작이 필요하면 `.ai/adapters/codex/overrides/<skill-name>.md`에 정의한다.
오버라이드 파일이 없으면 `.ai/core/skills/<skill-name>/skill.md` 본문을 그대로 사용한다.

## Codex 전용 스킬

- **codex-statusline** (Codex 전용)
  경로: `.ai/adapters/codex/overrides/codex-statusline.md`
  설명: Codex CLI의 상태 표시줄(status line)과 터미널 제목(terminal title)을 `config.toml`의 `[tui]` 설정으로 구성하는 방법을 제공한다. Codex CLI 고유 기능이므로 공용 `core/skills`가 아닌 Codex 어댑터에만 존재한다.
  대표 트리거: `codex statusline`, `상태 표시줄`, `terminal title`, ...
  선행조건: `~/.codex/config.toml 또는 %USERPROFILE%\.codex\config.toml 쓰기 권한`, `Codex CLI 사용 환경`
