# Gemini 어댑터

## 응답 형식

- Markdown 기반 출력을 사용한다.
- 코드 변경 시 파일 경로와 변경 사유를 명시한 뒤 코드 블록으로 제시한다.

## 작업 워크플로우

1. **맥락 파악** — `repo-map.md`로 구조 파악. 관련 파일 탐색.
2. **정책 확인** — 변경 대상에 해당하는 정책 문서 확인.
3. **스킬 참조** — 작업 유형에 맞는 스킬이 있으면 core/skills 참조.
4. **변경 실행** — 최소 범위로 변경. 금융 로직 수정 시 `safety-rules.md` 재확인.
5. **검증 보고** — 빌드·테스트 결과 보고.

## Gemini 전용 지시

- GEMINI.md를 진입점으로 사용한다.
- MCP 서버 연동 시 `.ai/gemini/mcp/README.md`를 참조한다.
- 멀티모달 입력(이미지, 로그 스크린샷)을 활용할 수 있다.

## 오버라이드 규칙

스킬별 Gemini 특화 동작이 필요하면 `.ai/adapters/gemini/overrides/<skill-name>.md`에 정의한다.
오버라이드 파일이 없으면 `.ai/core/skills/<skill-name>/skill.md` 본문을 그대로 사용한다.
