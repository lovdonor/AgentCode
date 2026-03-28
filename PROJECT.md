# AgentCode — 멀티 에이전트 공유 규칙·스킬 저장소

## 1. 프로젝트 목적

다양한 AI 에이전트(Claude Code, Codex/OpenAI, Gemini 등)를 여러 프로젝트에 걸쳐 일관성 있게 활용하기 위해,
**규칙(rules)·정책(policies)·스킬(skills)을 단일 저장소에서 중앙 관리**하는 것을 목표로 한다.

실제 프로젝트에서는 이 저장소를 **Git Submodule**로 연결(`git submodule add`)하여
에이전트에게 제공할 컨텍스트 파일(CLAUDE.md / AGENTS.md / GEMINI.md)을 자동으로 생성한다.

### 핵심 원칙

| 원칙 | 내용 |
|------|------|
| **단일 진실 소스** | 모든 공통 규칙·스킬은 `.ai/core/`에만 존재한다 |
| **모델 독립성** | `core`는 특정 AI 모델에 종속되지 않는다 |
| **어댑터 패턴** | 모델별 차이는 `adapters/<model>/`에서만 처리한다 |
| **자동 생성** | 루트의 `CLAUDE.md` / `AGENTS.md` / `GEMINI.md`는 직접 수정하지 않고 스크립트로 생성한다 |
| **프로젝트 오버레이** | 프로젝트 전용 규칙은 `.ai-local/`에 추가하며 공유 저장소를 오염시키지 않는다 |

---

## 2. 전체 디렉토리 구조

```
AgentCode/                          ← 이 저장소 루트 (git submodule 대상)
│
├── CLAUDE.md                       ← [자동 생성] Claude Code용 컨텍스트
├── AGENTS.md                       ← [자동 생성] Codex(OpenAI)용 컨텍스트
├── GEMINI.md                       ← [자동 생성] Gemini용 컨텍스트
├── README.md                       ← 기술 참조 문서
├── PROJECT.md                      ← 이 파일 (프로젝트 전체 설명)
│
└── .ai/
    ├── core/                       ← 단일 진실 소스 (모델 무관)
    │   ├── policies/               ← 프로젝트 공통 정책 문서들
    │   │   ├── coding-standards.md
    │   │   ├── architecture-rules.md
    │   │   ├── testing-policy.md
    │   │   ├── safety-rules.md
    │   │   └── repo-map.md
    │   │
    │   ├── skills/                 ← 재사용 가능한 스킬 묶음
    │   │   └── <skill-name>/
    │   │       ├── manifest.yaml   ← 메타데이터, 트리거 조건, 의존 정책
    │   │       ├── skill.md        ← 스킬 본문 (에이전트가 읽는 지시문)
    │   │       ├── checklist.md    ← (선택) 단계별 체크리스트
    │   │       └── scripts/        ← (선택) 헬퍼 스크립트
    │   │
    │   └── templates/              ← 재사용 템플릿
    │       └── manifest-template.yaml
    │
    ├── adapters/                   ← 모델별 어댑터 (차이만 정의)
    │   ├── _base.md                ← 공통 프리앰블 (모든 모델에 포함)
    │   ├── claude/
    │   │   ├── preamble.md         ← Claude Code 전용 지시
    │   │   └── overrides/          ← 스킬별 Claude 특화 오버라이드
    │   ├── codex/
    │   │   ├── preamble.md         ← Codex 전용 지시
    │   │   └── overrides/
    │   └── gemini/
    │       ├── preamble.md         ← Gemini 전용 지시
    │       └── overrides/
    │
    └── scripts/
        └── generate.sh             ← 루트 .md 파일 자동 생성 스크립트
```

---

## 3. 핵심 컴포넌트 설명

### 3-1. `_base.md` — 공통 프리앰블

모든 모델에 공통으로 삽입되는 내용.
프로젝트 개요, 핵심 원칙, 정책 참조 목록, 스킬 참조 안내 등을 담는다.

### 3-2. `adapters/<model>/preamble.md` — 모델별 지시문

각 AI 에이전트의 특성에 맞는 응답 형식, 워크플로우, 전용 지시를 정의한다.

| 파일 | 주요 내용 |
|------|----------|
| `claude/preamble.md` | XML 분석 포맷, TodoList, `/compact` 지시 등 Claude Code 특성 반영 |
| `codex/preamble.md` | PR 단위 변경, 샌드박스 제약 고려 |
| `gemini/preamble.md` | 멀티모달 입력 활용, MCP 서버 연동 안내 |

### 3-3. `core/skills/<name>/` — 스킬

특정 작업 유형(빌드, 리뷰, 디버깅 등)에 대한 에이전트 행동 지침 묶음.

```yaml
# manifest.yaml 예시
name: code-review
version: "1.0"
description: 코드 리뷰 요청 시 활성화되어 체계적 리뷰를 수행한다.
policies:
  - coding-standards
  - safety-rules
triggers:
  - "코드 리뷰"
  - "review"
adapters:
  claude: override       # adapters/claude/overrides/code-review.md 적용
  codex: default
  gemini: default
```

### 3-4. `generate.sh` — 자동 생성 스크립트

**생성 순서:**
1. 공통 `_base.md` 삽입
2. 모델별 `preamble.md` 삽입
3. `core/skills/` 내 각 스킬 삽입 (오버라이드 파일이 있으면 우선 적용)
4. `.ai-local/` 존재 시 프로젝트 전용 내용 추가 머지

---

## 4. 실제 프로젝트에서의 사용법

### Step 1 — Submodule 추가

```bash
cd my-project
git submodule add https://github.com/lovdonor/AgentCode.git .ai
```

### Step 2 — 에이전트 컨텍스트 파일 생성

```bash
# 전체 모델 생성
.ai/scripts/generate.sh

# 특정 모델만 생성
.ai/scripts/generate.sh claude
.ai/scripts/generate.sh gemini
```

생성된 파일:

```
my-project/
├── CLAUDE.md    ← Claude Code가 자동으로 읽는 컨텍스트
├── AGENTS.md    ← Codex가 자동으로 읽는 컨텍스트
├── GEMINI.md    ← Gemini가 자동으로 읽는 컨텍스트
└── .ai/         ← submodule (이 저장소)
```

생성된 파일들을 프로젝트 저장소에 커밋한다:

```bash
git add CLAUDE.md AGENTS.md GEMINI.md
git commit -m "chore: AI 컨텍스트 파일 초기 생성"
```

### Step 3 — 프로젝트 전용 규칙 추가 (`.ai-local/`)

공유 저장소(AgentCode)를 수정하지 않고 프로젝트 고유 내용을 추가하려면
프로젝트 루트에 `.ai-local/` 디렉토리를 생성한다.

```
my-project/
├── .ai/                         ← submodule (AgentCode, 수정 금지)
├── .ai-local/                   ← 프로젝트 전용 (이 저장소에 커밋)
│   ├── policies/
│   │   └── project-rules.md     ← 프로젝트 전용 정책
│   └── skills/
│       └── deploy/
│           ├── manifest.yaml
│           └── skill.md         ← 프로젝트 전용 스킬
├── CLAUDE.md
└── ...
```

`generate.sh` 재실행 시 `.ai-local/` 내용이 자동으로 머지된다.

### Step 4 — Submodule 업데이트 (공유 규칙 갱신)

AgentCode 저장소에 새로운 스킬이나 정책이 추가된 경우:

```bash
# submodule 최신화
git submodule update --remote .ai

# 컨텍스트 파일 재생성
.ai/scripts/generate.sh

# 변경사항 커밋
git add .ai CLAUDE.md AGENTS.md GEMINI.md
git commit -m "chore: AI 규칙 업데이트 반영"
```

---

## 5. 스킬 추가 가이드

새로운 스킬을 공유 저장소에 추가하는 절차:

```bash
# 1. 스킬 디렉토리 생성
mkdir -p .ai/core/skills/my-skill

# 2. manifest.yaml 작성 (templates/manifest-template.yaml 참조)
cp .ai/core/templates/manifest-template.yaml .ai/core/skills/my-skill/manifest.yaml

# 3. skill.md 작성 (에이전트용 지시문)
touch .ai/core/skills/my-skill/skill.md

# 4. 모델별 오버라이드가 필요한 경우 (선택)
touch .ai/adapters/claude/overrides/my-skill.md

# 5. 컨텍스트 파일 재생성
.ai/scripts/generate.sh
```

---

## 6. 파일 수정 규칙

| 파일/경로 | 수정 방법 |
|-----------|----------|
| `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` | **직접 수정 금지** → `generate.sh`로 재생성 |
| `.ai/adapters/_base.md` | 모든 모델에 공통 적용할 내용만 추가 |
| `.ai/adapters/<model>/preamble.md` | 해당 모델 전용 지시만 추가 |
| `.ai/core/skills/<name>/skill.md` | 스킬 본문 자유 수정 가능 |
| `.ai-local/` | 프로젝트 저장소에 커밋, AgentCode 저장소와는 무관 |

---

## 7. 브랜치 전략

```
main          ← 안정 버전. 실제 프로젝트의 submodule이 참조
dev           ← 개발 브랜치. 새 스킬/정책 실험
feature/*     ← 특정 스킬/정책 개발 단위
```

프로젝트의 `.gitmodules`에서 특정 브랜치를 고정하는 것을 권장한다:

```ini
[submodule ".ai"]
    path = .ai
    url = https://github.com/lovdonor/AgentCode.git
    branch = main
```

---

## 8. 지원 에이전트 목록

| 에이전트 | 진입점 파일 | 어댑터 경로 |
|----------|------------|------------|
| Claude Code | `CLAUDE.md` | `.ai/adapters/claude/` |
| Codex / OpenAI | `AGENTS.md` | `.ai/adapters/codex/` |
| Gemini (Antigravity) | `GEMINI.md` | `.ai/adapters/gemini/` |
