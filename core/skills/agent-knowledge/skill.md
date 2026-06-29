# agent-knowledge — 작업 가이드 지식 베이스 사용

이 프로젝트는 **AgentKnowledge**(작업 가이드 KB — "이 작업은 이렇게 하면 한 번에 된다"를 모아둔 곳)를 참조한다.
**작업 가이드가 본체**이고 과거의 시행착오·증상은 그 가이드를 뒷받침한다.
KB의 **실제 경로**는 `.ai-local/policies/agent-knowledge.md`의 핀을 따른다.
**전체 프로토콜·스키마의 단일 진실원본은 KB repo의 `AGENTS.md`** 다(주로 *쓸 때* 참조) — 일상 조회는 그 파일을 열지 말고 `INDEX.md`부터. 여기서는 중복하지 않고 운영 요점만 둔다.

## 언제 읽나 (어떤 작업을 시작할 때)

1. KB의 **`INDEX.md` 하나만 먼저** 연다. (id·summary·task·status 카탈로그; symptoms는 보조)
2. 하려는 **작업**을 `task`로 매칭한다(디버깅 중이면 `symptoms`로도). 후보가 여럿이면 `summary`로 고른다.
3. **고른 entry 1개만** 열고, **「올바른 방법 — 그대로 따라하기」 섹션부터** 따라간다. INDEX가 놓치면 KB `entries/`를 grep.

→ KB 전체를 컨텍스트에 넣지 않는다 (토큰 전략의 핵심).

### snippets 읽기 규칙

- entry가 `snippets/<slug>/`를 참조하면, 먼저 해당 snippet 디렉터리의 `README.md`만 읽어 파일 역할과 필요한 파일을 확인한다.
- snippet 파일은 entry 또는 snippet `README.md`가 지정한 파일만 **1개씩** 연다.
- `snippets/` 전체 또는 snippet 디렉터리 전체를 한 번에 읽지 않는다. 큰 코드/Tcl 정본은 필요한 부분만 선별해 읽는다.

## 언제 쓰나 (capture)

어려운 작업을 한 번에 해내는 길을 찾은 세션 끝에 사용자가 "이거 KB로 정리해" 하면:

1. KB의 `templates/entry-template.md`를 `entries/<id>.md`로 복사.
2. frontmatter를 KB `AGENTS.md`의 스키마·허용 어휘대로 채운다 (`id`=파일명·불변, `task`=주 매칭 키).
3. 본문은 **「올바른 방법」을 먼저** 작성(가이드가 본체). 시행착오는 「배경」 섹션에 뒤따른다.
4. `python3 scripts/build_index.py`로 INDEX를 재생성.

→ INDEX는 손으로 고치지 말고 항상 생성기로 (drift 방지).

## 원칙

- **가이드 우선**: 주 검색축은 "무슨 작업을 하려는가"(`task`). 증상은 막혔을 때의 보조 진입점.
- **단일 원본**: KB는 한 벌만 존재하고 모든 프로젝트가 경로로 참조한다. 복사·서브모듈 금지.
- **MCP 회피**: 탐색은 `Read`/`grep`. 의미 검색이 꼭 필요한 임계점 전까지 MCP·DB·FTS5 미도입.

## 프로젝트 연결 (프로젝트당 한 번)

프로젝트 루트에 `.ai-local/policies/agent-knowledge.md`를 만들고 이 PC의 KB 경로를 핀으로 둔다.
보일러플레이트는 같은 폴더의 `pin-example.md` 참조 — generate.sh가 이 핀을 컨텍스트 파일에 병합한다.
