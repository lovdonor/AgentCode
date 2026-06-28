# AgentKnowledge 기획

AI 에이전트가 **어떤 작업을 다음에 한 번에 올바르게 수행하도록 가이드**하는 지식 저장소.
"이 작업은 이런 API/순서로 한다"는 **작업 가이드가 본체**이고, 과거의 시행착오·증상은 그 가이드를 뒷받침한다.
사람이 브라우징하는 위키가 아니라, 에이전트가 **작업으로 검색·매칭**하는 agent-native KB (증상은 보조 진입점).

- 대상: 솔로 개발자, 주로 코딩 분야, 프로젝트당 소스 200개 이하
- 핵심 요구: 토큰 절약 / read-heavy(업데이트보다 사용이 많음) / MCP 최대한 회피

---

## 1. 설계 원칙

1. **1 사건 = 1 파일.** lesson·recipe·mistake·decision·checklist는 폴더가 아니라 한 entry 안의 섹션. 사건 단위 응집을 깨지 않는 게 검색의 최우선.
2. **작업으로 매칭.** 에이전트는 폴더를 브라우징하지 않고 `task`(주)·`tech`·`status`로 매칭하며, 막혔을 땐 `symptoms`(보조)로도 찾는다. 타입(recipe·lesson·mistake·decision)은 폴더가 아니라 entry 섹션이다.
3. **위키 시스템은 No, 위키식 링크는 Yes.** 별도 위키/DB 없이 평평한 마크다운 + `[[wikilink]]`/상대경로 + frontmatter `related`로 그래프를 만든다. INDEX.md가 메인 허브. 보고 싶을 때만 같은 폴더를 Obsidian으로 열어 백링크·그래프 뷰를 얻는다.
4. **staleness를 명시.** `status` + `last_verified` + `versions`로 지식의 유효기간을 표시. "기술적으론 되지만 라이선스로 롤백" 같은 제약 조건을 decision 섹션에 보존한다.
5. **capture 마찰 제로.** 직접 쓰지 말고, 어려운 문제를 푼 세션 끝에 에이전트에게 "이거 KB entry로 정리해"라고 시킨다.
6. **단일 진실원본(single source of truth).** KB는 항상 최신 한 벌만 존재하고 모든 프로젝트가 그것을 참조한다.

---

## 2. 디렉터리 구조

```
AgentKnowledge/
  AGENTS.md       # 에이전트 사용 규약 (읽기/쓰기 프로토콜) — 가장 중요
  INDEX.md        # 허브 페이지: task·tech별 entry 링크 목차 (생성물)
  entries/        # 1 사건 = 1 마크다운 파일 (KB의 본체)
  snippets/       # 여러 entry가 공유하는 코드만 분리
  projects/       # 프로젝트별 얇은 프로필 + 적용 entry 목록
  decisions/      # (선택) 프로젝트 횡단의 영속적 결정 = ADR
```

- 전부 git로 버전 관리.
- 별도 위키 시스템·DB·FTS5 인덱스 **없음**.
- `lessons/recipes/mistakes/checklists` 같은 타입별 폴더는 두지 않는다(entry 섹션으로 흡수).

---

## 3. entry frontmatter 스키마 (확정본)

```yaml
id: 2026-05-30-wpf-telerik-raddocking-layout-persistence  # == 파일명, 불변 opaque 핸들
title: Telerik RadDocking 레이아웃 저장/복원 — 구현 가이드   # 작업 가이드명
summary: "RadDocking 동적 pane 레이아웃을 한 번에 저장/복원하는 올바른 API 사용법"  # INDEX 선택용 = 작업 + 핵심 방법, 한 줄
task:                            # ★ 주 매칭 키 — 무슨 작업을 하려는가 (자연어)
  - "Telerik RadDocking 레이아웃 save/load 구현"
  - "WPF 동적 생성 pane 레이아웃 영속화"
created: 2026-05-30
last_verified: 2026-05-30
domain: wpf                      # 닫힌 어휘 = INDEX 분할 키
tech: [dotnet, telerik, raddocking]
symptoms:                        # 보조 진입점 — 이 가이드가 막아주는 증상 (비워도 됨)
  - "복원된 pane content가 비어있음"
  - "런타임에 동적 생성한 pane이 사라짐"
root_causes: [content-not-serialized, unstable-pane-id, wrong-load-timing]  # 보조: naive 실패 이유
status: verified          # verified | unverified | stale
resolution: workaround    # (선택) trouble-shooting 성격일 때만
versions: { dotnet: "4.8", telerik: "unknown", windows: "11" }
projects: [Monsoon]
related: ["[[wpf-layout-persistence-pattern]]"]
superseded_by: []
```

### 필드 설계 근거

- **`task`가 주 매칭 키.** 이 KB의 본질은 "다음에 *이 작업*을 한 번에 올바르게 하는 가이드"이므로, 에이전트는 하려는 **작업**을 `task`로 매칭한다. `symptoms`는 디버깅하다 들어오는 *보조* 진입점으로 강등 — 한 entry가 작업 가이드이면서 증상으로도 발견된다.
- **summary는 INDEX 선택용 필드.** `task`(매칭)·`title`(이름)과 직교한다 — `task`로 *매칭*하고 `summary`로 *선택*한다(후보가 여럿일 때 entry를 열지 않고 고르게 함). 따라서 summary는 `[작업] + [핵심 방법]` 한 줄로 적는다. (INDEX는 frontmatter에서 생성되므로 summary는 *사본*이 아니라 *원본* → drift 없음)
- **상태는 직교하는 2축만 유지.**
  - `resolution` (해법의 질): `fix` / `workaround` / `rolled-back` / `none`
  - `status` (신뢰도·현행성): `verified` / `unverified` / `stale`
  - `lifecycle`·`confidence`·`agent_priority`·`types`는 제거 — 중복이거나 파생 가능하거나 주관적이라 솔로 환경에서 drift한다. (`confidence`는 `status`와 중복, `priority`는 결국 전부 high, `types`는 §4 본문 7섹션의 채움 여부에서 파생됨)
  - **`superseded`는 `status` enum에서 제거.** 대체됨은 `superseded_by` 링크 유무로만 표현한다(같은 정보를 두 곳에 두지 않는다). 링크가 대체 대상까지 담아 더 유용하다.
  - **`updated` 필드 불채택.** "마지막 편집 시각"은 git이 정확·무료로 보유한다(KB 전체가 git 관리). "편집했지만 미검증" 상태는 날짜가 아니라 `status: unverified`로 표현한다.
  - **`resolution`은 선택 필드.** 순수 작업 가이드면 `none`/생략하고, trouble-shooting 성격(문제를 풀어 가이드가 된 경우)일 때만 `fix`/`workaround`/`rolled-back`을 채운다.
- **task·symptoms 모두 자연어 문장으로 유지.** 슬러그는 통제 어휘 파일을 따로 관리해야 하고 의미 검색에 불리하다. `task`는 "무엇을 하려는가", `symptoms`는 "이 가이드가 막아주는 증상"으로 적되, symptoms엔 가능하면 **실제 에러 메시지 원문**을 포함해 grep·임베딩 recall을 높인다. (나중에 임베딩 인덱스를 붙이며 필터용 슬러그를 *병행 추가*하는 것은 가능)
- **root_causes는 슬러그 허용.** 종류가 한정적이라 슬러그가 견딜 만하다. (매칭이 아니라 보조 주석 용도 — 「배경」 섹션의 근거. 슬러그가 약간 흔들려도 무해)
- **domain은 닫힌 어휘.** 거친 상위 버킷(wpf/fpga/web). `tech`는 구체적인 것만(중복 제거). domain은 INDEX 분할 키(§6)이므로 `task`/`symptoms`보다 엄격하게 일관성을 지킨다 — 허용 목록은 KB의 AGENTS.md에 박아 쓰기 시점에 강제.
- **프로젝트 연결은 `projects:` 필드로 단일화.** `related`는 entry↔entry/concept 링크 전용으로 비운다(`[[project-monsoon]]` 같은 프로젝트 링크 중복 제거). 프로젝트 프로필은 `projects/` 폴더가 담당.
- **versions**는 staleness 판단의 기준점이므로 가능한 채운다. 값 포맷은 일관되게(다중 타깃이면 명시적으로), 모르면 `"unknown"`을 *명시*해 생략과 구분한다.

---

## 4. entry 본문 템플릿

```markdown
## 목표 / 작업
## 올바른 방법 — 그대로 따라하기   ★ recipe (핵심, 맨 앞)
## 핵심 API / 코드            (snippets 링크 포함)
## 검증 방법                (checklist)
## 함정 (반복 금지)
## 배경: 시행착오와 원인       (보조 — lessons + mistakes, naive 실패 이유)
## 왜 이 방식 / 트레이드오프    (decision, 제약 포함)
```

**레시피(올바른 방법)가 본체**이고 시행착오는 「배경」으로 뒤따른다. 타입(recipe·lesson·mistake·decision)은 별도 필드가 아니라 섹션 채움 여부로 드러난다.

---

## 5. 운영 / 배치 방식

### 위치: PC 상위 디렉터리에 단일 KB (독립 git repo)

```
~/knowledge/AgentKnowledge/     ← 단일 원본, 독립 git repo
   AGENTS.md  INDEX.md  entries/ ...

~/projects/Monsoon/
   AGENTS.md   ← "지식은 ~/knowledge/AgentKnowledge/ 참조" 명시
~/projects/<기타>/
   AGENTS.md
```

- KB를 **자체 git repo로 독립**시키되, 프로젝트에 **서브모듈로 끼우지 않는다.**
- 각 프로젝트는 **경로만 가리킨다**(심볼릭 링크보다 경로 명시 권장 — OS·도구에 따라 에이전트가 심링크를 못 따라가는 경우가 있음).
- KB는 한 곳에서 한 번 업데이트되고 모든 프로젝트가 즉시 최신을 본다 → "업데이트 N회" 문제 소멸.

### 채택하지 않은 방식과 이유

- **서브모듈 탑재 (AgentCode에 KB 합치기): 채택 안 함.** 서브모듈은 특정 커밋에 핀되는 스냅샷 동기화 모델이라, 항상 최신을 원하는 read-heavy 지식과 철학이 반대. entry 추가마다 N개 프로젝트에서 update+commit 필요 → capture 마찰 부활.
- **MCP: 현 단계 보류.** 의미 검색으로 "수백 entry 중 관련된 것만" 꺼낼 임계점에 도달했을 때 가치가 있음. 현재 규모에선 오버헤드·서버 상주·capture 번거로움만 늘어남.
- **기존 AgentCode repo(샘플 코드·도구)는 서브모듈 그대로 유지.** 버전 고정이 의미 있는 코드 자산이라 서브모듈이 적합. 성질이 다른 KB와는 분리.

---

## 6. 읽기 프로토콜 (토큰 전략의 핵심)

디렉터리 위치보다 토큰에 더 큰 영향을 준다. 핵심은 **KB 전체를 컨텍스트에 넣지 않는 것.**

1. 에이전트는 항상 `INDEX.md` **하나만 먼저** 로드한다. (entry 본문이 아니라 `id`·`summary`·`task`·`status`만 담긴 가벼운 카탈로그; symptoms는 보조)
2. 하려는 **작업**을 `task`로 매칭하고(디버깅 중이면 `symptoms`로도), 후보가 여럿이면 `summary`로 고른다 — entry를 열지 않고 선택.
3. **그 한 개 파일만** 열고, **「올바른 방법」 섹션부터** 따라간다.

INDEX 한 행 예시:

```
- [[2026-05-30-wpf-telerik-raddocking-layout-persistence]] — RadDocking 동적 pane 레이아웃을 한 번에 저장/복원하는 올바른 API 사용법  ·verified  ⟨Telerik RadDocking 레이아웃 save/load 구현 / WPF 동적 생성 pane 레이아웃 영속화⟩  [복원된 pane content가 비어있음 / 런타임에 동적 생성한 pane이 사라짐]
```

→ 평소 읽기 비용 = "INDEX(작음) + entry 1개"로 고정.
→ INDEX.md를 가볍게 유지하는 게 토큰 전략의 핵심. entry가 수백 개로 늘면 INDEX를 domain별로 분할.
→ **INDEX.md는 손으로 유지하지 말고 entries/*.md frontmatter에서 생성한다.** task·summary·symptoms·status가 entry와 INDEX 두 곳에 비정규화되므로, 손 유지하면 capture 마찰 제로(§1.5) 흐름에서 곧바로 drift한다. capture 프로토콜의 마지막 단계 = "entry 저장 → INDEX 재생성". (최소한 INDEX 미스 시 `entries/`를 직접 grep하는 폴백을 둔다)

---

## 7. 인덱스 진화 경로

- **지금:** 마크다운 + frontmatter + INDEX.md + grep로 충분.
- **키워드 검색이 자꾸 놓치기 시작하면:** FTS5가 아니라 **임베딩 기반 의미 검색**을 그때 얹는다. (작업/증상 기반 의미 매칭이 본질이라 lexical 검색은 한계가 있음)

---

## 8. 다음 할 일

- [ ] `~/knowledge/AgentKnowledge/` 독립 repo 생성
- [ ] AGENTS.md 작성 (참조 경로 + 읽기/쓰기 프로토콜)
- [ ] 프로젝트 쪽 AGENTS.md 한 줄 참조 문구 작성
- [ ] INDEX.md 생성기 작성 (entries frontmatter → `id`·`summary`·`task`·`symptoms`·`status` 행으로 재생성)
- entry 작성·관리는 AgentKnowledge repo 의 `entries/`에서 한다 (설계 문서에는 개별 entry를 보관하지 않음)
